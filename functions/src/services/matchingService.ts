import * as admin from 'firebase-admin';
import { calculateDistanceKm } from '../utils/geo';
import { DriverProfile, BookingRecord } from '../types';
import { NotificationService } from './notificationService';

export class MatchingService {
  /**
   * Searches for available, verified, online drivers of matching vehicle category
   * within an expanding radius (default starting 5 km, expandable up to 20 km)
   */
  static async findEligibleDrivers(
    booking: BookingRecord,
    radiusKm: number,
    excludeDriverIds: string[] = []
  ): Promise<{ driver: DriverProfile; distance: number }[]> {
    const db = admin.firestore();

    // Query active online drivers
    const snapshot = await db
      .collection('drivers')
      .where('isOnline', '==', true)
      .where('verificationStatus', '==', 'approved')
      .where('driverStatus', '==', 'idle')
      .where('isActive', '==', true)
      .where('isBlocked', '==', false)
      .get();

    const candidates: { driver: DriverProfile; distance: number }[] = [];

    for (const doc of snapshot.docs) {
      const driver = { uid: doc.id, ...(doc.data() as any) } as DriverProfile;

      // Filter out excluded/already attempted drivers
      if (excludeDriverIds.includes(driver.uid)) {
        continue;
      }

      // Check vehicle category compatibility
      if (driver.vehicleCategoryId && driver.vehicleCategoryId !== booking.vehicleCategoryId) {
        continue;
      }

      if (driver.currentLocation && driver.currentLocation.latitude && driver.currentLocation.longitude) {
        const distance = calculateDistanceKm(
          booking.pickup.latitude,
          booking.pickup.longitude,
          driver.currentLocation.latitude,
          driver.currentLocation.longitude
        );

        if (distance <= radiusKm) {
          candidates.push({ driver, distance });
        }
      }
    }

    // Sort by proximity ascending
    candidates.sort((a, b) => a.distance - b.distance);
    return candidates;
  }

  /**
   * Offers a booking to the nearest candidate driver
   */
  static async offerBookingToDriver(
    bookingId: string,
    driverId: string,
    distanceKm: number,
    timeoutSeconds = 25
  ): Promise<void> {
    const db = admin.firestore();
    const expiresAt = new Date(Date.now() + timeoutSeconds * 1000);

    const requestRef = db.collection('bookingRequests').doc();
    await requestRef.set({
      id: requestRef.id,
      bookingId,
      driverId,
      pickupDistanceKm: distanceKm,
      status: 'offered',
      offeredAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
    });

    // Update booking's attempted drivers list
    await db.collection('bookings').doc(bookingId).update({
      status: 'searching_driver',
      currentRequestId: requestRef.id,
      attemptedDriverIds: admin.firestore.FieldValue.arrayUnion(driverId),
    });

    // Notify the driver via FCM
    await NotificationService.sendToUser(
      driverId,
      'New Ride Request!',
      `Ride request nearby (~${distanceKm} km). Tap to accept.`,
      {
        type: 'NEW_BOOKING_REQUEST',
        bookingId,
        requestId: requestRef.id,
      }
    );
  }
}
