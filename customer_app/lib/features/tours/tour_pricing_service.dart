import 'dart:math';
import 'package:district_car_shared/models/models.dart';

/// Predefined Major Jharkhand Hub Cities for Tour Starting Points
class TourHubCity {
  final String id;
  final String name;
  final String hindiName;
  final double latitude;
  final double longitude;

  const TourHubCity({
    required this.id,
    required this.name,
    required this.hindiName,
    required this.latitude,
    required this.longitude,
  });
}

class TourPricingBreakdown {
  final double basePackageFare;
  final double extraWaitingFare;
  final double nearbyStopsFare;
  final double driverAllowance;
  final double tollsAndTaxes;
  final double totalFare;
  final double perPersonFare;
  final double distanceKm;
  final int durationMinutes;
  final String durationText;
  final bool isServiceable;
  final String? unserviceableReason;
  final String hubCityName;
  final int stayHours;

  const TourPricingBreakdown({
    required this.basePackageFare,
    required this.extraWaitingFare,
    required this.nearbyStopsFare,
    required this.driverAllowance,
    required this.tollsAndTaxes,
    required this.totalFare,
    required this.perPersonFare,
    required this.distanceKm,
    required this.durationMinutes,
    required this.durationText,
    required this.isServiceable,
    this.unserviceableReason,
    required this.hubCityName,
    required this.stayHours,
  });
}

class TourPricingService {
  /// Maximum tour pickup radius from destination before requiring a hub city selection
  static const double kMaxTourServiceRadiusKm = 150.0;

  /// Average rural travel speed in Jharkhand hill and plateau routes (30-45 km/h range)
  static const double kAverageRuralSpeedKmh = 35.0;

  /// Top 5 Jharkhand Hub Cities
  static const List<TourHubCity> hubCities = [
    TourHubCity(
      id: 'ranchi',
      name: 'Ranchi',
      hindiName: 'राँची',
      latitude: 23.3441,
      longitude: 85.3096,
    ),
    TourHubCity(
      id: 'jamshedpur',
      name: 'Jamshedpur',
      hindiName: 'जमशेदपुर',
      latitude: 22.8046,
      longitude: 86.2029,
    ),
    TourHubCity(
      id: 'bokaro',
      name: 'Bokaro',
      hindiName: 'बोकारो',
      latitude: 23.6693,
      longitude: 86.1511,
    ),
    TourHubCity(
      id: 'dhanbad',
      name: 'Dhanbad',
      hindiName: 'धनबाद',
      latitude: 23.7957,
      longitude: 86.4304,
    ),
    TourHubCity(
      id: 'deoghar',
      name: 'Deoghar',
      hindiName: 'देवघर',
      latitude: 24.4826,
      longitude: 86.7001,
    ),
  ];

  /// Find the nearest hub city to given coordinates
  static TourHubCity findNearestHubCity(double lat, double lng) {
    TourHubCity closest = hubCities.first;
    double minDistance = double.infinity;

    for (final hub in hubCities) {
      final d = calculateRoadDistanceKm(lat, lng, hub.latitude, hub.longitude);
      if (d < minDistance) {
        minDistance = d;
        closest = hub;
      }
    }
    return closest;
  }

  /// Accurate Haversine Distance with rural Jharkhand terrain & road curve multiplier
  static double calculateRoadDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double p = 0.017453292519943295; // Pi / 180
    final double a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    final double crowFliesKm = 12742 * asin(sqrt(a));

