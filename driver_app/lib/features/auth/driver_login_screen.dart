import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import '../../services/driver_service.dart';

class DriverLoginScreen extends ConsumerStatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  ConsumerState<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends ConsumerState<DriverLoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  void _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await ref.read(driverServiceProvider).signInWithGoogle();
      final isOnboarded = await ref.read(driverServiceProvider).isDriverOnboarded(user.uid);
      final prefs = await SharedPreferences.getInstance();
      final hasConsent = prefs.getBool('driver_consent_given') ?? false;

      if (mounted) {
        if (!isOnboarded) {
          context.go('/driver-onboarding');
        } else if (!hasConsent) {
          context.go('/driver-consent');
        } else {
          context.go('/driver-home');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Google Sign-In notice: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // TOP SECTION: Full-width Hero Illustration / Graphic
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/login_hero_illustration.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF065F46),
                      child: const Center(
                        child: Icon(Icons.directions_car, size: 80, color: Colors.white54),
                      ),
                    ),
                  ),
                  // Dark Vignette Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.15),
                          Colors.black.withValues(alpha: 0.7),
                          const Color(0xFF0F172A),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Tagline banner near bottom of image
                  Positioned(
                    bottom: 24,
                    left: 24,
                    right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Drive with Freedom\nEarn on Every Journey',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1.25,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Direct bookings from local stands to district headquarters',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // BOTTOM SECTION: Elevated Sign-In Form & Actions toward Bottom
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Partner Sign In',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Choose your login method to access driver trips & wallet.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Error notice if any
                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFFDC2626), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 1. Google 1-Click Sign-In Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.login, size: 20, color: Colors.white),
                                SizedBox(width: 10),
                                Text(
                                  'Sign In with Google Account',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
