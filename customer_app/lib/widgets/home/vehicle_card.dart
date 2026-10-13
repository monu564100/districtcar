import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../services/haptic_service.dart';

/// Compact & Responsive Vehicle Selection Card
/// Optimized proportions with sleek vehicle asset rendering and overflow prevention
class VehicleCard extends StatefulWidget {
  final String id;
  final String name;
  final String displayName;
  final String imageAsset;
  final double fare;
  final String eta;
  final int seats;
  final String? badgeTag; // e.g. "Cheapest", "Popular", "Fastest"
  final bool isSelected;
  final bool isServiceable;
  final VoidCallback onSelect;

  const VehicleCard({
    super.key,
    required this.id,
    required this.name,
    required this.displayName,
    required this.imageAsset,
    required this.fare,
    this.eta = '3 min',
    this.seats = 4,
    this.badgeTag,
    required this.isSelected,
    this.isServiceable = true,
    required this.onSelect,
  });

  @override
  State<VehicleCard> createState() => _VehicleCardState();
}

class _VehicleCardState extends State<VehicleCard> with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _floatAnim = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    if (widget.isSelected) {
      _floatController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(VehicleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !_floatController.isAnimating) {
      _floatController.repeat(reverse: true);
    } else if (!widget.isSelected && _floatController.isAnimating) {
      _floatController.stop();
      _floatController.reset();
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.selection();
        widget.onSelect();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: 104,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        decoration: BoxDecoration(
          color: widget.isSelected ? Colors.white : const Color(0xFFFAFAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.isSelected ? const Color(0xFF6A5CFF) : const Color(0xFFE2E8F0),
            width: widget.isSelected ? 1.8 : 1.0,
          ),
          boxShadow: widget.isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6A5CFF).withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Badge Tag or ETA + Check badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.badgeTag != null)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: widget.badgeTag == 'Cheapest' || widget.badgeTag == 'सबसे सस्ता'
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        widget.badgeTag!,
                        style: TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w800,
                          color: widget.badgeTag == 'Cheapest' || widget.badgeTag == 'सबसे सस्ता'
                              ? const Color(0xFF15803D)
                              : const Color(0xFFB45309),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                else
                  Text(
                    widget.eta,
                    style: const TextStyle(fontSize: 8.5, color: AppTokens.textHint, fontWeight: FontWeight.w700),
                  ),
                if (widget.isSelected)
                  Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3D2FD6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 9),
                  ),
              ],
            ),

            // Vehicle Image (Compact 32px height)
            Center(
              child: AnimatedBuilder(
                animation: _floatAnim,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, widget.isSelected ? _floatAnim.value : 0),
                    child: child,
                  );
                },
                child: SizedBox(
                  height: 32,
                  child: Image.asset(
                    widget.imageAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Image.asset(
                      widget.imageAsset.replaceAll('.png', '.jpg'),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.directions_car_filled_rounded,
                        size: 26,
                        color: Color(0xFF6A5CFF),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Info: Name & Seats
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.displayName,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppTokens.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person, size: 9, color: AppTokens.textHint),
                    Text(
                      '${widget.seats}',
                      style: const TextStyle(fontSize: 8.5, color: AppTokens.textHint, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),

            // Fare Price
            Text(
              widget.isServiceable ? '₹${widget.fare.toStringAsFixed(0)}' : 'Unavailable',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: widget.isServiceable ? const Color(0xFF0F172A) : AppTokens.textHint,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
