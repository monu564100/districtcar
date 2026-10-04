import 'package:flutter/material.dart';

/// District Car Premium Design System Colors
/// Matching modern transportation identity (Deep cobalt blue, soft lavender-periwinkle accents,
/// clean card surfaces, and subtle dark contrasting controls).
class AppColors {
  // Brand Primaries
  static const Color primary = Color(0xFF2538E8); // Deep Cobalt / Electric Royal Blue
  static const Color primaryDark = Color(0xFF1424B8);
  static const Color primaryLight = Color(0xFFEAEBFF); // Soft lavender-tinted container

  // Secondary & Accents
  static const Color accent = Color(0xFF6366F1); // Indigo Accent
  static const Color secondary = Color(0xFF3B82F6);

  // Backgrounds & Surfaces
  static const Color background = Color(0xFFF7F8FD); // Ultra-clean light tinted canvas
  static const Color surface = Colors.white;
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFF1F3F9); // Light pill & input fill

  // Pill & Nav Dock
  static const Color dockBackground = Color(0xFF1E212B); // Floating bottom navigation dock
  static const Color dockActivePill = Color(0xFF2538E8);
  static const Color dockInactiveIcon = Color(0xFF8E95A5);

  // Text Colors
  static const Color textPrimary = Color(0xFF111827); // Dark Charcoal
  static const Color textSecondary = Color(0xFF6B7280); // Cool Grey
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textLight = Colors.white;

  // Status & Utility
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);

  // Gradient definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3346F4), Color(0xFF1D28C4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFFEAEBFF), Color(0xFFF7F8FD)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardOverlayGradient = LinearGradient(
    colors: [Colors.black54, Colors.transparent],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );
}

/// Material 3 Typography & Theme Configuration
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        background: AppColors.background,
        error: AppColors.error,
        brightness: Brightness.light,
      ),
      fontFamily: 'SF Pro Display',
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
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
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
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
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