    // Road winding multiplier for Chotanagpur plateau terrain
    return double.parse((crowFliesKm * 1.28).toStringAsFixed(1));
  }

  /// Calculates realistic rural travel duration (30-45 km/h verified)
  static int calculateRuralDurationMinutes(double distanceKm) {
    if (distanceKm <= 0) return 0;
    final hours = distanceKm / kAverageRuralSpeedKmh;
    return max(15, (hours * 60).round());
  }

  /// Formatted duration string e.g. "1 hr 15 mins"
  static String formatDurationText(int minutes) {
    if (minutes < 60) return '$minutes mins';
    final hrs = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '$hrs hr${hrs > 1 ? 's' : ''}';
    return '$hrs hr${hrs > 1 ? 's' : ''} $mins mins';
  }

  /// Evaluates whether the pickup is within the allowable tour booking service area
  static bool isWithinServiceArea(
    double pickupLat,
    double pickupLng,
    double destLat,
    double destLng, {
    double maxRadiusKm = kMaxTourServiceRadiusKm,
  }) {
    final distance = calculateRoadDistanceKm(pickupLat, pickupLng, destLat, destLng);
    return distance <= maxRadiusKm;
  }

  /// Package pricing calculation per destination per hub city with add-ons
  static TourPricingBreakdown calculateTourPackageFare({
    required PopularDestinationModel destination,
    required double pickupLat,
    required double pickupLng,
    required String vehicleType, // 'auto', 'mini', 'sedan', 'suv'
    required bool isRoundTrip,
    required int stayHours, // 1 free, 2, 3, 4, etc.
    int passengerCount = 1,
    List<Map<String, dynamic>> selectedAddonStops = const [],
    double? overrideDistanceKm,
  }) {
    // 1. Calculate one-way distance (fallback to destination.approxDistanceKm if <= 0)
    double distanceKm = overrideDistanceKm ??
        calculateRoadDistanceKm(
          pickupLat,
          pickupLng,
          destination.latitude,
          destination.longitude,
        );
    if (distanceKm <= 0.0) {
      distanceKm = destination.approxDistanceKm > 0 ? destination.approxDistanceKm : 45.0;
    }

    // 2. Geofence & Serviceability Check
    final isServiceable = distanceKm <= kMaxTourServiceRadiusKm;
    if (!isServiceable) {
      return TourPricingBreakdown(
        basePackageFare: 0,
        extraWaitingFare: 0,
        nearbyStopsFare: 0,
        driverAllowance: 0,
        tollsAndTaxes: 0,
        totalFare: 0,
        perPersonFare: 0,
        distanceKm: distanceKm,
        durationMinutes: calculateRuralDurationMinutes(distanceKm),
        durationText: formatDurationText(calculateRuralDurationMinutes(distanceKm)),
        isServiceable: false,
        unserviceableReason: 'Aapki location door hai (> 150 km)',
        hubCityName: findNearestHubCity(pickupLat, pickupLng).name,
        stayHours: stayHours,
      );
    }

    // 3. Base Package Pricing dynamically configured from Admin Panel (destination.startingFare)
    final adminPackageBase = destination.startingFare > 0 ? destination.startingFare : 1299.0;

    double baseRatePerKm;
    double minPackageFloor;
    double extraWaitingRatePerHour;

    switch (vehicleType.toLowerCase()) {
      case 'auto':
        baseRatePerKm = 13.0;
        minPackageFloor = (adminPackageBase * 0.70).roundToDouble();
        extraWaitingRatePerHour = 100.0;
        break;
      case 'mini':
        baseRatePerKm = 17.0;
        minPackageFloor = adminPackageBase;
        extraWaitingRatePerHour = 120.0;
        break;
      case 'sedan':
        baseRatePerKm = 21.0;
        minPackageFloor = (adminPackageBase * 1.30).roundToDouble();
        extraWaitingRatePerHour = 150.0;
        break;
      case 'suv':
      default:
        baseRatePerKm = 27.0;
        minPackageFloor = (adminPackageBase * 1.75).roundToDouble();
        extraWaitingRatePerHour = 200.0;
        break;
    }

    // Round trip distance multiplier (round trip is typically ~1.85x due to package discount)
    final tripDistance = isRoundTrip ? distanceKm * 2 : distanceKm;
    double baseFare = max(minPackageFloor, tripDistance * baseRatePerKm);

    // Round to clean nearest ₹10
    baseFare = (baseFare / 10).round() * 10.0;

    // 4. Extra Waiting hours (1st hour is free in round trip package)
    final extraHours = max(0, stayHours - 1);
    final extraWaitingFare = extraHours * extraWaitingRatePerHour;

    // 5. Add-on stops
    double nearbyStopsFare = 0.0;
    for (final stop in selectedAddonStops) {
      final extraFee = (stop['fare'] as num?)?.toDouble() ?? 300.0;
      nearbyStopsFare += extraFee;
    }

    // 6. Included allowances
    final driverAllowance = isRoundTrip ? 200.0 : 0.0; // Included in package total
    const tollsAndTaxes = 0.0; // All-inclusive guaranteed pricing

    final totalFare = baseFare + extraWaitingFare + nearbyStopsFare;
    final passengers = max(1, passengerCount);
    final perPersonFare = (totalFare / passengers).roundToDouble();

    final durationMins = calculateRuralDurationMinutes(distanceKm);

    return TourPricingBreakdown(
      basePackageFare: baseFare,
      extraWaitingFare: extraWaitingFare,
      nearbyStopsFare: nearbyStopsFare,
      driverAllowance: driverAllowance,
      tollsAndTaxes: tollsAndTaxes,
      totalFare: totalFare,
      perPersonFare: perPersonFare,
      distanceKm: distanceKm,
      durationMinutes: durationMins,
      durationText: formatDurationText(durationMins),
      isServiceable: true,
      hubCityName: findNearestHubCity(pickupLat, pickupLng).name,
      stayHours: stayHours,
    );
  }
}
