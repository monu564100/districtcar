import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { FareService } from './services/fareService';
import { MatchingService } from './services/matchingService';
import { NotificationService } from './services/notificationService';
import { generateReadableBookingId, generateRideOtp, calculateDistanceKm, encodeGeohash } from './utils/geo';
import { BookingRecord, DriverProfile } from './types';

admin.initializeApp();
const db = admin.firestore();

// -------------------------------------------------------------
// 1. FARE ESTIMATION (Callable)
// -------------------------------------------------------------
export const estimateFare = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { categoryId, pickup, destination } = data;
  if (!categoryId || !pickup || !destination) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing parameters');
  }

  const category = await FareService.getCategory(categoryId);
  if (!category) {
    throw new functions.https.HttpsError('not-found', 'Vehicle category not found');
  }

  const distanceKm = calculateDistanceKm(
    pickup.latitude,
    pickup.longitude,
    destination.latitude,
    destination.longitude
  );

  // Estimating average city driving speed ~25 km/h + baseline 5 mins
  const durationMinutes = Math.max(5, Math.round((distanceKm / 25) * 60));
  const fareBreakdown = FareService.calculateFare(category, distanceKm, durationMinutes);

  return {
    category,
    distanceKm,
    durationMinutes,
    fareBreakdown,
  };
});

// -------------------------------------------------------------
// 2. CREATE BOOKING (Callable)
// -------------------------------------------------------------
export const createBooking = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const customerId = context.auth.uid;
  const { categoryId, pickup, destination, paymentMethod = 'cash' } = data;

  if (!categoryId || !pickup || !destination) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing booking fields');
  }

  // Validate customer active status
  const customerDoc = await db.collection('users').doc(customerId).get();
  if (!customerDoc.exists || customerDoc.data()?.isBlocked) {
    throw new functions.https.HttpsError('permission-denied', 'Customer account is blocked or inactive');
  }

  const category = await FareService.getCategory(categoryId);
  if (!category) {
    throw new functions.https.HttpsError('not-found', 'Vehicle category not found');
  }

  const distanceKm = calculateDistanceKm(
    pickup.latitude,
    pickup.longitude,
    destination.latitude,
    destination.longitude
  );
  const durationMinutes = Math.max(5, Math.round((distanceKm / 25) * 60));
  const fareBreakdown = FareService.calculateFare(category, distanceKm, durationMinutes);

  const readableId = generateReadableBookingId();
  const rideOtp = generateRideOtp();

  const bookingRef = db.collection('bookings').doc();
  const newBooking: BookingRecord = {
    id: bookingRef.id,
    readableId,
    customerId,
    vehicleCategoryId: categoryId,
    pickup: {
      ...pickup,
      geohash: encodeGeohash(pickup.latitude, pickup.longitude),
    },
    destination: {
      ...destination,
      geohash: encodeGeohash(destination.latitude, destination.longitude),
    },
    estimatedDistanceKm: distanceKm,
    estimatedDurationMinutes: durationMinutes,
    estimatedFare: fareBreakdown.totalFare,
    fareSnapshot: fareBreakdown,
    paymentMethod,
    paymentStatus: 'pending',
    status: 'searching_driver',
    rideOtp,
    searchRadiusKm: 5,
    attemptedDriverIds: [],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await bookingRef.set(newBooking);

  // Trigger driver search & matching
  const eligibleDrivers = await MatchingService.findEligibleDrivers(newBooking, 5, []);
  if (eligibleDrivers.length > 0) {
    const target = eligibleDrivers[0];
    await MatchingService.offerBookingToDriver(bookingRef.id, target.driver.uid, target.distance, 25);
  } else {
    // If no driver in 5 km, expand to 10 km
    const expanded = await MatchingService.findEligibleDrivers(newBooking, 10, []);
    if (expanded.length > 0) {
      const target = expanded[0];
      await MatchingService.offerBookingToDriver(bookingRef.id, target.driver.uid, target.distance, 25);
    } else {
      // Mark as no driver found
      await bookingRef.update({ status: 'no_driver_found' });
      await NotificationService.sendToUser(
        customerId,
        'No Drivers Available',
        'We could not find any active drivers near your pickup location.',
        { bookingId: bookingRef.id, status: 'no_driver_found' }
      );
    }
  }

  return {
    bookingId: bookingRef.id,
    readableId,
    status: 'searching_driver',
    estimatedFare: fareBreakdown.totalFare,
    rideOtp,
  };
});

