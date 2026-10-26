/**
 * District Car Admin Web — Firebase Configuration & Service Layer
 * Direct connection to Firebase Firestore & Authentication
 */

const firebaseConfig = {
  apiKey: "AIzaSyDwi6OV-l7mDqCpPaRI4Yn9gUXiZrf73QM",
  authDomain: "districtcar-4b880.firebaseapp.com",
  projectId: "districtcar-4b880",
  storageBucket: "districtcar-4b880.firebasestorage.app",
  messagingSenderId: "319163006406",
  appId: "1:319163006406:web:c4807f606480e920fa46c7"
};

// Initialize Firebase using compat libraries (loaded via CDN in index.html)
let firebaseApp, auth, db;

try {
  if (typeof firebase !== 'undefined') {
    firebaseApp = firebase.initializeApp(firebaseConfig);
    auth = firebase.auth();
    db = firebase.firestore();
    console.log("🔥 [Firebase] Successfully initialized District Car Admin connection.");
  } else {
    console.warn("⚠️ [Firebase] SDK not loaded from CDN. Operating in local mode.");
  }
} catch (err) {
  console.error("❌ [Firebase] Initialization error:", err);
}

// Global data store to cache live snapshots
const AdminStore = {
  users: [],
  drivers: [],
  bookings: [],
  payouts: [],
  categories: [],
  remoteConfig: null,
  isLive: false,
  listeners: []
};

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
        AdminStore.drivers.push({ id: doc.id, ...doc.data() });
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
        AdminStore.bookings.push({ id: doc.id, ...doc.data() });
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

    // 5. Listen to Remote Updates Config
    db.collection('remote_configs').doc('app_updates').onSnapshot((doc) => {
      if (doc.exists) {
        AdminStore.remoteConfig = doc.data();
        if (onDataChange) onDataChange('remoteConfig');
      }
    }, (err) => {
      console.warn("Remote config error:", err.message);
    });

    // 6. Listen to Vehicle Categories
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
    console.error("Error setting up listeners:", e);
    loadFallbackData(onDataChange);
  }
}

/**
 * Driver Actions
 */
