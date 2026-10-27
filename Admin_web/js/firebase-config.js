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

async function apiSaveRemoteConfig(driverBuild, customerBuild, forceUpdate, apkUrl, showGuestSignInPopup) {
  if (!db) return false;
  try {
    await db.collection('remote_configs').doc('app_updates').set({
      driverCurrentBuild: parseInt(driverBuild, 10) || 26,
      customerCurrentBuild: parseInt(customerBuild, 10) || 26,
      forceUpdate: Boolean(forceUpdate),
      driverApkUrl: apkUrl || "https://districtcar.in/build_outputs/DistrictCar_Driver_Release.apk",
      showGuestSignInPopup: showGuestSignInPopup !== undefined ? Boolean(showGuestSignInPopup) : true,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
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
