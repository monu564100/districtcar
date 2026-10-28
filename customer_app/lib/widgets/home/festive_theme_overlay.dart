import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/haptic_service.dart';

/// Server-Driven UI (SDUI) Festive Theme Model
/// Stored in Firestore `remote_configs/festive_theme`
class FestiveThemeConfig {
  final bool enabled;
  final String theme; // e.g., 'diwali_rockets', 'new_year_confetti', 'holi_splash', 'custom_gif'
  final int durationSeconds; // 5 - 15 seconds
  final List<Color> colors;
  final Color primaryColor;
  final Color secondaryColor;
  final Color sparkleColor;
  final int rocketCount;
  final int sparkleDensity;
  final bool interactiveTap; // Tap anywhere on screen to spawn fireworks!
  final bool enableHaptics;
  final bool showGreetingBadge;
  final String greetingText;

  // Media / Animated GIF / Video / Image Support
  final bool showMedia;
  final String? mediaUrl; // Can be a GIF URL (e.g. Diya lamp, fireworks, goddess, dancing)
  final String mediaPosition; // 'center', 'bottom', 'top', 'floating'
  final String mediaAnimation; // 'pulse', 'bounce', 'float', 'rotate'
  final double mediaWidth;
  final double mediaHeight;

  // Banner / Promo Card Support
  final bool showPromoCard;
  final String? promoTitle;
  final String? promoSubtitle;
  final String? promoCouponCode;
  final String? promoActionText;

  // Particle Shape
  final String particleShape; // 'sparks', 'stars', 'confetti', 'rings'

  const FestiveThemeConfig({
    this.enabled = true,
    this.theme = 'diwali_rockets',
    this.durationSeconds = 8,
    this.colors = const [
      Color(0xFFFFD700), // Gold
      Color(0xFFFF4500), // Orange Red
      Color(0xFFFF1493), // Deep Pink
      Color(0xFF00E676), // Green
      Color(0xFFFFFFFF), // White
    ],
    this.primaryColor = const Color(0xFFFFD700),
    this.secondaryColor = const Color(0xFFFF4500),
    this.sparkleColor = const Color(0xFFFFFFFF),
    this.rocketCount = 6,
    this.sparkleDensity = 45,
    this.interactiveTap = true,
    this.enableHaptics = true,
    this.showGreetingBadge = true,
    this.greetingText = '✨ Shubh Deepawali from District Car ✨',
    this.showMedia = false,
    this.mediaUrl,
    this.mediaPosition = 'center',
    this.mediaAnimation = 'pulse',
    this.mediaWidth = 140,
    this.mediaHeight = 140,
    this.showPromoCard = false,
    this.promoTitle,
    this.promoSubtitle,
    this.promoCouponCode,
    this.promoActionText,
    this.particleShape = 'stars',
  });

  factory FestiveThemeConfig.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const FestiveThemeConfig(enabled: false);

    Color parseColor(dynamic val, Color fallback) {
      if (val == null) return fallback;
      if (val is int) return Color(val);
      if (val is String) {
        String hex = val.replaceAll('#', '').trim();
        if (hex.length == 6) hex = 'FF$hex';
        final int? parsed = int.tryParse(hex, radix: 16);
        if (parsed != null) return Color(parsed);
      }
      return fallback;
    }

    List<Color> parseColorList(dynamic val) {
      if (val is List) {
        final list = <Color>[];
        for (final item in val) {
          list.add(parseColor(item, const Color(0xFFFFD700)));
        }
        if (list.isNotEmpty) return list;
      }
      return const [
        Color(0xFFFFD700),
        Color(0xFFFF4500),
        Color(0xFFFF1493),
        Color(0xFF00E676),
        Color(0xFFFFFFFF),
      ];
    }

    final pColor = parseColor(data['primaryColor'], const Color(0xFFFFD700));
    final sColor = parseColor(data['secondaryColor'], const Color(0xFFFF4500));
    final spColor = parseColor(data['sparkleColor'], const Color(0xFFFFFFFF));