async function apiUpdateDriverVerification(driverId, status, rejectionReason = '') {
  if (!db) return false;
  try {
    const payload = {
      verificationStatus: status,
      reviewedAt: firebase.firestore.FieldValue.serverTimestamp()
    };
    if (rejectionReason) payload.rejectionReason = rejectionReason;
    await db.collection('drivers').doc(driverId).update(payload);
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

async function apiSettleDriverCommission(driverId, amountSettled = 0) {
  if (!db) return false;
  try {
    await db.collection('drivers').doc(driverId).update({
      pendingCommission: 0,
      unpaidTripsCount: 0,
      lastCommissionSettledAt: firebase.firestore.FieldValue.serverTimestamp()
    });

    // Record in audit log
    await db.collection('auditLogs').add({
      action: 'commission_settled',
      targetId: driverId,
      amount: amountSettled,
      timestamp: firebase.firestore.FieldValue.serverTimestamp()
    });
    return true;
  } catch (e) {
    console.error("Error settling commission:", e);
    throw e;
  }
}

/**
 * User Actions
 */
async function apiToggleUserBlock(userId, currentBlockedStatus) {
  if (!db) return false;
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
 * Payout Request Actions
 */
async function apiProcessPayout(payoutId, status, transactionRef = '') {
  if (!db) return false;
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
async function apiSaveRemoteConfig(driverBuild, customerBuild, forceUpdate, apkUrl) {
  if (!db) return false;
  try {
    await db.collection('remote_configs').doc('app_updates').set({
      driverCurrentBuild: parseInt(driverBuild, 10) || 26,
      customerCurrentBuild: parseInt(customerBuild, 10) || 26,
      forceUpdate: Boolean(forceUpdate),
      driverApkUrl: apkUrl || "https://districtcar.in/build_outputs/DistrictCar_Driver_Release.apk",
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
  AdminStore.remoteConfig = {
    driverCurrentBuild: 26,
    customerCurrentBuild: 26,
    forceUpdate: false,
    driverApkUrl: "https://districtcar.in/build_outputs/DistrictCar_Driver_Release.apk"
  };
  if (callback) callback('all');
}

function loadFallbackDrivers(callback) {
  AdminStore.drivers = [
    {
      id: "drv_001_suresh",
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
      unpaidTripsCount: 2,
      totalTrips: 48,
      rating: 4.9,
      dlNumber: "JH0120190045120",
      rcPhotoUrl: "https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?auto=format&fit=crop&w=600&q=80",
      dlPhotoUrl: "https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=600&q=80"
    },
    {
      id: "drv_002_ramesh",
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
      unpaidTripsCount: 3,
      totalTrips: 114,
      rating: 4.8,
      dlNumber: "JH0720180099411",
      rcPhotoUrl: "https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?auto=format&fit=crop&w=600&q=80",
      dlPhotoUrl: "https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=600&q=80"
    },
    {
      id: "drv_003_anand",
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
      unpaidTripsCount: 0,
      totalTrips: 0,
      rating: 5.0,
      dlNumber: "JH0120230087419",
      rcPhotoUrl: "https://images.unsplash.com/photo-1552519507-da3b142c6e3d?auto=format&fit=crop&w=600&q=80",
      dlPhotoUrl: "https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=600&q=80"
    },
    {
      id: "drv_004_md_arif",
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
      unpaidTripsCount: 1,
      totalTrips: 82,
      rating: 4.7,
      dlNumber: "JH0120200031892",
      rcPhotoUrl: "",
      dlPhotoUrl: ""
    },
    {
      id: "drv_005_vikash",
      fullName: "Vikash Tirkey",
      phoneNumber: "+91 91224 81044",
      vehicleCategoryId: "suv",
      vehicleModel: "Scorpio Classic",
      vehiclePlateNumber: "JH-20-D-1102",
      verificationStatus: "approved",
      driverStatus: "offline",
      isOnline: false,
      walletBalance: 7890,
      pendingCommission: 650,
      unpaidTripsCount: 2,
      totalTrips: 63,
      rating: 4.9,
      dlNumber: "JH2020210049210",
      rcPhotoUrl: "",
      dlPhotoUrl: ""
    }
  ];
  if (callback) callback('drivers');
}

function loadFallbackBookings(callback) {
  AdminStore.bookings = [
    {
      id: "bk_001_dc",
      readableId: "#DC-984210",
      customerId: "usr_101",
      customerName: "Pooja Kumari",
      customerPhone: "+91 82103 44910",
      driverId: "drv_002_ramesh",
      driverName: "Rameshwar Oraon",
      driverPhone: "+91 87896 01387",
      vehicleCategoryId: "suv",
      vehiclePlate: "JH-07-E-9021",
      vehicleModel: "Mahindra Bolero Neo",
      pickup: { address: "Albert Ekka Chowk, Main Road, Ranchi" },
      destination: { address: "Patratu Valley Viewpoint, Ramgarh" },
      estimatedFare: 2999,
      finalFare: 2999,
      status: "trip_completed",
      paymentMethod: "cash",
      paymentStatus: "completed",
      rideOtp: "4821",
      isRoundTrip: true,
      roundTripStoppingHours: 2.0,
      createdAt: { seconds: Math.floor(Date.now() / 1000) - 7200 }
    },
    {
      id: "bk_002_dc",
      readableId: "#DC-984211",
      customerId: "usr_102",
      customerName: "Amitabh Choudhary",
      customerPhone: "+91 94311 02944",
      driverId: "drv_001_suresh",
      driverName: "Suresh Mahto",
      driverPhone: "+91 98351 44210",
      vehicleCategoryId: "mini",
      vehiclePlate: "JH-01-AX-4821",
      vehicleModel: "Maruti Suzuki WagonR",
      pickup: { address: "Ranchi Railway Station (RNC)" },
      destination: { address: "Birsa Munda Airport (IXR), Hinoo" },
      estimatedFare: 450,
      finalFare: 450,
      status: "trip_completed",
      paymentMethod: "upi",
      paymentStatus: "completed",
      rideOtp: "9012",
      isRoundTrip: false,
      createdAt: { seconds: Math.floor(Date.now() / 1000) - 14400 }
    },
    {
      id: "bk_003_dc",
      readableId: "#DC-984212",
      customerId: "usr_103",
      customerName: "Sunil Marandi",
      customerPhone: "+91 79032 88122",
      driverId: "drv_004_md_arif",
      driverName: "Md. Arif Ansari",
      driverPhone: "+91 70041 29930",
      vehicleCategoryId: "auto",
      vehiclePlate: "JH-01-BZ-5544",
      vehicleModel: "Bajaj Compact Auto",
      pickup: { address: "Khadgarha Bus Stand, Kantatoli" },
      destination: { address: "RIMS Hospital, Bariatu, Ranchi" },
      estimatedFare: 160,
      finalFare: 160,
      status: "trip_started",
      paymentMethod: "cash",
      paymentStatus: "pending",
      rideOtp: "3319",
      isRoundTrip: false,
      createdAt: { seconds: Math.floor(Date.now() / 1000) - 1800 }
    },
    {
      id: "bk_004_dc",
      readableId: "#DC-984213",
      customerId: "usr_104",
      customerName: "Dr. Alok Verma",
      customerPhone: "+91 98355 12099",
      driverId: null,
      driverName: null,
      driverPhone: null,
      vehicleCategoryId: "sedan",
      pickup: { address: "Doranda, Ranchi" },
      destination: { address: "Dassam Falls, Bundu, NH-33" },
      estimatedFare: 2199,
      status: "searching_driver",
      paymentMethod: "cash",
      paymentStatus: "pending",
      rideOtp: "7724",
      isRoundTrip: true,
      createdAt: { seconds: Math.floor(Date.now() / 1000) - 300 }
    },
    {
      id: "bk_005_dc",
      readableId: "#DC-984214",
      customerId: "usr_105",
      customerName: "Rahul Soren",
      customerPhone: "+91 91223 99014",
      driverId: "drv_005_vikash",
      driverName: "Vikash Tirkey",
      driverPhone: "+91 91224 81044",
      vehicleCategoryId: "suv",
      vehiclePlate: "JH-20-D-1102",
      pickup: { address: "Bata Chowk, Khunti" },
      destination: { address: "Panchghagh Falls, Murhu" },
      estimatedFare: 850,
      finalFare: 850,
      status: "trip_completed",
      paymentMethod: "cash",
      paymentStatus: "completed",
      rideOtp: "1104",
      isRoundTrip: true,
      createdAt: { seconds: Math.floor(Date.now() / 1000) - 48000 }
    }
  ];
  if (callback) callback('bookings');
}

function loadFallbackUsers(callback) {
  AdminStore.users = [
    {
      id: "usr_101",
      displayName: "Pooja Kumari",
      phoneNumber: "+91 82103 44910",
      email: "pooja.kumari@gmail.com",
      isBlocked: false,
      createdAt: "2026-08-14T10:20:00Z",
      totalBookings: 6,
      totalSpent: 8450
    },
    {
      id: "usr_102",
      displayName: "Amitabh Choudhary",
      phoneNumber: "+91 94311 02944",
      email: "amitabh.c@yahoo.com",
      isBlocked: false,
      createdAt: "2026-09-02T14:15:00Z",
      totalBookings: 12,
      totalSpent: 14200
    },
    {
      id: "usr_103",
      displayName: "Sunil Marandi",
      phoneNumber: "+91 79032 88122",
      email: "sunil.marandi@jharkhand.in",
      isBlocked: false,
      createdAt: "2026-09-18T09:40:00Z",
      totalBookings: 4,
      totalSpent: 1240
    },
    {
      id: "usr_104",
      displayName: "Dr. Alok Verma",
      phoneNumber: "+91 98355 12099",
      email: "dr.alokverma@rims.edu",
      isBlocked: false,
      createdAt: "2026-07-22T16:05:00Z",
      totalBookings: 19,
      totalSpent: 38900
    },
    {
      id: "usr_105",
      displayName: "Rahul Soren",
      phoneNumber: "+91 91223 99014",
      email: "rahul.soren@gmail.com",
      isBlocked: false,
      createdAt: "2026-10-01T11:50:00Z",
      totalBookings: 3,
      totalSpent: 2650
    }
  ];
  if (callback) callback('users');
}

function loadFallbackPayouts(callback) {
  AdminStore.payouts = [
    {
      id: "pay_001",
      driverId: "drv_002_ramesh",
      driverName: "Rameshwar Oraon",
      driverPhone: "+91 87896 01387",
      amount: 5000,
      upiId: "rameshwar.oraon@okaxis",
      status: "pending",
      requestedAt: { seconds: Math.floor(Date.now() / 1000) - 3600 }
    },
    {
      id: "pay_002",
      driverId: "drv_001_suresh",
      driverName: "Suresh Mahto",
      driverPhone: "+91 98351 44210",
      amount: 3500,
      upiId: "sureshmahto@ybl",
      status: "approved",
      transactionRef: "UTR983210492810",
      requestedAt: { seconds: Math.floor(Date.now() / 1000) - 86400 }
    }
  ];
  if (callback) callback('payouts');
}
