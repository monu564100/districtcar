import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../services/haptic_service.dart';

/// Modal dialog shown when a customer attempts to book a Long Trip (> 25 km) One-Way ride,
/// prompting them with the option to switch to a Round-Trip to save 35%.
class RoundTripSuggestionDialog extends StatelessWidget {
  final double distanceKm;
  final double oneWayFare;
  final double roundTripFare;
  final double savingsAmount;

  const RoundTripSuggestionDialog({
    super.key,
    required this.distanceKm,
    required this.oneWayFare,
    required this.roundTripFare,
    required this.savingsAmount,
  });

  /// Shows the dialog. Returns `true` if customer opted to switch to Round Trip,
  /// `false` if customer chose to continue with One-Way, or `null` if dismissed.
  static Future<bool?> show(
    BuildContext context, {
    required double distanceKm,
    required double oneWayFare,
    required double roundTripFare,
    required double savingsAmount,
  }) async {
    HapticService.selection();
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (BuildContext dialogContext) => RoundTripSuggestionDialog(
        distanceKm: distanceKm,
        oneWayFare: oneWayFare,
        roundTripFare: roundTripFare,
        savingsAmount: savingsAmount,
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
              // 1. Header Banner with 3D promo asset
              Stack(
                children: [
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F172A),
                    ),
                    child: Image.asset(
                      'assets/images/promo_round_trip.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF0F5132), Color(0xFF198754)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.sync_alt_rounded,
                            size: 56,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),

                  // Soft Gradient scrim
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.25),
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.9),
                            Colors.white,
                          ],
                          stops: const [0.0, 0.45, 0.88, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Discount Badge
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTokens.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.discount_rounded, size: 13, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'SAVE 35% DISCOUNT',
                            style: TextStyle(
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

                  // Close Button
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
                          Navigator.of(context).pop(false);
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Icon(Icons.close_rounded, size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // 2. Body Details
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Switch to Round Trip & Save?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Long trip one-way journeys (${distanceKm.toStringAsFixed(1)} km) include a 40% driver return compensation fee.\n\nTurn on Round Trip now to get double the one-way price with an instant 35% discount + 1 hr free waiting!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Fare comparison card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'One-Way (+40% driver comp.):',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '₹${oneWayFare.toInt()}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16, thickness: 1, color: Color(0xFFE2E8F0)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, size: 15, color: Color(0xFF16A34A)),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Round Trip (2x with 35% OFF):',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF16A34A),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '₹${roundTripFare.toInt()}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action 1: Switch to Round Trip
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticService.selection();
                          Navigator.of(context).pop(true);
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
                            Icon(Icons.swap_calls_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Switch to Round Trip (Save 35%)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Action 2: Continue One-Way
                    TextButton(
                      onPressed: () {
                        HapticService.selection();
                        Navigator.of(context).pop(false);
                      },
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: Colors.grey.shade600,
                      ),
                      child: const Text(
                        'Continue with One-Way',
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
