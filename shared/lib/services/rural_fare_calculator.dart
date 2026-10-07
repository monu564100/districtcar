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
      // One-Way Trip to Village / Remote Area:
      // Base fare + (dist * perKmRate * 1.45 rural deadhead factor) + booking fee
      final ruralDistanceCharge = dist * category.perKmRate * 1.45;
      final total = category.baseFare + ruralDistanceCharge + category.bookingFee;
      return total < category.minimumFare ? category.minimumFare : total.roundToDouble();
    } else {
      // Round-Trip (Cheaper per km because return passenger is guaranteed!):
      // Total km = 2 * dist
      // Discounted perKmRate (0.75x) because vehicle has guaranteed revenue both ways
      final totalKm = dist * 2.0;
      final roundTripKmCharge = totalKm * (category.perKmRate * 0.75);
      
      // Stopping / Waiting charge:
      // First 1 hour is FREE
      final billableWaitHours = (stoppingHours - 1.0).clamp(0.0, 12.0);
      final waitingCost = billableWaitHours * 60.0; // ₹60 per extra hour

      final total = category.baseFare + roundTripKmCharge + waitingCost + category.bookingFee;
      return total < (category.minimumFare * 1.5) ? (category.minimumFare * 1.5) : total.roundToDouble();
    }
  }

  /// Estimated savings when choosing Round-Trip compared to two separate one-ways
  static double calculateSavings({
    required VehicleCategoryModel category,
    required double oneWayDistanceKm,
  }) {
    final twoOneWays = calculateFare(
          category: category,
          oneWayDistanceKm: oneWayDistanceKm,
          isRoundTrip: false,
        ) * 2;
    final roundTrip = calculateFare(
      category: category,
      oneWayDistanceKm: oneWayDistanceKm,
      isRoundTrip: true,
      stoppingHours: 1.0,
    );
    return (twoOneWays - roundTrip).clamp(0.0, 9999.0).roundToDouble();
  }
}
