import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Server-Driven UI (SDUI) Festive Theme Model
/// Stored in Firestore `remote_configs/festive_theme`
class FestiveThemeConfig {
  final bool enabled;
  final String theme; // e.g., 'diwali_rockets', 'new_year', 'holi'
  final int durationSeconds; // 5 - 10 seconds
  final Color primaryColor;
  final Color secondaryColor;
  final Color sparkleColor;
  final int rocketCount;
  final int sparkleDensity;
  final bool showGreetingBadge;
  final String greetingText;

  const FestiveThemeConfig({
    this.enabled = true,
    this.theme = 'diwali_rockets',
    this.durationSeconds = 8,
    this.primaryColor = const Color(0xFFFFD700), // Gold
    this.secondaryColor = const Color(0xFFFF5722), // Festive Orange/Red
    this.sparkleColor = const Color(0xFFFFFFFF), // White star
    this.rocketCount = 5,
    this.sparkleDensity = 40,
    this.showGreetingBadge = true,
    this.greetingText = '✨ Shubh Deepawali from District Car ✨',
  });

  factory FestiveThemeConfig.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const FestiveThemeConfig(enabled: false);

    Color parseColor(dynamic val, Color fallback) {
      if (val == null) return fallback;
      if (val is int) return Color(val);
      if (val is String) {
        String hex = val.replaceAll('#', '');
        if (hex.length == 6) hex = 'FF$hex';
        final int? parsed = int.tryParse(hex, radix: 16);
        if (parsed != null) return Color(parsed);
      }
      return fallback;
    }

    return FestiveThemeConfig(
      enabled: data['enabled'] == true,
      theme: data['theme']?.toString() ?? 'diwali_rockets',
      durationSeconds: ((data['durationSeconds'] as num?)?.toInt() ?? 8).clamp(5, 10),
      primaryColor: parseColor(data['primaryColor'], const Color(0xFFFFD700)),
      secondaryColor: parseColor(data['secondaryColor'], const Color(0xFFFF5722)),
      sparkleColor: parseColor(data['sparkleColor'], const Color(0xFFFFFFFF)),
      rocketCount: ((data['rocketCount'] as num?)?.toInt() ?? 5).clamp(2, 12),
      sparkleDensity: ((data['sparkleDensity'] as num?)?.toInt() ?? 40).clamp(15, 80),
      showGreetingBadge: data['showGreetingBadge'] != false,
      greetingText: data['greetingText']?.toString() ?? '✨ Shubh Deepawali from District Car ✨',
    );
  }
}

/// Festive Server-Driven UI Non-blocking Overlay
/// Renders Diwali rocket fireworks & sparkling particle animation for 5-10 seconds.
/// Does NOT obstruct or alter any underlying home page widgets.
class FestiveThemeOverlay extends StatefulWidget {
  const FestiveThemeOverlay({super.key});

  @override
  State<FestiveThemeOverlay> createState() => _FestiveThemeOverlayState();
}

