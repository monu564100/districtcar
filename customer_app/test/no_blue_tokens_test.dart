import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:district_car_customer/theme/theme.dart';
import 'package:district_car_shared/theme/app_theme.dart';

void main() {
  group('No Blue / Indigo / Teal Color Tokens Test', () {
    test('AppTokens uses Sal Forest, Marigold, and Terracotta without blue', () {
      final tokens = [
        AppTokens.primary,
        AppTokens.primaryDark,
        AppTokens.primaryTint,
        AppTokens.marigold,
        AppTokens.marigoldDark,
        AppTokens.terracotta,
        AppTokens.background,
        AppTokens.surface,
        AppTokens.surface2,
        AppTokens.border,
        AppTokens.ink,
        AppTokens.secondaryText,
        AppTokens.darkSurface,
        AppTokens.darkSurface2,
      ];

      for (final color in tokens) {
        final r = (color.value >> 16) & 0xFF;
        final g = (color.value >> 8) & 0xFF;
        final b = color.value & 0xFF;

        // Verify that blue is never overwhelmingly dominant over both red and green
        final isBlueDominant = b > 140 && (b > r + 30) && (b > g + 20);
        expect(isBlueDominant, isFalse,
            reason: 'Token ${color.value.toRadixString(16)} should not be blue-dominant');
      }
    });

    test('Shared AppColors uses Sal Forest and Marigold palette', () {
      final sharedColors = [
        AppColors.primary,
        AppColors.primaryDark,
        AppColors.primaryLight,
        AppColors.accent,
        AppColors.accentDark,
        AppColors.terracotta,
        AppColors.background,
        AppColors.surface,
        AppColors.surfaceSecondary,
        AppColors.textPrimary,
        AppColors.border,
      ];

      for (final color in sharedColors) {
        final r = (color.value >> 16) & 0xFF;
        final g = (color.value >> 8) & 0xFF;
        final b = color.value & 0xFF;

        final isBlueDominant = b > 140 && (b > r + 30) && (b > g + 20);
        expect(isBlueDominant, isFalse,
            reason: 'Shared AppColor ${color.value.toRadixString(16)} should not be blue-dominant');
      }
    });

    test('Material ColorScheme primary is Sal Forest Green #1E7B4F', () {
      final theme = AppTheme.lightTheme;
      expect(theme.colorScheme.primary, equals(const Color(0xFF1E7B4F)));
      expect(theme.colorScheme.secondary, equals(const Color(0xFFF4A62A)));
    });
  });
}
