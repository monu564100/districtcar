import 'dart:math';
import '../models/models.dart';

/// Dynamic District Car Pricing Rules
/// Stored in Firestore doc: `remote_configs/pricing_rules`
/// Fully customizable from Admin Web
class DistrictCarPricingRules {
  final double minDistanceCapKm; // Default 5.0 km
  final double shortTripMaxDistanceKm; // Default 25.0 km
  final double shortTripSurgePercent; // Default 10.0 %
  final double shortTripCommissionPercent; // Default 18.0 %
  final double longTripCommissionPercent; // Default 10.0 %
  final double shortTripOneWayCompensationPercent; // Default 20.0 %
  final double longTripOneWayCompensationPercent; // Default 40.0 %
  final double roundTripDiscountPercent; // Default 35.0 %
  final bool adminSurgeEnabled; // Default false (Admin Web toggle)
  final double adminSurgePercent; // Default 8.0 %

  const DistrictCarPricingRules({
    this.minDistanceCapKm = 5.0,
    this.shortTripMaxDistanceKm = 25.0,
    this.shortTripSurgePercent = 10.0,
    this.shortTripCommissionPercent = 18.0,
    this.longTripCommissionPercent = 10.0,
    this.shortTripOneWayCompensationPercent = 20.0,
    this.longTripOneWayCompensationPercent = 40.0,
    this.roundTripDiscountPercent = 35.0,
    this.adminSurgeEnabled = false,
    this.adminSurgePercent = 8.0,
  });

  Map<String, dynamic> toMap() => {
    'minDistanceCapKm': minDistanceCapKm,
    'shortTripMaxDistanceKm': shortTripMaxDistanceKm,
    'shortTripSurgePercent': shortTripSurgePercent,
    'shortTripCommissionPercent': shortTripCommissionPercent,
    'longTripCommissionPercent': longTripCommissionPercent,
    'shortTripOneWayCompensationPercent': shortTripOneWayCompensationPercent,
    'longTripOneWayCompensationPercent': longTripOneWayCompensationPercent,
    'roundTripDiscountPercent': roundTripDiscountPercent,
    'adminSurgeEnabled': adminSurgeEnabled,
    'adminSurgePercent': adminSurgePercent,
  };

  factory DistrictCarPricingRules.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const DistrictCarPricingRules();
    return DistrictCarPricingRules(
      minDistanceCapKm: (map['minDistanceCapKm'] as num?)?.toDouble() ?? 5.0,
      shortTripMaxDistanceKm: (map['shortTripMaxDistanceKm'] as num?)?.toDouble() ?? 25.0,
      shortTripSurgePercent: (map['shortTripSurgePercent'] as num?)?.toDouble() ?? 10.0,
      shortTripCommissionPercent: (map['shortTripCommissionPercent'] as num?)?.toDouble() ?? 18.0,
      longTripCommissionPercent: (map['longTripCommissionPercent'] as num?)?.toDouble() ?? 10.0,
      shortTripOneWayCompensationPercent: (map['shortTripOneWayCompensationPercent'] as num?)?.toDouble() ?? 20.0,
      longTripOneWayCompensationPercent: (map['longTripOneWayCompensationPercent'] as num?)?.toDouble() ?? 40.0,
      roundTripDiscountPercent: (map['roundTripDiscountPercent'] as num?)?.toDouble() ?? 35.0,
      adminSurgeEnabled: map['adminSurgeEnabled'] == true,
      adminSurgePercent: (map['adminSurgePercent'] as num?)?.toDouble() ?? 8.0,
    );
  }
}

/// Complete Fare Breakdown Result
class DistrictCarFareBreakdown {
  final double finalFare;
  final double baseDistanceCost;
  final double oneWayCompensation;
  final double roundTripDiscount;
  final double shortTripSurge;
  final double adminSurge;
  final double waitingCharge;
  final double platformCommission;
  final double platformCommissionPercent;
  final double driverNetEarnings;
  final bool isShortTrip;
  final bool isBelowMinCap;
  final double minDistanceCapKm;
  final String? suggestionMessage;

  const DistrictCarFareBreakdown({
    required this.finalFare,
    required this.baseDistanceCost,
    required this.oneWayCompensation,
    required this.roundTripDiscount,
    required this.shortTripSurge,
    required this.adminSurge,
    required this.waitingCharge,
    required this.platformCommission,
    required this.platformCommissionPercent,
    required this.driverNetEarnings,
    required this.isShortTrip,
    required this.isBelowMinCap,
    required this.minDistanceCapKm,
    this.suggestionMessage,
  });
}

