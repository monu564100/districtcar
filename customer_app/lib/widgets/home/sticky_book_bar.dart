import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../services/haptic_service.dart';

/// Sticky Bottom Bar: Fixed 58h book ride button + water-glass navigation dock
/// Features sleek translucent water styling and an active floating bubble pill over the selected page.
class StickyBookBar extends StatefulWidget {
  final String vehicleName;
  final double fare;
  final bool isServiceable;
  final bool isDestinationSelected;
  final bool isLoading;
  final VoidCallback onBook;
  final int currentNavIndex;
  final Function(int) onNavSelected;
  final bool isHindi;

  const StickyBookBar({
    super.key,
    required this.vehicleName,
    required this.fare,
    this.isServiceable = true,
    required this.isDestinationSelected,
    this.isLoading = false,
    required this.onBook,
    required this.currentNavIndex,
    required this.onNavSelected,
    this.isHindi = false,
  });

  @override
  State<StickyBookBar> createState() => _StickyBookBarState();
}

class _StickyBookBarState extends State<StickyBookBar> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool canBook = widget.isDestinationSelected && widget.isServiceable && !widget.isLoading;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFEEF0F6), width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(11, 16, 32, 0.06),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Primary Action Button (Height 58)
          SizedBox(
            width: double.infinity,
            height: AppTokens.primaryButtonHeight,
            child: AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return ElevatedButton(
                  onPressed: canBook
                      ? () {
                          HapticService.buttonPress();
                          widget.onBook();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canBook ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
                    foregroundColor: Colors.white,
                    elevation: canBook ? 4 : 0,
                    shadowColor: const Color(0xFF0F172A).withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusButtons),
                    ),
                  ),
                  child: widget.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.directions_car_rounded, size: 20, color: Colors.white),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                !widget.isDestinationSelected
                                    ? (widget.isHindi ? 'कहाँ जाना है? चुनें' : 'Select Destination')
                                    : !widget.isServiceable
                                        ? (widget.isHindi ? 'दूरी सीमा से बाहर है' : 'Out of Service Range')
                                        : '${widget.isHindi ? "बुक करें" : "Book"} ${widget.vehicleName} • ₹${widget.fare.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // 2. Floating Labeled Bottom Navigation Dock (Water glass with liquid bubble over selected page)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9), // Translucent liquid water base
              borderRadius: BorderRadius.circular(34),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(15, 23, 42, 0.04),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, widget.isHindi ? 'होम' : 'Home'),
                _buildNavItem(1, Icons.explore_rounded, widget.isHindi ? 'एक्सप्लोर' : 'Explore'),
                _buildNavItem(2, Icons.receipt_long_rounded, widget.isHindi ? 'सफर' : 'Trips'),
                _buildNavItem(3, Icons.person_rounded, widget.isHindi ? 'प्रोफाइल' : 'Profile'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Navigation Tab item with liquid white water bubble pill over selected page
  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = widget.currentNavIndex == index;

    return GestureDetector(
      onTap: () {
        HapticService.selection();
        widget.onNavSelected(index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 18 : 10,
          vertical: 6,
        ),
        decoration: isSelected
            ? BoxDecoration(
                color: Colors.white, // Elevated liquid water bubble (No blue overlay)
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white,
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(15, 23, 42, 0.09),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                  BoxShadow(
                    color: Color.fromRGBO(255, 255, 255, 0.95),
                    blurRadius: 2,
                    offset: Offset(0, -1),
                  ),
                ],
              )
            : BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 19,
              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                letterSpacing: isSelected ? -0.1 : 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
