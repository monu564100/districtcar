import 'package:flutter/material.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class AdminSidebar extends StatelessWidget {
  final String activeRoute;

  const AdminSidebar({super.key, required this.activeRoute});

  @override
  Widget build(BuildContext context) {
    final bool hasDrawer = Scaffold.maybeOf(context)?.hasDrawer ?? false;

    return Container(
      width: 260,
      color: const Color(0xFF1B2030),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 16, 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.directions_car_filled, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'DISTRICT CAR',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Operations Console',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasDrawer)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  _buildItem(context, 'Dashboard', Icons.dashboard_outlined, '/dashboard'),
                  _buildItem(context, 'Driver Earnings & Cuts', Icons.account_balance_wallet_outlined, '/driver-earnings'),
                  _buildItem(context, 'Push Broadcasts', Icons.campaign_outlined, '/notifications'),
                  _buildItem(context, 'Tourism & Destinations', Icons.travel_explore_rounded, '/destinations'),
                  _buildItem(context, 'Driver Approvals', Icons.verified_user_outlined, '/driver-verification'),
                  _buildItem(context, 'User Moderation', Icons.security_outlined, '/users'),
                  _buildItem(context, 'Remote App Updates', Icons.system_update_alt, '/remote-updates'),
                  _buildItem(context, 'Fares & Dynamic Pricing', Icons.payments_outlined, '/fares'),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(color: Colors.white12, height: 1),
                  ),
                  _buildItem(context, 'Lock Console', Icons.lock_outline, '/admin-login'),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, String title, IconData icon, String route) {
    final isSelected = activeRoute == route;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.18) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isSelected ? Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1) : null,
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Icon(
          icon,
          color: isSelected ? AppColors.accent : const Color(0xFF94A3B8),
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13.5,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () {
          if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
            Navigator.of(context).maybePop();
          }
          if (!isSelected) {
            context.go(route);
          }
        },
      ),
    );
  }
}
