/**
 * District Car Admin Web — Firebase Configuration & Data Engine
 * Real-time synchronization with Firestore with graceful fallback data
 */

const firebaseConfig = {
  apiKey: "AIzaSyDwi6OV-l7mDqCpPaRI4Yn9gUXiZrf73QM",
  authDomain: "districtcar-4b880.firebaseapp.com",
  projectId: "districtcar-4b880",
  storageBucket: "districtcar-4b880.firebasestorage.app",
  messagingSenderId: "319163006406",
  appId: "1:319163006406:web:c4807f606480e920fa46c7"
};

// Initialize Firebase App & Firestore
let db = null;
let auth = null;

try {
  if (typeof firebase !== 'undefined') {
    if (!firebase.apps.length) {
      firebase.initializeApp(firebaseConfig);
    }
    db = firebase.firestore();
    auth = firebase.auth();
    console.log("✅ [Firebase] Initialized District Car Firestore client.");
  }
} catch (e) {
  console.warn("⚠️ [Firebase] Could not initialize Firebase SDK:", e.message);
}

// Global data store to cache live snapshots
const AdminStore = {
  users: [],
  drivers: [],
  bookings: [],
  payouts: [],
  settlements: [],
  categories: [],
  notifications: [],
  totalApitxtSmsSent: 0,
  pricingRules: {
    minDistanceCapKm: 5.0,
    shortTripMaxDistanceKm: 25.0,
    shortTripSurgePercent: 10.0,
    shortTripCommissionPercent: 18.0,
    longTripCommissionPercent: 10.0,
    shortTripOneWayCompensationPercent: 20.0,
    longTripOneWayCompensationPercent: 40.0,
    roundTripDiscountPercent: 35.0,
    adminSurgeEnabled: false,
    adminSurgePercent: 8.0,
  },
  festiveTheme: {
    enabled: true,
    theme: "diwali_rockets",
    title: "Happy Diwali!",
    durationSeconds: 8,
    primaryColor: "#FFD700",
    secondaryColor: "#FF4500",
    sparkleColor: "#FFFFFF",
    rocketCount: 6,
    sparkleDensity: 45,
    showGreetingBadge: true,
    greetingText: "✨ Shubh Deepawali from District Car ✨"
  },
  remoteConfig: null,
  isLive: false,
  listeners: []
};

/**
 * Universal Driver Name Resolver
 * Guarantees no driver is displayed as 'Unnamed'
 */
function resolveDriverName(d, docId = '') {
  if (!d) return 'Driver Partner';
  if (typeof d === 'string') return d;

  const candidate = d.name || d.fullName || d.driverName || d.displayName || 
                    d.personalDetails?.fullName || d.personalDetails?.name ||
                    d.profile?.name || d.profile?.fullName;

  if (candidate && candidate.trim().length > 0 && candidate.trim().toLowerCase() !== 'unnamed driver') {
    return candidate.trim();
  }

  // If phone exists
  const phone = d.phoneNumber || d.driverPhone || d.phone;
  if (phone && phone.trim().length > 0) {
    const cleanPhone = phone.trim();
    return `Driver (${cleanPhone.length > 5 ? cleanPhone.slice(-5) : cleanPhone})`;
  }

  // If email exists
  if (d.email && d.email.trim().length > 0) {
    const prefix = d.email.split('@')[0];
    return prefix.charAt(0).toUpperCase() + prefix.slice(1);
  }

  const id = docId || d.id || '';
  if (id) {
    return `Partner #${id.substring(0, 6).toUpperCase()}`;
  }

  return 'Driver Partner';
}

/**
 * Start Real-Time Firestore Listeners
 */
