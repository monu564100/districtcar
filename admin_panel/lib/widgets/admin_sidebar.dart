import 'package:flutter/material.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class AdminSidebar extends StatelessWidget {
  final String activeRoute;

  const AdminSidebar({super.key, required this.activeRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: const Color(0xFF1B2030),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.directions_car_filled, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Text(
                  'DISTRICT CAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 16),
          _buildItem(context, 'Dashboard', Icons.dashboard_outlined, '/dashboard'),
          _buildItem(context, 'Driver Trips & Commission', Icons.account_balance_wallet_outlined, '/driver-earnings'),
          _buildItem(context, 'Push Notifications & Offers', Icons.campaign_outlined, '/notifications'),
          _buildItem(context, 'Tours & Popular Places', Icons.travel_explore_rounded, '/destinations'),
          _buildItem(context, 'Driver Verifications', Icons.verified_user_outlined, '/driver-verification'),
          _buildItem(context, 'User Moderation & Block', Icons.security_outlined, '/users'),
          _buildItem(context, 'Remote App Updates', Icons.system_update_alt, '/remote-updates'),
          _buildItem(context, 'Dynamic Fares & Pricing', Icons.payments_outlined, '/fares'),
          const Spacer(),
          _buildItem(context, 'Lock Console', Icons.lock_outline, '/admin-login'),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, String title, IconData icon, String route) {
    final isSelected = activeRoute == route;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.accent : const Color(0xFF8E95A5), size: 20),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF8E95A5),
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 14,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withOpacity(0.15),
      onTap: () {
        if (!isSelected) {
          context.go(route);
        }
      },
    );
  }
}
