const { firebaseClient, clientFirestore } = require('./firebaseClient');
const notificationService = require('./notificationService');

const {
  clientCollection,
  clientOnSnapshot,
  clientGetDoc,
  clientDoc,
  clientUpdateDoc,
  clientServerTimestamp,
} = clientFirestore;

class FirestoreWatcher {
  constructor() {
    this.isListening = false;
  }

  start() {
    const db = firebaseClient.clientDb;
    if (!db) {
      console.warn('[FirestoreWatcher] Firestore db not available. Watcher paused.');
      return;
    }

    if (this.isListening) return;
    this.isListening = true;

    console.log('👀 [FirestoreWatcher] Listening to real-time changes on "bookings" collection...');

    try {
      const bookingsRef = clientCollection(db, 'bookings');

      clientOnSnapshot(
        bookingsRef,
        (snapshot) => {
          snapshot.docChanges().forEach((change) => {
            const data = change.doc.data();
            const id = change.doc.id;

            // 1. New Booking created: status is 'requested' or 'searching_driver'
            if (change.type === 'added') {
              if (
                (data.status === 'requested' || data.status === 'searching_driver') &&
                !data.notifiedDrivers
              ) {
                console.log(`[FirestoreWatcher] Detected new booking: ${id} (${data.readableId || id})`);

                notificationService.notifyDriversNewBooking({
                  bookingId: id,
                  readableId: data.readableId || id,
                  categoryId: data.vehicleCategoryId,
                  pickupAddress: data.pickup?.address || 'Pickup Point',
                  destinationAddress: data.destination?.address || 'Destination',
                  estimatedFare: data.estimatedFare || data.fareSnapshot?.totalFare || 0,
                }).then(() => {
                  clientUpdateDoc(clientDoc(db, 'bookings', id), {
                    notifiedDrivers: true,
                    notifiedDriversAt: clientServerTimestamp(),
                  }).catch(() => {});
                });
              }
            }

            // 2. Booking accepted: status transitioned to 'driver_assigned'
            if (change.type === 'modified') {
              if (
                data.status === 'driver_assigned' &&
                data.driverId &&
                data.customerId &&
                !data.notifiedCustomerAccepted
              ) {
                console.log(`[FirestoreWatcher] Detected driver assignment for booking ${id}`);

                clientGetDoc(clientDoc(db, 'drivers', data.driverId)).then((driverSnap) => {
                  const driverData = driverSnap.exists() ? driverSnap.data() : {};

                  notificationService.notifyCustomerBookingAccepted({
                    bookingId: id,
                    customerId: data.customerId,
                    driverName: driverData.name || 'Assigned Driver',
                    driverPhone: driverData.phoneNumber || '+91 87896 01387',
                    vehiclePlate: driverData.vehiclePlate || 'Verified Cab',
                    vehicleModel: driverData.vehicleModel || 'District Car',
                    rideOtp: data.rideOtp,
                  }).then(() => {
                    clientUpdateDoc(clientDoc(db, 'bookings', id), {
                      notifiedCustomerAccepted: true,
                      notifiedCustomerAcceptedAt: clientServerTimestamp(),
                    }).catch(() => {});
                  });
                });
              }
            }
          });
        },
        (error) => {
          console.warn('[FirestoreWatcher] Snapshot warning:', error.message);
        }
      );
    } catch (err) {
      console.warn('[FirestoreWatcher] Start error:', err.message);
    }
  }
}

module.exports = new FirestoreWatcher();
