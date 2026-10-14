import 'package:flutter_test/flutter_test.dart';
import 'package:district_car_shared/models/models.dart';
import 'package:district_car_customer/features/tours/tour_pricing_service.dart';

void main() {
  group('Tour Pricing & Geofencing Tests', () {
    final hundruFalls = PopularDestinationModel(
      id: 'hundru_falls',
      name: 'Hundru Falls',
      category: 'waterfall',
      district: 'Ranchi',
      locationAddress: 'Ormanjhi, Ranchi',
      latitude: 23.4503,
      longitude: 85.6567,
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/hundru.jpg',
      description: 'Scenic waterfall',
      startingFare: 1199.0,
      approxDistanceKm: 44.0,
    );

    test('Distance between Ranchi City Center and Hundru Falls is realistic (~44 km)', () {
      // Ranchi Albert Ekka Chowk: (23.3441, 85.3096)
      final distance = TourPricingService.calculateRoadDistanceKm(
        23.3441,
        85.3096,
        hundruFalls.latitude,
        hundruFalls.longitude,
      );
      // Realistic road distance should be between 35 km and 55 km
      expect(distance, greaterThan(35.0));
      expect(distance, lessThan(55.0));
    });

    test('Rural travel duration matches 30-45 km/h speed bounds', () {
      const distance = 44.0;
      final durationMins = TourPricingService.calculateRuralDurationMinutes(distance);

      // 44 km at 35 km/h is ~75 minutes (1h 15m)
      expect(durationMins, greaterThanOrEqualTo(55)); // Not faster than ~48 km/h
      expect(durationMins, lessThanOrEqualTo(95)); // Not slower than ~28 km/h
    });

    test('Pickup within 150 km is serviceable', () {
      final breakdown = TourPricingService.calculateTourPackageFare(
        destination: hundruFalls,
        pickupLat: 23.3441,
        pickupLng: 85.3096,
        vehicleType: 'auto',
        isRoundTrip: true,
        stayHours: 1,
      );

      expect(breakdown.isServiceable, isTrue);
      expect(breakdown.totalFare, greaterThan(800.0));
      expect(breakdown.unserviceableReason, isNull);
    });

    test('Pickup beyond 150 km triggers Out-of-Area rule (Aapki location door hai)', () {
      // Patna coordinates: (25.5941, 85.1376) ~280 km from Ranchi
      final breakdown = TourPricingService.calculateTourPackageFare(
        destination: hundruFalls,
        pickupLat: 25.5941,
        pickupLng: 85.1376,
        vehicleType: 'sedan',
        isRoundTrip: true,
        stayHours: 2,
      );

      expect(breakdown.isServiceable, isFalse);
      expect(breakdown.totalFare, equals(0.0));
      expect(breakdown.unserviceableReason, contains('location door hai'));
    });

    test('Extra waiting hours add separate line item to package fare', () {
      final standard1h = TourPricingService.calculateTourPackageFare(
        destination: hundruFalls,
        pickupLat: 23.3441,
        pickupLng: 85.3096,
        vehicleType: 'mini',
        isRoundTrip: true,
        stayHours: 1,
      );

      final with3hWait = TourPricingService.calculateTourPackageFare(
        destination: hundruFalls,
        pickupLat: 23.3441,
        pickupLng: 85.3096,
        vehicleType: 'mini',
        isRoundTrip: true,
        stayHours: 3, // 1h free + 2 extra hours * 120 = +240
      );

      expect(with3hWait.extraWaitingFare, equals(240.0));
      expect(with3hWait.totalFare, equals(standard1h.totalFare + 240.0));
    });
  });
}