    return FestiveThemeConfig(
      enabled: data['enabled'] == true,
      theme: data['theme']?.toString() ?? 'diwali_rockets',
      durationSeconds: ((data['durationSeconds'] as num?)?.toInt() ?? 8).clamp(5, 25),
      colors: parseColorList(data['colors']),
      primaryColor: pColor,
      secondaryColor: sColor,
      sparkleColor: spColor,
      rocketCount: ((data['rocketCount'] as num?)?.toInt() ?? 6).clamp(2, 16),
      sparkleDensity: ((data['sparkleDensity'] as num?)?.toInt() ?? 45).clamp(15, 120),
      interactiveTap: data['interactiveTap'] != false,
      enableHaptics: data['enableHaptics'] != false,
      showGreetingBadge: data['showGreetingBadge'] != false,
      greetingText: data['greetingText']?.toString() ?? '✨ Shubh Deepawali from District Car ✨',
      showMedia: data['showMedia'] == true || (data['mediaUrl'] != null && data['mediaUrl'].toString().isNotEmpty),
      mediaUrl: data['mediaUrl']?.toString(),
      mediaPosition: data['mediaPosition']?.toString() ?? 'center',
      mediaAnimation: data['mediaAnimation']?.toString() ?? 'pulse',
      mediaWidth: ((data['mediaWidth'] as num?)?.toDouble() ?? 140).clamp(40.0, 320.0),
      mediaHeight: ((data['mediaHeight'] as num?)?.toDouble() ?? 140).clamp(40.0, 320.0),
      showPromoCard: data['showPromoCard'] == true,
      promoTitle: data['promoTitle']?.toString(),
      promoSubtitle: data['promoSubtitle']?.toString(),
      promoCouponCode: data['promoCouponCode']?.toString(),
      promoActionText: data['promoActionText']?.toString(),
      particleShape: data['particleShape']?.toString() ?? 'stars',
    );
  }
}

/// Ultra-Interactive Server-Driven UI (SDUI) Festive Overlay
/// Supports:
/// - Auto rising rockets with explosive firework bursts & gravity sparks.
/// - Dynamic interactive tap-to-burst fireworks anywhere the user touches.
/// - Animated GIF / Image layer with pulse, bounce, or float physics.
/// - Promo card / Festive greeting banner.
/// - Haptic feedback calibrated on explosions.
/// - Non-obtrusive with graceful auto-fade and instant dismiss button.
class FestiveThemeOverlay extends StatefulWidget {
  const FestiveThemeOverlay({super.key});

  @override
  State<FestiveThemeOverlay> createState() => _FestiveThemeOverlayState();
}

