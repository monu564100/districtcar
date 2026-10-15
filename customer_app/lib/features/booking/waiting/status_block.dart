import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../theme/theme.dart';
import 'segmented_progress.dart';

/// Status Block placed directly underneath the hero radar scene.
/// Features a serif status headline, 4s cross-fading rotating sub-messages with 8px slide-up,
/// 4-segment progress track, and tabular figures elapsed timer with typical-wait hint.
class StatusBlock extends StatefulWidget {
  final int elapsedSeconds;
  final int activeProgressStep;
  final String? customHeadline;
  final String? customSubMessage;

  const StatusBlock({
    super.key,
    required this.elapsedSeconds,
    required this.activeProgressStep,
    this.customHeadline,
    this.customSubMessage,
  });

  @override
  State<StatusBlock> createState() => _StatusBlockState();
}

class _StatusBlockState extends State<StatusBlock> {
  bool _isEnglish = false;
  int _messageIndex = 0;
  Timer? _rotationTimer;

  static const List<Map<String, String>> _rotatingMessages = [
    {
      'hi': 'Aas-paas ke drivers ko request bhej di gayi hai',
      'en': 'Request dispatched to all verified nearby drivers',
    },
    {
      'hi': 'Village Return Guarantee: aapki ride 100% accept hogi',
      'en': 'Village Return Guarantee: guaranteed ride acceptance',
    },
    {
      'hi': 'Fixed price. Koi extra charge nahi.',
      'en': 'Fixed price guarantee. Zero surge or hidden charges.',
    },
    {
      'hi': 'Verified local drivers, 24x7 support',
      'en': 'Verified Jharkhand drivers, 24x7 live phone support',
    },
  ];

  @override
  void initState() {
    super.initState();
    _rotationTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _rotatingMessages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    super.dispose();
  }

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString()}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final headline = widget.customHeadline ??
        (_isEnglish ? 'Finding your driver…' : 'Aapke liye driver dhundh rahe hain…');

    final subMessage = widget.customSubMessage ??
        (_isEnglish
            ? _rotatingMessages[_messageIndex]['en']!
            : _rotatingMessages[_messageIndex]['hi']!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: const BoxDecoration(
        color: AppTokens.surface,
        border: Border(
          bottom: BorderSide(color: AppTokens.border, width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Headline + Language Toggle
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  headline,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 24,
                    height: 1.22,
                    fontWeight: FontWeight.w800,
                    color: AppTokens.ink,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // EN / हिन्दी Language Toggle Pill
              InkWell(
                onTap: () => setState(() => _isEnglish = !_isEnglish),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTokens.surface2,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTokens.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.language_rounded, size: 14, color: AppTokens.primary),
                      const SizedBox(width: 4),
                      Text(
                        _isEnglish ? 'EN' : 'हिन्दी',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTokens.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 4-second Animated Cross-fading Sub-message with 8px Slide-up
          SizedBox(
            height: 24,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, animation) {
                final slideIn = Tween<Offset>(
                  begin: const Offset(0, 0.35),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: slideIn, child: child),
                );
              },
              child: Row(
                key: ValueKey<String>(subMessage),
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 14,
                    color: AppTokens.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      subMessage,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppTokens.secondaryText,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Segmented Progress Track (4 steps)
          SegmentedProgress(activeStep: widget.activeProgressStep),
          const SizedBox(height: 14),

          // Live Timer Row (Tabular Figures) + Typical Wait Hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTokens.primaryTint.withOpacity(0.55),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTokens.primaryTint),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, size: 16, color: AppTokens.primaryDark),
                    const SizedBox(width: 6),
                    Text(
                      'Elapsed: ',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppTokens.primaryDark.withOpacity(0.85),
                      ),
                    ),
                    Text(
                      _formatTimer(widget.elapsedSeconds),
                      style: const TextStyle(
                        fontFeatures: [FontFeature.tabularFigures()],
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTokens.primaryDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Text(
                  _isEnglish ? 'Typical wait: 1–3 mins' : 'Aam taur par 1–3 minute',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTokens.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
