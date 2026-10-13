import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../services/haptic_service.dart';

/// Collapsible Fare Summary Card in Dark Gradient (#0B1020 → #1B2347)
/// Features animated rolling counter, distance • duration, and expandable breakdown.
class FareCard extends StatefulWidget {
  final double totalFare;
  final double distanceKm;
  final String formattedDuration;
  final bool isRoundTrip;
  final double baseFare;
  final double distanceFare;
  final double returnAllowance;
  final bool isHindi;

  const FareCard({
    super.key,
    required this.totalFare,
    required this.distanceKm,
    required this.formattedDuration,
    required this.isRoundTrip,
    this.baseFare = 60.0,
    this.distanceFare = 0.0,
    this.returnAllowance = 0.0,
    this.isHindi = false,
  });

  @override
  State<FareCard> createState() => _FareCardState();
}

class _FareCardState extends State<FareCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: AppTokens.fareDarkGradient,
        borderRadius: BorderRadius.circular(AppTokens.radiusCards),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(11, 16, 32, 0.35),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main Collapsible Bar
          InkWell(
            onTap: () {
              HapticService.selection();
              setState(() => _isExpanded = !_isExpanded);
            },
            borderRadius: BorderRadius.circular(AppTokens.radiusCards),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  // Rolling counter Fare
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: widget.totalFare, end: widget.totalFare),
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Text(
                                  '₹${value.round()}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 25,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                    fontFeatures: [FontFeature.tabularFigures()],
                                  ),
                                );
                              },
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A).withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                widget.isHindi ? 'फिक्स रेट' : 'Fixed price, no surge',
                                style: const TextStyle(
                                  color: Color(0xFF4ADE80),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.distanceKm.toStringAsFixed(1)} km  •  ${widget.formattedDuration}${widget.isRoundTrip ? (widget.isHindi ? '  •  राउंड ट्रिप' : '  •  Round trip') : ''}',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Expand breakdown chevron
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded Breakdown Drawer
          if (_isExpanded) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
              child: Column(
                children: [
                  const Divider(color: Color(0xFF334155), height: 16),
                  _buildBreakdownRow(
                    widget.isHindi ? 'बेस किराया' : 'Base fare',
                    '₹${widget.baseFare.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 6),
                  _buildBreakdownRow(
                    widget.isHindi ? 'दूरी शुल्क' : 'Distance charges',
                    '₹${(widget.totalFare - widget.baseFare).clamp(0, 99999).toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 6),
                  _buildBreakdownRow(
                    widget.isHindi ? 'ग्रामीण ड्राइवर रिटर्न भत्ता' : 'Village return guarantee',
                    widget.isHindi ? 'शामिल (₹0 अतिरिक्त)' : 'Included (₹0 extra)',
                    isHighlight: true,
                  ),
                  const SizedBox(height: 6),
                  _buildBreakdownRow(
                    widget.isHindi ? 'जीएसटी एवं टैक्स' : 'Taxes & tolls',
                    '₹0 (No surge)',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String title, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isHighlight ? const Color(0xFFFBBF24) : const Color(0xFFCBD5E1),
            fontSize: 11.5,
            fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isHighlight ? const Color(0xFFFBBF24) : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
