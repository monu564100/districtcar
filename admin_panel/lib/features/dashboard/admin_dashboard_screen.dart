import 'package:flutter/material.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import '../../widgets/admin_sidebar.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const AdminSidebar(activeRoute: '/dashboard'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Operations Overview',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  const Text('Real-time system health and platform performance metrics.', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 32),
                  // KPI Grid
                  Row(
                    children: [
                      _buildMetricCard('Total Bookings', '1,280', '+14% this week', AppColors.primary),
                      const SizedBox(width: 20),
                      _buildMetricCard('Active Online Drivers', '42', 'High availability', AppColors.success),
                      const SizedBox(width: 20),
                      _buildMetricCard('Pending Approvals', '7', 'Requires review', AppColors.warning),
                      const SizedBox(width: 20),
                      _buildMetricCard("Gross Revenue", '₹182,450', '+22% growth', const Color(0xFF6366F1)),
                    ],
                  ),
                  const SizedBox(height: 36),
                  // Operations Table Container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Recent Live Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildActivityRow('DC-20261004-9102', 'Car', 'Sonu Kumar', 'Carlos Santos', '₹240', 'Completed'),
                        _buildActivityRow('DC-20261004-8931', 'Bike', 'Muhammad A.', 'Deepak Verma', '₹65', 'In Progress'),
                        _buildActivityRow('DC-20261004-7622', 'Auto', 'Priya S.', 'Rajesh Kumar', '₹110', 'Searching'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String val, String sub, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text(val, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 8),
            Text(sub, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityRow(String id, String cat, String customer, String driver, String fare, String status) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(id, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(cat),
          Text(customer),
          Text(driver),
          Text(fare, style: const TextStyle(fontWeight: FontWeight.bold)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(status, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
