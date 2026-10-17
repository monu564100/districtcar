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
    // In-memory set to guarantee exactly ONE notification per event across real-time snapshot fluctuations
    this.processedEvents = new Set();
  }

  _isProcessed(key) {
    return this.processedEvents.has(key);
  }

  _markProcessed(key) {
    this.processedEvents.add(key);
    // Keep memory clean
    if (this.processedEvents.size > 2500) {
      const it = this.processedEvents.values();
      for (let i = 0; i < 500; i++) {
        this.processedEvents.delete(it.next().value);
      }
    }
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
            if (change.type === 'added' || change.type === 'modified') {
              const newBookingKey = `${id}_new_booking`;
              if (
                (data.status === 'requested' || data.status === 'searching_driver') &&
                !data.notifiedDrivers &&
                !this._isProcessed(newBookingKey)
              ) {
                this._markProcessed(newBookingKey);
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
              const acceptedKey = `${id}_driver_assigned`;
              if (
                data.status === 'driver_assigned' &&
                data.driverId &&
                data.customerId &&
                !data.notifiedCustomerAccepted &&
                !this._isProcessed(acceptedKey)
              ) {
                this._markProcessed(acceptedKey);
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

              // 3. Trip Initiated / Started Riding -> Zomato Style Live Progress Notification
              const tripStartedKey = `${id}_trip_started`;
              if (
                (data.status === 'trip_started' || data.status === 'in_progress') &&
                data.customerId &&
                !data.notifiedCustomerTripStarted &&
                !this._isProcessed(tripStartedKey)
              ) {
                this._markProcessed(tripStartedKey);
                console.log(`[FirestoreWatcher] Detected trip started for booking ${id}`);

                const driverDocRef = data.driverId ? clientDoc(db, 'drivers', data.driverId) : null;
                const fetchDriver = driverDocRef ? clientGetDoc(driverDocRef) : Promise.resolve({ exists: () => false });

                fetchDriver.then((driverSnap) => {
                  const driverData = driverSnap.exists() ? driverSnap.data() : {};

                  notificationService.notifyCustomerTripStarted({
                    bookingId: id,
                    customerId: data.customerId,
                    driverName: driverData.name || data.driverName || 'Partner Driver',
                    destinationAddress: data.destination?.address || 'Destination',
                    vehiclePlate: driverData.vehiclePlate || data.vehiclePlate || 'Verified Partner',
                    vehicleModel: driverData.vehicleModel || data.vehicleModel || 'Cab',
                  }).then(() => {
                    clientUpdateDoc(clientDoc(db, 'bookings', id), {
                      notifiedCustomerTripStarted: true,
                      notifiedCustomerTripStartedAt: clientServerTimestamp(),
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
