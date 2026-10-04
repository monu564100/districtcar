import 'package:flutter/material.dart';
import 'package:district_car_shared/theme/app_theme.dart';

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
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2030),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildPillTab(
            index: 0,
            icon: Icons.home_rounded,
            label: 'Home',
          ),
          _buildIconTab(
            index: 1,
            icon: Icons.receipt_long_rounded,
          ),
          _buildIconTab(
            index: 2,
            icon: Icons.account_balance_wallet_outlined,
          ),
          _buildIconTab(
            index: 3,
            icon: Icons.person_outline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildPillTab({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = currentIndex == index;
    if (isSelected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    return _buildIconTab(index: index, icon: icon);
  }

  Widget _buildIconTab({
    required int index,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: () => onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Icon(
          icon,
          color: const Color(0xFF8E95A5),
          size: 22,
        ),
      ),
    );
  }
}
