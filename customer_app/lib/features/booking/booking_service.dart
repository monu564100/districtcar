import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:district_car_shared/models/models.dart';

class BookingService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>> createBooking({
    required String categoryId,
    required LocationModel pickup,
    required LocationModel destination,
    String paymentMethod = 'cash',
    double? customFare,
    bool isRoundTrip = false,
    double roundTripStoppingHours = 1.0,
    String? scheduledDate,
    String? scheduledTimeSlot,
  }) async {
    // 1. Try Firebase Cloud Functions
    try {
      final callable = _functions.httpsCallable('createBooking');
      final response = await callable.call({
        'categoryId': categoryId,
        'pickup': pickup.toMap(),
        'destination': destination.toMap(),
        'paymentMethod': paymentMethod,
        'isRoundTrip': isRoundTrip,
        'roundTripStoppingHours': roundTripStoppingHours,
        'scheduledDate': scheduledDate,
        'scheduledTimeSlot': scheduledTimeSlot,
      }).timeout(const Duration(seconds: 4));
      return Map<String, dynamic>.from(response.data as Map);
    } catch (_) {
      // 2. Direct Firestore Creation Fallback for 100% offline & local testing reliability
      String customerId = _auth.currentUser?.uid ?? '';
      if (customerId.isEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          customerId = prefs.getString('district_user_uid') ?? '';
        } catch (_) {}
      }
      if (customerId.isEmpty) {
        customerId = 'guest_${Random().nextInt(99999)}';
      }

      final distMeters = Geolocator.distanceBetween(
        pickup.latitude,
        pickup.longitude,
        destination.latitude,
        destination.longitude,
      );
      final distanceKm = (distMeters / 1000.0 < 0.5) ? 1.0 : double.parse((distMeters / 1000.0).toStringAsFixed(1));
      final durationMinutes = (distanceKm / 25.0 * 60.0).round().clamp(5, 180);

      final fare = customFare ?? (50.0 + (distanceKm * 15.0) + 10.0).roundToDouble();

      final readableId = 'DC-${100000 + Random().nextInt(900000)}';
      final rideOtp = (1000 + Random().nextInt(9000)).toString();

      final bookingRef = _firestore.collection('bookings').doc();
      final newBooking = {
        'id': bookingRef.id,
        'readableId': readableId,
        'customerId': customerId,
        'vehicleCategoryId': categoryId,
        'pickup': pickup.toMap(),
        'destination': destination.toMap(),
        'estimatedDistanceKm': distanceKm,
        'estimatedDurationMinutes': durationMinutes.toDouble(),
        'estimatedFare': fare,
        'finalFare': fare,
        'paymentMethod': paymentMethod,
        'paymentStatus': 'pending',
        'status': 'searching_driver',
        'rideOtp': rideOtp,
        'isRoundTrip': isRoundTrip,
        'roundTripStoppingHours': roundTripStoppingHours,
        'scheduledDate': scheduledDate ?? 'Today',
        'scheduledTimeSlot': scheduledTimeSlot ?? 'Now',
        'createdAt': FieldValue.serverTimestamp(),
      };

      try {
        await bookingRef.set(newBooking);
      } catch (_) {}

      // Broadcast ride request ONLY to available (non-busy, non-blocked) drivers of that particular category
      try {
        final driversSnapshot = await _firestore.collection('drivers').get();
        for (final driverDoc in driversSnapshot.docs) {
          final dData = driverDoc.data();
          final isBusy = dData['isBusy'] == true || dData['activeBookingId'] != null;
          final isBlocked = dData['isBlocked'] == true;
          final driverCategory = (dData['vehicleCategoryId'] ?? dData['category'] ?? 'car').toString().trim().toLowerCase();
          final requestedCategory = categoryId.trim().toLowerCase();

          // Only send request if the driver is NOT busy on another ride, NOT blocked, and category matches
          if (!isBusy && !isBlocked && driverCategory == requestedCategory) {
            await _firestore.collection('bookingRequests').add({
              'bookingId': bookingRef.id,
              'driverId': driverDoc.id,
              'vehicleCategoryId': requestedCategory,
              'status': 'offered',
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        }
      } catch (_) {}

      return {
        'bookingId': bookingRef.id,
        'readableId': readableId,
        'estimatedFare': fare,
        'rideOtp': rideOtp,
        'isRoundTrip': isRoundTrip,
        'scheduledDate': scheduledDate,
        'scheduledTimeSlot': scheduledTimeSlot,
      };
    }
  }

  Future<void> cancelBooking(String bookingId, String reason) async {
    try {
      final callable = _functions.httpsCallable('cancelBooking');
      await callable.call({
        'bookingId': bookingId,
        'reason': reason,
      }).timeout(const Duration(seconds: 4));
    } catch (_) {
      try {
        await _firestore.collection('bookings').doc(bookingId).update({
          'status': 'cancelled_by_customer',
          'cancellationReason': reason,
          'cancelledAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
  }

  Future<void> submitRating({
    required String bookingId,
    required String targetUserId,
    required int rating,
    String review = '',
  }) async {
    try {
      final callable = _functions.httpsCallable('submitRating');
      await callable.call({
        'bookingId': bookingId,
        'targetUserId': targetUserId,
        'rating': rating,
        'review': review,
      }).timeout(const Duration(seconds: 4));
    } catch (_) {
      try {
        await _firestore.collection('bookings').doc(bookingId).update({
          'rating': rating,
          'review': review,
        });
      } catch (_) {}
    }
  }
  /// Stream active booking for current customer
  Stream<BookingModel?> streamUserActiveBooking(String customerId) {
    if (customerId.isEmpty) return Stream.value(null);
    return _firestore
        .collection('bookings')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      // Filter in memory for active statuses
      final activeDocs = snapshot.docs.where((doc) {
        final data = doc.data();
        final status = data['status'] as String? ?? '';
        return status == 'driver_assigned' ||
            status == 'driver_arrived' ||
            status == 'trip_started' ||
            status == 'searching_driver';
      }).toList();

      if (activeDocs.isEmpty) return null;
      // Return the most recently updated or first active booking
      activeDocs.sort((a, b) {
        final aTime = a.data()['createdAt']?.toString() ?? '';
        final bTime = b.data()['createdAt']?.toString() ?? '';
        return bTime.compareTo(aTime);
      });

      final doc = activeDocs.first;
      return BookingModel.fromMap(doc.data(), doc.id);
    });
  }
}

final bookingServiceProvider = Provider<BookingService>((ref) => BookingService());
