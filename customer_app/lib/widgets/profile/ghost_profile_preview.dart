import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/haptic_service.dart';
import '../auth/google_sign_in_button.dart';
import '../auth/login_sheet.dart';

/// Logged-out preview screen for Profile tab.
/// Shows realistic blurred ghost profile cards behind an interactive
/// Google Sign-In card with 3D illustration and trust badges.
class GhostProfilePreview extends StatelessWidget {
  final VoidCallback onSignInSuccess;

  const GhostProfilePreview({
    super.key,
    required this.onSignInSuccess,
  });

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Ghost Sample Profile Cards in Background with Blur & Fade
        Positioned.fill(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              children: [
                _buildGhostUserCard(),
                const SizedBox(height: 14),
                _buildGhostQuickActions(),
                const SizedBox(height: 14),
                _buildGhostSettingsTile(
                  icon: Icons.shield_outlined,
                  title: 'Emergency Contacts & SOS',
                  subtitle: '2 contacts registered • Rural 112 Active',
                ),
                const SizedBox(height: 12),
                _buildGhostSettingsTile(
                  icon: Icons.receipt_long_outlined,
                  title: 'Ride Invoices & GST Bills',
                  subtitle: 'Download tax invoices for all rides',
                ),
                const SizedBox(height: 12),
                _buildGhostSettingsTile(
                  icon: Icons.favorite_border_rounded,
                  title: 'Saved Places & Villages',
                  subtitle: 'Home, Market & Railway Station',
                ),
              ],
            ),
          ),
        ),

        // Semi-transparent overlay with light blur
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.5, sigmaY: 5.5),
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

        // 2. Centered Interactive Sign-In Card
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                  // Friendly 3D Graphic (Avatar / verified shield)
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6A5CFF).withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(
                      'assets/images/icon_verified_support_3d.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/avatar_commuter_3d.jpg',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Image.network(
                          'assets/assets/images/icon_verified_support_3d.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.person_rounded,
                              size: 48,
                              color: Color(0xFF3D2FD6),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Title
                  const Text(
                    'Your profile, all in one place',
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
                    'Emergency SOS, travel passes, ride receipts and saved addresses: sign in with Google to access.',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF5B6478),
                      height: 1.45,
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

                  // Trust Line
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.verified_user_rounded, size: 14, color: Color(0xFF16A34A)),
                      SizedBox(width: 5),
                      Text(
                        'Encrypted & verified • Google login only',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Support Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Need help? ',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      GestureDetector(
                        onTap: () => _launchUrl('https://wa.me/918789601387?text=Hello%20District%20Car%20Support'),
                        child: const Text(
                          'WhatsApp Support',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF16A34A),
                            decoration: TextDecoration.underline,
                          ),
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

  Widget _buildGhostUserCard() {
    return Opacity(
      opacity: 0.50,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE2E8F0),
              ),
              child: const Icon(Icons.person, size: 34, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 140,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 100,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Verified',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGhostQuickActions() {
    return Opacity(
      opacity: 0.50,
      child: Row(
        children: [
          Expanded(child: _buildGhostActionItem(Icons.bookmark_border_rounded, 'Saved Trips')),
          const SizedBox(width: 10),
          Expanded(child: _buildGhostActionItem(Icons.credit_card_rounded, 'Payments')),
          const SizedBox(width: 10),
          Expanded(child: _buildGhostActionItem(Icons.support_agent_rounded, 'Helpline')),
        ],
      ),
    );
  }

  Widget _buildGhostActionItem(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: const Color(0xFF3D2FD6)),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }

  Widget _buildGhostSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Opacity(
      opacity: 0.45,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF3D2FD6)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
