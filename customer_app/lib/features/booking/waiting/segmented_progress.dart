import 'package:flutter/material.dart';
import '../../../../theme/theme.dart';

/// Segmented Progress Track for Ride Search
/// 4 distinct milestone segments:
/// 0: Request sent
/// 1: Drivers notified
/// 2: Waiting for accept
/// 3: Driver assigned
///
/// Completed segments fill green (#2E9E5B) with spring animation.
/// Active segment exhibits a soft Marigold (#F4A62A) ambient shimmer.
/// Never displays a fake percentage.
class SegmentedProgress extends StatefulWidget {
  final int activeStep; // 0 to 3

  const SegmentedProgress({
    super.key,
    required this.activeStep,
  });

  @override
  State<SegmentedProgress> createState() => _SegmentedProgressState();
}

class _SegmentedProgressState extends State<SegmentedProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  static const List<String> _segmentLabels = [
    'Request sent',
    'Drivers notified',
    'Waiting for accept',
    'Driver assigned',
  ];

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 4 Horizontal Segments
        Row(
          children: List.generate(4, (index) {
            final isCompleted = index < widget.activeStep;
            final isActive = index == widget.activeStep;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index < 3 ? 6.0 : 0.0),
                child: SizedBox(
                  height: 5.5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Stack(
                      children: [
                        // Background track
                        Container(color: AppTokens.border),

                        // Completed or Active fill
                        if (isCompleted)
                          Container(
                            decoration: BoxDecoration(
                              color: AppTokens.success,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          )
                        else if (isActive)
                          AnimatedBuilder(
                            animation: _shimmerController,
                            builder: (context, _) {
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTokens.marigold.withOpacity(0.40),
                                      AppTokens.marigold,
                                      AppTokens.marigoldDark,
                                      AppTokens.marigold.withOpacity(0.40),
                                    ],
                                    stops: const [0.0, 0.45, 0.65, 1.0],
                                    transform: GradientRotation(
                                      _shimmerController.value * 2 * 3.14159,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),

        // Active Step Label & Milestone Description
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step ${widget.activeStep + 1} of 4: ${_segmentLabels[widget.activeStep.clamp(0, 3)]}',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppTokens.primaryDark,
              ),
            ),
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_outlined, size: 13, color: AppTokens.primary),
                SizedBox(width: 4),
                Text(
                  '100% Guaranteed',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppTokens.secondaryText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
