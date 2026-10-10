const admin = require('firebase-admin');
const axios = require('axios');
const path = require('path');
const fs = require('fs');

// Modular web/client SDK for fallback when Admin SDK lacks local credentials file
const { initializeApp: initClientApp } = require('@firebase/app');
const {
  getFirestore: getClientFirestore,
  collection: clientCollection,
  onSnapshot: clientOnSnapshot,
  getDocs: clientGetDocs,
  getDoc: clientGetDoc,
  doc: clientDoc,
  addDoc: clientAddDoc,
  setDoc: clientSetDoc,
  updateDoc: clientUpdateDoc,
  query: clientQuery,
  where: clientWhere,
  serverTimestamp: clientServerTimestamp,
} = require('@firebase/firestore');

const FIREBASE_WEB_CONFIG = {
  apiKey: 'AIzaSyDwi6OV-l7mDqCpPaRI4Yn9gUXiZrf73QM',
  appId: '1:319163006406:web:c4807f606480e920fa46c7',
  messagingSenderId: '319163006406',
  projectId: 'districtcar-4b880',
  authDomain: 'districtcar-4b880.firebaseapp.com',
  storageBucket: 'districtcar-4b880.firebasestorage.app',
};

class FirebaseClient {
  constructor() {
    this.adminApp = null;
    this.adminDb = null;
    this.adminMessaging = null;

    this.clientApp = null;
    this.clientDb = null;
    this.useClientDb = false;

    this.serverKey = process.env.FCM_SERVER_KEY || null;
    this.init();
  }

  init() {
    // 1. Try initializing Firebase Admin SDK with Service Account JSON if present
    const serviceAccountPath =
      process.env.GOOGLE_APPLICATION_CREDENTIALS ||
      path.join(__dirname, 'serviceAccountKey.json');

    if (fs.existsSync(serviceAccountPath)) {
      try {
        const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
        this.adminApp = admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
          projectId: serviceAccount.project_id || 'districtcar-4b880',
        });
        this.adminDb = admin.firestore();
        this.adminMessaging = admin.messaging();
        console.log('[FirebaseClient] Initialized Firebase Admin SDK with serviceAccountKey.json');
      } catch (err) {
        console.warn('[FirebaseClient] Admin SDK certificate init error:', err.message);
      }
    }

    // 2. Always initialize modular Firestore Client SDK (Works reliably anywhere without requiring GCP private key!)
    try {
      this.clientApp = initClientApp(FIREBASE_WEB_CONFIG);
      this.clientDb = getClientFirestore(this.clientApp);
      this.useClientDb = true;
      console.log('[FirebaseClient] Initialized Firebase Client SDK for project districtcar-4b880');
    } catch (clientErr) {
      console.warn('[FirebaseClient] Client SDK init notice:', clientErr.message);
    }

    // Refresh Server Key from Firestore
    this.refreshServerKey();
  }

  async refreshServerKey() {
    try {
      if (this.serverKey) return;
      if (this.clientDb) {
        const ref = clientDoc(this.clientDb, 'app_config', 'fcm_settings');
        const snap = await clientGetDoc(ref);
        if (snap.exists() && snap.data()?.serverKey) {
          this.serverKey = snap.data().serverKey;
          console.log('[FirebaseClient] Loaded FCM Server Key dynamically from app_config/fcm_settings');
        }
      }
    } catch (e) {
      // Ignored
    }
  }

  /**
   * Universal push dispatcher:
   * 1. If Admin SDK is active, uses FCM Admin messaging.
   * 2. If Legacy HTTP Server Key is available, dispatches high-priority push via FCM API.
   */
  async sendPushNotification({ target, title, body, data = {}, imageUrl = null }) {
    let success = false;
    let methodUsed = 'none';

    // 1. Admin SDK
    if (this.adminMessaging) {
      try {
        const isTopic = target.startsWith('/topics/');
        const topicName = isTopic ? target.replace('/topics/', '') : null;

        const payload = {
          notification: {
            title,
            body,
            imageUrl: imageUrl || undefined,
          },
          data: {
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
            title,
            body,
            ...Object.keys(data).reduce((acc, k) => {
              acc[k] = String(data[k]);
              return acc;
            }, {}),
          },
          android: {
            priority: 'high',
            notification: {
              sound: 'default',
              channelId: 'district_car_rides',
            },
          },
        };

        if (isTopic) {
          await this.adminMessaging.send({ ...payload, topic: topicName });
        } else {
          await this.adminMessaging.send({ ...payload, token: target });
        }
        success = true;
        methodUsed = 'admin_sdk';
        return { success, methodUsed };
      } catch (_) {}
    }

    // 2. HTTP Legacy API Fallback
    if (this.serverKey) {
      try {
        const httpPayload = {
          to: target,
          notification: {
            title,
            body,
            sound: 'default',
            ...(imageUrl ? { image: imageUrl } : {}),
          },
          data: {
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
            title,
            body,
            ...data,
          },
          priority: 'high',
        };

        const res = await axios.post('https://fcm.googleapis.com/fcm/send', httpPayload, {
          headers: {
            'Content-Type': 'application/json',
            Authorization: `key=${this.serverKey}`,
          },
          timeout: 7000,
        });

        if (res.status === 200) {
          success = true;
          methodUsed = 'http_legacy';
        }
      } catch (err) {
        // Will return success: false
      }
    }

    return { success, methodUsed };
  }
}

module.exports = {
  firebaseClient: new FirebaseClient(),
  clientFirestore: {
    clientCollection,
    clientOnSnapshot,
    clientGetDocs,
    clientGetDoc,
    clientDoc,
    clientAddDoc,
    clientSetDoc,
    clientUpdateDoc,
    clientQuery,
    clientWhere,
    clientServerTimestamp,
  },
};