// -------------------------------------------------------------
// 3. ACCEPT BOOKING (Callable - Atomic Transaction against race condition)
// -------------------------------------------------------------
export const acceptBooking = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const driverId = context.auth.uid;
  const { bookingId, requestId } = data;

  if (!bookingId) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing bookingId');
  }

  const bookingRef = db.collection('bookings').doc(bookingId);
  const driverRef = db.collection('drivers').doc(driverId);
  const requestRef = requestId ? db.collection('bookingRequests').doc(requestId) : null;

  return await db.runTransaction(async (transaction) => {
    const bookingDoc = await transaction.get(bookingRef);
    if (!bookingDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Booking not found');
    }

    const bookingData = bookingDoc.data() as BookingRecord;

    // Check if another driver already claimed this booking
    if (bookingData.status !== 'searching_driver' && bookingData.status !== 'requested') {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'This ride has already been assigned or cancelled.'
      );
    }

    const driverDoc = await transaction.get(driverRef);
    if (!driverDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Driver profile not found');
    }

    const driverData = driverDoc.data() as DriverProfile;
    if (driverData.isBlocked || !driverData.isOnline || driverData.driverStatus !== 'idle') {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'Driver is not available to accept rides'
      );
    }

    // Assign driver atomically
    transaction.update(bookingRef, {
      driverId,
      status: 'driver_assigned',
      assignedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    transaction.update(driverRef, {
      driverStatus: 'busy',
      currentBookingId: bookingId,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    if (requestRef) {
      transaction.update(requestRef, {
        status: 'accepted',
        respondedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    return {
      success: true,
      bookingId,
      message: 'Booking assigned successfully',
    };
  }).then(async (result) => {
    // Notify customer
    const bookingDoc = await bookingRef.get();
    const customerId = bookingDoc.data()?.customerId;
    if (customerId) {
      await NotificationService.sendToUser(
        customerId,
        'Driver Assigned!',
        'A driver is on their way to pick you up.',
        { type: 'DRIVER_ASSIGNED', bookingId }
      );
    }
    return result;
  });
});

// -------------------------------------------------------------
// 4. REJECT BOOKING / EXPIRE (Callable)
// -------------------------------------------------------------
export const rejectBooking = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const driverId = context.auth.uid;
  const { bookingId, requestId, reason = 'declined_by_driver' } = data;

  if (requestId) {
    await db.collection('bookingRequests').doc(requestId).update({
      status: 'rejected',
      rejectionReason: reason,
      respondedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  // Find next eligible driver, excluding the declining driver
  const bookingDoc = await db.collection('bookings').doc(bookingId).get();
  if (!bookingDoc.exists) return { success: false };

  const booking = bookingDoc.data() as BookingRecord;
  if (booking.status === 'searching_driver') {
    const attempted = Array.from(new Set([...(booking.attemptedDriverIds || []), driverId]));
    const candidates = await MatchingService.findEligibleDrivers(booking, 10, attempted);

    if (candidates.length > 0) {
      const nextCandidate = candidates[0];
      await MatchingService.offerBookingToDriver(bookingId, nextCandidate.driver.uid, nextCandidate.distance, 25);
    } else {
      await db.collection('bookings').doc(bookingId).update({
        status: 'no_driver_found',
      });
      await NotificationService.sendToUser(
        booking.customerId,
        'No Driver Found',
        'Nearby drivers are currently busy. Please try again soon.',
        { bookingId, status: 'no_driver_found' }
      );
    }
  }

  return { success: true };
});

// -------------------------------------------------------------
// 5. DRIVER ARRIVED AT PICKUP (Callable)
// -------------------------------------------------------------
export const driverArrived = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const driverId = context.auth.uid;
  const { bookingId } = data;

  const bookingRef = db.collection('bookings').doc(bookingId);
  const bookingDoc = await bookingRef.get();

  if (!bookingDoc.exists || bookingDoc.data()?.driverId !== driverId) {
    throw new functions.https.HttpsError('permission-denied', 'Unauthorized for this booking');
  }

  await bookingRef.update({
    status: 'driver_arrived',
    arrivedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  const customerId = bookingDoc.data()?.customerId;
  if (customerId) {
    await NotificationService.sendToUser(
      customerId,
      'Driver Has Arrived!',
      'Your driver has reached your pickup location.',
      { type: 'DRIVER_ARRIVED', bookingId }
    );
  }

  return { success: true, status: 'driver_arrived' };
});

// -------------------------------------------------------------
// 6. START TRIP (Verified with Ride OTP)
// -------------------------------------------------------------
export const startTrip = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const driverId = context.auth.uid;
  const { bookingId, rideOtp } = data;

  const bookingRef = db.collection('bookings').doc(bookingId);
  const bookingDoc = await bookingRef.get();

  if (!bookingDoc.exists || bookingDoc.data()?.driverId !== driverId) {
    throw new functions.https.HttpsError('permission-denied', 'Unauthorized for this booking');
  }

  const booking = bookingDoc.data() as BookingRecord;
  if (booking.rideOtp && booking.rideOtp !== rideOtp) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid ride verification OTP');
  }

  await bookingRef.update({
    status: 'trip_started',
    startedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  if (booking.customerId) {
    await NotificationService.sendToUser(
      booking.customerId,
      'Trip Started',
      'Have a safe journey with District Car!',
      { type: 'TRIP_STARTED', bookingId }
    );
  }

  return { success: true, status: 'trip_started' };
});

// -------------------------------------------------------------
// 7. COMPLETE TRIP (Calculates final fare, frees driver)
// -------------------------------------------------------------
export const completeTrip = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const driverId = context.auth.uid;
  const { bookingId } = data;

  const bookingRef = db.collection('bookings').doc(bookingId);
  const driverRef = db.collection('drivers').doc(driverId);

  return await db.runTransaction(async (transaction) => {
    const bookingDoc = await transaction.get(bookingRef);
    if (!bookingDoc.exists || bookingDoc.data()?.driverId !== driverId) {
      throw new functions.https.HttpsError('permission-denied', 'Unauthorized for this booking');
    }

    const booking = bookingDoc.data() as BookingRecord;
    const finalFare = booking.estimatedFare;

    transaction.update(bookingRef, {
      status: 'trip_completed',
      finalFare,
      paymentStatus: 'completed',
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    transaction.update(driverRef, {
      driverStatus: 'idle',
      currentBookingId: admin.firestore.FieldValue.delete(),
      totalTrips: admin.firestore.FieldValue.increment(1),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      bookingId,
      finalFare,
      status: 'trip_completed',
    };
  }).then(async (result) => {
    const bookingDoc = await bookingRef.get();
    const customerId = bookingDoc.data()?.customerId;
    if (customerId) {
      await NotificationService.sendToUser(
        customerId,
        'Trip Completed!',
        `Your trip is complete. Total fare: ₹${result.finalFare}. Please rate your driver.`,
        { type: 'TRIP_COMPLETED', bookingId, fare: String(result.finalFare) }
      );
    }
    return result;
  });
});

// -------------------------------------------------------------
// 8. CANCEL BOOKING (Callable - Customer or Driver)
// -------------------------------------------------------------
export const cancelBooking = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const userId = context.auth.uid;
  const { bookingId, reason = 'User requested cancellation' } = data;

  const bookingRef = db.collection('bookings').doc(bookingId);
  const bookingDoc = await bookingRef.get();

  if (!bookingDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'Booking not found');
  }

  const booking = bookingDoc.data() as BookingRecord;
  const isCustomer = booking.customerId === userId;
  const isDriver = booking.driverId === userId;

  if (!isCustomer && !isDriver) {
    throw new functions.https.HttpsError('permission-denied', 'Not permitted to cancel this booking');
  }

  const newStatus = isCustomer ? 'cancelled_by_customer' : 'cancelled_by_driver';

  await bookingRef.update({
    status: newStatus,
    cancelledBy: isCustomer ? 'customer' : 'driver',
    cancellationReason: reason,
    cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Free driver if one was assigned
  if (booking.driverId) {
    await db.collection('drivers').doc(booking.driverId).update({
      driverStatus: 'idle',
      currentBookingId: admin.firestore.FieldValue.delete(),
    });

    if (isCustomer) {
      await NotificationService.sendToUser(
        booking.driverId,
        'Ride Cancelled',
        'The customer cancelled the ride.',
        { type: 'BOOKING_CANCELLED', bookingId }
      );
    }
  }

  if (isDriver && booking.customerId) {
    await NotificationService.sendToUser(
      booking.customerId,
      'Ride Cancelled by Driver',
      'The driver had to cancel. Searching for a new ride...',
      { type: 'BOOKING_CANCELLED', bookingId }
    );
  }

  return { success: true, status: newStatus };
});

// -------------------------------------------------------------
// 9. SUBMIT RATING & AGGREGATION
// -------------------------------------------------------------
export const submitRating = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const fromUserId = context.auth.uid;
  const { bookingId, targetUserId, rating, review = '' } = data;

  if (!bookingId || !targetUserId || !rating || rating < 1 || rating > 5) {
    throw new functions.https.HttpsError('invalid-argument', 'Valid rating (1-5) is required');
  }

  // Prevent duplicate rating
  const existing = await db
    .collection('ratings')
    .where('bookingId', '==', bookingId)
    .where('fromUserId', '==', fromUserId)
    .get();

  if (!existing.empty) {
    throw new functions.https.HttpsError('already-exists', 'You have already rated this trip');
  }

  await db.collection('ratings').add({
    bookingId,
    fromUserId,
    targetUserId,
    rating,
    review,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Recalculate target driver/user average rating
  const ratingsSnapshot = await db.collection('ratings').where('targetUserId', '==', targetUserId).get();
  if (!ratingsSnapshot.empty) {
    let sum = 0;
    ratingsSnapshot.docs.forEach((d) => (sum += d.data().rating || 0));
    const avg = Math.round((sum / ratingsSnapshot.docs.length) * 10) / 10;

    // Check if target is driver
    const driverRef = db.collection('drivers').doc(targetUserId);
    const driverDoc = await driverRef.get();
    if (driverDoc.exists) {
      await driverRef.update({ rating: avg });
    }
  }

  return { success: true };
});

// -------------------------------------------------------------
// 10. UPDATE DRIVER LOCATION & ONLINE STATUS
// -------------------------------------------------------------
export const updateDriverLocation = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const driverId = context.auth.uid;
  const { latitude, longitude, isOnline } = data;

  if (typeof latitude !== 'number' || typeof longitude !== 'number') {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid coordinates');
  }

  const updatePayload: any = {
    currentLocation: {
      latitude,
      longitude,
      geohash: encodeGeohash(latitude, longitude),
    },
    lastLocationAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (typeof isOnline === 'boolean') {
    updatePayload.isOnline = isOnline;
    if (isOnline) {
      updatePayload.onlineAt = admin.firestore.FieldValue.serverTimestamp();
    }
  }

  await db.collection('drivers').doc(driverId).update(updatePayload);
  return { success: true };
});

// -------------------------------------------------------------
// 11. ADMIN ACTIONS: VERIFY DRIVER, MANAGE FARES
// -------------------------------------------------------------
export const verifyDriver = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const adminId = context.auth.uid;
  const { driverId, status, rejectionReason } = data;

  if (!['approved', 'rejected', 'suspended'].includes(status)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid verification status');
  }

  const updateData: any = {
    verificationStatus: status,
    reviewedBy: adminId,
    reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (rejectionReason) {
    updateData.rejectionReason = rejectionReason;
  }

  await db.collection('drivers').doc(driverId).update(updateData);

  // Write audit log
  await db.collection('auditLogs').add({
    actorId: adminId,
    action: `driver_verification_${status}`,
    targetId: driverId,
    metadata: { status, rejectionReason },
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true };
});
