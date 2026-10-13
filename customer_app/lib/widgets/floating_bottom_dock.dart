import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Floating Bottom Dock with transparent white water blurry glassmorphism
/// and a floating bubble capsule over the active selected page.
class FloatingBottomDock extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  const FloatingBottomDock({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(38),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A5CFF).withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xEEFFFFFF), // Transparent water glass look
          borderRadius: BorderRadius.circular(38),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(15, 23, 42, 0.08),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildTabItem(
              index: 0,
              icon: Icons.home_rounded,
              label: 'Home',
            ),
            const SizedBox(width: 4),
            _buildTabItem(
              index: 1,
              icon: Icons.explore_rounded,
              label: 'Explore',
            ),
            const SizedBox(width: 4),
            _buildTabItem(
              index: 2,
              icon: Icons.receipt_long_rounded,
              label: 'Trips',
            ),
            const SizedBox(width: 4),
            _buildTabItem(
              index: 3,
              icon: Icons.person_rounded,
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTabSelected(index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 18 : 12,
          vertical: 8,
        ),
        decoration: isSelected
            ? BoxDecoration(
                color: Colors.white, // Elevated liquid water bubble (no blue overlay)
                borderRadius: BorderRadius.circular(26),
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
                borderRadius: BorderRadius.circular(26),
              ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF3D2FD6) : const Color(0xFF64748B),
              size: 20,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
