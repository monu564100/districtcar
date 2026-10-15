import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../theme/theme.dart';

/// Decorative vehicle silhouette definition
/// NOTE: Illustrative decorative positions along simulated Khunti regional road corridors.
/// These represent simulated nearby vehicle drifts and must never imply real GPS
/// driver coordinates unless provided directly by the live fleet backend.
class IllustrativeDriverVehicle {
  final double angleOffset; // Initial angle along orbital path
  final double speed;       // Movement speed multiplier
  final double radiusRatio; // Distance from center
  final String type;        // 'auto', 'bike', 'cab', 'suv'
  final double baseOpacity;

  const IllustrativeDriverVehicle({
    required this.angleOffset,
    required this.speed,
    required this.radiusRatio,
    required this.type,
    this.baseOpacity = 0.85,
  });
}

/// 60fps CustomPainter for Live Radar & Map Scene
/// Drives 3 ripple rings, rotating sweep wedge, expanding dashed radius ring,
/// pulsing pickup pin, and decorative drifting vehicle silhouettes.
class RadarPainter extends CustomPainter {
  final double rippleProgress;  // 0.0 -> 1.0 (2.4s loop)
  final double sweepProgress;   // 0.0 -> 1.0 (3.0s linear rotation)
  final double pulseProgress;   // 0.0 -> 1.0 (1.2s pin pulse)
  final double currentRadiusKm; // 5.0, 8.0, 12.0 km
  final double radiusAnimValue; // 0.0 -> 1.0 interpolation when radius changes
  final bool isLiteMode;        // For devices with ≤3GB RAM
  final bool reduceMotion;      // Accessibility setting
  final ui.Image? mapBackdropImage;

  // Statically defined illustrative vehicle paths
  static const List<IllustrativeDriverVehicle> _vehicles = [
    IllustrativeDriverVehicle(angleOffset: 0.35, speed: 0.6, radiusRatio: 0.42, type: 'auto'),
    IllustrativeDriverVehicle(angleOffset: 1.80, speed: 0.8, radiusRatio: 0.68, type: 'cab'),
    IllustrativeDriverVehicle(angleOffset: 3.20, speed: 1.1, radiusRatio: 0.32, type: 'bike'),
    IllustrativeDriverVehicle(angleOffset: 4.60, speed: 0.5, radiusRatio: 0.58, type: 'auto'),
    IllustrativeDriverVehicle(angleOffset: 5.70, speed: 0.7, radiusRatio: 0.76, type: 'suv'),
  ];

