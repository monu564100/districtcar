import 'package:flutter/material.dart';

/// District Car Premium Design System Colors
/// Theme Concept: "Sal forest + marigold + laterite earth"
/// Strictly NO BLUE / INDIGO / VIOLET / NAVY / TEAL ANYWHERE.
class AppColors {
  // Brand Primaries (Sal Forest)
  static const Color primary = Color(0xFF1E7B4F);
  static const Color primaryDark = Color(0xFF0B3F28);
  static const Color primaryLight = Color(0xFFE8F4EC); // Primary Tint

  // Accent & Warmth (Marigold & Laterite)
  static const Color accent = Color(0xFFF4A62A); // Marigold
  static const Color accentDark = Color(0xFFE98A15);
  static const Color accentLight = Color(0xFFFFF3DC);
  static const Color terracotta = Color(0xFFC65A3A); // Laterite Earth

  // Backgrounds & Warm Neutrals
  static const Color background = Color(0xFFFAF8F4);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFF3F0E9); // surface-2

  // Pill & Nav Dock
  static const Color dockBackground = Color(0xFF101A14); // Deep Forest Charcoal
  static const Color dockActivePill = Color(0xFF1E7B4F);
  static const Color dockInactiveIcon = Color(0xFFA09A8F);

  // Text Colors
  static const Color textPrimary = Color(0xFF1C1B18); // Ink
  static const Color textSecondary = Color(0xFF6A645A);
  static const Color textMuted = Color(0xFFA09A8F);
  static const Color textLight = Colors.white;

  // Status & Utility
  static const Color success = Color(0xFF2E9E5B);
  static const Color warning = Color(0xFFF4A62A);
  static const Color error = Color(0xFFD64545);
  static const Color border = Color(0xFFECE7DD);
  static const Color borderLight = Color(0xFFF3F0E9);

  // Gradients
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

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFFE8F4EC), Color(0xFFFAF8F4)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardOverlayGradient = LinearGradient(
    colors: [Color.fromRGBO(16, 26, 20, 0.75), Colors.transparent],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  static const LinearGradient darkForestGradient = LinearGradient(
    colors: [Color(0xFF1E2A22), Color(0xFF101A14)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Material 3 Typography & Complete Theme Configuration
/// Overrides seed and components so that NO blue or indigo default ever renders.
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryLight,
        onPrimaryContainer: AppColors.primaryDark,
        secondary: AppColors.accent,
        onSecondary: AppColors.textPrimary, // Ink on marigold
        secondaryContainer: AppColors.accentLight,
        onSecondaryContainer: AppColors.textPrimary,
        tertiary: AppColors.terracotta,
        onTertiary: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceSecondary,
        outline: AppColors.border,
        outlineVariant: AppColors.borderLight,
        shadow: Color.fromRGBO(28, 27, 24, 0.08),
      ),
      fontFamily: 'Plus Jakarta Sans',
      // Links & Text Selection
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: Color(0x331E7B4F),
        selectionHandleColor: AppColors.primary,
      ),
      // Progress indicators
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.primaryLight,
        circularTrackColor: AppColors.primaryLight,
      ),
      // Switches, Checkboxes, Radios
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return const Color(0xFFA09A8F);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primaryLight;
          return const Color(0xFFECE7DD);
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.textMuted;
        }),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(58),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
