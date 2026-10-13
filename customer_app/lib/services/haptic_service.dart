import 'package:flutter/services.dart';

/// Central Haptic & Vibration Service for District Car
/// Provides tactile micro-feedback calibrated for low-end to high-end devices.
class HapticService {
  static bool isEnabled = true;

  /// Vehicle card select → light tick
  static void selection() {
    if (!isEnabled) return;
    HapticFeedback.selectionClick();
  }

  /// Swap pickup/drop → light impact
  static void swap() {
    if (!isEnabled) return;
    HapticFeedback.lightImpact();
  }

  /// Toggle round trip or switch option
  static void toggle({required bool value}) {
    if (!isEnabled) return;
    if (value) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  /// Date/time/passenger change
  static void stepChange() {
    if (!isEnabled) return;
    HapticFeedback.selectionClick();
  }

  /// Place picked from suggestions / chip tapped
  static void placePicked() {
    if (!isEnabled) return;
    HapticFeedback.lightImpact();
  }

  /// Book button press-down
  static void buttonPress() {
    if (!isEnabled) return;
    HapticFeedback.lightImpact();
  }

  /// Booking confirmed success pattern
  static void bookingConfirmed() {
    if (!isEnabled) return;
    HapticFeedback.heavyImpact();
  }

  /// Error / out-of-service area / validation fail
  static void error() {
    if (!isEnabled) return;
    HapticFeedback.heavyImpact();
  }
}
