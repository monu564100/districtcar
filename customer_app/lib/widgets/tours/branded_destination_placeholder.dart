import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import 'tour_assets.dart';

/// Branded Destination Placeholder (Rule 0a)
/// Rendered when real destination photos are missing or loading.
/// Displays a stylized Jharkhand hill and waterfall illustration in
/// the Sal Forest + Marigold palette. NEVER shows an incorrect photo.
class BrandedDestinationPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? caption;

  const BrandedDestinationPlaceholder({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppTokens.surface2,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(
            kPlaceholderLandscapeBytes,
            fit: fit,
          ),
          // Subtle gradient overlay for readability
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Color.fromRGBO(16, 26, 20, 0.45),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          if (caption != null && caption!.isNotEmpty)
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTokens.darkSurface.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTokens.border.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.forest_rounded, size: 12, color: AppTokens.marigold),
                    const SizedBox(width: 5),
                    Text(
                      caption!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