class _FestiveThemeOverlayState extends State<FestiveThemeOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  FestiveThemeConfig _config = const FestiveThemeConfig(enabled: false);
  bool _hasStarted = false;
  bool _isFinished = false;
  List<_RocketExplosion> _rockets = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  void _startAnimation(FestiveThemeConfig config) {
    if (_isFinished) return;
    _config = config;
    final totalDuration = Duration(seconds: config.durationSeconds);
    _controller.duration = totalDuration;

    // Seed randomized rockets
    final rnd = Random();
    _rockets = List.generate(config.rocketCount, (index) {
      // Launch time staggered across the first 65% of duration
      final launchDelay = 0.05 + (index * 0.14) + (rnd.nextDouble() * 0.08);
      final launchX = 0.15 + (rnd.nextDouble() * 0.70); // screen X ratio
      final burstY = 0.15 + (rnd.nextDouble() * 0.35); // burst Y ratio (upper half)
      final burstColor = (index % 2 == 0) ? config.primaryColor : config.secondaryColor;
      return _RocketExplosion(
        launchDelay: launchDelay.clamp(0.0, 0.8),
        launchX: launchX,
        burstY: burstY,
        color: burstColor,
        sparkleCount: config.sparkleDensity ~/ config.rocketCount + 15,
      );
    });

    _hasStarted = true;
    _controller.forward().then((_) {
      if (mounted) {
        setState(() {
          _isFinished = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinished) {
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
              _startAnimation(config);
            }
          });
        }

        return IgnorePointer(
          ignoring: true, // Absolutely non-blocking
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final progress = _controller.value;
              // Fade out during the last 15% of animation
              double opacity = 1.0;
              if (progress > 0.85) {
                opacity = ((1.0 - progress) / 0.15).clamp(0.0, 1.0);
              }

              return Opacity(
                opacity: opacity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Canvas fireworks animation
                    CustomPaint(
                      painter: _FestiveFireworksPainter(
                        progress: progress,
                        rockets: _rockets,
                        sparkleColor: _config.sparkleColor,
                      ),
                    ),

                    // Optional Festive Floating Pill at top
                    if (_config.showGreetingBadge && progress > 0.08)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 10,
                        left: 20,
                        right: 20,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _config.secondaryColor.withValues(alpha: 0.92),
                                  _config.primaryColor.withValues(alpha: 0.92),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: _config.primaryColor.withValues(alpha: 0.4),
                                  blurRadius: 16,
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
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _RocketExplosion {
  final double launchDelay;
  final double launchX;
  final double burstY;
  final Color color;
  final int sparkleCount;
  late final List<_SparkleParticle> particles;

  _RocketExplosion({
    required this.launchDelay,
    required this.launchX,
    required this.burstY,
    required this.color,
    required this.sparkleCount,
  }) {
    final rnd = Random();
    particles = List.generate(sparkleCount, (i) {
      final angle = rnd.nextDouble() * 2 * pi;
      final speed = 30.0 + rnd.nextDouble() * 110.0;
      final size = 2.0 + rnd.nextDouble() * 3.5;
      return _SparkleParticle(
        angle: angle,
        speed: speed,
        size: size,
        decay: 0.7 + rnd.nextDouble() * 0.3,
      );
    });
  }
}

class _SparkleParticle {
  final double angle;
  final double speed;
  final double size;
  final double decay;

  _SparkleParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.decay,
  });
}

class _FestiveFireworksPainter extends CustomPainter {
  final double progress;
  final List<_RocketExplosion> rockets;
  final Color sparkleColor;

  _FestiveFireworksPainter({
    required this.progress,
    required this.rockets,
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

    for (final rocket in rockets) {
      // Rocket rise duration is 0.18 in normalized progress
      const riseDuration = 0.18;
      final launchTime = rocket.launchDelay;
      final burstTime = launchTime + riseDuration;

      final startX = size.width * rocket.launchX;
      final startY = size.height;
      final targetY = size.height * rocket.burstY;

      // 1. Rising rocket phase
      if (progress >= launchTime && progress < burstTime) {
        final t = (progress - launchTime) / riseDuration;
        // Ease-out curve for rising rocket
        final currentY = startY - ((startY - targetY) * sin(t * pi / 2));

        // Rocket trail tail
        final tailY = min(startY, currentY + 45.0);
        rocketPaint.color = rocket.color.withValues(alpha: 0.9);
        rocketPaint.strokeWidth = 3.0;
        canvas.drawLine(Offset(startX, tailY), Offset(startX, currentY), rocketPaint);

        // Rocket glowing head
        burstPaint.color = Colors.white;
        canvas.drawCircle(Offset(startX, currentY), 3.5, burstPaint);

        // Golden spark tail drops
        burstPaint.color = const Color(0xFFFFD700).withValues(alpha: 0.7);
        canvas.drawCircle(Offset(startX + (sin(t * 15) * 2), currentY + 12), 2.0, burstPaint);
        canvas.drawCircle(Offset(startX - (cos(t * 12) * 3), currentY + 24), 1.5, burstPaint);
      }
      // 2. Exploding spark / firework burst phase
      else if (progress >= burstTime) {
        // Explosion lasts up to 0.32 in normalized progress
        const explosionDuration = 0.32;
        final elapsed = progress - burstTime;
        if (elapsed < explosionDuration) {
          final t = elapsed / explosionDuration;
          final fade = (1.0 - t).clamp(0.0, 1.0);

          for (final p in rocket.particles) {
            final distance = p.speed * t;
            // Gravity effect pulling sparks downward
            final gravity = 45.0 * (t * t);
            final px = startX + (cos(p.angle) * distance);
            final py = targetY + (sin(p.angle) * distance) + gravity;

            // Sparkle color alternating with gold
            final isStar = (p.size > 3.0);
            burstPaint.color = isStar
                ? sparkleColor.withValues(alpha: fade)
                : rocket.color.withValues(alpha: fade * p.decay);

            // Draw sparkling star/circle
            canvas.drawCircle(Offset(px, py), p.size * (1.0 - (t * 0.4)), burstPaint);

            // Subtle sparkle cross on bigger particles
            if (isStar && fade > 0.4) {
              final sparklePaint = Paint()
                ..color = Colors.white.withValues(alpha: fade * 0.8)
                ..strokeWidth = 1.0;
              canvas.drawLine(Offset(px - 3, py), Offset(px + 3, py), sparklePaint);
              canvas.drawLine(Offset(px, py - 3), Offset(px, py + 3), sparklePaint);
            }
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FestiveFireworksPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
