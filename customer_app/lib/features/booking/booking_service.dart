import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:district_car_shared/models/models.dart';

class BookingService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<Map<String, dynamic>> createBooking({
    required String categoryId,
    required LocationModel pickup,
    required LocationModel destination,
    String paymentMethod = 'cash',
  }) async {
    final callable = _functions.httpsCallable('createBooking');
    final response = await callable.call({
      'categoryId': categoryId,
      'pickup': pickup.toMap(),
      'destination': destination.toMap(),
      'paymentMethod': paymentMethod,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> cancelBooking(String bookingId, String reason) async {
    final callable = _functions.httpsCallable('cancelBooking');
    await callable.call({
      'bookingId': bookingId,
      'reason': reason,
    });
  }

  Future<void> submitRating({
    required String bookingId,
    required String targetUserId,
    required int rating,
    String review = '',
  }) async {
    final callable = _functions.httpsCallable('submitRating');
    await callable.call({
      'bookingId': bookingId,
      'targetUserId': targetUserId,
      'rating': rating,
      'review': review,
    });
  }
}

final bookingServiceProvider = Provider<BookingService>((ref) => BookingService());
