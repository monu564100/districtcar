import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../services/haptic_service.dart';

class GuestSignInPopupDialog extends StatelessWidget {
  const GuestSignInPopupDialog({super.key});

  static Future<void> show(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (BuildContext dialogContext) => const GuestSignInPopupDialog(),
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
              // Top Hero Image Banner with Close Icon
              Stack(
                children: [
                  // High Quality Illustration
                  SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: Image.asset(
                      'assets/images/onboarding_welcome_illustration.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: const BoxDecoration(
                            gradient: AppTokens.primaryGradient,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.directions_car_rounded,
                              size: 72,
                              color: Colors.white70,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Subtle gradient overlay for text readability & smooth transition
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.35),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.2),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Top Pill Badge
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTokens.marigold,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Jharkhand Ride Partner',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Circular Cancel / Close Button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.50),
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          HapticService.selection();
                          Navigator.of(context).pop();
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
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

              // Content Body
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Title
                    const Text(
                      'Welcome to District Car',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTokens.ink,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Sign in to book instant rides, connect with verified local drivers, and travel anywhere with fixed transparent fares.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTokens.secondaryText,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Feature highlights
                    _buildFeatureRow(
                      icon: Icons.flash_on_rounded,
                      color: AppTokens.marigold,
                      title: 'Instant Booking',
                      subtitle: 'Auto, Mini, Sedan & SUV across all blocks',
                    ),
                    const SizedBox(height: 8),
                    _buildFeatureRow(
                      icon: Icons.verified_user_rounded,
                      color: AppTokens.primary,
                      title: 'Verified Drivers & SOS',
                      subtitle: 'Full KYC verified & 24/7 travel safety',
                    ),
                    const SizedBox(height: 8),
                    _buildFeatureRow(
                      icon: Icons.payments_rounded,
                      color: const Color(0xFF10B981),
                      title: 'Zero Surge Pricing',
                      subtitle: 'Pay directly via Cash or UPI at destination',
                    ),
                    const SizedBox(height: 18),

                    // Sign In / Register Action Button
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: AppTokens.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppTokens.primaryDark.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            HapticService.selection();
                            Navigator.of(context).pop();
                            context.push('/login');
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.login_rounded,
                                  color: Colors.white,
                                  size: 19,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Sign In / Register',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Maybe Later / Cancel Button (Non-mandatory)
                    Center(
                      child: TextButton(
                        onPressed: () {
                          HapticService.selection();
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          foregroundColor: AppTokens.secondaryText,
                        ),
                        child: const Text(
                          'Maybe Later, Explore as Guest',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppTokens.secondaryText,
                          ),
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

  Widget _buildFeatureRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppTokens.ink,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTokens.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
