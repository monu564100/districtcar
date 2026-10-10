import 'package:flutter/material.dart';
import '../models/models.dart';

class RuralFareCalculator {
  /// User Cab Pricing Structure:
  /// Distance classification:
  /// - Short distance: Below 25 km
  /// - Long distance: Above 25 km (or >= 25 km)
  ///
  /// Rates per km:
  /// | Vehicle Type     | Short Distance   | Long Distance         |
  /// | Economy Mini Cab | ₹15/km (one-way) | ₹17.5/km (round trip) |
  /// | Auto             | ₹11/km           | ₹11/km                |
  /// | Comfort Sedan    | ₹23/km (one-way) | ₹25/km (round trip)   |
  /// | SUV              | ₹21/km           | ₹21/km                |
  ///
  /// Price Calculation:
  /// Round-trip: Price = Target Distance * 2 * Price per km + Extra Waiting Charge
  /// One-way:    Price = Target Distance * Price per km
  ///
  /// Free Waiting: 1 hour free included with round-trip. Additional waiting charged at ₹60/hour.

  static double getRatePerKm({
    required String categoryIdOrName,
    required double oneWayDistanceKm,
    required bool isRoundTrip,
  }) {
    final key = categoryIdOrName.toLowerCase();
    final bool isLongDistance = oneWayDistanceKm >= 25.0;

    if (key.contains('auto') || key.contains('rick')) {
      // Auto: ₹11/km short & long
      return 11.0;
    } else if (key.contains('sedan')) {
      // Comfort Sedan: ₹23/km short, ₹25/km long
      return isLongDistance ? 25.0 : 23.0;
    } else if (key.contains('suv') || key.contains('bolero')) {
      // SUV: ₹21/km short & long
      return 21.0;
    } else if (key.contains('bike')) {
      // Bike
      return 8.0;
    } else {
      // Economy Mini Cab (default 'car'): ₹15/km short, ₹17.5/km long
      return isLongDistance ? 17.5 : 15.0;
    }
  }

  static double calculateFare({
    required VehicleCategoryModel category,
    required double oneWayDistanceKm,
    required bool isRoundTrip,
    double stoppingHours = 1.0,
  }) {
    final double dist = oneWayDistanceKm < 1.0 ? 1.0 : oneWayDistanceKm;
    final double ratePerKm = getRatePerKm(
      categoryIdOrName: '${category.id} ${category.name} ${category.displayName}',
      oneWayDistanceKm: dist,
      isRoundTrip: isRoundTrip,
    );

    if (!isRoundTrip) {
      // One-way: Price = Target Distance * Price per km
      final total = dist * ratePerKm;
      return total < category.minimumFare ? category.minimumFare : total.roundToDouble();
    } else {
      // Round-trip: Price = Target Distance * 2 * Price per km
      final distanceFare = dist * 2.0 * ratePerKm;

      // 1 hour is 100% free. Any waiting hours beyond 1 hour are charged based on hourly rate
      final extraHours = (stoppingHours - 1.0).clamp(0.0, 48.0);
      final hourlyRate = category.hourlyWaitingCharge > 0 ? category.hourlyWaitingCharge : 60.0;
      final waitingFare = extraHours * hourlyRate;

      final total = distanceFare + waitingFare;
      return total < category.minimumFare ? category.minimumFare : total.roundToDouble();
    }
  }

  /// Estimated savings when choosing Round-Trip compared to two separate one-ways
  static double calculateSavings({
    required VehicleCategoryModel category,
    required double oneWayDistanceKm,
  }) {
    final shortRate = getRatePerKm(
      categoryIdOrName: '${category.id} ${category.name} ${category.displayName}',
      oneWayDistanceKm: oneWayDistanceKm,
      isRoundTrip: false,
    );
    final twoOneWays = (oneWayDistanceKm * shortRate) * 2.0;
    final roundTrip = calculateFare(
      category: category,
      oneWayDistanceKm: oneWayDistanceKm,
      isRoundTrip: true,
      stoppingHours: 1.0,
    );
    final diff = twoOneWays - roundTrip;
    return diff > 0 ? diff.roundToDouble() : 50.0;
  }
}
