import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:district_car_shared/models/models.dart';
import '../../services/haptic_service.dart';

/// Top Map Header on Home Screen (Ola / Uber Style)
/// Renders above From and To container with:
/// - Realistic interactive map with streets and landmarks
/// - User's live pickup pin (pulsing beacon + vertical pole + green pickup ring)
/// - Top-down live vehicles roaming nearby with headings (Cars, Bikes, Autos)
/// - Unserviceable 3D graphic overlay when out of bounds
/// - Smooth entrance animation on app open
class HomeMapHeader extends StatefulWidget {
  final LocationModel pickupLocation;
  final bool isServiceable;
  final bool isHindi;
  final VoidCallback? onRecenter;
  final VoidCallback? onSupportTap;

  const HomeMapHeader({
    super.key,
    required this.pickupLocation,
    this.isServiceable = true,
    this.isHindi = false,
    this.onRecenter,
    this.onSupportTap,
  });

  @override
  State<HomeMapHeader> createState() => _HomeMapHeaderState();
}

class _HomeMapHeaderState extends State<HomeMapHeader> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _expandAnimation;
  late Animation<double> _fadeAnimation;

  late AnimationController _pulseController;
  late AnimationController _driftController;

  // Pan offset for interactive map dragging
  Offset _mapPanOffset = Offset.zero;

  // Vehicles simulated around pickup point
  late List<_SimulatedVehicle> _vehicles;

  @override
  void initState() {
    super.initState();

    // 1. Entrance animation on app open (smooth expand & fade)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _expandAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );

    _entranceController.forward();

    // 2. Continuous pulse for user location beacon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // 3. Continuous gentle drift for idle live vehicles
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _initVehicles();
  }

  void _initVehicles() {
    // Top-down vehicles positioned relative to user location
    // Matching the user's reference image with cars, bike, auto at realistic road angles
    _vehicles = [
      // 1. White Sedan north-west (heading north-west ~ -45°)
      _SimulatedVehicle(
        type: _VehicleType.car,
        initialOffset: const Offset(-85, -55),
        headingDeg: -40,
        driftSpeed: 1.2,
      ),
      // 2. White Sedan north-east (heading north-east ~ 35°)
      _SimulatedVehicle(
        type: _VehicleType.car,
        initialOffset: const Offset(90, -75),
        headingDeg: 35,
        driftSpeed: 0.9,
      ),
      // 3. Green Scooter / Bike north (heading ~ -25°)
      _SimulatedVehicle(
        type: _VehicleType.bike,
        initialOffset: const Offset(-38, -80),
        headingDeg: -25,
        driftSpeed: 1.6,
      ),
      // 4. Yellow-Green Auto Rickshaw east (heading ~ 65°)
      _SimulatedVehicle(
        type: _VehicleType.auto,
        initialOffset: const Offset(62, -85),
        headingDeg: 70,
        driftSpeed: 1.0,
      ),
      // 5. White Sedan south-east (heading ~ 130°)
      _SimulatedVehicle(
        type: _VehicleType.car,
        initialOffset: const Offset(42, 65),
        headingDeg: 125,
        driftSpeed: 1.1,
      ),
      // 6. Another White Sedan south-east cluster (heading ~ 110°)
      _SimulatedVehicle(
        type: _VehicleType.car,
        initialOffset: const Offset(28, 48),
        headingDeg: 105,
        driftSpeed: 0.8,
      ),
      // 7. Greenish Car south (heading ~ 170°)
      _SimulatedVehicle(
        type: _VehicleType.carGreen,
        initialOffset: const Offset(-45, 85),
        headingDeg: 165,
        driftSpeed: 1.0,
      ),
    ];
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    _driftController.dispose();
    super.dispose();
  }

  void _handleRecenter() {
    HapticService.selection();
    setState(() {
      _mapPanOffset = Offset.zero;
    });
    if (widget.onRecenter != null) {
      widget.onRecenter!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _expandAnimation,
      axisAlignment: -1.0,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          height: 225,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(15, 23, 42, 0.08),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // 1. Interactive Road Network Canvas Layer
                Positioned.fill(
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _mapPanOffset += details.delta;
                        // Limit dragging boundary
                        _mapPanOffset = Offset(
                          _mapPanOffset.dx.clamp(-120.0, 120.0),
                          _mapPanOffset.dy.clamp(-90.0, 90.0),
                        );
                      });
                    },
                    child: AnimatedBuilder(
                      animation: _driftController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _RoadMapCanvasPainter(
                            panOffset: _mapPanOffset,
                            pulseValue: _pulseController.value,
                          ),
                          child: const SizedBox.expand(),
                        );
                      },
                    ),
                  ),
                ),

                // 2. Live Top-Down Animated Vehicles Layer (Shown ONLY if serviceable)
                if (widget.isServiceable)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _driftController,
                        builder: (context, child) {
                          return Stack(
                            children: _vehicles.map((v) {
                              // Calculate subtle idle vehicle movement along its heading
                              final driftPhase = (_driftController.value * 2 * math.pi) + v.driftSpeed;
                              final forwardDrift = math.sin(driftPhase) * 4.0;
                              final lateralDrift = math.cos(driftPhase) * 1.5;

                              final headingRad = v.headingDeg * math.pi / 180.0;
                              final dx = math.cos(headingRad) * forwardDrift - math.sin(headingRad) * lateralDrift;
                              final dy = math.sin(headingRad) * forwardDrift + math.cos(headingRad) * lateralDrift;

                              // Screen center + pan offset + initial vehicle offset + drift
                              return Positioned(
                                left: (MediaQuery.of(context).size.width - 32) / 2 +
                                    _mapPanOffset.dx +
                                    v.initialOffset.dx +
                                    dx -
                                    14,
                                top: 112.5 + _mapPanOffset.dy + v.initialOffset.dy + dy - 22,
                                child: Transform.rotate(
                                  angle: headingRad,
                                  child: _buildTopDownVehicle(v.type),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                  ),

                // 3. User Pickup Pin (Pulse blue dot + vertical pole + green ring marker)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: Transform.translate(
                        offset: _mapPanOffset,
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Floating ETA / "You are here" Tooltip
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color.fromRGBO(0, 0, 0, 0.25),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: widget.isServiceable
                                              ? const Color(0xFF22C55E)
                                              : const Color(0xFFEF4444),
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        widget.isServiceable
                                            ? (widget.isHindi ? 'पिकअप स्थान' : 'Pickup Location')
                                            : (widget.isHindi ? 'अमान्य क्षेत्र' : 'Out of Bounds'),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),

                                // Green Pickup Ring Marker (Ola / Uber style)
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF16A34A),
                                    border: Border.all(color: Colors.white, width: 2.5),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color.fromRGBO(0, 0, 0, 0.2),
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),

                                // Black Stem Connecting Pole
                                Container(
                                  width: 2,
                                  height: 12,
                                  color: const Color(0xFF0F172A),
                                ),

                                // Ground Level: Blue pulsing beacon dot
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Expanding aura wave
                                    Container(
                                      width: 14 + (_pulseController.value * 22),
                                      height: 14 + (_pulseController.value * 22),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF3B82F6).withValues(
                                          alpha: (1.0 - _pulseController.value) * 0.45,
                                        ),
                                      ),
                                    ),
                                    // Solid Blue Ground Dot
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF2563EB),
                                        border: Border.all(color: Colors.white, width: 2),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color.fromRGBO(37, 99, 235, 0.4),
                                            blurRadius: 6,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // 4. Top-Left Status Badge ("Vehicles Nearby" or "Service Unavailable")
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.isServiceable
                            ? const Color(0xFF16A34A).withValues(alpha: 0.3)
                            : const Color(0xFFEF4444).withValues(alpha: 0.3),
                        width: 1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.08),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pulsing radar dot
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.isServiceable
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFEF4444),
                                boxShadow: [
                                  BoxShadow(
                                    color: (widget.isServiceable
                                            ? const Color(0xFF16A34A)
                                            : const Color(0xFFEF4444))
                                        .withValues(alpha: 0.6),
                                    blurRadius: 4 + (_pulseController.value * 4),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.isServiceable
                              ? (widget.isHindi ? 'लाइव गाड़ियाँ उपलब्ध • 2-4 मिनट' : 'Live Cabs Nearby • 2–4 min')
                              : (widget.isHindi ? 'अमान्य क्षेत्र' : 'No service in this zone'),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: widget.isServiceable
                                ? const Color(0xFF15803D)
                                : const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 5. Top-Right GPS Recenter Button
                Positioned(
                  top: 10,
                  right: 10,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.94),
                    shape: const CircleBorder(),
                    elevation: 3,
                    shadowColor: Colors.black26,
                    child: InkWell(
                      onTap: _handleRecenter,
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.my_location_rounded,
                          size: 18,
                          color: Color(0xFF3D2FD6),
                        ),
                      ),
                    ),
                  ),
                ),

                // 6. Unserviceable Area Overlay (Shown ONLY if area is unserviceable)
                if (!widget.isServiceable)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                        child: Container(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.78),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          child: Row(
                            children: [
                              // 3D Unserviceable Image Graphic
                              Container(
                                width: 78,
                                height: 78,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    width: 1.5,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black38,
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.asset(
                                    'assets/images/unserviceable_area_3d.jpg',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: const Color(0xFF1E293B),
                                      child: const Icon(
                                        Icons.location_off_rounded,
                                        size: 38,
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Unserviceable Message & Call Button
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(0xFFEF4444).withValues(alpha: 0.6),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        widget.isHindi
                                            ? 'यहाँ सेवा उपलब्ध नहीं है'
                                            : 'NO SERVICE IN THIS AREA',
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.3,
                                          color: Color(0xFFF87171),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      widget.isHindi
                                          ? 'यह स्थान हमारे सेवा क्षेत्र से बाहर है।'
                                          : 'No vehicles active in this zone currently.',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.isHindi
                                          ? 'जल्द ही आपके गाँव/जिले में शुरू होगी।'
                                          : 'District Car expanding rapidly across Jharkhand.',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    GestureDetector(
                                      onTap: widget.onSupportTap,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.call_rounded, size: 12, color: Color(0xFF38BDF8)),
                                          const SizedBox(width: 4),
                                          Text(
                                            widget.isHindi ? 'हेल्पलाइन से बात करें' : 'Call Support Helpline',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF38BDF8),
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // 7. Subtle Google Watermark (as seen on maps)
                Positioned(
                  bottom: 6,
                  left: 10,
                  child: Row(
                    children: [
                      Text(
                        'Google',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.black.withValues(alpha: 0.35),
                          fontFamily: 'sans-serif',
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '• Jharkhand Live Transit',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.black.withValues(alpha: 0.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds high-quality top-down vehicle graphics matching the reference screenshot
  Widget _buildTopDownVehicle(_VehicleType type) {
    switch (type) {
      case _VehicleType.car:
        return const _TopDownCarWidget(bodyColor: Colors.white);
      case _VehicleType.carGreen:
        return const _TopDownCarWidget(bodyColor: Color(0xFFE2E8F0), roofTint: Color(0xFF86EFAC));
      case _VehicleType.bike:
        return const _TopDownBikeWidget();
      case _VehicleType.auto:
        return const _TopDownAutoWidget();
    }
  }
}

enum _VehicleType { car, carGreen, bike, auto }

class _SimulatedVehicle {
  final _VehicleType type;
  final Offset initialOffset;
  final double headingDeg;
  final double driftSpeed;

  _SimulatedVehicle({
    required this.type,
    required this.initialOffset,
    required this.headingDeg,
    required this.driftSpeed,
  });
}

/// Custom painter for crisp, realistic top-down road network matching Google Maps
class _RoadMapCanvasPainter extends CustomPainter {
  final Offset panOffset;
  final double pulseValue;

  _RoadMapCanvasPainter({
    required this.panOffset,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Light Map Landmass Background
    final bgPaint = Paint()..color = const Color(0xFFF1F3F4);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final ox = size.width / 2 + panOffset.dx;
    final oy = size.height / 2 + panOffset.dy;

    // 2. Green Park & Landscape Shapes (just like the reference image!)
    final parkPaint = Paint()
      ..color = const Color(0xFFCEEAD6)
      ..style = PaintingStyle.fill;

    // Water Body (Brookefield lake accent in blue)
    final waterPaint = Paint()
      ..color = const Color(0xFFAECBFA)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(ox - 140, oy + 45, 60, 45), const Radius.circular(16)),
      parkPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(ox + 80, oy + 30, 45, 55), const Radius.circular(14)),
      waterPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(ox + 50, oy - 95, 55, 35), const Radius.circular(12)),
      waterPaint,
    );

    // 3. Road Network (White roads with light gray borders)
    final roadBorderPaint = Paint()
      ..color = const Color(0xFFD3D8DE)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final roadSurfacePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Road lines connecting landmarks
    final List<Path> roads = [];

    // Main Diagonal Highway (NH-44 like in screenshot)
    final hwy = Path();
    hwy.moveTo(ox - 180, oy - 140);
    hwy.cubicTo(ox - 100, oy - 50, ox - 90, oy + 40, ox - 60, oy + 150);
    roads.add(hwy);

    // Secondary Cross Street 1
    final street1 = Path();
    street1.moveTo(ox - 120, oy - 80);
    street1.lineTo(ox + 160, oy - 45);
    roads.add(street1);

    // Diagonal Avenue 2
    final street2 = Path();
    street2.moveTo(ox - 70, oy - 40);
    street2.lineTo(ox + 120, oy + 120);
    roads.add(street2);

    // Curved Avenue 3 (through center pickup point)
    final street3 = Path();
    street3.moveTo(ox - 40, oy + 90);
    street3.lineTo(ox + 40, oy - 110);
    roads.add(street3);

    // East Outer Bypass
    final street4 = Path();
    street4.moveTo(ox + 130, oy - 120);
    street4.lineTo(ox + 150, oy + 130);
    roads.add(street4);

    // Draw borders first (thicker)
    for (final r in roads) {
      roadBorderPaint.strokeWidth = 24.0;
      canvas.drawPath(r, roadBorderPaint);
    }

    // Draw white road surfaces (narrower)
    for (final r in roads) {
      roadSurfacePaint.strokeWidth = 20.0;
      canvas.drawPath(r, roadSurfacePaint);
    }

    // 4. Landmark Text & Icons (matching reference image: "Brookefield", Cafe icon, etc.)
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    _drawLandmark(
      canvas: canvas,
      textPainter: textPainter,
      name: 'RANCHI MAIN RD',
      offset: Offset(ox - 40, oy + 10),
      isBold: true,
      color: const Color(0xFF64748B),
    );

    _drawLandmark(
      canvas: canvas,
      textPainter: textPainter,
      name: 'Albert Ekka Chowk',
      offset: Offset(ox - 10, oy - 38),
      isBold: false,
      color: const Color(0xFF475569),
    );

    _drawLandmark(
      canvas: canvas,
      textPainter: textPainter,
      name: 'Firayalal Market',
      offset: Offset(ox - 130, oy + 15),
      isBold: false,
      color: const Color(0xFF94A3B8),
    );
  }

  void _drawLandmark({
    required Canvas canvas,
    required TextPainter textPainter,
    required String name,
    required Offset offset,
    required bool isBold,
    required Color color,
  }) {
    textPainter.text = TextSpan(
      text: name,
      style: TextStyle(
        fontSize: isBold ? 11 : 9.5,
        fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
        color: color,
        letterSpacing: 0.8,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _RoadMapCanvasPainter oldDelegate) {
    return oldDelegate.panOffset != panOffset || oldDelegate.pulseValue != pulseValue;
  }
}

/// Top-Down White Car Vector Graphic (matching reference image)
class _TopDownCarWidget extends StatelessWidget {
  final Color bodyColor;
  final Color? roofTint;

  const _TopDownCarWidget({
    this.bodyColor = Colors.white,
    this.roofTint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 42,
      decoration: BoxDecoration(
        color: bodyColor,
        borderRadius: BorderRadius.circular(6.5),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.28),
            blurRadius: 4,
            offset: Offset(1, 2),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFCBD5E1),
          width: 0.8,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Front Headlights
          Positioned(
            top: 1,
            left: 2.5,
            child: Container(width: 3.5, height: 1.5, color: const Color(0xFFFEF08A)),
          ),
          Positioned(
            top: 1,
            right: 2.5,
            child: Container(width: 3.5, height: 1.5, color: const Color(0xFFFEF08A)),
          ),

          // Front Windshield (Dark trapezoid glass)
          Positioned(
            top: 7,
            child: Container(
              width: 14,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Roof Center
          Positioned(
            top: 13,
            child: Container(
              width: 13,
              height: 14,
              decoration: BoxDecoration(
                color: roofTint ?? const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
              ),
            ),
          ),

          // Rear Windshield
          Positioned(
            bottom: 6.5,
            child: Container(
              width: 13,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),

          // Rear Taillights (Red notches at bottom corners)
          Positioned(
            bottom: 0.5,
            left: 2,
            child: Container(width: 3, height: 1.5, color: const Color(0xFFEF4444)),
          ),
          Positioned(
            bottom: 0.5,
            right: 2,
            child: Container(width: 3, height: 1.5, color: const Color(0xFFEF4444)),
          ),
        ],
      ),
    );
  }
}

/// Top-Down Green Bike / Scooter Vector Graphic with Rider (matching reference image)
class _TopDownBikeWidget extends StatelessWidget {
  const _TopDownBikeWidget();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 34,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Bike Body / Chassis (Emerald Green)
          Container(
            width: 10,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A),
              borderRadius: BorderRadius.circular(5),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.3),
                  blurRadius: 3,
                  offset: Offset(1, 2),
                ),
              ],
            ),
          ),

          // Front Handlebar cross-bar
          Positioned(
            top: 4,
            child: Container(
              width: 16,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),

          // Rider Body & Dark Helmet (Circle in center)
          Positioned(
            top: 10,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1E293B),
                border: Border.all(color: const Color(0xFF475569), width: 1),
              ),
            ),
          ),

          // Helmet Visor notch
          Positioned(
            top: 10,
            child: Container(
              width: 6,
              height: 2.5,
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Top-Down Indian Auto Rickshaw Vector Graphic with Driver (matching reference image)
class _TopDownAutoWidget extends StatelessWidget {
  const _TopDownAutoWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 23,
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A), // Emerald green cabin
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.3),
            blurRadius: 4,
            offset: Offset(1, 2),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF15803D),
          width: 0.8,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Yellow Front Hood
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 11,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF59E0B),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ),
          ),

          // Front Single Headlight
          Positioned(
            top: 0,
            child: Container(
              width: 4,
              height: 1.5,
              color: const Color(0xFFFEF08A),
            ),
          ),

          // Driver in Front Cab
          Positioned(
            top: 7,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF334155),
              ),
            ),
          ),

          // Passenger Cabin Roof (Green)
          Positioned(
            bottom: 2,
            child: Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                color: const Color(0xFF047857),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
