import 'package:flutter/material.dart';

/// Design tokens for District Car: Sal Forest + Marigold + Laterite Earth
/// Zero Blue / Indigo / Teal anywhere in the system.
class AppTokens {
  // Brand Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E7B4F), Color(0xFF0F5A38)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient marigoldGradient = LinearGradient(
    colors: [Color(0xFFF4A62A), Color(0xFFE98A15)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient darkForestGradient = LinearGradient(
    colors: [Color(0xFF1E2A22), Color(0xFF101A14)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroScrim = LinearGradient(
    colors: [Colors.transparent, Color.fromRGBO(16, 26, 20, 0.75)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Core Primaries (Sal Forest)
  static const Color primary = Color(0xFF1E7B4F);
  static const Color primaryDark = Color(0xFF0B3F28);
  static const Color primaryTint = Color(0xFFE8F4EC);

  // Accent (Marigold)
  static const Color marigold = Color(0xFFF4A62A);
  static const Color marigoldDark = Color(0xFFE98A15);
  static const Color marigoldTint = Color(0xFFFFF3DC);

  // Terracotta (Laterite Earth)
  static const Color terracotta = Color(0xFFC65A3A);

  // Neutrals (Warm Sal Wood & Stone)
  static const Color background = Color(0xFFFAF8F4);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surface2 = Color(0xFFF3F0E9);
  static const Color border = Color(0xFFECE7DD);
  static const Color ink = Color(0xFF1C1B18);
  static const Color secondaryText = Color(0xFF6A645A);
  static const Color secondary = secondaryText;
  static const Color textSecondary = secondaryText;
  static const Color hint = Color(0xFFA09A8F);
  static const Color textHint = hint;
  static const Color borderLight = border;
  static const LinearGradient fareDarkGradient = darkForestGradient;

  // Status & Utility
  static const Color success = Color(0xFF2E9E5B);
  static const Color error = Color(0xFFD64545);
  static const Color warning = Color(0xFFF4A62A);

  // Dark Surfaces (Forest Charcoal)
  static const Color darkSurface = Color(0xFF101A14);
  static const Color darkSurface2 = Color(0xFF1E2A22);

  // Spacing (4pt grid: 4, 8, 12, 16, 20, 24, 32)
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
  static const double radiusCards = 24.0;
  static const double radiusSheets = 28.0;

  // Touch & Heights
  static const double minTouchTarget = 48.0;
  static const double primaryButtonHeight = 58.0;

  // Layered Soft Shadows
  static const List<BoxShadow> softCardShadow = [
    BoxShadow(
      color: Color.fromRGBO(28, 27, 24, 0.06),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color.fromRGBO(28, 27, 24, 0.10),
      blurRadius: 28,
      offset: Offset(0, 10),
    ),
  ];

  static const List<BoxShadow> elevationGlow = [
    BoxShadow(
      color: Color.fromRGBO(30, 123, 79, 0.20),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];
}
