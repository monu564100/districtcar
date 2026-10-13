import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/haptic_service.dart';
import '../auth/google_sign_in_button.dart';
import '../auth/login_sheet.dart';

class GhostTripPreview extends StatelessWidget {
  final VoidCallback onSignInSuccess;

  const GhostTripPreview({
    super.key,
    required this.onSignInSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Ghost sample trip cards in background with blur & fade
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                _buildGhostTripCard(
                  bookingId: 'DC-8921',
                  date: 'Yesterday, 04:30 PM',
                  from: 'Albert Ekka Chowk, Ranchi',
                  to: 'Khunti District Bus Stand',
                  fare: '₹420',
                  vehicle: 'District Auto',
                ),
                const SizedBox(height: 14),
                _buildGhostTripCard(
                  bookingId: 'DC-7740',
                  date: '10 Oct, 09:15 AM',
                  from: 'Ranchi Railway Station',
                  to: 'Hundru Waterfalls, Angara',
                  fare: '₹1,250',
                  vehicle: 'Bolero / Cab',
                ),
                const SizedBox(height: 14),
                _buildGhostTripCard(
                  bookingId: 'DC-6105',
                  date: '04 Oct, 06:45 PM',
                  from: 'Kanta Toli Bus Stand',
                  to: 'RIMS Medical Hospital',
                  fare: '₹180',
                  vehicle: 'Gramin Bike',
                ),
              ],
            ),
          ),
        ),

        // Semi-transparent overlay with light blur
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFF6F7FB).withValues(alpha: 0.65),
                    const Color(0xFFF6F7FB).withValues(alpha: 0.95),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 2. Centered Interactive Preview Card
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(16, 24, 40, 0.08),
                    blurRadius: 28,
                    offset: Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFFEEF0F6),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Friendly 3D Graphic (Auto + route line + location pin)
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      'assets/images/trips_empty_illustration.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/trips_empty_illustration.jpg',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Image.network(
                          'assets/assets/images/trips_empty_illustration.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Image.network(
                            'assets/assets/images/trips_empty_illustration.jpg',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFFEFF6FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.directions_car_filled_rounded,
                                size: 48,
                                color: Color(0xFF3D2FD6),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Title
                  const Text(
                    'Your rides, all in one place',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0B1020),
                      letterSpacing: -0.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  const Text(
                    'Receipts, upcoming tours and live tracking: sign in to see them',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF5B6478),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),

                  // "Sign in with Google" button
                  GoogleSignInButton(
                    label: 'Sign In with Google',
                    onPressed: () async {
                      HapticService.selection();
                      final user = await LoginSheet.show(context);
                      if (user != null) {
                        onSignInSuccess();
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  // Encrypted trust note
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFF16A34A)),
                      SizedBox(width: 5),
                      Text(
                        'Safe, private & verified account access',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGhostTripCard({
    required String bookingId,
    required String date,
    required String from,
    required String to,
    required String fare,
    required String vehicle,
  }) {
    return Opacity(
      opacity: 0.50,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  bookingId,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                ),
                Text(
                  fare,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF16A34A)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(date, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                Text(vehicle, style: const TextStyle(fontSize: 11, color: Color(0xFF3D2FD6), fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.circle, size: 8, color: Color(0xFF16A34A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    from,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 10, color: Color(0xFFDC2626)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    to,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
