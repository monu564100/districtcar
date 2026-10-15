import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../theme/theme.dart';
import 'radar_painter.dart';

/// Hero Section for Booking Waiting Screen (~48% height)
/// Features animated live radar, expanding radius chip, drifting vehicle dots,
/// and frosted glass status pill.
class SearchingHero extends StatefulWidget {
  final double radiusKm;
  final int matchedDriversCount;
  final bool isLiteMode;

  const SearchingHero({
    super.key,
    required this.radiusKm,
    this.matchedDriversCount = 0,
    this.isLiteMode = false,
  });

  @override
  State<SearchingHero> createState() => _SearchingHeroState();
}

class _SearchingHeroState extends State<SearchingHero>
    with TickerProviderStateMixin {
  late final AnimationController _rippleController;
  late final AnimationController _sweepController;
  late final AnimationController _pulseController;
  late final AnimationController _radiusController;
  ui.Image? _backdropImage;

  double _previousRadius = 5.0;

  @override
  void initState() {
    super.initState();

    // 1. Ripple Rings Controller: 2.4s loop
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    // 2. Conic Sweep Controller: 3.0s linear rotation
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // 3. Center Pin Pulse: 1.2s pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // 4. Radius Expansion Spring: 600ms easeInOut
    _radiusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: 1.0,
    );

    _loadBackdropImage();
  }

  Future<void> _loadBackdropImage() async {
    try {
      final data = await rootBundle.load('assets/images/radar_map_backdrop_dark.jpg');
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: 720,
      );
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() => _backdropImage = frame.image);
      }
    } catch (_) {
      // Graceful fallback to vector procedural terrain in RadarPainter
    }
  }

  @override
  void didUpdateWidget(covariant SearchingHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.radiusKm != widget.radiusKm) {
      _previousRadius = oldWidget.radiusKm;
      _radiusController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _sweepController.dispose();
    _pulseController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final reduceMotion = mediaQuery.disableAnimations;
    final screenHeight = mediaQuery.size.height;
    final heroHeight = (screenHeight * 0.46).clamp(310.0, 440.0);

    return Container(
      width: double.infinity,
      height: heroHeight,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Color(0xFF101A14), // Deep forest charcoal base
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Live Animated Radar Painter
          AnimatedBuilder(
            animation: Listenable.merge([
              _rippleController,
              _sweepController,
              _pulseController,
              _radiusController,
            ]),
            builder: (context, _) {
              return CustomPaint(
                painter: RadarPainter(
                  rippleProgress: _rippleController.value,
                  sweepProgress: _sweepController.value,
                  pulseProgress: _pulseController.value,
                  currentRadiusKm: widget.radiusKm,
                  radiusAnimValue: CurvedAnimation(
                    parent: _radiusController,
                    curve: Curves.easeOutCubic,
                  ).value,
                  isLiteMode: widget.isLiteMode,
                  reduceMotion: reduceMotion,
                  mapBackdropImage: _backdropImage,
                ),
              );
            },
          ),

          // 2. Cinematic Edge Scrims (Smooth transition into status card)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF101A14).withOpacity(0.55),
                    Colors.transparent,
                    Colors.transparent,
                    const Color(0xFF101A14).withOpacity(0.85),
                  ],
                  stops: const [0.0, 0.22, 0.72, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 3. Top-Right Radius Indicator Chip ("Searching within 12 km")
          Positioned(
            top: 14,
            right: 18,
            child: Semantics(
              label: 'Search radius: ${widget.radiusKm.toInt()} kilometres',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2A22).withOpacity(0.90),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTokens.marigold.withOpacity(0.55),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppTokens.marigold,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'Searching within ${widget.radiusKm.toInt()} km',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Floating Glass Status Chip at bottom of hero
          Positioned(
            bottom: 16,
            left: 20,
            right: 20,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2A22).withOpacity(0.78),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.radar_rounded,
                          size: 16,
                          color: AppTokens.marigold,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.matchedDriversCount > 0
                              ? '${widget.matchedDriversCount} drivers nearby alerted'
                              : 'Searching nearby drivers',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const _ThreeDotPulseLoader(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Subtle 3-dot animated pulse loader
class _ThreeDotPulseLoader extends StatefulWidget {
  const _ThreeDotPulseLoader();

  @override
  State<_ThreeDotPulseLoader> createState() => _ThreeDotPulseLoaderState();
}

class _ThreeDotPulseLoaderState extends State<_ThreeDotPulseLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_controller.value - (i * 0.22)) % 1.0;
            final scale = 0.5 + 0.5 * (1.0 - (t - 0.5).abs() * 2);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 3.5 * scale,
              height: 3.5 * scale,
              decoration: BoxDecoration(
                color: AppTokens.marigold.withOpacity((scale * 0.9).clamp(0.3, 1.0)),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
