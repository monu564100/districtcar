import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Stylized Jharkhand Hero Illustration
/// Features:
/// 1. Layered flat-gradient landscape: morning sky, sun glow, rolling green plateaus, cascading waterfall, forest trees, asphalt district road.
/// 2. An animated auto-rickshaw driving along the road in an 8-second smooth loop.
/// 3. Glass-morphic rounded logo badge with a 3-second breathing indigo glow pulse.
/// 4. Respects MediaQuery.of(context).disableAnimations.
class HeroJharkhandIllustration extends StatefulWidget {
  final double height;
  final String? heroImageAsset;

  const HeroJharkhandIllustration({
    super.key,
    this.height = 290,
    this.heroImageAsset,
  });

  @override
  State<HeroJharkhandIllustration> createState() => _HeroJharkhandIllustrationState();
}

class _HeroJharkhandIllustrationState extends State<HeroJharkhandIllustration>
    with TickerProviderStateMixin {
  late final AnimationController _driveController;
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _driveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _driveController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Layered Landscape Canvas Background
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Full-fidelity Hero Landscape Image with Vector Painter fallback
                  if (widget.heroImageAsset != null)
                    Image.asset(
                      widget.heroImageAsset!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.network(
                        'assets/${widget.heroImageAsset}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => CustomPaint(
                          painter: _JharkhandLandscapePainter(),
                          size: Size.infinite,
                        ),
                      ),
                    )
                  else
                    CustomPaint(
                      painter: _JharkhandLandscapePainter(),
                      size: Size.infinite,
                    ),

                  // Bottom road scrim for clean contrast
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 90,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            const Color(0xFF0F172A).withValues(alpha: 0.25),
                            const Color(0xFFF6F7FB).withValues(alpha: 0.90),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 2. Animated Auto-Rickshaw Driving on the Road
                  Positioned(
                    bottom: 22,
                    left: 0,
                    right: 0,
                    child: AnimatedBuilder(
                      animation: _driveController,
                      builder: (context, child) {
                        final progress = disableAnimations ? 0.5 : _driveController.value;
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final totalWidth = constraints.maxWidth;
                            final xPos = (progress * (totalWidth + 80)) - 60;
                            // Subtle bobbing motion
                            final yBob = disableAnimations ? 0.0 : math.sin(progress * math.pi * 16) * 1.5;

                            return Transform.translate(
                              offset: Offset(xPos, yBob),
                              child: child,
                            );
                          },
                        );
                      },
                      child: const _AutoRickshawVector(width: 44, height: 32),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Floating Glass-Morphism Logo Tile with Indigo Glow Pulse
          Positioned(
            top: 24,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  final glow = disableAnimations ? 0.5 : _glowController.value;
                  return Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: Colors.white.withValues(alpha: 0.88),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.95),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6A5CFF).withValues(alpha: 0.22 + (glow * 0.18)),
                          blurRadius: 18 + (glow * 14),
                          spreadRadius: glow * 3,
                          offset: const Offset(0, 8),
                        ),
                        const BoxShadow(
                          color: Color.fromRGBO(15, 23, 42, 0.06),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/app_logo.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF3D2FD6),
                          child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 32),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Vector Painter for Jharkhand's Landscape (Rolling hills, waterfall, sky, forest, road)
