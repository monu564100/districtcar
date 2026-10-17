import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverSupportScreen extends StatefulWidget {
  const DriverSupportScreen({super.key});

  @override
  State<DriverSupportScreen> createState() => _DriverSupportScreenState();
}

class _DriverSupportScreenState extends State<DriverSupportScreen> {
  int? _expandedFaqIndex;

  void _callHelpline(BuildContext context, String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) await launchUrl(uri);
    } catch (_) {
      try {
        await launchUrl(uri);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Helpline: $phone')),
          );
        }
      }
    }
  }

  void _openWhatsApp(BuildContext context, String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse(
      'https://wa.me/$cleanPhone?text=Hello%20District%20Car%20Support%2C%20I%20am%20a%20registered%20Driver%20Partner%20needing%20assistance.',
    );
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) await launchUrl(uri);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open WhatsApp')),
        );
      }
    }
  }

  void _sendEmail(BuildContext context, String email) async {
    final uri = Uri.parse('mailto:$email?subject=Driver%20Partner%20Support%20Request');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) await launchUrl(uri);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email: $email')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Help & 24/7 Support Desk',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        elevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double maxW = constraints.maxWidth > 640 ? 640 : constraints.maxWidth;
          final double contentW = (maxW - 36).clamp(280.0, 640.0);

          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: maxW,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                child: SizedBox(
                  width: contentW,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. HERO 24/7 SUPPORT BANNER
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF065F46), Color(0xFF047857), Color(0xFF059669)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF059669).withValues(alpha: 0.28),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.22),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.headset_mic_rounded, color: Colors.white, size: 16),
                                        SizedBox(width: 6),
                                        Text(
                                          '24/7 Partner Helpline',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'District Car Support Desk',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Our Jharkhand control team is active 24/7 for ride verification, location queries, and instant earnings assistance.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFD1FAE5),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.asset(
                                'assets/images/support_help_agent.jpg',
                                width: 84,
                                height: 84,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 84,
                                  height: 84,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Icon(Icons.support_agent, size: 48, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 2. EMERGENCY SOS STRIP (Call Direct Control Room)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFDC2626),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Emergency & Breakdown Assistance',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF991B1B),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'On-duty accident, road blockade or vehicle emergency',
                                    style: TextStyle(fontSize: 11, color: Color(0xFFB91C1C)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDC2626),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => _callHelpline(context, '+91 87896 01387'),
                              child: const Text('SOS CALL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 3. DIRECT CONTACT CHANNELS
                      const Text(
                        'Direct Help Channels',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Central Control Room Phone
                      _buildContactTile(
                        icon: Icons.phone_in_talk_rounded,
                        iconColor: const Color(0xFF059669),
                        title: 'Central Control Room',
                        subtitle: '+91 87896 01387 (24/7 Hotline)',
                        buttonText: 'Call Now',
                        onTap: () => _callHelpline(context, '+91 87896 01387'),
                      ),

                      // WhatsApp Support Desk
                      _buildContactTile(
                        icon: Icons.chat_rounded,
                        iconColor: const Color(0xFF16A34A),
                        title: 'WhatsApp Partner Desk',
                        subtitle: 'Quick chat for KYC, verification & stand info',
                        buttonText: 'Open Chat',
                        onTap: () => _openWhatsApp(context, '+918789601387'),
                      ),

                      // Email Desk
                      _buildContactTile(
                        icon: Icons.alternate_email_rounded,
                        iconColor: const Color(0xFF0284C7),
                        title: 'Official Partner Email',
                        subtitle: 'support@districtcar.com (For billing queries)',
                        buttonText: 'Send Email',
                        onTap: () => _sendEmail(context, 'support@districtcar.com'),
                      ),

                      // Regional Office
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_city_rounded, color: Color(0xFF475569), size: 24),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'District Car Headquarters',
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A)),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Albert Ekka Chowk, Main Road, Ranchi, Jharkhand - 834001\nOperational Hours: Mon - Sat (9:00 AM - 7:00 PM)',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 4. FREQUENTLY ASKED QUESTIONS
                      const Text(
                        'Driver Partner FAQ & Rules',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildFaqItem(
                        index: 0,
                        question: 'How do my wallet earnings & payout work?',
                        answer:
                            'You keep 90% of the trip fare directly. Completed bookings reflect immediately in your dynamic wallet on the home screen. Payouts can be withdrawn to your registered bank account or UPI.',
                      ),
                      _buildFaqItem(
                        index: 1,
                        question: 'How is distance to booking pickups calculated?',
                        answer:
                            'Your distance is calculated from your permanent registered stand location. If you tap "Change Active Location", incoming bookings will be matched against your newly chosen hotspot.',
                      ),
                      _buildFaqItem(
                        index: 2,
                        question: 'What if a rider cancels or does not arrive?',
                        answer:
                            'If the rider does not show up at pickup within 10 minutes, you can call them directly from the app or contact our 24/7 central desk to release or cancel the trip without penalty.',
                      ),
                      _buildFaqItem(
                        index: 3,
                        question: 'Why do I only receive rides for my vehicle category?',
                        answer:
                            'To ensure maximum earnings and zero irrelevant trips, our dispatch engine strictly routes requests matching your registered vehicle (Auto, Bike, or Cab).',
                      ),
                      _buildFaqItem(
                        index: 4,
                        question: 'How do I update my vehicle number or DL documents?',
                        answer:
                            'You can send updated photographs of your Vehicle RC or Driving License directly via our WhatsApp Partner Desk (+91 87896 01387) for prompt re-verification.',
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: iconColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: onTap,
            child: Text(buttonText, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem({
    required int index,
    required String question,
    required String answer,
  }) {
    final isExpanded = _expandedFaqIndex == index;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isExpanded ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedFaqIndex = isExpanded ? null : index;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      question,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isExpanded ? const Color(0xFF047857) : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: isExpanded ? const Color(0xFF047857) : const Color(0xFF64748B),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                answer,
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.45),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
