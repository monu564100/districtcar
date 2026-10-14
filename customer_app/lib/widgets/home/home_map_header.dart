import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:district_car_shared/models/models.dart';
import '../../services/haptic_service.dart';
import 'map_web_checker.dart';

/// Top Map Header on Home Screen (Ola / Uber Style)
/// Renders above From and To container with:
/// - Real Google Maps view centered at exact pickup location
/// - User's live pickup pin (Onyx/Amber beacon + vertical pole + pickup ring)
/// - Top-down live animated vehicles roaming nearby with headings (Cars, Bikes, Autos)
/// - Unserviceable 3D graphic overlay when out of bounds
/// - Smooth entrance animation on app open
/// - Zero blue and zero green colors (Sleek Carbon Onyx & Warm Amber palette)
class HomeMapHeader extends StatefulWidget {
  final LocationModel pickupLocation;
  final bool isServiceable;
  final bool isHindi;
  final VoidCallback? onRecenter;
  final VoidCallback? onSupportTap;
  final bool edgeToEdge;
  final double? height;

  const HomeMapHeader({
    super.key,
    required this.pickupLocation,
    this.isServiceable = true,
    this.isHindi = false,
    this.onRecenter,
    this.onSupportTap,
    this.edgeToEdge = false,
    this.height,
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

  GoogleMapController? _googleMapController;

  // Pan offset for interactive vehicle canvas layer
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
      // 1. White Sedan north-west (heading north-west ~ -40°)
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
      // 3. Sporty Commuter Bike north (heading ~ -25°)
      _SimulatedVehicle(
        type: _VehicleType.bike,
        initialOffset: const Offset(-38, -80),
        headingDeg: -25,
        driftSpeed: 1.6,
      ),
      // 4. Yellow-Amber Auto Rickshaw east (heading ~ 70°)
      _SimulatedVehicle(
        type: _VehicleType.auto,
        initialOffset: const Offset(62, -85),
        headingDeg: 70,
        driftSpeed: 1.0,
      ),
      // 5. White Sedan south-east (heading ~ 125°)
      _SimulatedVehicle(
        type: _VehicleType.car,
        initialOffset: const Offset(42, 65),
        headingDeg: 125,
        driftSpeed: 1.1,
      ),
      // 6. Another White Sedan south-east cluster (heading ~ 105°)
      _SimulatedVehicle(
        type: _VehicleType.car,
        initialOffset: const Offset(28, 48),
        headingDeg: 105,
        driftSpeed: 0.8,
      ),
      // 7. Compact Silver/White Car south (heading ~ 165°)
      _SimulatedVehicle(
        type: _VehicleType.carSilver,
        initialOffset: const Offset(-45, 85),
        headingDeg: 165,
        driftSpeed: 1.0,
      ),
    ];
  }

