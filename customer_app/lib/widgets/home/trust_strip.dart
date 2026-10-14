import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// Trust Strip: Horizontal trust credentials near top of fold
class TrustStrip extends StatelessWidget {
  final bool isHindi;

  const TrustStrip({super.key, this.isHindi = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppTokens.radiusChips),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildPill(
            icon: Icons.shield_rounded,
            iconColor: const Color(0xFFF59E0B),
            label: isHindi ? 'रिटर्न गारंटी' : 'Return Guarantee',
          ),
          Container(height: 14, width: 1, color: const Color(0xFFCBD5E1)),
          _buildPill(
            icon: Icons.verified_user_rounded,
            iconColor: const Color(0xFFD97706),
            label: isHindi ? 'सत्यापित ड्राइवर' : 'Verified Drivers',
          ),
          Container(height: 14, width: 1, color: const Color(0xFFCBD5E1)),
          _buildPill(
            icon: Icons.support_agent_rounded,
            iconColor: const Color(0xFF0F172A),
            label: isHindi ? '24x7 हेल्पलाइन' : '24x7 Helpline',
          ),
        ],
      ),
    );
  }

  Widget _buildPill({
    required IconData icon,
    required Color iconColor,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppTokens.ink,
          ),
        ),
      ],
    );
  }
}