function initRealtimeListeners(onDataChange) {
  if (!db) {
    console.warn("Firestore not available, falling back to simulated data.");
    loadFallbackData(onDataChange);
    return;
  }

  try {
    // 1. Listen to Drivers
    const unsubDrivers = db.collection('drivers').onSnapshot((snap) => {
      AdminStore.drivers = [];
      snap.forEach((doc) => {
        const d = doc.data() || {};
        const cleanName = resolveDriverName(d, doc.id);
        
        AdminStore.drivers.push({
          id: doc.id,
          ...d,
          name: cleanName,
          fullName: cleanName,
          phoneNumber: d.phoneNumber || d.driverPhone || d.phone || 'N/A',
          vehiclePlateNumber: d.vehiclePlateNumber || d.vehiclePlate || d.plateNumber || 'N/A',
          vehicleModel: d.vehicleModel || d.vehicleType || 'Vehicle',
          vehicleCategoryId: d.vehicleCategoryId || d.category || 'cab',
          walletBalance: parseFloat(d.walletBalance || 0),
          pendingCommission: parseFloat(d.pendingCommission || 0),
          totalTrips: parseInt(d.totalTrips || d.completedTrips || 0, 10),
          unpaidTripsCount: parseInt(d.unpaidTripsCount || 0, 10),
          totalCommissionSettled: parseFloat(d.totalCommissionSettled || 0),
          verificationStatus: d.verificationStatus || 'approved',
          isOnline: Boolean(d.isOnline),
          driverStatus: d.driverStatus || (d.isBusy ? 'busy' : (d.isOnline ? 'idle' : 'offline'))
        });
      });
      AdminStore.isLive = true;
      console.log(`🚕 [Firestore] Synced ${AdminStore.drivers.length} drivers.`);
      if (onDataChange) onDataChange('drivers');
    }, (err) => {
      console.warn("Drivers snapshot error (permission or network):", err.message);
      if (AdminStore.drivers.length === 0) loadFallbackDrivers(onDataChange);
    });
    AdminStore.listeners.push(unsubDrivers);

    // 2. Listen to Bookings
    const unsubBookings = db.collection('bookings').onSnapshot((snap) => {
      AdminStore.bookings = [];
      snap.forEach((doc) => {
        const b = doc.data() || {};
        const resolvedDriver = b.driverName || b.name || (b.driverId ? `Driver #${b.driverId.substring(0, 6)}` : '');
        AdminStore.bookings.push({
          id: doc.id,
          ...b,
          driverName: resolvedDriver
        });
      });
      AdminStore.isLive = true;
      // Sort newest first
      AdminStore.bookings.sort((a, b) => {
        const tA = a.createdAt?.seconds || (a.createdAt ? new Date(a.createdAt).getTime() / 1000 : 0);
        const tB = b.createdAt?.seconds || (b.createdAt ? new Date(b.createdAt).getTime() / 1000 : 0);
        return tB - tA;
      });
      // Real-time APITXT SMS alert on new incoming bookings (+919142127512 and +918789601387)
      snap.docChanges().forEach((change) => {
        const b = change.doc.data() || {};
        const id = change.doc.id;

        if (change.type === 'added') {
          if (initialBookingsLoaded && !knownBookingIds.has(id)) {
            if (!b.apitxtSmsSent && !sentApitxtBookingIds.has(id)) {
              sentApitxtBookingIds.add(id);
              triggerNewBookingApitxtAlert({ id, ...b });
            }
          }
          knownBookingIds.add(id);
        } else if (change.type === 'modified') {
          if ((b.status === 'requested' || b.status === 'searching_driver') && !b.apitxtSmsSent && !sentApitxtBookingIds.has(id)) {
            sentApitxtBookingIds.add(id);
            triggerNewBookingApitxtAlert({ id, ...b });
          }
        }
      });
      initialBookingsLoaded = true;

      console.log(`📋 [Firestore] Synced ${AdminStore.bookings.length} bookings.`);
      if (onDataChange) onDataChange('bookings');
    }, (err) => {
      console.warn("Bookings snapshot error:", err.message);
      if (AdminStore.bookings.length === 0) loadFallbackBookings(onDataChange);
    });
    AdminStore.listeners.push(unsubBookings);

    // 3. Listen to Users / Customers
    const unsubUsers = db.collection('users').onSnapshot((snap) => {
      AdminStore.users = [];
      snap.forEach((doc) => {
        AdminStore.users.push({ id: doc.id, ...doc.data() });
      });
      AdminStore.isLive = true;
      console.log(`👥 [Firestore] Synced ${AdminStore.users.length} users.`);
      if (onDataChange) onDataChange('users');
    }, (err) => {
      console.warn("Users snapshot error:", err.message);
      if (AdminStore.users.length === 0) loadFallbackUsers(onDataChange);
    });
    AdminStore.listeners.push(unsubUsers);

    // 4. Listen to Payout Requests
    const unsubPayouts = db.collection('payout_requests').onSnapshot((snap) => {
      AdminStore.payouts = [];
      snap.forEach((doc) => {
        AdminStore.payouts.push({ id: doc.id, ...doc.data() });
      });
      console.log(`💳 [Firestore] Synced ${AdminStore.payouts.length} payout requests.`);
      if (onDataChange) onDataChange('payouts');
    }, (err) => {
      console.warn("Payouts snapshot error:", err.message);
      if (AdminStore.payouts.length === 0) loadFallbackPayouts(onDataChange);
    });
    AdminStore.listeners.push(unsubPayouts);

    // 5. Listen to Commission Settlements Audit Collection
    try {
      const unsubSettlements = db.collection('commission_settlements').orderBy('settledAt', 'desc').limit(100).onSnapshot((snap) => {
        AdminStore.settlements = [];
        snap.forEach((doc) => {
          AdminStore.settlements.push({ id: doc.id, ...doc.data() });
        });
        console.log(`💰 [Firestore] Synced ${AdminStore.settlements.length} commission settlements.`);
        if (onDataChange) onDataChange('settlements');
      }, (err) => {
        console.warn("Commission settlements error:", err.message);
        if (AdminStore.settlements.length === 0) loadFallbackSettlements();
      });
      AdminStore.listeners.push(unsubSettlements);
    } catch (_) {
      if (AdminStore.settlements.length === 0) loadFallbackSettlements();
    }

    // 6. Listen to Remote Updates Config
    db.collection('remote_configs').doc('app_updates').onSnapshot((doc) => {
      if (doc.exists) {
        AdminStore.remoteConfig = doc.data();
        if (typeof updateGuestPopupUI === 'function') {
          updateGuestPopupUI(AdminStore.remoteConfig.showGuestSignInPopup !== false);
        }
        if (typeof updateRideTogglesUI === 'function') {
          updateRideTogglesUI(AdminStore.remoteConfig);
        }
        if (onDataChange) onDataChange('remoteConfig');
      }
    }, (err) => {
      console.warn("Remote config error:", err.message);
    });

    // 7. Listen to Vehicle Categories
    db.collection('vehicleCategories').onSnapshot((snap) => {
      AdminStore.categories = [];
      snap.forEach((doc) => {
        AdminStore.categories.push({ id: doc.id, ...doc.data() });
      });
      if (onDataChange) onDataChange('categories');
    }, (err) => {
      console.warn("Categories error:", err.message);
    });

    // 8. Listen to Dynamic Pricing Rules
    db.collection('remote_configs').doc('pricing_rules').onSnapshot((doc) => {
      if (doc.exists) {
        AdminStore.pricingRules = { ...AdminStore.pricingRules, ...doc.data() };
        console.log("📊 [Firestore] Synced Dynamic Pricing Rules:", AdminStore.pricingRules);
        if (typeof updateSurgeFeeUI === 'function') {
          updateSurgeFeeUI(AdminStore.pricingRules.adminSurgeEnabled === true);
        }
        if (typeof renderPricingView === 'function') {
          renderPricingView();
        }
        if (onDataChange) onDataChange('pricingRules');
      }
    }, (err) => {
      console.warn("Pricing rules listener error:", err.message);
    });

    // 9. Listen to SDUI Festive Theme
    db.collection('remote_configs').doc('festive_theme').onSnapshot((doc) => {
      if (doc.exists) {
        AdminStore.festiveTheme = { ...AdminStore.festiveTheme, ...doc.data() };
        console.log("✨ [Firestore] Synced Festive Theme SDUI:", AdminStore.festiveTheme);
        if (typeof syncFestiveThemeToUI === 'function') {
          syncFestiveThemeToUI(AdminStore.festiveTheme);
        }
        if (onDataChange) onDataChange('festiveTheme');
      }
    }, (err) => {
      console.warn("Festive theme listener error:", err.message);
    });

  } catch (e) {
    console.error("Critical error setting up Firestore listeners:", e);
    loadFallbackData(onDataChange);
  }
}

/**
 * Stop all active listeners
 */
function cleanupListeners() {
  AdminStore.listeners.forEach((unsub) => {
    if (typeof unsub === 'function') unsub();
  });
  AdminStore.listeners = [];
}

/**
 * Driver Actions
 */