class RuralFareCalculator {
  /// Global active rules cached in memory (updated dynamically from Firestore)
  static DistrictCarPricingRules currentRules = const DistrictCarPricingRules();

  /// Default per-km rate lookup by vehicle category
  static double getRatePerKm({
    required String categoryIdOrName,
    required double oneWayDistanceKm,
    required bool isRoundTrip,
  }) {
    final key = categoryIdOrName.toLowerCase();
    final bool isLongDistance = oneWayDistanceKm >= 25.0;

    if (key.contains('auto') || key.contains('rick')) {
      // Auto: ₹11/km
      return 11.0;
    } else if (key.contains('sedan')) {
      // Comfort Sedan: ₹23/km (one-way), ₹25/km (long)
      return isLongDistance ? 25.0 : 23.0;
    } else if (key.contains('suv') || key.contains('bolero')) {
      // SUV: ₹21/km
      return 21.0;
    } else if (key.contains('bike')) {
      // Bike: ₹8/km
      return 8.0;
    } else {
      // Economy Mini Cab (default 'car'): ₹15/km
      return 15.0;
    }
  }

  /// Full dynamic DistrictCar pricing calculation engine
  static DistrictCarFareBreakdown calculateDetailedFare({
    required VehicleCategoryModel category,
    required double oneWayDistanceKm,
    required bool isRoundTrip,
    double stoppingHours = 1.0,
    DistrictCarPricingRules? rules,
  }) {
    final r = rules ?? currentRules;
    final double dist = oneWayDistanceKm < 0.1 ? 0.1 : oneWayDistanceKm;

    // 1. Minimum cap check: rides below minDistanceCapKm (default 5.0 km) cannot be booked
    final bool isBelowMinCap = dist < r.minDistanceCapKm;

    // 2. Short Trip vs Long Trip classification
    final bool isShortTrip = dist <= r.shortTripMaxDistanceKm;

    // 3. Base Per-KM Rate
    final double ratePerKm = category.perKmRate > 0.0
        ? category.perKmRate
        : getRatePerKm(
            categoryIdOrName: '${category.id} ${category.name} ${category.displayName}',
            oneWayDistanceKm: dist,
            isRoundTrip: false,
          );

    final double baseFee = category.baseFare > 0.0 ? category.baseFare : 0.0;

    // 4. If Round-Trip:
    // User Specification: "when customer click round trip it should be double the price of one way and then off 35% on it this is round trip make this in customer ."
    if (isRoundTrip) {
      // Step A: Calculate full one-way fare for this distance & vehicle category
      final oneWayBreakdown = calculateDetailedFare(
        category: category,
        oneWayDistanceKm: dist,
        isRoundTrip: false,
        stoppingHours: 0.0,
        rules: r,
      );

      final double oneWayFare = oneWayBreakdown.finalFare;

      // Step B: Double the price of one way
      final double doubleOfOneWay = oneWayFare * 2.0;

      // Step C: 35% discount applied on the doubled one-way price
      final double discountPct = r.roundTripDiscountPercent / 100.0;
      final double roundTripDiscount = (doubleOfOneWay * discountPct).roundToDouble();
      final double baseRoundTripFare = doubleOfOneWay - roundTripDiscount;

      // Step D: Waiting Charges (1 hour free; extra hours billed at category waiting charge)
      double waitingCharge = 0.0;
      final double extraHours = (stoppingHours - 1.0).clamp(0.0, 48.0);
      final double hourlyRate = category.hourlyWaitingCharge > 0 ? category.hourlyWaitingCharge : 60.0;
      waitingCharge = (extraHours * hourlyRate).roundToDouble();

      // Step E: Final Fare guaranteed to be at least category.minimumFare
      final double computedFare = baseRoundTripFare + waitingCharge;
      final double finalFare = max(category.minimumFare, computedFare).roundToDouble();

      // Step F: Platform Commission
      double commPercent = isShortTrip ? r.shortTripCommissionPercent : r.longTripCommissionPercent;
      if (r.adminSurgeEnabled) {
        commPercent += r.adminSurgePercent;
      }

      final double platformCommission = (finalFare * (commPercent / 100.0)).roundToDouble();
      final double driverNetEarnings = max(0.0, finalFare - platformCommission).roundToDouble();

      return DistrictCarFareBreakdown(
        finalFare: finalFare,
        baseDistanceCost: doubleOfOneWay,
        oneWayCompensation: 0.0,
        roundTripDiscount: roundTripDiscount,
        shortTripSurge: (oneWayBreakdown.shortTripSurge * 2.0).roundToDouble(),
        adminSurge: (oneWayBreakdown.adminSurge * 2.0).roundToDouble(),
        waitingCharge: waitingCharge,
        platformCommission: platformCommission,
        platformCommissionPercent: commPercent,
        driverNetEarnings: driverNetEarnings,
        isShortTrip: isShortTrip,
        isBelowMinCap: isBelowMinCap,
        minDistanceCapKm: r.minDistanceCapKm,
        suggestionMessage: null,
      );
    }

    // --- ONE-WAY CALCULATION ---
    final double rawDistanceCost = baseFee + (dist * ratePerKm);

    double oneWayCompensation = 0.0;
    String? suggestionMessage;

    if (isShortTrip) {
      // Short trip one-way: +20% driver compensation
      final double compPct = r.shortTripOneWayCompensationPercent / 100.0;
      oneWayCompensation = rawDistanceCost * compPct;
      suggestionMessage = 'Save 35% on return fare by switching to Round Trip!';
    } else {
      // Long trip one-way: +40% driver compensation
      final double compPct = r.longTripOneWayCompensationPercent / 100.0;
      oneWayCompensation = rawDistanceCost * compPct;
      suggestionMessage = 'Tip: Turn on Round Trip to save 35% on return travel!';
    }

    double intermediateCost = rawDistanceCost + oneWayCompensation;

    // 5. Short Trip Surge: 10% hike applicable on 5-25 km trips
    double shortTripSurge = 0.0;
    if (isShortTrip && !isBelowMinCap) {
      final double surgePct = r.shortTripSurgePercent / 100.0;
      shortTripSurge = intermediateCost * surgePct;
    }

    // 6. Admin Surge Fee (Dynamic toggle from admin_web: +8% platform fee)
    double adminSurge = 0.0;
    if (r.adminSurgeEnabled) {
      final double adminSurgePct = r.adminSurgePercent / 100.0;
      adminSurge = (intermediateCost + shortTripSurge) * adminSurgePct;
    }

    // 7. Total Gross Fare before minimum floor
    double computedFare = intermediateCost + shortTripSurge + adminSurge;
    final double finalFare = max(category.minimumFare, computedFare).roundToDouble();

    // 8. Platform Commission Calculation
    double commPercent = isShortTrip ? r.shortTripCommissionPercent : r.longTripCommissionPercent;
    if (r.adminSurgeEnabled) {
      commPercent += r.adminSurgePercent;
    }

    final double platformCommission = (finalFare * (commPercent / 100.0)).roundToDouble();
    final double driverNetEarnings = max(0.0, finalFare - platformCommission).roundToDouble();

    return DistrictCarFareBreakdown(
      finalFare: finalFare,
      baseDistanceCost: rawDistanceCost.roundToDouble(),
      oneWayCompensation: oneWayCompensation.roundToDouble(),
      roundTripDiscount: 0.0,
      shortTripSurge: shortTripSurge.roundToDouble(),
      adminSurge: adminSurge.roundToDouble(),
      waitingCharge: 0.0,
      platformCommission: platformCommission,
      platformCommissionPercent: commPercent,
      driverNetEarnings: driverNetEarnings,
      isShortTrip: isShortTrip,
      isBelowMinCap: isBelowMinCap,
      minDistanceCapKm: r.minDistanceCapKm,
      suggestionMessage: suggestionMessage,
    );
  }

