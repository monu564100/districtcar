import 'package:flutter/material.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  Future<void> _makeCall(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String number) async {
    final uri = Uri.parse('https://wa.me/918789601387?text=Hello%20District%20Car%20Team');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'About Us (हमारे बारे में)',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Brand Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF064E3B), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF059669).withOpacity(0.25), blurRadius: 18, offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'JHARKHAND 1ST GRAMIN & DISTRICT CAB NETWORK',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'District Car Mobility',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Bridging Jharkhand villages, Sadar Hospitals, district headquarters & tourism hubs with fair fares and verified local Sarathi drivers.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Leadership & Founders Section
            const Text(
              'Leadership & Founders (संस्थापक मंडल)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),

            // CEO Card - Monu Kumar
            _buildFounderCard(
              name: 'MONU KUMAR',
              role: 'Chief Executive Officer (CEO)',
              badgeColor: const Color(0xFF16A34A),
              bio: 'Visionary leader dedicated to solving rural accessibility in Jharkhand. Spearheading operations, pricing integrity, and commuter safety across all 24 districts.',
              contact: '+91 87896 01387',
              icon: Icons.person_pin_rounded,
            ),
            const SizedBox(height: 12),

            // Co-Founder Card - Sonu Kumar
            _buildFounderCard(
              name: 'SONU KUMAR',
              role: 'Co-Founder & Head of Operations',
              badgeColor: const Color(0xFF0284C7),
              bio: 'Co-founder driving Sarathi driver onboarding, vehicle quality checks, and rural route logistics from Khunti to every block headquarters.',
              contact: '+91 87896 01387',
              icon: Icons.groups_rounded,
            ),
            const SizedBox(height: 24),

            // Registered Office & Headquarters
            const Text(
              'Registered Office & Headquarters',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOfficeRow(
                    Icons.location_on_rounded,
                    'Operational HQ & Dispatch Center',
                    'Nichey Chowk, Khunti, Jharkhand - 835210',
                    highlight: true,
                  ),
                  const Divider(height: 24),
                  _buildOfficeRow(
                    Icons.phone_in_talk_rounded,
                    'Official Contact Helpline',
                    '+91 87896 01387',
                    onTap: () => _makeCall('+918789601387'),
                  ),
                  const Divider(height: 24),
                  _buildOfficeRow(
                    Icons.mail_outline_rounded,
                    'Official Support Email',
                    'support@districtcar.in',
                  ),
                  const Divider(height: 24),
                  _buildOfficeRow(
                    Icons.language_rounded,
                    'Official Portal & APK Download',
                    'https://districtcar.in',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Call & WhatsApp Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text('Call +91 87896 01387', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () => _makeCall('+918789601387'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                    label: const Text('WhatsApp Us', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () => _openWhatsApp('+918789601387'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFounderCard({
    required String name,
    required String role,
    required Color badgeColor,
    required String bio,
    required String contact,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: badgeColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        role.split('(').first.trim(),
                        style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  bio,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.45),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 13, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      contact,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficeRow(IconData icon, String title, String value, {bool highlight = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: highlight ? const Color(0xFF059669) : AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: highlight ? const Color(0xFF0F172A) : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
        ],
      ),
    );
  }
}
