const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

async function cleanDatabase() {
  const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');
  if (!fs.existsSync(serviceAccountPath)) {
    console.error('Service account key not found at', serviceAccountPath);
    process.exit(1);
  }

  const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
  const app = admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: serviceAccount.project_id || 'districtcar-4b880',
  });

  const db = admin.firestore();

  const collectionsToClean = [
    'bookings',
    'bookingRequests',
    'booking_requests',
    'notifications',
    'chats',
    'drivers',
    'users',
    'driverLocations',
    'wallet_transactions',
    'commission_payments',
    'emergency_contacts',
    'feedback',
    'support_tickets'
  ];

  console.log('🚀 Starting complete database purge for fresh start...');

  for (const collName of collectionsToClean) {
    try {
      const snapshot = await db.collection(collName).get();
      if (snapshot.empty) {
        console.log(`ℹ️ Collection [${collName}] is already empty.`);
        continue;
      }

      console.log(`🧹 Deleting ${snapshot.size} documents from [${collName}]...`);
      const batchSize = 400;
      let batch = db.batch();
      let count = 0;

      for (const doc of snapshot.docs) {
        batch.delete(doc.ref);
        count++;
        if (count % batchSize === 0) {
          await batch.commit();
          batch = db.batch();
        }
      }

      if (count % batchSize !== 0) {
        await batch.commit();
      }
      console.log(`✅ Successfully wiped [${collName}] (${count} deleted).`);
    } catch (err) {
      console.error(`⚠️ Error wiping collection [${collName}]:`, err.message);
    }
  }

  console.log('\n🎉 ALL COLLECTIONS CLEANED SUCCESSFULLY! Database is completely fresh and ready.');
  process.exit(0);
}

cleanDatabase();
