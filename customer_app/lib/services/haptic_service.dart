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

  /// Booking confirmed or sign-in success pattern
  static void success() {
    if (!isEnabled) return;
    HapticFeedback.mediumImpact();
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

  /// Screen enters (request sent) → lightImpact once
  static void requestSent() {
    if (!isEnabled) return;
    HapticFeedback.lightImpact();
  }

  /// Radius expands → selectionClick
  static void radiusExpanded() {
    if (!isEnabled) return;
    HapticFeedback.selectionClick();
  }

  /// Each progress segment completes → selectionClick
  static void progressSegmentCompleted() {
    if (!isEnabled) return;
    HapticFeedback.selectionClick();
  }

  /// DRIVER FOUND → success pattern [0, 30, 60, 30, 60, 80] ms
  static Future<void> driverFound() async {
    if (!isEnabled) return;
    try {
      HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 60));
      HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 60));
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Driver arrived → strong double pulse [0, 80, 100, 80]
  static Future<void> driverArrived() async {
    if (!isEnabled) return;
    try {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// NO DRIVER FOUND → heavyImpact + [0, 60, 40, 60]
  static Future<void> noDriverFound() async {
    if (!isEnabled) return;
    try {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 60));
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Cancel confirmed → mediumImpact
  static void cancelConfirmed() {
    if (!isEnabled) return;
    HapticFeedback.mediumImpact();
  }

  // Standard aliases
  static void selectionClick() {
    if (!isEnabled) return;
    HapticFeedback.selectionClick();
  }

  static void lightImpact() {
    if (!isEnabled) return;
    HapticFeedback.lightImpact();
  }

  static void mediumImpact() {
    if (!isEnabled) return;
    HapticFeedback.mediumImpact();
  }

  static void heavyImpact() {
    if (!isEnabled) return;
    HapticFeedback.heavyImpact();
  }
}