  @override
  void didUpdateWidget(covariant HomeMapHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pickupLocation.latitude != oldWidget.pickupLocation.latitude ||
        widget.pickupLocation.longitude != oldWidget.pickupLocation.longitude) {
      _googleMapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(widget.pickupLocation.latitude, widget.pickupLocation.longitude),
        ),
      );
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    _driftController.dispose();
    _googleMapController?.dispose();
    super.dispose();
  }

  void _handleRecenter() {
    HapticService.selection();
    setState(() {
      _mapPanOffset = Offset.zero;
    });
    _googleMapController?.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(widget.pickupLocation.latitude, widget.pickupLocation.longitude),
      ),
    );
    if (widget.onRecenter != null) {
      widget.onRecenter!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetLatLng = LatLng(
      widget.pickupLocation.latitude,
      widget.pickupLocation.longitude,
    );
    final topPadding = MediaQuery.of(context).padding.top;
    final mapHeight = widget.height ?? (widget.edgeToEdge ? 330.0 : 225.0);
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = widget.edgeToEdge ? screenWidth : (screenWidth - 32);

    return SizeTransition(
      sizeFactor: _expandAnimation,
      axisAlignment: -1.0,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          height: mapHeight,
          margin: widget.edgeToEdge ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: widget.edgeToEdge
                ? BorderRadius.zero
                : BorderRadius.circular(24),
            border: widget.edgeToEdge
                ? null
                : Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
            boxShadow: widget.edgeToEdge
                ? null
                : const [
                    BoxShadow(
                      color: Color.fromRGBO(15, 23, 42, 0.08),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: widget.edgeToEdge
                ? BorderRadius.zero
                : BorderRadius.circular(22),
            child: Stack(
              children: [
                // 1. Exact Google Maps Layer (Centered at Pickup Location)
                if (!kIsWeb || isGoogleMapsJsReady())
                  Positioned.fill(
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: targetLatLng,
                        zoom: 15.8,
                      ),
                      onMapCreated: (controller) {
                        _googleMapController = controller;
                        controller.animateCamera(CameraUpdate.newLatLng(targetLatLng));
                      },
                      myLocationEnabled: false,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      compassEnabled: false,
                      rotateGesturesEnabled: true,
                      scrollGesturesEnabled: true,
                      tiltGesturesEnabled: false,
                      zoomGesturesEnabled: true,
                    ),
                  )
                else
                  Positioned.fill(
                    child: _buildVectorMapPlaceholder(targetLatLng),
                  ),

                // 2. Interactive Gesture Layer & Animated Top-Down Vehicles
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _driftController,
                      builder: (context, child) {
                        return Stack(
                          children: _vehicles.map((v) {
                            // Subtle idle vehicle movement along its heading
                            final driftPhase = (_driftController.value * 2 * math.pi) + v.driftSpeed;
                            final forwardDrift = math.sin(driftPhase) * 4.0;
                            final lateralDrift = math.cos(driftPhase) * 1.5;

                            final headingRad = v.headingDeg * math.pi / 180.0;
                            final dx = math.cos(headingRad) * forwardDrift - math.sin(headingRad) * lateralDrift;
                            final dy = math.sin(headingRad) * forwardDrift + math.cos(headingRad) * lateralDrift;

                            // Screen center + pan offset + initial vehicle offset + drift
                            return Positioned(
                              left: (contentWidth / 2) +
                                  _mapPanOffset.dx +
                                  v.initialOffset.dx +
                                  dx -
                                  14,
                              top: (mapHeight / 2) + _mapPanOffset.dy + v.initialOffset.dy + dy - 22,
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

                // 3. User Pickup Pin (Pulse aura + vertical pole + Carbon Onyx/Amber marker)
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
                                // Floating ETA / "Pickup Location" Tooltip
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color.fromRGBO(0, 0, 0, 0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6.5,
                                        height: 6.5,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFFF59E0B),
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        widget.isHindi ? 'पिकअप स्थान' : 'Pickup Location',
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

                                // Top Marker: Carbon Onyx ring with Amber center (Ola/Uber style)
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF0F172A),
                                    border: Border.all(color: Colors.white, width: 2.5),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color.fromRGBO(0, 0, 0, 0.25),
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
                                        color: Color(0xFFF59E0B),
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

                                // Ground Level: Pulsing beacon dot
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Expanding aura wave (Amber / Onyx)
                                    Container(
                                      width: 14 + (_pulseController.value * 22),
                                      height: 14 + (_pulseController.value * 22),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF0F172A).withValues(
                                          alpha: (1.0 - _pulseController.value) * 0.35,
                                        ),
                                      ),
                                    ),
                                    // Solid Ground Dot (Carbon Onyx)
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF0F172A),
                                        border: Border.all(color: Colors.white, width: 2),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color.fromRGBO(15, 23, 42, 0.4),
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

                // 4. Status Badge (Live Cabs Nearby) - Only shown when serviceable, never shows unserviceable tag
                if (widget.isServiceable)
                  Positioned(
                    top: widget.edgeToEdge ? (topPadding + 10) : 12,
                    left: widget.edgeToEdge ? 16 : 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
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
                                  color: const Color(0xFFD97706),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                                      blurRadius: 4 + (_pulseController.value * 4),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.isHindi ? 'लाइव गाड़ियाँ उपलब्ध • 2-4 मिनट' : 'Live Cabs Nearby • 2–4 min',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 5. GPS Recenter Button (Carbon Onyx)
                Positioned(
                  top: widget.edgeToEdge ? null : 10,
                  bottom: widget.edgeToEdge ? 36 : null,
                  right: widget.edgeToEdge ? 16 : 10,
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
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),
                ),


              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVectorMapPlaceholder(LatLng pos) {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: _RoadGridPainter(),
          ),
          Positioned(
            right: 12,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                '${pos.latitude.toStringAsFixed(4)}° N, ${pos.longitude.toStringAsFixed(4)}° E',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds top-down vehicle graphics matching the reference screenshot (no blue, no green)
  Widget _buildTopDownVehicle(_VehicleType type) {
    switch (type) {
      case _VehicleType.car:
        return const _TopDownCarWidget(bodyColor: Colors.white);
      case _VehicleType.carSilver:
        return const _TopDownCarWidget(bodyColor: Color(0xFFE2E8F0));
      case _VehicleType.bike:
        return const _TopDownBikeWidget();
      case _VehicleType.auto:
        return const _TopDownAutoWidget();
    }
  }
}

enum _VehicleType { car, carSilver, bike, auto }

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

/// Top-Down White Car Vector Graphic (matching reference image)
class _TopDownCarWidget extends StatelessWidget {
  final Color bodyColor;

  const _TopDownCarWidget({
    this.bodyColor = Colors.white,
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
          // Front Headlights (Pale Amber)
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

          // Front Windshield (Dark glass)
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
                color: const Color(0xFFF1F5F9),
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

/// Top-Down Commuter Bike / Scooter Vector Graphic with Rider (Neutral Charcoal / Amber)
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
          // Bike Body / Chassis (Dark Charcoal with Amber highlight)
          Container(
            width: 10,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
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
                color: const Color(0xFFD97706),
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
                color: const Color(0xFF0F172A),
                border: Border.all(color: const Color(0xFF64748B), width: 1),
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
                color: const Color(0xFFFBBF24),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Top-Down Indian Auto Rickshaw Vector Graphic with Driver (Yellow & Charcoal)
class _TopDownAutoWidget extends StatelessWidget {
  const _TopDownAutoWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 23,
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Charcoal cabin
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.3),
            blurRadius: 4,
            offset: Offset(1, 2),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF334155),
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
                color: Color(0xFF475569),
              ),
            ),
          ),

          // Passenger Cabin Roof
          Positioned(
            bottom: 2,
            child: Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: const Color(0xFF334155), width: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for crisp, realistic map road vectors
class _RoadGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Arterial Highway
    final highwayPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 26
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final highwayCasing = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 30
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final highwayPath = Path()
      ..moveTo(-20, size.height * 0.72)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.68,
        size.width * 0.55,
        size.height * 0.42,
        size.width + 20,
        size.height * 0.38,
      );

    canvas.drawPath(highwayPath, highwayCasing);
    canvas.drawPath(highwayPath, highwayPaint);

    // 2. Secondary Roads
    final roadPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;

    final roadCasing = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 17
      ..style = PaintingStyle.stroke;

    final road1 = Path()
      ..moveTo(size.width * 0.28, -10)
      ..lineTo(size.width * 0.36, size.height + 10);

    final road2 = Path()
      ..moveTo(size.width * 0.72, -10)
      ..lineTo(size.width * 0.65, size.height + 10);

    final road3 = Path()
      ..moveTo(-10, size.height * 0.30)
      ..lineTo(size.width + 10, size.height * 0.25);

    for (final p in [road1, road2, road3]) {
      canvas.drawPath(p, roadCasing);
      canvas.drawPath(p, roadPaint);
    }

    // 3. Roundabout / Central Plaza Ring
    final roundaboutCenter = Offset(size.width * 0.48, size.height * 0.50);
    final ringPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke;

    final ringCasing = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 22
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(roundaboutCenter, 34, ringCasing);
    canvas.drawCircle(roundaboutCenter, 34, ringPaint);

    // Roundabout green island (swapped to neutral slate/charcoal)
    final islandPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(roundaboutCenter, 22, islandPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
