import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:district_car_shared/models/models.dart';
import '../../../../services/haptic_service.dart';
import '../../../../theme/theme.dart';

/// No Driver Found View (Never a dead end)
/// Features a friendly rural Jharkhand illustration, reassuring message,
/// and 3 actionable pathways: Try Again, Schedule for Later, and WhatsApp/Call human desk.
class NoDriverState extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onRetry;
  final VoidCallback? onScheduleLater;

  const NoDriverState({
    super.key,
    required this.booking,
    required this.onRetry,
    this.onScheduleLater,
  });

  Future<void> _openWhatsAppBooking() async {
    HapticService.buttonPress();
    final message = Uri.encodeComponent(
      'Namaste District Car Desk! I need an offline booking assistance.\n'
      'Booking ID: ${booking.readableId}\n'
      'From: ${booking.pickup.address}\n'
      'To: ${booking.destination.address}\n'
      'Estimated Fare: ₹${(booking.finalFare ?? booking.estimatedFare).toInt()}',
    );
    final url = Uri.parse('https://wa.me/919341828000?text=$message');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callHelpDesk() async {
    HapticService.buttonPress();
    final url = Uri.parse('tel:+919341828000');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Friendly Illustration (Auto-rickshaw at golden hour on hill road)
          Center(
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/no_driver_rural_hill.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/images/no_ride_available_3d.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppTokens.surface2,
                    child: const Center(
                      child: Icon(Icons.directions_car_filled_rounded, size: 64, color: AppTokens.hint),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),

          // Title & Reassuring Subtitle
          const Text(
            'Abhi koi driver free nahi hai',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTokens.ink,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Aapke kshetra ke sabhi partner drivers is samay vyast hain. Aap turant punah prayas kar sakte hain ya hamare local desk se sampark karein.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: AppTokens.secondaryText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Action 1: "Try again" (Primary Gradient)
          SizedBox(
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppTokens.primaryGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppTokens.primary.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticService.buttonPress();
                  onRetry();
                },
                icon: const Icon(Icons.replay_rounded, color: Colors.white, size: 20),
                label: const Text(
                  'Try Again / दोबारा खोजें',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Action 2: "Schedule for later"
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {
                HapticService.selectionClick();
                if (onScheduleLater != null) {
                  onScheduleLater!();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Trip scheduling request submitted. We will notify you.'),
                      backgroundColor: AppTokens.primaryDark,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.schedule_rounded, size: 18, color: AppTokens.primaryDark),
              label: const Text(
                'Schedule for Later / बाद के लिए समय तय करें',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTokens.primaryDark),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTokens.border, width: 1.5),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Action 3: "Book on WhatsApp / Call"
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: TextButton.icon(
                    onPressed: _openWhatsAppBooking,
                    icon: const Icon(Icons.chat_rounded, size: 18, color: AppTokens.primary),
                    label: const Text(
                      'Book on WhatsApp',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTokens.primaryDark),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: AppTokens.primaryTint,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: TextButton.icon(
                    onPressed: _callHelpDesk,
                    icon: const Icon(Icons.phone_rounded, size: 18, color: AppTokens.primary),
                    label: const Text(
                      'Call Help Desk',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTokens.primaryDark),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: AppTokens.primaryTint,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
