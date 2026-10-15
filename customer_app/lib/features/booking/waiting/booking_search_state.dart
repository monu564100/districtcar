import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:district_car_shared/models/models.dart';
import '../../../../services/haptic_service.dart';

/// Sealed hierarchy for Booking Search State Machine
@immutable
sealed class BookingSearchState {
  final int elapsedSeconds;
  final double radiusKm;
  final int matchedDriversCount;
  final String statusHeadline;
  final String statusSubMessage;
  final int activeProgressStep; // 0: Request sent, 1: Drivers notified, 2: Waiting for accept, 3: Driver assigned

  const BookingSearchState({
    required this.elapsedSeconds,
    required this.radiusKm,
    required this.matchedDriversCount,
    required this.statusHeadline,
    required this.statusSubMessage,
    required this.activeProgressStep,
  });
}

/// 1. Initial / Immediate Search Phase (0–40s, 5 km radius)
class SearchingNearbyState extends BookingSearchState {
  const SearchingNearbyState({
    required super.elapsedSeconds,
    super.radiusKm = 5.0,
    super.matchedDriversCount = 0,
    super.statusHeadline = 'Aapke liye driver dhundh rahe hain…',
    super.statusSubMessage = 'Aas-paas ke drivers ko request bhej di gayi hai',
    super.activeProgressStep = 1,
  });
}

/// 2. First Expansion Phase (40–90s, 8 km radius)
class SearchExpandedState extends BookingSearchState {
  const SearchExpandedState({
    required super.elapsedSeconds,
    super.radiusKm = 8.0,
    super.matchedDriversCount = 0,
    super.statusHeadline = 'Thoda aur door tak dhundh rahe hain…',
    super.statusSubMessage = '8 km ke daayre mein drivers ko request bheji ja rahi hai',
    super.activeProgressStep = 2,
  });
}

/// 3. Wide Expansion Phase (90–150s, 12 km radius)
class SearchWideExpandedState extends BookingSearchState {
  const SearchWideExpandedState({
    required super.elapsedSeconds,
    super.radiusKm = 12.0,
    super.matchedDriversCount = 0,
    super.statusHeadline = 'Sabhi aas-paas ke drivers se sampark jaari…',
    super.statusSubMessage = 'Village Return Guarantee: aapki ride 100% accept hogi',
    super.activeProgressStep = 2,
  });
}

/// 4. Driver Found / Accepted State
class DriverFoundState extends BookingSearchState {
  final String driverId;
  final String driverName;
  final String? driverPhone;
  final String? driverPhotoUrl;
  final double rating;
  final String vehicleName;
  final String vehicleNumber;
  final String vehicleType;
  final String etaText;
  final String otp;

  const DriverFoundState({
    required super.elapsedSeconds,
    required this.driverId,
    required this.driverName,
    this.driverPhone,
    this.driverPhotoUrl,
    this.rating = 4.85,
    required this.vehicleName,
    required this.vehicleNumber,
    required this.vehicleType,
    this.etaText = '3 min away',
    this.otp = '4821',
  }) : super(
          radiusKm: 5.0,
          matchedDriversCount: 1,
          statusHeadline: 'Driver mil gaya!',
          statusSubMessage: 'Aapka driver pickup location par aa raha hai',
          activeProgressStep: 3,
        );
}

/// 5. No Driver Found State (Timeout > 7-8 min or backend no_driver_found)
class NoDriverFoundState extends BookingSearchState {
  final String failureReason;

  const NoDriverFoundState({
    required super.elapsedSeconds,
    this.failureReason = 'No driver immediate for immediate ride',
  }) : super(
          radiusKm: 12.0,
          matchedDriversCount: 0,
          statusHeadline: 'No driver immediate for immediate ride',
          statusSubMessage: '7-8 minute intezaar ke baad abhi koi driver uplabdh nahi ho paya. Kripya punah prayas karein.',
          activeProgressStep: 2,
        );
}

