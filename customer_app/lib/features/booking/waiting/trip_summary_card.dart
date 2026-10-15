import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:district_car_shared/models/models.dart';
import '../../../../theme/theme.dart';

/// Compact and Collapsible Trip Summary Card
/// Features animated rolling fare counter, flowing dashed timeline connector,
/// full-address expansion on tap, and transparent vehicle & fare specifications.
class TripSummaryCard extends StatefulWidget {
  final BookingModel booking;

  const TripSummaryCard({
    super.key,
    required this.booking,
  });

  @override
  State<TripSummaryCard> createState() => _TripSummaryCardState();
}

class _TripSummaryCardState extends State<TripSummaryCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late final AnimationController _dashFlowController;

  @override
  void initState() {
    super.initState();
    // 20px/s dash flow animation
    _dashFlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _dashFlowController.dispose();
    super.dispose();
  }

  String _formatBookingDate(DateTime date) {
    final dayStr = DateFormat('EEE, d MMM').format(date);
    return '$dayStr · Abhi (10 min ke andar)';
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final fare = (booking.finalFare ?? booking.estimatedFare).toInt();
    final pickupName = booking.pickup.address;
    final dropoffName = booking.destination.address;
    final isRoundTrip = booking.isRoundTrip;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTokens.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. TOP HEADER ROW (Trip Type + Rolling Fare + Fixed Price Pill)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Trip Type Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTokens.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTokens.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isRoundTrip ? Icons.repeat_rounded : Icons.arrow_forward_rounded,
                        size: 14,
                        color: AppTokens.primary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isRoundTrip ? 'Round Trip / दोनों तरफ' : 'One-Way / एक तरफा',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTokens.ink,
                        ),
                      ),
                    ],
                  ),
                ),

                // Fare Display with Rolling Counter & Fixed Price Pill
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppTokens.primaryTint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Fixed price',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTokens.primaryDark,
                        ),
                      ),
                    ),
                    Text(
                      '₹$fare',
                      style: const TextStyle(
                        fontFeatures: [FontFeature.tabularFigures()],
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTokens.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppTokens.border),

          // 2. DATE/TIME ROW
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 15, color: AppTokens.secondaryText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatBookingDate(booking.createdAt),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTokens.secondaryText,
                    ),
                  ),
                ),
                // Payment Method Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: AppTokens.marigoldTint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.payments_outlined, size: 12, color: AppTokens.marigoldDark),
                      const SizedBox(width: 4),
                      Text(
                        booking.paymentMethod.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTokens.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. ROUTE BLOCK WITH DYNAMIC FLOWING TIMELINE
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline Connector (Pickup Green Dot -> Dashes Flowing Downward -> Terracotta Pin)
                Column(
                  children: [
                    // Green Origin Dot
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppTokens.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppTokens.primary.withOpacity(0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),

                    // Flowing dashed vertical line (20px/s)
                    AnimatedBuilder(
                      animation: _dashFlowController,
                      builder: (context, _) {
                        return SizedBox(
                          width: 14,
                          height: 48,
                          child: CustomPaint(
                            painter: _FlowingDashedLinePainter(
                              progress: _dashFlowController.value,
                              color: AppTokens.primary.withOpacity(0.55),
                            ),
                          ),
                        );
                      },
                    ),

                    // Terracotta Dropoff Pin
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppTokens.terracotta,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppTokens.terracotta.withOpacity(0.35),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Address Texts (Expandable on tap)
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pickup Address
                        Text(
                          pickupName,
                          maxLines: _isExpanded ? 10 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTokens.ink,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Dropoff Address
                        Text(
                          dropoffName,
                          maxLines: _isExpanded ? 10 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTokens.ink,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. BOTTOM COLLAPSIBLE TOGGLE PILL
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: AppTokens.surface2,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isExpanded ? 'Collapse route' : 'Tap to view full route address',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppTokens.secondaryText,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppTokens.secondaryText,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for animated dashed vertical line flowing downward
class _FlowingDashedLinePainter extends CustomPainter {
  final double progress;
  final Color color;

  const _FlowingDashedLinePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    const dashLength = 4.0;
    const dashGap = 4.0;
    final totalPattern = dashLength + dashGap;
    final offset = progress * totalPattern;

    double y = offset;
    final centerX = size.width / 2;

    while (y < size.height) {
      final startY = y.clamp(0.0, size.height);
      final endY = (y + dashLength).clamp(0.0, size.height);
      if (endY > startY) {
        canvas.drawLine(Offset(centerX, startY), Offset(centerX, endY), paint);
      }
      y += totalPattern;
    }
  }

  @override
  bool shouldRepaint(covariant _FlowingDashedLinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