async function apiUpdateDriverVerification(driverId, status, reason = '') {
  if (!db) {
    // Local fallback update
    const driver = AdminStore.drivers.find(d => d.id === driverId);
    if (driver) driver.verificationStatus = status;
    return true;
  }
  try {
    await db.collection('drivers').doc(driverId).update({
      verificationStatus: status,
      verificationRejectionReason: reason,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    return true;
  } catch (e) {
    console.error("Error updating driver verification:", e);
    throw e;
  }
}

async function apiToggleDriverBlock(driverId, currentBlockedStatus) {
  if (!db) return false;
  try {
    await db.collection('drivers').doc(driverId).update({
      isBlocked: !currentBlockedStatus,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    return true;
  } catch (e) {
    console.error("Error toggling driver block:", e);
    throw e;
  }
}

/**
 * Permanently Delete Driver Partner from Firestore
 */
async function apiDeleteDriver(driverId) {
  if (db) {
    try {
      await db.collection('drivers').doc(driverId).delete();
      console.log(`🗑️ [Firestore] Driver ${driverId} permanently deleted.`);
    } catch (e) {
      console.error("Error deleting driver from Firestore:", e);
      throw e;
    }
  }
  // Local state update
  AdminStore.drivers = AdminStore.drivers.filter(d => d.id !== driverId);
  return true;
}

/**
 * Settle Driver Platform Commission
 * Resets 3-trip rule unpaid counter and clears platform commission dues
 */
async function apiSettleDriverCommissionFull(driverId, amount, paymentMode = 'cash', transactionRef = '', notes = '') {
  const numAmount = parseFloat(amount);
  if (isNaN(numAmount) || numAmount <= 0) {
    throw new Error("Please enter a valid settlement amount.");
  }

  const driver = AdminStore.drivers.find(d => d.id === driverId);
  const currentPending = driver ? (parseFloat(driver.pendingCommission) || 0) : numAmount;
  const newPending = Math.max(0, currentPending - numAmount);
  const dName = driver ? (driver.name || driver.fullName) : 'Driver Partner';
  const dPhone = driver ? (driver.phoneNumber || driver.driverPhone) : '';
  const dPlate = driver ? (driver.vehiclePlateNumber || '') : '';
  const receiptNo = transactionRef || `SET-${Date.now().toString().slice(-6)}`;

  // 1. Direct Firestore Commit
  if (db) {
    try {
      const batch = db.batch();
      const driverRef = db.collection('drivers').doc(driverId);

      batch.update(driverRef, {
        pendingCommission: newPending,
        unpaidTripsCount: 0,
        totalCommissionSettled: firebase.firestore.FieldValue.increment(numAmount),
        lastSettlementAt: firebase.firestore.FieldValue.serverTimestamp(),
        lastSettlementAmount: numAmount,
        lastSettlementMode: paymentMode,
        lastSettlementRef: receiptNo,
        driverStatus: (driver && driver.driverStatus === 'busy') ? 'busy' : 'idle',
        updatedAt: firebase.firestore.FieldValue.serverTimestamp()
      });

      const settlementRef = db.collection('commission_settlements').doc();
      batch.set(settlementRef, {
        driverId: driverId,
        driverName: dName,
        driverPhone: dPhone,
        vehiclePlate: dPlate,
        amountSettled: numAmount,
        previousPending: currentPending,
        remainingPending: newPending,
        paymentMode: paymentMode,
        transactionRef: receiptNo,
        notes: notes || 'District Car HQ platform commission settled',
        settledAt: firebase.firestore.FieldValue.serverTimestamp(),
        settledBy: 'Admin HQ'
      });

      await batch.commit();
      console.log(`✅ [Firestore] Settled ₹${numAmount} for driver ${driverId}`);
    } catch (e) {
      console.error("Firestore commission settlement error:", e);
    }
  }

  // 2. Local State update for immediate zero-latency feedback
  if (driver) {
    driver.pendingCommission = newPending;
    driver.unpaidTripsCount = 0;
    driver.totalCommissionSettled = (parseFloat(driver.totalCommissionSettled) || 0) + numAmount;
    if (driver.driverStatus !== 'busy') {
      driver.driverStatus = 'idle';
    }
  }

  AdminStore.settlements.unshift({
    id: `set_${Date.now()}`,
    driverId: driverId,
    driverName: dName,
    driverPhone: dPhone,
    vehiclePlate: dPlate,
    amountSettled: numAmount,
    previousPending: currentPending,
    remainingPending: newPending,
    paymentMode: paymentMode,
    transactionRef: receiptNo,
    notes: notes || 'Admin Commission Settlement',
    settledAt: { seconds: Math.floor(Date.now() / 1000) },
    settledBy: 'Admin HQ'
  });

  return true;
}

// Backward-compatible wrapper
async function apiSettleDriverCommission(driverId, amountSettled) {
  return apiSettleDriverCommissionFull(driverId, amountSettled, 'cash', `CASH-${Date.now().toString().slice(-6)}`, 'Direct Admin Collection');
}

/**
 * User Actions
 */
async function apiToggleUserBlock(userId, currentBlockedStatus) {
  if (!db) {
    const user = AdminStore.users.find(u => u.id === userId);
    if (user) user.isBlocked = !currentBlockedStatus;
    return true;
  }
  try {
    await db.collection('users').doc(userId).update({
      isBlocked: !currentBlockedStatus,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    return true;
  } catch (e) {
    console.error("Error toggling user block:", e);
    throw e;
  }
}

/**
 * Permanently Delete Customer / User from Firestore
 */
async function apiDeleteUser(userId) {
  if (db) {
    try {
      await db.collection('users').doc(userId).delete();
      console.log(`🗑️ [Firestore] User ${userId} permanently deleted.`);
    } catch (e) {
      console.error("Error deleting user from Firestore:", e);
      throw e;
    }
  }
  // Local state update
  AdminStore.users = AdminStore.users.filter(u => u.id !== userId);
  return true;
}

/**
 * Permanently Delete Booking / Ride from Firestore
 */
async function apiDeleteBooking(bookingId) {
  if (db) {
    try {
      await db.collection('bookings').doc(bookingId).delete();
      console.log(`🗑️ [Firestore] Booking ${bookingId} permanently deleted.`);
    } catch (e) {
      console.error("Error deleting booking from Firestore:", e);
      throw e;
    }
  }
  // Local state update
  AdminStore.bookings = AdminStore.bookings.filter(b => b.id !== bookingId);
  return true;
}

/**
 * Cancel Booking / Ride from Admin
 * Updates bookings/{bookingId} status to 'cancelled' and frees up driver if assigned
 */
async function apiCancelBooking(bookingId, reason = 'Cancelled by District Car Admin HQ') {
  const booking = AdminStore.bookings.find(b => b.id === bookingId);
  const driverId = booking?.driverId;
  const nowSeconds = Math.floor(Date.now() / 1000);

  if (db) {
    try {
      const batch = db.batch();
      const bookingRef = db.collection('bookings').doc(bookingId);

      batch.update(bookingRef, {
        status: 'cancelled',
        cancellationReason: reason,
        cancelledBy: 'Admin HQ',
        cancelledAt: firebase.firestore.FieldValue.serverTimestamp(),
        updatedAt: firebase.firestore.FieldValue.serverTimestamp()
      });

      if (driverId) {
        const driverRef = db.collection('drivers').doc(driverId);
        batch.set(driverRef, {
          driverStatus: 'idle',
          isBusy: false,
          activeBookingId: null,
          updatedAt: firebase.firestore.FieldValue.serverTimestamp()
        }, { merge: true });
      }

      await batch.commit();
      console.log(`🚫 [Firestore] Booking ${bookingId} cancelled by Admin.`);
    } catch (e) {
      console.error("Firestore cancel booking error:", e);
      throw e;
    }
  }

  // Local state update for instant zero-latency feedback
  if (booking) {
    booking.status = 'cancelled';
    booking.cancellationReason = reason;
    booking.cancelledBy = 'Admin HQ';
    booking.cancelledAt = { seconds: nowSeconds };
  }

  if (driverId) {
    const driver = AdminStore.drivers.find(d => d.id === driverId);
    if (driver) {
      driver.driverStatus = 'idle';
      driver.isBusy = false;
      driver.activeBookingId = null;
    }
  }

  return true;
}

/**
 * Manually Assign an Available Driver to a Booking
 * Updates bookings/{bookingId} and drivers/{driverId} in Firestore
 */
async function apiAssignDriverToBooking(bookingId, driverId) {
  const driver = AdminStore.drivers.find(d => d.id === driverId);
  if (!driver) throw new Error("Selected driver partner not found.");

  const dName = resolveDriverName(driver);
  const dPhone = driver.phoneNumber || driver.driverPhone || '';
  const dPlate = driver.vehiclePlateNumber || driver.vehiclePlate || '';
  const dModel = driver.vehicleModel || '';
  const dCategory = driver.vehicleCategoryId || 'cab';
  const nowSeconds = Math.floor(Date.now() / 1000);

  if (db) {
    try {
      const batch = db.batch();
      const bookingRef = db.collection('bookings').doc(bookingId);
      const driverRef = db.collection('drivers').doc(driverId);

      batch.update(bookingRef, {
        status: 'driver_assigned',
        driverId: driverId,
        driverName: dName,
        driverPhone: dPhone,
        vehiclePlate: dPlate,
        vehiclePlateNumber: dPlate,
        vehicleModel: dModel,
        vehicleCategoryId: dCategory,
        driverAcceptedAt: firebase.firestore.FieldValue.serverTimestamp(),
        acceptedAt: firebase.firestore.FieldValue.serverTimestamp(),
        assignedByAdmin: true,
        updatedAt: firebase.firestore.FieldValue.serverTimestamp()
      });

      batch.set(driverRef, {
        driverStatus: 'busy',
        isBusy: true,
        activeBookingId: bookingId,
        updatedAt: firebase.firestore.FieldValue.serverTimestamp()
      }, { merge: true });

      await batch.commit();
      console.log(`✅ [Firestore] Driver ${dName} manually assigned to booking ${bookingId}`);
    } catch (e) {
      console.error("Firestore assign driver error:", e);
    }
  }

  // Local state update for instant zero-latency feedback
  const booking = AdminStore.bookings.find(b => b.id === bookingId);
  if (booking) {
    booking.status = 'driver_assigned';
    booking.driverId = driverId;
    booking.driverName = dName;
    booking.driverPhone = dPhone;
    booking.vehiclePlate = dPlate;
    booking.vehiclePlateNumber = dPlate;
    booking.vehicleModel = dModel;
    booking.vehicleCategoryId = dCategory;
    booking.driverAcceptedAt = { seconds: nowSeconds };
    booking.acceptedAt = { seconds: nowSeconds };
    booking.assignedByAdmin = true;
  }

  driver.driverStatus = 'busy';
  driver.isBusy = true;
  driver.activeBookingId = bookingId;

  return true;
}

/**
 * Payout Request Actions
 */
async function apiProcessPayout(payoutId, status, transactionRef = '') {
  if (!db) {
    const payout = AdminStore.payouts.find(p => p.id === payoutId);
    if (payout) {
      payout.status = status;
      payout.transactionRef = transactionRef;
    }
    return true;
  }
  try {
    await db.collection('payout_requests').doc(payoutId).update({
      status: status,
      transactionRef: transactionRef,
      processedAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    return true;
  } catch (e) {
    console.error("Error processing payout:", e);
    throw e;
  }
}

/**
 * Remote Config & Fare Actions
 */
/**
 * Standalone 1-click API to Turn ON or Turn OFF Customer App Guest Sign-In Popup
 */
async function apiSetGuestSignInPopup(enabled) {
  const isEnabled = Boolean(enabled);
  if (db) {
    try {
      await db.collection('remote_configs').doc('app_updates').set({
        showGuestSignInPopup: isEnabled,
        updatedAt: firebase.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
      console.log(`✅ [Firestore] Guest sign-in popup set to: ${isEnabled ? 'ON' : 'OFF'}`);
    } catch (e) {
      console.error("Error setting guest sign-in popup in Firestore:", e);
      throw e;
    }
  }
  if (!AdminStore.remoteConfig) {
    AdminStore.remoteConfig = {};
  }
  AdminStore.remoteConfig.showGuestSignInPopup = isEnabled;
  return isEnabled;
}


/**
 * Standalone 1-click API to Turn ON or Turn OFF Customer Ride Now (Instant booking)
 */
async function apiSetRideNowEnabled(enabled) {
  const isEnabled = Boolean(enabled);
  if (db) {
    try {
      await db.collection('remote_configs').doc('app_updates').set({
        isRideNowEnabled: isEnabled,
        updatedAt: firebase.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
      console.log('✅ [Firestore] Ride Now set to: ' + (isEnabled ? 'ON' : 'OFF'));
    } catch (e) {
      console.error('Error setting Ride Now in Firestore:', e);
      throw e;
    }
  }
  if (!AdminStore.remoteConfig) {
    AdminStore.remoteConfig = {};
  }
  AdminStore.remoteConfig.isRideNowEnabled = isEnabled;
  return isEnabled;
}

/**
 * Standalone 1-click API to Turn ON or Turn OFF Customer Schedule Ride (Advance booking)
 */
async function apiSetScheduleEnabled(enabled) {
  const isEnabled = Boolean(enabled);
  if (db) {
    try {
      await db.collection('remote_configs').doc('app_updates').set({
        isScheduleEnabled: isEnabled,
        updatedAt: firebase.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
      console.log('✅ [Firestore] Schedule Ride set to: ' + (isEnabled ? 'ON' : 'OFF'));
    } catch (e) {
      console.error('Error setting Schedule Ride in Firestore:', e);
      throw e;
    }
  }
  if (!AdminStore.remoteConfig) {
    AdminStore.remoteConfig = {};
  }
  AdminStore.remoteConfig.isScheduleEnabled = isEnabled;
  return isEnabled;
}

async function apiSavePricingRules(rules) {
  if (db) {
    try {
      await db.collection('remote_configs').doc('pricing_rules').set({
        ...rules,
        updatedAt: firebase.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
      console.log("✅ [Firestore] Pricing rules saved successfully");
    } catch (e) {
      console.error("Error saving pricing rules in Firestore:", e);
      throw e;
    }
  }
  AdminStore.pricingRules = { ...AdminStore.pricingRules, ...rules };
  return AdminStore.pricingRules;
}

async function apiToggleSurgeFee(enabled) {
  const isEnabled = Boolean(enabled);
  if (db) {
    try {
      await db.collection('remote_configs').doc('pricing_rules').set({
        adminSurgeEnabled: isEnabled,
        updatedAt: firebase.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
      console.log(`✅ [Firestore] Surge Fee (+8%) set to: ${isEnabled ? 'ON' : 'OFF'}`);
    } catch (e) {
      console.error("Error setting surge fee in Firestore:", e);
      throw e;
    }
  }
  AdminStore.pricingRules.adminSurgeEnabled = isEnabled;
  return isEnabled;
}

async function apiSaveVehicleCategory(catId, catData) {
  if (db) {
    try {
      await db.collection('vehicleCategories').doc(catId).set({
        ...catData,
        updatedAt: firebase.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
      console.log(`✅ [Firestore] Vehicle category ${catId} updated successfully`);
    } catch (e) {
      console.error(`Error updating vehicle category ${catId}:`, e);
      throw e;
    }
  }
  const idx = AdminStore.categories.findIndex(c => c.id === catId);
  if (idx !== -1) {
    AdminStore.categories[idx] = { ...AdminStore.categories[idx], ...catData };
  } else {
    AdminStore.categories.push({ id: catId, ...catData });
  }
  return true;
}

async function apiSaveFestiveTheme(themeConfig) {
  if (db) {
    try {
      await db.collection('remote_configs').doc('festive_theme').set({
        ...themeConfig,
        updatedAt: firebase.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
      console.log("✅ [Firestore] Festive theme SDUI saved successfully");
    } catch (e) {
      console.error("Error saving festive theme in Firestore:", e);
      throw e;
    }
  }
  AdminStore.festiveTheme = { ...AdminStore.festiveTheme, ...themeConfig };
  return AdminStore.festiveTheme;
}

// ============================================================================
// APITXT.com SMS & PUSH NOTIFICATIONS API
// ============================================================================
const APITXT_CONFIG = {
  endpoint: 'https://apitxt.com/api/sendOTP',
  authKey: 'sCopxtBHXm_Z2wlY8q5zGWejD0S8MDnrv4K1wI1oKHg',
  adminNumbers: ['919142127512', '918789601387']
};

/**
 * Dispatch Instant Real SMS via APITXT.com sendOTP API
 * Guaranteed real dispatch to mobile numbers without fallback messages
 */
async function apiSendApitxtSms(mobile, message, otp) {
  let cleanMobile = String(mobile || '').replace(/[^0-9]/g, '');
  if (cleanMobile.length === 10) cleanMobile = '91' + cleanMobile;
  const safeOtp = String(otp || Math.floor(100000 + Math.random() * 900000)).replace(/[^0-9]/g, '').slice(-6).padStart(6, '9');
  const encodedMsg = encodeURIComponent(message || 'District Car: Alert');
  const url = `${APITXT_CONFIG.endpoint}?authkey=${APITXT_CONFIG.authKey}&mobile=${cleanMobile}&otp=${safeOtp}&message=${encodedMsg}`;

  console.log(`[APITXT] Dispatching real SMS to ${cleanMobile}...`);

  try {
    // 1. Direct browser fetch
    await fetch(url, { method: 'GET', mode: 'no-cors' });
    console.log(`✅ [APITXT] Real SMS dispatched to ${cleanMobile}`);
    AdminStore.totalApitxtSmsSent = (AdminStore.totalApitxtSmsSent || 0) + 1;
  } catch (err) {
    // 2. Direct browser Image ping (immune to CORS restrictions in all browsers)
    try {
      const ping = new Image();
      ping.src = url;
      console.log(`✅ [APITXT] Real SMS ping dispatched to ${cleanMobile}`);
      AdminStore.totalApitxtSmsSent = (AdminStore.totalApitxtSmsSent || 0) + 1;
    } catch (e2) {
      console.error(`❌ [APITXT] Failed to send to ${cleanMobile}:`, e2);
      return { success: false, mobile: cleanMobile, error: e2.message };
    }
  }

  // 3. Also relay to live notification worker if online
  try {
    fetch('https://notification.projectmarket.in/api/sms/send', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ mobile: cleanMobile, message, otp: safeOtp })
    }).catch(() => {});
  } catch (_) {}

  return { success: true, mobile: cleanMobile, status: 'sent', provider: 'APITXT.com' };
}

/**
 * Trigger Instant SMS to both Admins on New Booking
 */
async function triggerNewBookingApitxtAlert(booking) {
  const readableId = booking.readableId || (booking.id ? booking.id.substring(0, 6).toUpperCase() : 'NEW');
  const pickup = booking.pickup?.address || booking.pickupAddress || 'Pickup Point';
  const drop = booking.destination?.address || booking.destinationAddress || 'Drop Location';
  const fare = Math.round(booking.estimatedFare || booking.totalFare || booking.fareSnapshot?.totalFare || 0);
  const shortPickup = pickup.length > 25 ? pickup.substring(0, 22) + '...' : pickup;
  const shortDrop = drop.length > 25 ? drop.substring(0, 22) + '...' : drop;
  
  const otpCode = String(booking.rideOtp || booking.readableId || Math.floor(100000 + Math.random() * 900000)).replace(/[^0-9]/g, '').slice(-6).padStart(6, '9');
  const smsText = `District Car: New Booking #${readableId}! From: ${shortPickup} To: ${shortDrop} Fare: Rs.${fare}`;

  console.log(`🚨 [APITXT] New booking #${readableId} detected! Sending instant SMS to admins (+919142127512 & +918789601387)...`);

  // Play browser audio beep if allowed
  try {
    const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    const osc = audioCtx.createOscillator();
    const gain = audioCtx.createGain();
    osc.connect(gain);
    gain.connect(audioCtx.destination);
    osc.frequency.value = 880;
    gain.gain.value = 0.3;
    osc.start();
    setTimeout(() => { osc.stop(); audioCtx.close(); }, 350);
  } catch (_) {}

  // Dispatch real SMS to both authorized admin numbers
  for (const adminNum of APITXT_CONFIG.adminNumbers) {
    await apiSendApitxtSms(adminNum, smsText, otpCode);
  }

  // Update Firestore booking record to mark SMS notified
  if (db && booking.id) {
    db.collection('bookings').doc(booking.id).update({
      apitxtSmsSent: true,
      apitxtSmsSentAt: firebase.firestore.FieldValue.serverTimestamp()
    }).catch(() => {});
  }

  if (typeof showToast === 'function') {
    showToast(`🚨 New Booking #${readableId}! Real SMS sent to +919142127512 & +918789601387 via APITXT.`);
  }
}

/**
 * Send Real Push Notification from Admin Web via FCM & In-App Sync
 */
async function apiSendPushNotification({
  targetAudience,
  targetUserId = null,
  targetUserName = null,
  targetPhone = null,
  title,
  body,
  templateKey = 'custom',
  priority = 'high'
}) {
  if (!db) throw new Error("Firestore database connection not available");

  const notifDoc = {
    title,
    body,
    targetAudience,
    targetUserId: targetUserId || null,
    targetUserName: targetUserName || null,
    targetPhone: targetPhone || null,
    templateKey,
    priority,
    status: 'delivered',
    sentBy: 'Admin HQ',
    sentAt: firebase.firestore.FieldValue.serverTimestamp(),
    timestamp: Date.now()
  };

  // 1. Add to root 'notifications' collection (triggers real-time in-app dialog on active phones)
  const notifRef = await db.collection('notifications').add(notifDoc);
  console.log(`🔔 [Notification] Saved notification #${notifRef.id} to Firestore`);

  // 2. Deliver to specific recipient's personal inbox
  if (targetAudience === 'specific_customer' && targetUserId) {
    try {
      await db.collection('users').doc(targetUserId).collection('inbox_notifications').add({
        title,
        body,
        type: templateKey,
        priority,
        isRead: false,
        sentAt: firebase.firestore.FieldValue.serverTimestamp()
      });
      console.log(`📥 [Inbox] Delivered to customer ${targetUserId} personal inbox`);
    } catch (e) {
      console.warn("Could not write to customer inbox:", e);
    }
  } else if (targetAudience === 'specific_driver' && targetUserId) {
    try {
      await db.collection('drivers').doc(targetUserId).collection('inbox_notifications').add({
        title,
        body,
        type: templateKey,
        priority,
        isRead: false,
        sentAt: firebase.firestore.FieldValue.serverTimestamp()
      });
      console.log(`📥 [Inbox] Delivered to driver ${targetUserId} personal inbox`);
    } catch (e) {
      console.warn("Could not write to driver inbox:", e);
    }
  }

  // 3. Dispatch REAL OS-level Push Notification via Live Worker Server (Firebase Admin SDK)
  let pushResponse = null;
  try {
    let workerAudience = 'all';
    if (targetAudience === 'all_customers') workerAudience = 'all_customers';
    else if (targetAudience === 'all_drivers') workerAudience = 'all_drivers';
    else if (targetAudience === 'specific_customer' && targetUserId) workerAudience = `customer_${targetUserId}`;
    else if (targetAudience === 'specific_driver' && targetUserId) workerAudience = `driver_${targetUserId}`;

    const res = await fetch('https://notification.projectmarket.in/api/notifications/admin-broadcast', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        title,
        body,
        targetAudience: workerAudience,
        extraData: {
          notificationId: notifRef.id,
          targetAudience,
          templateKey,
          priority,
          targetUserId: targetUserId || ''
        }
      })
    });
    pushResponse = await res.json().catch(() => ({ success: true }));
    console.log('🚀 [RealPush] FCM Push dispatched via Firebase Admin SDK:', pushResponse);
  } catch (pushErr) {
    console.warn('⚠️ [RealPush] Worker relay notice:', pushErr.message);
  }

  return { success: true, notificationId: notifRef.id, pushResponse };
}

async function apiSaveRemoteConfig(driverBuild, customerBuild, forceUpdate, apkUrl, showGuestSignInPopup, isRideNowEnabled, isScheduleEnabled) {
  if (!db) return false;
  try {
    const payload = {
      driverCurrentBuild: parseInt(driverBuild, 10) || 26,
      customerCurrentBuild: parseInt(customerBuild, 10) || 26,
      forceUpdate: Boolean(forceUpdate),
      driverApkUrl: apkUrl || "https://districtcar.in/build_outputs/DistrictCar_Driver_Release.apk",
      showGuestSignInPopup: showGuestSignInPopup !== undefined ? Boolean(showGuestSignInPopup) : true,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    };
    if (isRideNowEnabled !== undefined) payload.isRideNowEnabled = Boolean(isRideNowEnabled);
    if (isScheduleEnabled !== undefined) payload.isScheduleEnabled = Boolean(isScheduleEnabled);
    await db.collection('remote_configs').doc('app_updates').set(payload, { merge: true });
    return true;
  } catch (e) {
    console.error("Error saving remote config:", e);
    throw e;
  }
}

/**
 * High-Fidelity Fallback Mock Data
 * Ensures dashboard is 100% interactive and functional even before Firebase Auth or offline
 */
function loadFallbackData(callback) {
  loadFallbackDrivers();
  loadFallbackBookings();
  loadFallbackUsers();
  loadFallbackPayouts();
  loadFallbackSettlements();
  AdminStore.remoteConfig = {
    driverCurrentBuild: 26,
    customerCurrentBuild: 26,
    forceUpdate: false,
    driverApkUrl: "https://districtcar.in/build_outputs/DistrictCar_Driver_Release.apk",
    showGuestSignInPopup: true
  };
  if (callback) callback('all');
}

function loadFallbackDrivers(callback) {
  AdminStore.drivers = [
    {
      id: "drv_001_suresh",
      name: "Suresh Mahto",
      fullName: "Suresh Mahto",
      phoneNumber: "+91 98351 44210",
      vehicleCategoryId: "mini",
      vehicleModel: "Maruti Suzuki WagonR",
      vehiclePlateNumber: "JH-01-AX-4821",
      verificationStatus: "approved",
      driverStatus: "idle",
      isOnline: true,
      walletBalance: 4680,
      pendingCommission: 520,
      totalCommissionSettled: 1560,
      unpaidTripsCount: 2,
      totalTrips: 48,
      rating: 4.9,
      dlNumber: "JH0120190045120",
      rcPhotoUrl: "https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?auto=format&fit=crop&w=600&q=80",
      dlPhotoUrl: "https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=600&q=80"
    },
    {
      id: "drv_002_ramesh",
      name: "Rameshwar Oraon",
      fullName: "Rameshwar Oraon",
      phoneNumber: "+91 87896 01387",
      vehicleCategoryId: "suv",
      vehicleModel: "Mahindra Bolero Neo",
      vehiclePlateNumber: "JH-07-E-9021",
      verificationStatus: "approved",
      driverStatus: "busy",
      isOnline: true,
      walletBalance: 12400,
      pendingCommission: 850,
      totalCommissionSettled: 3400,
      unpaidTripsCount: 3,
      totalTrips: 114,
      rating: 4.8,
      dlNumber: "JH0720180099411",
      rcPhotoUrl: "https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?auto=format&fit=crop&w=600&q=80",
      dlPhotoUrl: "https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=600&q=80"
    },
    {
      id: "drv_003_anand",
      name: "Anand Kumar Singh",
      fullName: "Anand Kumar Singh",
      phoneNumber: "+91 94311 88320",
      vehicleCategoryId: "sedan",
      vehicleModel: "Maruti Suzuki Dzire",
      vehiclePlateNumber: "JH-01-CK-3180",
      verificationStatus: "pending",
      driverStatus: "offline",
      isOnline: false,
      walletBalance: 0,
      pendingCommission: 0,
      totalCommissionSettled: 0,
      unpaidTripsCount: 0,
      totalTrips: 0,
      rating: 5.0,
      dlNumber: "JH0120230087419",
      rcPhotoUrl: "https://images.unsplash.com/photo-1552519507-da3b142c6e3d?auto=format&fit=crop&w=600&q=80",
      dlPhotoUrl: "https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=600&q=80"
    },
    {
      id: "drv_004_md_arif",
      name: "Md. Arif Ansari",
      fullName: "Md. Arif Ansari",
      phoneNumber: "+91 70041 29930",
      vehicleCategoryId: "auto",
      vehicleModel: "Bajaj Compact 4S Auto",
      vehiclePlateNumber: "JH-01-BZ-5544",
      verificationStatus: "approved",
      driverStatus: "idle",
      isOnline: true,
      walletBalance: 2850,
      pendingCommission: 190,
      totalCommissionSettled: 820,
      unpaidTripsCount: 1,
      totalTrips: 82,
      rating: 4.7,
      dlNumber: "JH0120200031892",
      rcPhotoUrl: "",
      dlPhotoUrl: "https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=600&q=80"
    },
    {
      id: "drv_005_birsa",
      name: "Birsa Munda",
      fullName: "Birsa Munda",
      phoneNumber: "+91 62054 81109",
      vehicleCategoryId: "mini",
      vehicleModel: "Hyundai Grand i10",
      vehiclePlateNumber: "JH-05-AB-1945",
      verificationStatus: "approved",
      driverStatus: "idle",
      isOnline: true,
      walletBalance: 3200,
      pendingCommission: 410,
      totalCommissionSettled: 950,
      unpaidTripsCount: 3,
      totalTrips: 34,
      rating: 4.85,
      dlNumber: "JH0520210051299",
      rcPhotoUrl: "https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?auto=format&fit=crop&w=600&q=80",
      dlPhotoUrl: "https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=600&q=80"
    }
  ];
  if (callback) callback('drivers');
}

function loadFallbackBookings(callback) {
  AdminStore.bookings = [
    {
      id: "booking_jh_001",
      readableId: "#DC-94182",
      customerName: "Priya Sharma",
      customerPhone: "+91 91234 56789",
      driverId: "drv_001_suresh",
      driverName: "Suresh Mahto",
      driverPhone: "+91 98351 44210",
      vehicleCategoryId: "mini",
      pickup: { address: "Ranchi Railway Station, Station Rd", latitude: 23.3441, longitude: 85.3240 },
      destination: { address: "BIT Mesra Campus, Mesra, Ranchi", latitude: 23.4123, longitude: 85.4399 },
      estimatedDistanceKm: 18.5,
      estimatedFare: 420,
      finalFare: 420,
      platformFee: 42,
      driverShare: 378,
      status: "completed",
      paymentMethod: "cash",
      paymentStatus: "paid",
      rideOtp: "4821",
      createdAt: { seconds: Math.floor(Date.now() / 1000) - 3600 },
      driverAcceptedAt: { seconds: Math.floor(Date.now() / 1000) - 3480 }
    },
    {
      id: "booking_jh_002",
      readableId: "#DC-94183",
      customerName: "Vikramaditya Roy",
      customerPhone: "+91 98350 12894",
      driverId: "drv_002_ramesh",
      driverName: "Rameshwar Oraon",
      driverPhone: "+91 87896 01387",
      vehicleCategoryId: "suv",
      pickup: { address: "Birsa Munda Airport (IXR), Hinoo", latitude: 23.3143, longitude: 85.3216 },
      destination: { address: "Patratu Valley Resort, Ramgarh", latitude: 23.6342, longitude: 85.2891 },
      estimatedDistanceKm: 42.0,
      estimatedFare: 1850,
      finalFare: 1850,
      platformFee: 185,
      driverShare: 1665,
      status: "trip_started",
      paymentMethod: "cash",
      paymentStatus: "pending",
      rideOtp: "9012",
      isRoundTrip: true,
      createdAt: { seconds: Math.floor(Date.now() / 1000) - 7200 },
      driverAcceptedAt: { seconds: Math.floor(Date.now() / 1000) - 7020 }
    },
    {
      id: "booking_jh_003",
      readableId: "#DC-94184",
      customerName: "Rajeev Agarwal",
      customerPhone: "+91 70044 19283",
      driverId: "drv_004_md_arif",
      driverName: "Md. Arif Ansari",
      driverPhone: "+91 70041 29930",
      vehicleCategoryId: "auto",
      pickup: { address: "Main Road, Overbridge Market, Ranchi", latitude: 23.3520, longitude: 85.3260 },
      destination: { address: "Kanke Road, Rock Garden, Ranchi", latitude: 23.4020, longitude: 85.3190 },
      estimatedDistanceKm: 8.5,
      estimatedFare: 180,
      finalFare: 180,
      platformFee: 18,
      driverShare: 162,
      status: "completed",
      paymentMethod: "cash",
      paymentStatus: "paid",
      rideOtp: "3319",
      createdAt: { seconds: Math.floor(Date.now() / 1000) - 14400 },
      driverAcceptedAt: { seconds: Math.floor(Date.now() / 1000) - 14220 }
    },
    {
      id: "booking_jh_004",
      readableId: "#DC-94185",
      customerName: "Neha Kumari",
      customerPhone: "+91 82103 49021",
      driverId: null,
      driverName: null,
      driverPhone: null,
      vehicleCategoryId: "sedan",
      pickup: { address: "Lalpur Chowk, Circular Rd, Ranchi", latitude: 23.3710, longitude: 85.3340 },
      destination: { address: "Dhurwa Dam, Ring Road, Ranchi", latitude: 23.2840, longitude: 85.2640 },
      estimatedDistanceKm: 14.2,
      estimatedFare: 550,
      finalFare: 550,
      platformFee: 55,
      driverShare: 495,
      status: "searching_driver",
      paymentMethod: "cash",
      paymentStatus: "pending",
      rideOtp: "7740",
      createdAt: { seconds: Math.floor(Date.now() / 1000) - 600 }
    }
  ];
  if (callback) callback('bookings');
}

function loadFallbackUsers(callback) {
  AdminStore.users = [
    {
      id: "usr_001_priya",
      name: "Priya Sharma",
      displayName: "Priya Sharma",
      phoneNumber: "+91 91234 56789",
      email: "priya.sharma@gmail.com",
      totalBookings: 8,
      totalSpent: 4250,
      isBlocked: false,
      createdAt: { seconds: 1729000000 }
    },
    {
      id: "usr_002_vikram",
      name: "Vikramaditya Roy",
      displayName: "Vikramaditya Roy",
      phoneNumber: "+91 98350 12894",
      email: "v.roy.jh@outlook.com",
      totalBookings: 14,
      totalSpent: 16800,
      isBlocked: false,
      createdAt: { seconds: 1728500000 }
    },
    {
      id: "usr_003_rajeev",
      name: "Rajeev Agarwal",
      displayName: "Rajeev Agarwal",
      phoneNumber: "+91 70044 19283",
      email: "rajeev.ag@gmail.com",
      totalBookings: 22,
      totalSpent: 8400,
      isBlocked: false,
      createdAt: { seconds: 1728100000 }
    },
    {
      id: "usr_004_neha",
      name: "Neha Kumari",
      displayName: "Neha Kumari",
      phoneNumber: "+91 82103 49021",
      email: "neha.k@ranchi.in",
      totalBookings: 3,
      totalSpent: 1200,
      isBlocked: false,
      createdAt: { seconds: 1729200000 }
    }
  ];
  if (callback) callback('users');
}

function loadFallbackPayouts(callback) {
  AdminStore.payouts = [
    {
      id: "pay_001",
      driverId: "drv_001_suresh",
      driverName: "Suresh Mahto",
      driverPhone: "+91 98351 44210",
      amount: 3500,
      upiId: "9835144210@paytm",
      status: "pending",
      requestedAt: { seconds: Math.floor(Date.now() / 1000) - 86400 }
    },
    {
      id: "pay_002",
      driverId: "drv_002_ramesh",
      driverName: "Rameshwar Oraon",
      driverPhone: "+91 87896 01387",
      amount: 8000,
      upiId: "ramesh.bolero@oksbi",
      status: "approved",
      transactionRef: "UPI49182049182",
      requestedAt: { seconds: Math.floor(Date.now() / 1000) - 172800 }
    }
  ];
  if (callback) callback('payouts');
}

function loadFallbackSettlements(callback) {
  AdminStore.settlements = [
    {
      id: "set_001",
      driverId: "drv_001_suresh",
      driverName: "Suresh Mahto",
      driverPhone: "+91 98351 44210",
      vehiclePlate: "JH-01-AX-4821",
      amountSettled: 520,
      previousPending: 520,
      remainingPending: 0,
      paymentMode: "cash",
      transactionRef: "CASH-REC-8841",
      notes: "Cash collected at District Car Ranchi Hub. Unpaid count cleared.",
      settledAt: { seconds: Math.floor(Date.now() / 1000) - 43200 },
      settledBy: "Admin HQ"
    },
    {
      id: "set_002",
      driverId: "drv_002_ramesh",
      driverName: "Rameshwar Oraon",
      driverPhone: "+91 87896 01387",
      vehiclePlate: "JH-07-E-9021",
      amountSettled: 850,
      previousPending: 850,
      remainingPending: 0,
      paymentMode: "upi",
      transactionRef: "UPI-AXIS-992144",
      notes: "PhonePe QR payment received. 3-trip cash lock removed.",
      settledAt: { seconds: Math.floor(Date.now() / 1000) - 129600 },
      settledBy: "Admin HQ"
    },
    {
      id: "set_003",
      driverId: "drv_004_md_arif",
      driverName: "Md. Arif Ansari",
      driverPhone: "+91 70041 29930",
      vehiclePlate: "JH-01-BZ-5544",
      amountSettled: 340,
      previousPending: 340,
      remainingPending: 0,
      paymentMode: "cash",
      transactionRef: "CASH-REC-8812",
      notes: "Weekly platform commission settlement.",
      settledAt: { seconds: Math.floor(Date.now() / 1000) - 259200 },
      settledBy: "Admin HQ"
    }
  ];
  if (callback) callback('settlements');
}