/// 6. Cancelled State
class CancelledSearchState extends BookingSearchState {
  final String cancelReason;

  const CancelledSearchState({
    required super.elapsedSeconds,
    required this.cancelReason,
  }) : super(
          radiusKm: 0.0,
          matchedDriversCount: 0,
          statusHeadline: 'Booking radd kardi gayi hai',
          statusSubMessage: 'Ride cancel ho chuki hai',
          activeProgressStep: 0,
        );
}

/// Controller that drives state machine transitions, timing, and events
class BookingSearchController extends ChangeNotifier {
  BookingSearchState _state;
  Timer? _tickerTimer;
  DateTime? _startedAt;
  final int maxTimeoutSeconds; // Default 450s (7.5 mins, 7-8 minute threshold)
  final void Function(String eventName, Map<String, dynamic> params)? onAnalyticsEvent;
  final VoidCallback? onTimeout;

  BookingSearchController({
    DateTime? initialStartedAt,
    this.maxTimeoutSeconds = 450,
    this.onAnalyticsEvent,
    this.onTimeout,
  }) : _state = const SearchingNearbyState(elapsedSeconds: 0) {
    _startedAt = initialStartedAt ?? DateTime.now();
    _startTimer();
    HapticService.requestSent();
    _logEvent('search_started', {'initial_radius_km': 5.0});
  }

  BookingSearchState get state => _state;

