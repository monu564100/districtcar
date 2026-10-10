import 'package:flutter/material.dart';

/// Mobbin & iOS-inspired animated empty state widget.
/// Features a breathing ambient glow, smooth floating image/icon, refined typography,
/// and an interactive call to action button.
class PremiumEmptyState extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? imageAsset;
  final IconData? fallbackIcon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? glowColor;

  const PremiumEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.imageAsset,
    this.fallbackIcon,
    this.actionLabel,
    this.onAction,
    this.glowColor,
  });

  @override
  State<PremiumEmptyState> createState() => _PremiumEmptyStateState();
}

class _PremiumEmptyStateState extends State<PremiumEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _floatAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _pulseAnim = Tween<double>(begin: 0.88, end: 1.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveGlow = widget.glowColor ?? const Color(0xFF384CF5);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Floating & glowing ambient illustration container
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatAnim.value),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ambient light pulse
                      Transform.scale(
                        scale: _pulseAnim.value,
                        child: Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                effectiveGlow.withValues(alpha: 0.22),
                                effectiveGlow.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Core visual: image or vector illustration
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: effectiveGlow.withValues(alpha: 0.25),
                              blurRadius: 28,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: widget.imageAsset != null
                              ? Image.asset(
                                  widget.imageAsset!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _buildFallbackIcon(effectiveGlow),
                                )
                              : _buildFallbackIcon(effectiveGlow),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 26),

            // Typography & Visual Hierarchy
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Interactive Call to action
            if (widget.actionLabel != null && widget.onAction != null)
              ElevatedButton(
                onPressed: widget.onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.actionLabel!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackIcon(Color glow) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Icon(
          widget.fallbackIcon ?? Icons.search_off_rounded,
          size: 54,
          color: glow,
        ),
      ),
    );
  }
}
