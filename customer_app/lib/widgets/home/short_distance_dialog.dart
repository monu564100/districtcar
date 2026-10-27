import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../services/haptic_service.dart';

/// Modal dialog shown when a customer attempts to book a ride with distance < 5 km.
/// As per District Car policy, minimum booking cap is 5 km.
class ShortDistanceDialog extends StatelessWidget {
  final double distanceKm;
  final double minCapKm;

  const ShortDistanceDialog({
    super.key,
    required this.distanceKm,
    this.minCapKm = 5.0,
  });

  static Future<void> show(
    BuildContext context, {
    required double distanceKm,
    double minCapKm = 5.0,
  }) async {
    HapticService.error();
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (BuildContext dialogContext) => ShortDistanceDialog(
        distanceKm: distanceKm,
        minCapKm: minCapKm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final maxDialogWidth = size.width > 420 ? 380.0 : size.width * 0.90;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: maxDialogWidth,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Beautiful 3D Header Illustration
              Stack(
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3F4F6),
                    ),
                    child: Image.asset(
                      'assets/images/unserviceable_area_3d.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFF1E293B),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.near_me_disabled_rounded,
                            size: 64,
                            color: Color(0xFFE2E8F0),
                          ),
                        );
                      },
                    ),
                  ),

                  // Soft Gradient scrim for readability
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.2),
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.85),
                            Colors.white,
                          ],
                          stops: const [0.0, 0.4, 0.85, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Category Badge at top-left
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.straighten_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'MIN CAP ${minCapKm.toStringAsFixed(0)} KM',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Close Button at top-right
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          HapticService.selection();
                          Navigator.of(context).pop();
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // 2. Content Body
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Distance pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFCA5A5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Current Route: ${distanceKm.toStringAsFixed(1)} KM',
                        style: const TextStyle(
                          color: Color(0xFFB91C1C),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Title
                    const Text(
                      'Trip Distance Is Too Short',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Explanation
                    Text(
                      'District Car caters to rural corridors and inter-district travel with a minimum booking cap of ${minCapKm.toStringAsFixed(0)} km.\n\nPlease expand your pickup or destination to at least ${minCapKm.toStringAsFixed(0)} km to confirm this booking.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info highlight card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTokens.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.savings_outlined,
                              size: 18,
                              color: AppTokens.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Tip: Save up to 35% by booking Round Trips for your full journey!',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Primary Button: Change Locations
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticService.selection();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTokens.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit_location_alt_rounded, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Change Locations',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Secondary dismiss button
                    TextButton(
                      onPressed: () {
                        HapticService.selection();
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: Colors.grey.shade600,
                      ),
                      child: const Text(
                        'I Understand',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