class _JharkhandLandscapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Sky Gradient (Sunrise glow: soft amber into twilight indigo)
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF2A1FA8), // Primary dark indigo
          Color(0xFF5B4CEE), // Vibrant violet
          Color(0xFFFBBF24), // Morning sun amber
          Color(0xFFFDE68A), // Light horizon
        ],
        stops: [0.0, 0.45, 0.82, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.7));

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.7), skyPaint);

    // Morning Sun Orb
    final sunPaint = Paint()
      ..color = const Color(0xFFFEF08A).withValues(alpha: 0.85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(Offset(w * 0.78, h * 0.22), 26, sunPaint);

    // 2. Far Hills (Deep Blue/Purple Plateau)
    final farHills = Path()
      ..moveTo(0, h * 0.44)
      ..quadraticBezierTo(w * 0.25, h * 0.36, w * 0.5, h * 0.42)
      ..quadraticBezierTo(w * 0.75, h * 0.48, w, h * 0.38)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    final farHillsPaint = Paint()..color = const Color(0xFF3730A3).withValues(alpha: 0.85);
    canvas.drawPath(farHills, farHillsPaint);

    // 3. Mid Hills (Lush Green Plateau with Waterfall gorge)
    final midHills = Path()
      ..moveTo(0, h * 0.52)
      ..quadraticBezierTo(w * 0.35, h * 0.46, w * 0.65, h * 0.54)
      ..lineTo(w, h * 0.50)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    final midHillsPaint = Paint()..color = const Color(0xFF047857);
    canvas.drawPath(midHills, midHillsPaint);

    // Cascading Waterfall (Hundru/Dassam style stream)
    final waterfall = Path()
      ..moveTo(w * 0.48, h * 0.48)
      ..quadraticBezierTo(w * 0.50, h * 0.55, w * 0.49, h * 0.64)
      ..lineTo(w * 0.52, h * 0.64)
      ..quadraticBezierTo(w * 0.53, h * 0.55, w * 0.50, h * 0.48)
      ..close();
    final waterfallPaint = Paint()
      ..color = const Color(0xFFE0F2FE).withValues(alpha: 0.90)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    canvas.drawPath(waterfall, waterfallPaint);

    // 4. Foreground Sal Tree Hills & Foliage
    final nearHills = Path()
      ..moveTo(0, h * 0.62)
      ..quadraticBezierTo(w * 0.4, h * 0.66, w * 0.8, h * 0.60)
      ..lineTo(w, h * 0.64)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    final nearHillsPaint = Paint()..color = const Color(0xFF065F46);
    canvas.drawPath(nearHills, nearHillsPaint);

    // 5. Asphalt Rural Road
    final road = Path()
      ..moveTo(0, h * 0.82)
      ..quadraticBezierTo(w * 0.5, h * 0.78, w, h * 0.84)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    final roadPaint = Paint()..color = const Color(0xFF334155);
    canvas.drawPath(road, roadPaint);

    // Dashed Center Road Stripe
    final stripePaint = Paint()
      ..color = const Color(0xFFFDE047).withValues(alpha: 0.80)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final stripePath = Path()
      ..moveTo(0, h * 0.89)
      ..quadraticBezierTo(w * 0.5, h * 0.86, w, h * 0.91);
    canvas.drawPath(stripePath, stripePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Compact vector rendering of an Indian Auto-Rickshaw
class _AutoRickshawVector extends StatelessWidget {
  final double width;
  final double height;
  const _AutoRickshawVector({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _AutoRickshawPainter(),
      ),
    );
  }
}

class _AutoRickshawPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Auto Yellow Hood / Roof
    final yellowPaint = Paint()..color = const Color(0xFFFBBF24);
    final hoodPath = Path()
      ..moveTo(w * 0.1, h * 0.4)
      ..quadraticBezierTo(w * 0.2, h * 0.1, w * 0.6, h * 0.1)
      ..lineTo(w * 0.88, h * 0.18)
      ..lineTo(w * 0.85, h * 0.45)
      ..lineTo(w * 0.1, h * 0.4)
      ..close();
    canvas.drawPath(hoodPath, yellowPaint);

    // Auto Green Body
    final greenPaint = Paint()..color = const Color(0xFF16A34A);
    final bodyPath = Path()
      ..moveTo(w * 0.08, h * 0.4)
      ..lineTo(w * 0.85, h * 0.45)
      ..lineTo(w * 0.82, h * 0.75)
      ..lineTo(w * 0.12, h * 0.75)
      ..close();
    canvas.drawPath(bodyPath, greenPaint);

    // Black Wheels
    final wheelPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawCircle(Offset(w * 0.24, h * 0.82), h * 0.18, wheelPaint);
    canvas.drawCircle(Offset(w * 0.74, h * 0.82), h * 0.18, wheelPaint);

    // Wheel hubs
    final hubPaint = Paint()..color = const Color(0xFFE2E8F0);
    canvas.drawCircle(Offset(w * 0.24, h * 0.82), h * 0.07, hubPaint);
    canvas.drawCircle(Offset(w * 0.74, h * 0.82), h * 0.07, hubPaint);

    // Windshield (cyan/white tint)
    final glassPaint = Paint()..color = const Color(0xFFBAE6FD).withValues(alpha: 0.9);
    final glassPath = Path()
      ..moveTo(w * 0.58, h * 0.2)
      ..lineTo(w * 0.84, h * 0.24)
      ..lineTo(w * 0.80, h * 0.44)
      ..lineTo(w * 0.56, h * 0.42)
      ..close();
    canvas.drawPath(glassPath, glassPaint);

    // Headlight glow
    final lightPaint = Paint()..color = const Color(0xFFFEF08A);
    canvas.drawCircle(Offset(w * 0.85, h * 0.52), 2.5, lightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