class _FestiveThemeOverlayState extends State<FestiveThemeOverlay>
    with TickerProviderStateMixin {
  late AnimationController _timelineController;
  late AnimationController _mediaAnimController;
  FestiveThemeConfig _config = const FestiveThemeConfig(enabled: false);
  bool _hasStarted = false;
  bool _isDismissed = false;

  List<_RocketLaunch> _autoRockets = [];
  final List<_InteractiveBurst> _tapBursts = [];

  @override
  void initState() {
    super.initState();
    _timelineController = AnimationController(vsync: this);
    _mediaAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  void _startTheme(FestiveThemeConfig config) {
    if (_isDismissed) return;
    _config = config;
    final totalDuration = Duration(seconds: config.durationSeconds);
    _timelineController.duration = totalDuration;

    final rnd = Random();
    final palette = config.colors.isNotEmpty ? config.colors : [config.primaryColor, config.secondaryColor];

    _autoRockets = List.generate(config.rocketCount, (index) {
      final launchDelay = 0.04 + (index * 0.12) + (rnd.nextDouble() * 0.06);
      final launchX = 0.12 + (rnd.nextDouble() * 0.76);
      final burstY = 0.14 + (rnd.nextDouble() * 0.38);
      final color = palette[index % palette.length];
      return _RocketLaunch(
        launchDelay: launchDelay.clamp(0.0, 0.75),
        launchX: launchX,
        burstY: burstY,
        color: color,
        sparkleCount: (config.sparkleDensity ~/ config.rocketCount) + 16,
        shape: config.particleShape,
      );
    });

    _hasStarted = true;
    _timelineController.forward().then((_) {
      if (mounted) {
        setState(() {
          _isDismissed = true;
        });
      }
    });
  }

  void _handleTapBurst(Offset position, Size screenSize) {
    if (!_config.interactiveTap || _isDismissed) return;

    if (_config.enableHaptics) {
      HapticService.lightImpact();
    }

    final rnd = Random();
    final palette = _config.colors.isNotEmpty ? _config.colors : [_config.primaryColor, _config.secondaryColor];
    final color = palette[rnd.nextInt(palette.length)];

    setState(() {
      _tapBursts.add(
        _InteractiveBurst(
          position: position,
          color: color,
          particleCount: 28,
          createdAtProgress: _timelineController.value,
          shape: _config.particleShape,
        ),
      );
      // Cap bursts in memory
      if (_tapBursts.length > 20) {
        _tapBursts.removeAt(0);
      }
    });
  }

  void _dismissOverlay() {
    HapticService.selection();
    setState(() {
      _isDismissed = true;
    });
  }

  @override
  void dispose() {
    _timelineController.dispose();
    _mediaAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('remote_configs')
          .doc('festive_theme')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final config = FestiveThemeConfig.fromMap(snapshot.data!.data());
        if (!config.enabled) {
          return const SizedBox.shrink();
        }

        if (!_hasStarted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_hasStarted) {
              _startTheme(config);
            }
          });
        }

        final screenSize = MediaQuery.of(context).size;
        final topPadding = MediaQuery.of(context).padding.top;

        return AnimatedBuilder(
          animation: _timelineController,
          builder: (context, child) {
            final progress = _timelineController.value;
            // Smooth fade out during last 12% of duration
            double masterOpacity = 1.0;
            if (progress > 0.88) {
              masterOpacity = ((1.0 - progress) / 0.12).clamp(0.0, 1.0);
            }

            return Opacity(
              opacity: masterOpacity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Full-screen Tap Area (spawns fireworks on user tap!)
                  if (_config.interactiveTap)
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTapDown: (details) => _handleTapBurst(details.localPosition, screenSize),
                      ),
                    ),

                  // 2. Custom Canvas Painter: Auto rockets & Interactive touch bursts
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: true,
                      child: CustomPaint(
                        painter: _InteractiveFestivePainter(
                          progress: progress,
                          rockets: _autoRockets,
                          interactiveBursts: _tapBursts,
                          sparkleColor: _config.sparkleColor,
                        ),
                      ),
                    ),
                  ),

                  // 3. Media / Animated GIF Layer (Configurable from SDUI JSON)
                  if (_config.showMedia && _config.mediaUrl != null && _config.mediaUrl!.isNotEmpty)
                    _buildMediaLayer(screenSize, topPadding),

                  // 4. Festive Greeting Floating Badge
                  if (_config.showGreetingBadge && progress > 0.05)
                    Positioned(
                      top: topPadding + 10,
                      left: 16,
                      right: 16,
                      child: Center(
                        child: IgnorePointer(
                          ignoring: true,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _config.secondaryColor.withValues(alpha: 0.94),
                                  _config.primaryColor.withValues(alpha: 0.94),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: _config.primaryColor.withValues(alpha: 0.45),
                                  blurRadius: 18,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    _config.greetingText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5,
                                      letterSpacing: 0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // 5. Promo Card (if enabled in SDUI JSON)
                  if (_config.showPromoCard && progress > 0.12 && progress < 0.85)
                    _buildPromoCard(screenSize),

                  // 6. Interactive Floating Controls: Tap hint & Skip Button
                  Positioned(
                    top: topPadding + 10,
                    right: 12,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: _dismissOverlay,
                        child: const Padding(
                          padding: EdgeInsets.all(7.0),
                          child: Icon(Icons.close_rounded, size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ),

                  // Interactive tap prompt toast
                  if (_config.interactiveTap && progress > 0.06 && progress < 0.45)
                    Positioned(
                      bottom: 85,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: IgnorePointer(
                          ignoring: true,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.60),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.touch_app_rounded, size: 14, color: Color(0xFFFFD700)),
                                SizedBox(width: 5),
                                Text(
                                  'Tap anywhere for fireworks ✨',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMediaFallback() {
    return Container(
      width: _config.mediaWidth,
      height: _config.mediaHeight,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [_config.primaryColor, _config.secondaryColor],
        ),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.flare_rounded, size: 48, color: Colors.white),
    );
  }

  /// Builds Animated Media / GIF component based on SDUI JSON
  Widget _buildMediaLayer(Size screenSize, double topPadding) {
    final rawUrl = _config.mediaUrl!;
    final isLocalAsset = rawUrl.startsWith('assets/') || rawUrl.startsWith('asset/');

    final Widget imageWidget = isLocalAsset
        ? Image.asset(
            rawUrl,
            width: _config.mediaWidth,
            height: _config.mediaHeight,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => _buildMediaFallback(),
          )
        : Image.network(
            rawUrl,
            width: _config.mediaWidth,
            height: _config.mediaHeight,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return SizedBox(
                width: _config.mediaWidth,
                height: _config.mediaHeight,
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFFFD700),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => _buildMediaFallback(),
          );

    Widget mediaContent = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: imageWidget,
    );

    // Apply configured animation physics
    if (_config.mediaAnimation == 'pulse') {
      mediaContent = AnimatedBuilder(
        animation: _mediaAnimController,
        builder: (context, child) {
          final scale = 1.0 + (_mediaAnimController.value * 0.12);
          return Transform.scale(scale: scale, child: child);
        },
        child: mediaContent,
      );
    } else if (_config.mediaAnimation == 'bounce') {
      mediaContent = AnimatedBuilder(
        animation: _mediaAnimController,
        builder: (context, child) {
          final dy = -16.0 * sin(_mediaAnimController.value * pi);
          return Transform.translate(offset: Offset(0, dy), child: child);
        },
        child: mediaContent,
      );
    } else if (_config.mediaAnimation == 'float') {
      mediaContent = AnimatedBuilder(
        animation: _mediaAnimController,
        builder: (context, child) {
          final dy = 10.0 * sin(_mediaAnimController.value * 2 * pi);
          return Transform.translate(offset: Offset(0, dy), child: child);
        },
        child: mediaContent,
      );
    }

    // Position according to SDUI JSON
    if (_config.mediaPosition == 'center') {
      return Center(
        child: IgnorePointer(
          ignoring: true,
          child: mediaContent,
        ),
      );
    } else if (_config.mediaPosition == 'bottom') {
      return Positioned(
        bottom: 110,
        left: 0,
        right: 0,
        child: Center(
          child: IgnorePointer(
            ignoring: true,
            child: mediaContent,
          ),
        ),
      );
    } else if (_config.mediaPosition == 'top') {
      return Positioned(
        top: topPadding + 55,
        left: 0,
        right: 0,
        child: Center(
          child: IgnorePointer(
            ignoring: true,
            child: mediaContent,
          ),
        ),
      );
    }

    // Default floating center
    return Center(
      child: IgnorePointer(
        ignoring: true,
        child: mediaContent,
      ),
    );
  }

  /// Builds Optional Promo / Coupon Card from SDUI JSON
  Widget _buildPromoCard(Size screenSize) {
    return Positioned(
      bottom: 120,
      left: 24,
      right: 24,
      child: Center(
        child: Container(
          width: screenSize.width > 420 ? 360 : screenSize.width * 0.88,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _config.primaryColor.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _config.primaryColor.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_config.promoTitle != null)
                Text(
                  _config.promoTitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              if (_config.promoSubtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  _config.promoSubtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
              if (_config.promoCouponCode != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFD700)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.confirmation_number_outlined, size: 14, color: Color(0xFFFFD700)),
                      const SizedBox(width: 6),
                      Text(
                        _config.promoCouponCode!,
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RocketLaunch {
  final double launchDelay;
  final double launchX;
  final double burstY;
  final Color color;
  final int sparkleCount;
  final String shape;
  late final List<_Particle> particles;

  _RocketLaunch({
    required this.launchDelay,
    required this.launchX,
    required this.burstY,
    required this.color,
    required this.sparkleCount,
    required this.shape,
  }) {
    final rnd = Random();
    particles = List.generate(sparkleCount, (i) {
      final angle = rnd.nextDouble() * 2 * pi;
      final speed = 35.0 + rnd.nextDouble() * 115.0;
      final size = 2.0 + rnd.nextDouble() * 3.8;
      return _Particle(
        angle: angle,
        speed: speed,
        size: size,
        decay: 0.7 + rnd.nextDouble() * 0.3,
      );
    });
  }
}

class _InteractiveBurst {
  final Offset position;
  final Color color;
  final int particleCount;
  final double createdAtProgress;
  final String shape;
  late final List<_Particle> particles;

  _InteractiveBurst({
    required this.position,
    required this.color,
    required this.particleCount,
    required this.createdAtProgress,
    required this.shape,
  }) {
    final rnd = Random();
    particles = List.generate(particleCount, (i) {
      final angle = rnd.nextDouble() * 2 * pi;
      final speed = 40.0 + rnd.nextDouble() * 130.0;
      final size = 2.5 + rnd.nextDouble() * 4.0;
      return _Particle(
        angle: angle,
        speed: speed,
        size: size,
        decay: 0.8 + rnd.nextDouble() * 0.2,
      );
    });
  }
}

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final double decay;

  _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.decay,
  });
}

class _InteractiveFestivePainter extends CustomPainter {
  final double progress;
  final List<_RocketLaunch> rockets;
  final List<_InteractiveBurst> interactiveBursts;
  final Color sparkleColor;

  _InteractiveFestivePainter({
    required this.progress,
    required this.rockets,
    required this.interactiveBursts,
    required this.sparkleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rocketPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final burstPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    // 1. Paint Auto Rockets & Fireworks
    for (final rocket in rockets) {
      const riseDuration = 0.18;
      final launchTime = rocket.launchDelay;
      final burstTime = launchTime + riseDuration;

      final startX = size.width * rocket.launchX;
      final startY = size.height;
      final targetY = size.height * rocket.burstY;

      if (progress >= launchTime && progress < burstTime) {
        final t = (progress - launchTime) / riseDuration;
        final currentY = startY - ((startY - targetY) * sin(t * pi / 2));

        // Rocket Trail
        final tailY = min(startY, currentY + 48.0);
        rocketPaint.color = rocket.color.withValues(alpha: 0.95);
        rocketPaint.strokeWidth = 3.2;
        canvas.drawLine(Offset(startX, tailY), Offset(startX, currentY), rocketPaint);

        // Rocket Glowing Head
        burstPaint.color = Colors.white;
        canvas.drawCircle(Offset(startX, currentY), 4.0, burstPaint);

        // Golden spark tail drops
        burstPaint.color = const Color(0xFFFFD700).withValues(alpha: 0.75);
        canvas.drawCircle(Offset(startX + (sin(t * 15) * 2), currentY + 12), 2.0, burstPaint);
        canvas.drawCircle(Offset(startX - (cos(t * 12) * 3), currentY + 24), 1.5, burstPaint);
      } else if (progress >= burstTime) {
        const explosionDuration = 0.32;
        final elapsed = progress - burstTime;
        if (elapsed < explosionDuration) {
          final t = elapsed / explosionDuration;
          final fade = (1.0 - t).clamp(0.0, 1.0);

          for (final p in rocket.particles) {
            final distance = p.speed * t;
            final gravity = 45.0 * (t * t);
            final px = startX + (cos(p.angle) * distance);
            final py = targetY + (sin(p.angle) * distance) + gravity;

            final isStar = (p.size > 3.0);
            burstPaint.color = isStar
                ? sparkleColor.withValues(alpha: fade)
                : rocket.color.withValues(alpha: fade * p.decay);

            canvas.drawCircle(Offset(px, py), p.size * (1.0 - (t * 0.4)), burstPaint);

            if (isStar && fade > 0.4) {
              final sparklePaint = Paint()
                ..color = Colors.white.withValues(alpha: fade * 0.85)
                ..strokeWidth = 1.0;
              canvas.drawLine(Offset(px - 3.5, py), Offset(px + 3.5, py), sparklePaint);
              canvas.drawLine(Offset(px, py - 3.5), Offset(px, py + 3.5), sparklePaint);
            }
          }
        }
      }
    }

    // 2. Paint Interactive Touch Bursts (Sparks spawned at tap coordinates)
    const touchExplosionDuration = 0.16;
    for (final burst in interactiveBursts) {
      final elapsed = progress - burst.createdAtProgress;
      if (elapsed >= 0 && elapsed < touchExplosionDuration) {
        final t = elapsed / touchExplosionDuration;
        final fade = (1.0 - t).clamp(0.0, 1.0);

        for (final p in burst.particles) {
          final distance = p.speed * t;
          final gravity = 35.0 * (t * t);
          final px = burst.position.dx + (cos(p.angle) * distance);
          final py = burst.position.dy + (sin(p.angle) * distance) + gravity;

          burstPaint.color = burst.color.withValues(alpha: fade * p.decay);
          canvas.drawCircle(Offset(px, py), p.size * (1.0 - (t * 0.3)), burstPaint);

          // Star sparkle twinkle
          if (p.size > 3.0 && fade > 0.3) {
            final starPaint = Paint()
              ..color = Colors.white.withValues(alpha: fade * 0.9)
              ..strokeWidth = 1.0;
            canvas.drawLine(Offset(px - 3, py), Offset(px + 3, py), starPaint);
            canvas.drawLine(Offset(px, py - 3), Offset(px, py + 3), starPaint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _InteractiveFestivePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.interactiveBursts.length != interactiveBursts.length;
  }
}
