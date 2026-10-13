import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:district_car_shared/models/models.dart';
import 'package:district_car_shared/services/fcm_notification_service.dart';

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
    double? maxSearchRadiusKm,
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

      String customerName = _auth.currentUser?.displayName ?? '';
      String customerPhone = _auth.currentUser?.phoneNumber ?? '';
      try {
        final prefs = await SharedPreferences.getInstance();
        if (customerName.isEmpty) customerName = prefs.getString('district_user_name') ?? '';
        if (customerPhone.isEmpty) customerPhone = prefs.getString('district_user_phone') ?? '';
      } catch (_) {}
      if (customerName.isEmpty) customerName = 'District Customer';

      final readableId = 'DC-${100000 + Random().nextInt(900000)}';
      final rideOtp = (1000 + Random().nextInt(9000)).toString();

      final bookingRef = _firestore.collection('bookings').doc();
      final newBooking = {
        'id': bookingRef.id,
        'readableId': readableId,
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'bookingType': 'regular',
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
        // Radius logic:
        // Short distance: default 12.0 km (or 25.0 km if extended fare).
        // Long distance / Tours: up to 35.0 km.
        final bool isLongDistance = distanceKm >= 30.0 || isRoundTrip;
        final double searchRadiusKm = maxSearchRadiusKm ?? (isLongDistance ? 35.0 : 12.0);
        final String requestedCategory = categoryId.trim().toLowerCase();
        final List<String> matchingDriverIds = [];
        final List<String> matchingDriverTokens = [];

        final driversSnapshot = await _firestore.collection('drivers').get();
        for (final driverDoc in driversSnapshot.docs) {
          final dData = driverDoc.data();
          final isBusy = dData['isBusy'] == true || dData['activeBookingId'] != null;
          final isBlocked = dData['isBlocked'] == true;
          final driverCategory = (dData['vehicleCategoryId'] ?? dData['category'] ?? 'car').toString().trim().toLowerCase();

          // Only send request if the driver is NOT busy, NOT blocked, and category matches
          if (!isBusy && !isBlocked && driverCategory == requestedCategory) {
            // Extract driver coordinates (from currentLocation, location, or defaults)
            double driverLat = 23.0740;
            double driverLng = 85.2780;
            if (dData['currentLocation'] != null && dData['currentLocation']['latitude'] != null) {
              driverLat = (dData['currentLocation']['latitude'] as num).toDouble();
              driverLng = (dData['currentLocation']['longitude'] as num).toDouble();
            } else if (dData['location'] != null && dData['location']['latitude'] != null) {
              driverLat = (dData['location']['latitude'] as num).toDouble();
              driverLng = (dData['location']['longitude'] as num).toDouble();
            } else if (dData['latitude'] != null) {
              driverLat = (dData['latitude'] as num).toDouble();
              driverLng = (dData['longitude'] as num).toDouble();
            }

            final distToDriverMeters = Geolocator.distanceBetween(
              pickup.latitude,
              pickup.longitude,
              driverLat,
              driverLng,
            );
            final distToDriverKm = distToDriverMeters / 1000.0;

            // Only notify drivers within the search radius (e.g. 10-12 km short, 20-25 km expanded, 35 km long tour)
            if (distToDriverKm <= searchRadiusKm) {
              matchingDriverIds.add(driverDoc.id);
              final token = dData['fcmToken'] as String?;
              if (token != null && token.isNotEmpty) {
                matchingDriverTokens.add(token);
              }

              await _firestore.collection('bookingRequests').add({
                'bookingId': bookingRef.id,
                'driverId': driverDoc.id,
                'vehicleCategoryId': requestedCategory,
                'pickupDistanceKm': double.parse(distToDriverKm.toStringAsFixed(1)),
                'status': 'offered',
                'createdAt': FieldValue.serverTimestamp(),
              });
            }
          }
        }

        // Update booking document with search radius and found drivers count
        await bookingRef.update({
          'searchRadiusKm': searchRadiusKm,
          'matchedDriversCount': matchingDriverIds.length,
          'hasNearDrivers': matchingDriverIds.isNotEmpty,
        }).catchError((_) {});

        // Dispatch High-Priority System Push Notification to all matching drivers (Background & Closed App delivery)
        if (matchingDriverIds.isNotEmpty) {
          await FCMNotificationService.sendBookingOfferedNotificationToDrivers(
            bookingId: bookingRef.id,
            readableId: readableId,
            categoryId: requestedCategory,
            pickupAddress: pickup.address,
            destinationAddress: destination.address,
            estimatedFare: fare,
            driverTokens: matchingDriverTokens,
            driverIds: matchingDriverIds,
          );
        }
      } catch (err) {
        debugPrint('Driver push notification dispatch notice: $err');
      }

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

  /// Expand Search to 20-25km with increased fare for long range drivers
  Future<void> expandSearchRadiusWithHigherFare({
    required String bookingId,
    required double additionalFare,
    required double newTotalFare,
  }) async {
    try {
      final docRef = _firestore.collection('bookings').doc(bookingId);
      final snap = await docRef.get();
      if (!snap.exists) return;

      final data = snap.data()!;
      final pickupMap = data['pickup'] as Map<String, dynamic>;
      final pickupLat = (pickupMap['latitude'] as num).toDouble();
      final pickupLng = (pickupMap['longitude'] as num).toDouble();
      final categoryId = (data['vehicleCategoryId'] ?? 'car').toString().trim().toLowerCase();

      // Update booking with expanded fare and 25km radius
      await docRef.update({
        'searchRadiusKm': 25.0,
        'estimatedFare': newTotalFare,
        'finalFare': newTotalFare,
        'fareBoost': additionalFare,
        'expandedSearchAt': FieldValue.serverTimestamp(),
      });

      // Search drivers in 20-25km radius
      final driversSnapshot = await _firestore.collection('drivers').get();
      final List<String> newDriverTokens = [];
      final List<String> newDriverIds = [];

      for (final driverDoc in driversSnapshot.docs) {
        final dData = driverDoc.data();
        final isBusy = dData['isBusy'] == true || dData['activeBookingId'] != null;
        final isBlocked = dData['isBlocked'] == true;
        final driverCategory = (dData['vehicleCategoryId'] ?? dData['category'] ?? 'car').toString().trim().toLowerCase();

        if (!isBusy && !isBlocked && driverCategory == categoryId) {
          double driverLat = 23.0740;
          double driverLng = 85.2780;
          if (dData['currentLocation'] != null && dData['currentLocation']['latitude'] != null) {
            driverLat = (dData['currentLocation']['latitude'] as num).toDouble();
            driverLng = (dData['currentLocation']['longitude'] as num).toDouble();
          } else if (dData['location'] != null && dData['location']['latitude'] != null) {
            driverLat = (dData['location']['latitude'] as num).toDouble();
            driverLng = (dData['location']['longitude'] as num).toDouble();
          }

          final distToDriverKm = Geolocator.distanceBetween(
            pickupLat,
            pickupLng,
            driverLat,
            driverLng,
          ) / 1000.0;

          if (distToDriverKm <= 25.0) {
            newDriverIds.add(driverDoc.id);
            final tok = dData['fcmToken'] as String?;
            if (tok != null && tok.isNotEmpty) newDriverTokens.add(tok);

            await _firestore.collection('bookingRequests').add({
              'bookingId': bookingId,
              'driverId': driverDoc.id,
              'vehicleCategoryId': categoryId,
              'pickupDistanceKm': double.parse(distToDriverKm.toStringAsFixed(1)),
              'isLongRangeBoost': true,
              'status': 'offered',
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }

      if (newDriverIds.isNotEmpty) {
        await FCMNotificationService.sendBookingOfferedNotificationToDrivers(
          bookingId: bookingId,
          readableId: data['readableId'] ?? bookingId,
          categoryId: categoryId,
          pickupAddress: pickupMap['address'] ?? 'Pickup Point',
          destinationAddress: (data['destination']?['address']) ?? 'Destination',
          estimatedFare: newTotalFare,
          driverTokens: newDriverTokens,
          driverIds: newDriverIds,
        );
      }
    } catch (e) {
      debugPrint('Error expanding search radius: $e');
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
      // Filter in memory for confirmed active statuses only (no pending searching)
      final activeDocs = snapshot.docs.where((doc) {
        final data = doc.data();
        final status = data['status'] as String? ?? '';
        return status == 'driver_assigned' ||
            status == 'driver_arrived' ||
            status == 'trip_started';
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
