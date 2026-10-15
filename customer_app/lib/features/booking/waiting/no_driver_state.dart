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
            'कोई राइडर अभी उपलब्ध नहीं है',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTokens.ink,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '30 मिनट की खोज के बाद भी आसपास कोई राइडर उपलब्ध नहीं हो पाया।',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTokens.secondaryText,
            ),
          ),
          const SizedBox(height: 18),

          // High Quality Quote Container:
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.format_quote_rounded, color: Color(0xFFD97706), size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '“थोड़ा देर ही सही, पर आरामदायक यात्रा के लिए अभी शेड्यूल करें”',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF92400E),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Thoda der hi sahi, par aaramdayak journey ke liye schedule karein',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFFB45309).withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action 1: "Schedule Ride" (Primary High-Emphasis Gradient)
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
                  HapticService.selectionClick();
                  if (onScheduleLater != null) {
                    onScheduleLater!();
                  } else {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                icon: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 20),
                label: const Text(
                  'सवारी शेड्यूल करें / Schedule Ride',
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

          // Action 2: "Try again"
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                HapticService.buttonPress();
                onRetry();
              },
              icon: const Icon(Icons.replay_rounded, size: 18, color: AppTokens.primaryDark),
              label: const Text(
                'Try Again / दोबारा खोजें',
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
