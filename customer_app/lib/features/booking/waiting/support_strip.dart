import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:district_car_shared/models/models.dart';
import '../../../../services/haptic_service.dart';
import '../../../../theme/theme.dart';

/// Safety & Support Strip (Always Visible)
/// Contains WhatsApp and Call Support buttons (52h, outlined green)
/// along with a "Share trip with family" link.
class SupportStrip extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback? onWhatsAppTapped;
  final VoidCallback? onCallTapped;
  final VoidCallback? onShareTapped;

  const SupportStrip({
    super.key,
    required this.booking,
    this.onWhatsAppTapped,
    this.onCallTapped,
    this.onShareTapped,
  });

  static const String supportPhone = '+919341828000';

  Future<void> _launchWhatsApp(BuildContext context) async {
    HapticService.buttonPress();
    onWhatsAppTapped?.call();
    final message = Uri.encodeComponent(
      'Namaste District Car Support! Need assistance with my booking.\n'
      'Booking ID: ${booking.readableId}\n'
      'Pickup: ${booking.pickup.address}\n'
      'Destination: ${booking.destination.address}',
    );
    final url = Uri.parse('https://wa.me/919341828000?text=$message');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp could not be opened. Calling support instead...')),
        );
      }
      _callSupport();
    }
  }

  Future<void> _callSupport() async {
    HapticService.buttonPress();
    onCallTapped?.call();
    final url = Uri.parse('tel:$supportPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _shareTripWithFamily(BuildContext context) {
    HapticService.selectionClick();
    onShareTapped?.call();
    final shareText =
        'District Car Ride Status:\n'
        'Booking: ${booking.readableId}\n'
        'From: ${booking.pickup.address}\n'
        'To: ${booking.destination.address}\n'
        'Status: Searching for drivers near Khunti\n'
        '24x7 Support: +91 93418 28000';

    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ride details copied to clipboard! Share with your family.'),
        backgroundColor: AppTokens.primaryDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              // WhatsApp Support Button (Outlined Green, 52h)
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => _launchWhatsApp(context),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 19, color: AppTokens.primary),
                    label: const Text(
                      'WhatsApp',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTokens.primaryDark,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTokens.primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: AppTokens.primaryTint.withOpacity(0.35),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Call Support Button (Outlined Green, 52h)
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _callSupport,
                    icon: const Icon(Icons.phone_in_talk_rounded, size: 19, color: AppTokens.primary),
                    label: const Text(
                      'Call Support',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTokens.primaryDark,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTokens.primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: AppTokens.primaryTint.withOpacity(0.35),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Share Trip Link
          InkWell(
            onTap: () => _shareTripWithFamily(context),
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.share_location_rounded, size: 16, color: AppTokens.primary),
                  SizedBox(width: 6),
                  Text(
                    'Share trip with family / परिवार के साथ शेयर करें',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppTokens.primaryDark,
                      decoration: TextDecoration.underline,
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
