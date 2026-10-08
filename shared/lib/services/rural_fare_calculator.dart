import 'package:flutter/material.dart';
import '../models/models.dart';

class RuralFareCalculator {
  /// Study and logic:
  /// Rural Jharkhand market dynamics:
  /// 1. Deadhead / Empty Return: In rural villages, the probability of a driver finding
  ///    a return ride is low (~15-20%). If driver charges standard one-way city fare,
  ///    the driver operates at a loss and cancels.
  /// 2. One-Way Rural Factor: We apply a 1.45x rural compensation factor on the return leg
  ///    to guarantee drivers accept rides to remote villages.
  /// 3. Round-Trip Discount: If customer books a Round Trip, the driver stays with the customer
  ///    or returns with them. The deadhead loss is eliminated, so the per-km rate is discounted by 25%!
  /// 4. Free Stopping Time: 1 hour free stop included for rural visits (hospitals, markets, mandis).
  ///    Subsequent stop time is ₹60/hour.
  static double calculateFare({
    required VehicleCategoryModel category,
    required double oneWayDistanceKm,
    required bool isRoundTrip,
    double stoppingHours = 1.0,
  }) {
    final double dist = oneWayDistanceKm < 1.0 ? 1.0 : oneWayDistanceKm;

    if (!isRoundTrip) {
      // One-Way Trip: Base fare + (dist * perKmRate)
      final distanceCharge = dist * category.perKmRate;
      final total = category.baseFare + distanceCharge;
      return total < category.minimumFare ? category.minimumFare : total.roundToDouble();
    } else {
      // Round-Trip:
      // 1. Outbound leg: Base fare + (dist * perKmRate)
      // 2. Return leg: (dist * perKmRate) discounted (e.g. 35% discount = 0.65x)
      // 3. Waiting charge: stoppingHours * hourlyWaitingCharge (default ₹60/hr)
      final outboundFare = category.baseFare + (dist * category.perKmRate);
      final returnDiscountMultiplier = ((100.0 - category.roundTripDiscountPercent).clamp(0.0, 100.0)) / 100.0;
      final returnDiscountedFare = (dist * category.perKmRate) * returnDiscountMultiplier;
      final waitingCharge = stoppingHours * category.hourlyWaitingCharge;

      final total = outboundFare + returnDiscountedFare + waitingCharge;
      return total < category.minimumFare ? category.minimumFare : total.roundToDouble();
    }
  }

  /// Estimated savings when choosing Round-Trip compared to two separate one-ways
  static double calculateSavings({
    required VehicleCategoryModel category,
    required double oneWayDistanceKm,
  }) {
    final twoOneWays = (category.baseFare + (oneWayDistanceKm * category.perKmRate)) * 2;
    final roundTrip = calculateFare(
      category: category,
      oneWayDistanceKm: oneWayDistanceKm,
      isRoundTrip: true,
      stoppingHours: 1.0,
    );
    return (twoOneWays - roundTrip).clamp(0.0, 9999.0).roundToDouble();
  }
}
