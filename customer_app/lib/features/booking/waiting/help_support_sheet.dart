import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:district_car_shared/models/models.dart';
import '../../../../services/haptic_service.dart';
import '../../../../theme/theme.dart';

/// Support Sheet opened via the App Bar "Help" action
class HelpSupportSheet extends StatelessWidget {
  final BookingModel booking;

  const HelpSupportSheet({super.key, required this.booking});

  static void show(BuildContext context, BookingModel booking) {
    HapticService.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => HelpSupportSheet(booking: booking),
    );
  }

  Future<void> _launchWhatsApp() async {
    HapticService.buttonPress();
    final message = Uri.encodeComponent(
      'Namaste District Car Support! Need urgent help with booking ID: ${booking.readableId}',
    );
    final url = Uri.parse('https://wa.me/919341828000?text=$message');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callSupport() async {
    HapticService.buttonPress();
    final url = Uri.parse('tel:+919341828000');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        14,
        24,
        mediaQuery.padding.bottom + 18,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: AppTokens.border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Support Header with Illustrated Avatar
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppTokens.primaryTint,
                  borderRadius: BorderRadius.circular(16),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/support_help_agent.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '24x7 District Helpline',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTokens.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Assistance for ${booking.readableId}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppTokens.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // WhatsApp Action
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            tileColor: AppTokens.surface2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: const Icon(Icons.chat_bubble_outline_rounded, color: AppTokens.primary, size: 22),
            title: const Text(
              'Chat on WhatsApp',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppTokens.ink),
            ),
            subtitle: const Text('Fastest response within 60 seconds', style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTokens.hint),
            onTap: _launchWhatsApp,
          ),
          const SizedBox(height: 10),

          // Direct Call Action
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            tileColor: AppTokens.surface2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: const Icon(Icons.phone_in_talk_rounded, color: AppTokens.primary, size: 22),
            title: const Text(
              'Call Help Center (+91 93418 28000)',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppTokens.ink),
            ),
            subtitle: const Text('Toll-free regional support desk', style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTokens.hint),
            onTap: _callSupport,
          ),
        ],
      ),
    );
  }
}
