import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:district_car_shared/models/models.dart';
import '../../../../services/haptic_service.dart';
import '../../../../theme/theme.dart';
import 'booking_search_state.dart';

/// Driver Found Celebration & Contact Card
/// Slides up when driver accepts ride with animated OTP digits, verified badges,
/// direct call/WhatsApp 56h actions, and green/marigold celebratory confetti burst.
class DriverFoundCard extends StatefulWidget {
  final DriverFoundState state;
  final BookingModel booking;
  final bool isLiteMode;

  const DriverFoundCard({
    super.key,
    required this.state,
    required this.booking,
    this.isLiteMode = false,
  });

  @override
  State<DriverFoundCard> createState() => _DriverFoundCardState();
}

class _DriverFoundCardState extends State<DriverFoundCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (!widget.isLiteMode) {
      _confettiController.forward();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _callDriver() async {
    HapticService.buttonPress();
    final phone = widget.state.driverPhone ?? '+919341828000';
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _whatsAppDriver() async {
    HapticService.buttonPress();
    final phone = widget.state.driverPhone?.replaceAll(RegExp(r'\D'), '') ?? '919341828000';
    final message = Uri.encodeComponent(
      'Namaste ${widget.state.driverName}! Main pickup point par hoon: ${widget.booking.pickup.address}. Ride ID: ${widget.booking.readableId}',
    );
    final url = Uri.parse('https://wa.me/$phone?text=$message');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _shareTrip(BuildContext context) {
    HapticService.selectionClick();
    final text =
        'District Car Ride Assigned!\n'
        'Driver: ${widget.state.driverName} (${widget.state.vehicleNumber})\n'
        'Car: ${widget.state.vehicleName}\n'
        'OTP: ${widget.state.otp}\n'
        'Live tracking: https://districtcar.in/track/${widget.booking.readableId}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Driver and OTP details copied to clipboard!'),
        backgroundColor: AppTokens.primaryDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final driver = widget.state;
    final otpDigits = driver.otp.split('');

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Confetti Particle Burst Overlay
        if (!widget.isLiteMode)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _confettiController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _ConfettiBurstPainter(
                      progress: _confettiController.value,
                    ),
                  );
                },
              ),
            ),
          ),

        // Main Bottom Sheet Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          decoration: const BoxDecoration(
            color: AppTokens.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.18),
                blurRadius: 32,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Celebration Top Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTokens.primaryTint,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTokens.primary.withOpacity(0.2)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 16, color: AppTokens.primary),
                        SizedBox(width: 6),
                        Text(
                          'Driver Found & Assigned!',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppTokens.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ETA Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTokens.marigoldTint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.near_me_rounded, size: 14, color: AppTokens.marigoldDark),
                        const SizedBox(width: 4),
                        Text(
                          driver.etaText,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppTokens.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Driver Profile Row
              Row(
                children: [
                  // Driver Avatar with Verified Badge
                  Stack(
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTokens.surface2,
                          border: Border.all(color: AppTokens.primary, width: 2),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/avatar_commuter_3d.jpg'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: AppTokens.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, size: 13, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  // Driver Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              driver.driverName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTokens.ink,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTokens.surface2,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, size: 13, color: AppTokens.marigold),
                                  const SizedBox(width: 2),
                                  Text(
                                    driver.rating.toStringAsFixed(1),
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${driver.vehicleType} • ${driver.vehicleName}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTokens.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          driver.vehicleNumber,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppTokens.ink,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 4-DIGIT PICKUP OTP CONTAINER
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTokens.surface2,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTokens.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'START RIDE OTP',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTokens.secondaryText,
                            letterSpacing: 0.6,
                          ),
                        ),
                        Text(
                          'Driver ko yeh code batayein',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppTokens.ink,
                          ),
                        ),
                      ],
                    ),

                    // OTP Digit Boxes (32px tabular figures)
                    Row(
                      children: otpDigits.map((digit) {
                        return Container(
                          width: 38,
                          height: 44,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTokens.primary, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              digit,
                              style: const TextStyle(
                                fontFeatures: [FontFeature.tabularFigures()],
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppTokens.primaryDark,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // DIRECT CALL & WHATSAPP BUTTONS (56h)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _callDriver,
                        icon: const Icon(Icons.phone_in_talk_rounded, size: 20),
                        label: const Text(
                          'Call Driver',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTokens.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: _whatsAppDriver,
                        icon: const Icon(Icons.chat_bubble_rounded, size: 20, color: AppTokens.primaryDark),
                        label: const Text(
                          'WhatsApp',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTokens.primaryDark),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTokens.primaryDark, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          backgroundColor: AppTokens.primaryTint.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Share Trip Link
              Center(
                child: TextButton.icon(
                  onPressed: () => _shareTrip(context),
                  icon: const Icon(Icons.share_rounded, size: 16, color: AppTokens.secondaryText),
                  label: const Text(
                    'Share ride details with family',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTokens.secondaryText,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Lightweight 60fps celebratory confetti particle burst
class _ConfettiBurstPainter extends CustomPainter {
  final double progress;

  _ConfettiBurstPainter({required this.progress});

  static final List<_ConfettiParticle> _particles = List.generate(36, (i) {
    final rand = math.Random(i * 19);
    final angle = rand.nextDouble() * 2 * math.pi;
    final speed = 80 + rand.nextDouble() * 160;
    final color = i % 2 == 0 ? AppTokens.marigold : AppTokens.primary;
    final size = 4.0 + rand.nextDouble() * 4.0;
    return _ConfettiParticle(angle: angle, speed: speed, color: color, size: size);
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;

    final center = Offset(size.width / 2, size.height * 0.35);
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    for (final p in _particles) {
      final distance = p.speed * Curves.easeOutQuad.transform(progress);
      final dx = center.dx + distance * math.cos(p.angle);
      final dy = center.dy + distance * math.sin(p.angle) + (progress * 40); // gravity

      final paint = Paint()
        ..color = p.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(dx, dy), p.size * (1.0 - progress * 0.3), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiBurstPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _ConfettiParticle {
  final double angle;
  final double speed;
  final Color color;
  final double size;

  const _ConfettiParticle({
    required this.angle,
    required this.speed,
    required this.color,
    required this.size,
  });
}