  RadarPainter({
    required this.rippleProgress,
    required this.sweepProgress,
    required this.pulseProgress,
    required this.currentRadiusKm,
    this.radiusAnimValue = 1.0,
    this.isLiteMode = false,
    this.reduceMotion = false,
    this.mapBackdropImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.46;

    // 1. Draw Map Backdrop (Image or Stylized Vector roads/river)
    _drawStylizedMap(canvas, size);

    // 2. Draw Dynamic Dash Radius Boundary (5km / 8km / 12km)
    _drawRadiusBoundaryRing(canvas, center, maxRadius);

    if (reduceMotion) {
      // Accessible static glow without motion
      _drawStaticAccessibleGlow(canvas, center, maxRadius);
      _drawCenterPickupPin(canvas, center, 1.0);
      return;
    }

    // 3. Draw Concentric Expanding Ripple Rings (3 rings staggered 0.8s)
    _drawRippleRings(canvas, center, maxRadius);

    // 4. Draw Rotating Radar Sweep Wedge (green-to-transparent conic)
    if (!isLiteMode) {
      _drawSweepWedge(canvas, center, maxRadius);
    }

    // 5. Draw Decorative Drifting Vehicle Silhouettes (Illustrative)
    if (!isLiteMode) {
      _drawDriftingVehicleSilhouettes(canvas, center, maxRadius);
    }

    // 6. Draw Center Pulsing Pickup Pin
    final pulseScale = 1.0 + 0.15 * math.sin(pulseProgress * 2 * math.pi).abs();
    _drawCenterPickupPin(canvas, center, pulseScale);
  }

  /// 1. Stylized Khunti Regional Terrain (River waterway, Sal forest patches, rural roads)
  void _drawStylizedMap(Canvas canvas, Size size) {
    if (mapBackdropImage != null) {
      final src = Rect.fromLTWH(0, 0, mapBackdropImage!.width.toDouble(), mapBackdropImage!.height.toDouble());
      final dst = Rect.fromLTWH(0, 0, size.width, size.height);
      final paint = Paint()
        ..filterQuality = FilterQuality.medium
        ..color = Colors.white.withOpacity(0.92);
      canvas.drawImageRect(mapBackdropImage!, src, dst, paint);
      return;
    }

    // Fallback vector terrain in deep forest charcoal palette (#101A14 -> #1E2A22)
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, size.height),
        [const Color(0xFF1E2A22), const Color(0xFF101A14)],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // River Waterway (soft organic curve)
    final riverPaint = Paint()
      ..color = const Color(0xFF172B20).withOpacity(0.7)
      ..strokeWidth = 24
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final riverPath = Path()
      ..moveTo(0, size.height * 0.25)
      ..cubicTo(
        size.width * 0.35, size.height * 0.35,
        size.width * 0.60, size.height * 0.70,
        size.width, size.height * 0.75,
      );
    canvas.drawPath(riverPath, riverPaint);

    // Sal Forest Canopy Patches (low contrast green-charcoal blobs)
    final forestPaint = Paint()
      ..color = const Color(0xFF15241B).withOpacity(0.85)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.20, size.height * 0.75), width: 140, height: 90),
      forestPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.85, size.height * 0.30), width: 160, height: 110),
      forestPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.75, size.height * 0.85), width: 120, height: 70),
      forestPaint,
    );

    // Regional Rural Highways (Muted Road Lines)
    final roadPaint = Paint()
      ..color = const Color(0xFF24352B)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    final roadPath1 = Path()
      ..moveTo(size.width * 0.1, 0)
      ..quadraticBezierTo(size.width * 0.45, size.height * 0.45, size.width * 0.9, size.height);
    canvas.drawPath(roadPath1, roadPaint);

    final roadPath2 = Path()
      ..moveTo(0, size.height * 0.8)
      ..cubicTo(
        size.width * 0.3, size.height * 0.6,
        size.width * 0.7, size.height * 0.5,
        size.width, size.height * 0.2,
      );
    canvas.drawPath(roadPath2, roadPaint);
  }

  /// 2. Concentric Expanding Ripple Rings (3 rings, 2.4s loop, staggered 0.8s)
  void _drawRippleRings(Canvas canvas, Offset center, double maxRadius) {
    const ringCount = 3;
    final singleLoop = isLiteMode ? 1 : ringCount;

    for (int i = 0; i < singleLoop; i++) {
      // Stagger by 0.333 (equivalent to 0.8s in 2.4s loop)
      double t = (rippleProgress + (i / ringCount)) % 1.0;

      // Ease out scaling
      final easedScale = 0.20 + 0.80 * Curves.easeOut.transform(t);
      final currentRadius = maxRadius * easedScale;

      // Opacity fades from 0.40 -> 0.0
      final opacity = (0.40 * (1.0 - t)).clamp(0.0, 1.0);

      final ringPaint = Paint()
        ..color = AppTokens.marigold.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, currentRadius, ringPaint);
    }
  }

  /// 3. Rotating Radar Sweep Wedge (Green conic gradient, 3s linear rotation)
  void _drawSweepWedge(Canvas canvas, Offset center, double maxRadius) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    final sweepAngleRad = sweepProgress * 2 * math.pi;
    canvas.rotate(sweepAngleRad);

    final sweepRect = Rect.fromCircle(center: Offset.zero, radius: maxRadius);
    final sweepPaint = Paint()
      ..shader = ui.Gradient.sweep(
        Offset.zero,
        [
          AppTokens.primary.withOpacity(0.0),
          AppTokens.primary.withOpacity(0.0),
          AppTokens.primary.withOpacity(0.05),
          AppTokens.primary.withOpacity(0.26),
        ],
        [0.0, 0.70, 0.88, 1.0],
      );

    canvas.drawCircle(Offset.zero, maxRadius, sweepPaint);
    canvas.restore();
  }

  /// 4. Dynamic Dashed Radius Boundary Ring (Expands 5km -> 8km -> 12km)
  void _drawRadiusBoundaryRing(Canvas canvas, Offset center, double maxRadius) {
    // Map radius km (5 -> 0.55, 8 -> 0.78, 12 -> 1.00)
    final double targetFraction = currentRadiusKm <= 5.0
        ? 0.55
        : (currentRadiusKm <= 8.0 ? 0.78 : 1.00);

    final boundaryRadius = maxRadius * targetFraction * radiusAnimValue;

    final dashPaint = Paint()
      ..color = AppTokens.marigold.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    // Draw dashed circle
    const totalDashes = 36;
    const dashFraction = 0.65; // Dash length vs gap
    final anglePerDash = (2 * math.pi) / totalDashes;

    for (int i = 0; i < totalDashes; i++) {
      final startAngle = i * anglePerDash;
      final sweepAngle = anglePerDash * dashFraction;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: boundaryRadius),
        startAngle,
        sweepAngle,
        false,
        dashPaint,
      );
    }
  }

  /// 5. Decorative Drifting Vehicle Dots (Illustrative)
  void _drawDriftingVehicleSilhouettes(Canvas canvas, Offset center, double maxRadius) {
    final t = sweepProgress; // Shared smooth movement clock

    for (final v in _vehicles) {
      final angle = v.angleOffset + (t * 2 * math.pi * v.speed);
      final r = maxRadius * v.radiusRatio;

      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      final pos = Offset(x, y);

      // Soft breathing vehicle dot
      final fade = 0.5 + 0.5 * math.sin(angle * 2).abs();
      final alpha = (v.baseOpacity * fade).clamp(0.2, 0.95);

      final dotPaint = Paint()
        ..color = (v.type == 'auto' ? AppTokens.marigold : const Color(0xFFF3F0E9)).withOpacity(alpha)
        ..style = PaintingStyle.fill;

      // Glow halo
      canvas.drawCircle(pos, 5.0, Paint()..color = dotPaint.color.withOpacity(0.25));
      // Vehicle center pip
      canvas.drawCircle(pos, 2.6, dotPaint);
    }
  }

  /// 6. Center Pulsing Pickup Pin (Marigold dot with white halo & shadow)
  void _drawCenterPickupPin(Canvas canvas, Offset center, double scale) {
    final baseRadius = 8.5 * scale;

    // Drop shadow
    canvas.drawCircle(
      center.translate(0, 3),
      baseRadius + 2,
      Paint()
        ..color = Colors.black.withOpacity(0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Outer pulsating Marigold Glow
    canvas.drawCircle(
      center,
      baseRadius + 6,
      Paint()..color = AppTokens.marigold.withOpacity(0.30),
    );

    // Pure White Border Ring
    canvas.drawCircle(
      center,
      baseRadius + 2.5,
      Paint()..color = Colors.white,
    );

    // Core Marigold Pill Dot
    final pinPaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        baseRadius,
        [const Color(0xFFFDBA74), AppTokens.marigold, AppTokens.marigoldDark],
        [0.0, 0.65, 1.0],
      );
    canvas.drawCircle(center, baseRadius, pinPaint);

    // Tiny Center Specular Highlight
    canvas.drawCircle(
      center.translate(-1.5, -1.5),
      2.0,
      Paint()..color = Colors.white.withOpacity(0.85),
    );
  }

  /// Accessible Static Glow for Reduce Motion
  void _drawStaticAccessibleGlow(Canvas canvas, Offset center, double maxRadius) {
    canvas.drawCircle(
      center,
      maxRadius * 0.75,
      Paint()
        ..color = AppTokens.marigold.withOpacity(0.20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  @override
  bool shouldRepaint(covariant RadarPainter oldDelegate) {
    return oldDelegate.rippleProgress != rippleProgress ||
        oldDelegate.sweepProgress != sweepProgress ||
        oldDelegate.pulseProgress != pulseProgress ||
        oldDelegate.currentRadiusKm != currentRadiusKm ||
        oldDelegate.radiusAnimValue != radiusAnimValue ||
        oldDelegate.mapBackdropImage != mapBackdropImage;
  }
}