  /// Backward-compatible wrapper returning double finalFare
  static double calculateFare({
    required VehicleCategoryModel category,
    required double oneWayDistanceKm,
    required bool isRoundTrip,
    double stoppingHours = 1.0,
    DistrictCarPricingRules? rules,
  }) {
    final breakdown = calculateDetailedFare(
      category: category,
      oneWayDistanceKm: oneWayDistanceKm,
      isRoundTrip: isRoundTrip,
      stoppingHours: stoppingHours,
      rules: rules,
    );
    return breakdown.finalFare;
  }

  /// Estimated savings when choosing Round-Trip compared to two separate one-ways
  static double calculateSavings({
    required VehicleCategoryModel category,
    required double oneWayDistanceKm,
    DistrictCarPricingRules? rules,
  }) {
    final oneWayFare = calculateFare(
      category: category,
      oneWayDistanceKm: oneWayDistanceKm,
      isRoundTrip: false,
      rules: rules,
    );
    final twoOneWays = oneWayFare * 2.0;

    final roundTripFare = calculateFare(
      category: category,
      oneWayDistanceKm: oneWayDistanceKm,
      isRoundTrip: true,
      stoppingHours: 1.0,
      rules: rules,
    );
    final diff = twoOneWays - roundTripFare;
    return diff > 0 ? diff.roundToDouble() : 50.0;
  }
}