  void _startTimer() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_state is DriverFoundState ||
          _state is NoDriverFoundState ||
          _state is CancelledSearchState) {
        timer.cancel();
        return;
      }

      final elapsed = DateTime.now().difference(_startedAt!).inSeconds;

      if (elapsed >= maxTimeoutSeconds) {
        _transitionToNoDriver('No driver immediate for immediate ride');
        onTimeout?.call();
        return;
      }

      if (elapsed >= 90 && _state.radiusKm < 12.0) {
        HapticService.radiusExpanded();
        _logEvent('radius_expanded', {'radius_km': 12.0, 'elapsed_seconds': elapsed});
        _state = SearchWideExpandedState(
          elapsedSeconds: elapsed,
          matchedDriversCount: _state.matchedDriversCount,
        );
        notifyListeners();
      } else if (elapsed >= 40 && _state.radiusKm < 8.0) {
        HapticService.radiusExpanded();
        _logEvent('radius_expanded', {'radius_km': 8.0, 'elapsed_seconds': elapsed});
        _state = SearchExpandedState(
          elapsedSeconds: elapsed,
          matchedDriversCount: _state.matchedDriversCount,
        );
        notifyListeners();
      } else {
        // Keep elapsed seconds ticking every second
        if (_state is SearchingNearbyState) {
          _state = SearchingNearbyState(
            elapsedSeconds: elapsed,
            radiusKm: _state.radiusKm,
            matchedDriversCount: _state.matchedDriversCount,
          );
          notifyListeners();
        } else if (_state is SearchExpandedState) {
          _state = SearchExpandedState(
            elapsedSeconds: elapsed,
            radiusKm: _state.radiusKm,
            matchedDriversCount: _state.matchedDriversCount,
          );
          notifyListeners();
        } else if (_state is SearchWideExpandedState) {
          _state = SearchWideExpandedState(
            elapsedSeconds: elapsed,
            radiusKm: _state.radiusKm,
            matchedDriversCount: _state.matchedDriversCount,
          );
          notifyListeners();
        }
      }
    });
  }

  /// Ingest raw backend events (from Firestore or BookingModel stream)
  void updateFromBackend({
    required String? status,
    required String? driverId,
    required Map<String, dynamic> rawData,
  }) {
    if (_state is CancelledSearchState) return;

    // Check Driver Accepted
    if (driverId != null && driverId.isNotEmpty && status == 'confirmed') {
      if (_state is! DriverFoundState) {
        final elapsed = DateTime.now().difference(_startedAt!).inSeconds;
        HapticService.driverFound();
        _logEvent('driver_found', {
          'seconds': elapsed,
          'driver_id': driverId,
        });

        final driverName = rawData['driverName'] as String? ?? 'District Partner Driver';
        final driverPhone = rawData['driverPhone'] as String?;
        final driverPhoto = rawData['driverPhoto'] as String?;
        final rating = (rawData['driverRating'] as num?)?.toDouble() ?? 4.9;
        final vehicleName = rawData['vehicleModel'] as String? ?? 'Maruti Suzuki Dzire';
        final vehicleNumber = rawData['vehicleNumber'] as String? ?? 'JH 01 DD 4821';
        final vehicleType = rawData['vehicleType'] as String? ?? 'Prime Sedan';
        final otp = rawData['otp'] as String? ?? '4821';

        _tickerTimer?.cancel();
        _state = DriverFoundState(
          elapsedSeconds: elapsed,
          driverId: driverId,
          driverName: driverName,
          driverPhone: driverPhone,
          driverPhotoUrl: driverPhoto,
          rating: rating,
          vehicleName: vehicleName,
          vehicleNumber: vehicleNumber,
          vehicleType: vehicleType,
          etaText: '3 min away',
          otp: otp,
        );
        notifyListeners();
      }
      return;
    }

    // Check No Driver / Closed
    if (status == 'no_driver_found' || status == 'expired') {
      if (_state is! NoDriverFoundState) {
        _transitionToNoDriver(rawData['closedReason'] as String? ?? 'No nearby drivers available');
      }
      return;
    }

    // Drivers Notified count update
    final int matchedCount = (rawData['matchedDriversCount'] as num?)?.toInt() ?? 0;
    if (matchedCount > 0 && matchedCount != _state.matchedDriversCount) {
      if (_state is SearchingNearbyState) {
        _state = SearchingNearbyState(
          elapsedSeconds: _state.elapsedSeconds,
          radiusKm: _state.radiusKm,
          matchedDriversCount: matchedCount,
        );
        notifyListeners();
      } else if (_state is SearchExpandedState) {
        _state = SearchExpandedState(
          elapsedSeconds: _state.elapsedSeconds,
          radiusKm: _state.radiusKm,
          matchedDriversCount: matchedCount,
        );
        notifyListeners();
      } else if (_state is SearchWideExpandedState) {
        _state = SearchWideExpandedState(
          elapsedSeconds: _state.elapsedSeconds,
          radiusKm: _state.radiusKm,
          matchedDriversCount: matchedCount,
        );
        notifyListeners();
      }
    }
  }

  void _transitionToNoDriver(String reason) {
    _tickerTimer?.cancel();
    final elapsed = DateTime.now().difference(_startedAt!).inSeconds;
    HapticService.noDriverFound();
    _logEvent('no_driver_found', {
      'seconds': elapsed,
      'reason': reason,
    });
    _state = NoDriverFoundState(
      elapsedSeconds: elapsed,
      failureReason: reason,
    );
    notifyListeners();
  }

  /// User confirms cancellation
  void cancelSearch(String reason) {
    _tickerTimer?.cancel();
    final elapsed = DateTime.now().difference(_startedAt!).inSeconds;
    HapticService.cancelConfirmed();
    _logEvent('cancel_confirmed', {
      'reason': reason,
      'seconds_waited': elapsed,
    });
    _state = CancelledSearchState(
      elapsedSeconds: elapsed,
      cancelReason: reason,
    );
    notifyListeners();
  }

  /// Re-try search
  void retry() {
    _tickerTimer?.cancel();
    _startedAt = DateTime.now();
    _state = const SearchingNearbyState(elapsedSeconds: 0);
    _startTimer();
    HapticService.requestSent();
    _logEvent('retry_tapped', {'radius_km': 5.0});
    notifyListeners();
  }

  void _logEvent(String name, Map<String, dynamic> params) {
    if (onAnalyticsEvent != null) {
      onAnalyticsEvent!(name, params);
    }
    debugPrint('[SEARCH_ANALYTICS] $name: $params');
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
  }
}
