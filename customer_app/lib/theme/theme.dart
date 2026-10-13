import 'package:flutter/material.dart';

/// Design tokens for District Car
/// Inspired by top-tier mobility apps (Uber/Rapido/Ola) crafted for rural & district Jharkhand.
class AppTokens {
  // Brand Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6A5CFF), Color(0xFF3D2FD6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient fareDarkGradient = LinearGradient(
    colors: [Color(0xFF0B1020), Color(0xFF1B2347)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Core Colors
  static const Color primaryDark = Color(0xFF2A1FA8);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFE5484D);

  // Ink Typography Colors
  static const Color ink = Color(0xFF0B1020);
  static const Color textSecondary = Color(0xFF5B6478);
  static const Color secondary = Color(0xFF5B6478);
  static const Color textHint = Color(0xFF98A2B3);
  static const Color hint = Color(0xFF98A2B3);

  // Surfaces & Canvas
  static const Color background = Color(0xFFF6F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFF1F3F9);
  static const Color borderLight = Color(0xFFEEF0F6);

  // Dark Mode Tokens
  static const Color darkBackground = Color(0xFF0A0D1A);
  static const Color darkSurface = Color(0xFF141A2E);
  static const Color darkBorder = Color(0x14FFFFFF);

  // Spacing (4pt grid: 4, 8, 12, 16, 24, 32)
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;

  // Radii
  static const double radiusChips = 14.0;
  static const double radiusInputs = 16.0;
  static const double radiusButtons = 18.0;
  static const double radiusCards = 20.0;
  static const double radiusSheets = 28.0;

  // Touch & Heights
  static const double minTouchTarget = 48.0;
  static const double primaryButtonHeight = 58.0;

  // Shadows
  static const List<BoxShadow> softCardShadow = [
    BoxShadow(
      color: Color.fromRGBO(16, 24, 40, 0.04),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color.fromRGBO(16, 24, 40, 0.08),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> elevationGlow = [
    BoxShadow(
      color: Color.fromRGBO(106, 92, 255, 0.22),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];
}
