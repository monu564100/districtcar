import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import '../../services/driver_service.dart';

class DriverEarningsScreen extends ConsumerWidget {
  const DriverEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(driverServiceProvider).currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Earnings')),
        body: const Center(child: Text('Sign in to view earnings')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Earnings & Wallet")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('driverId', '==', user.uid)
            .where('status', '==', 'trip_completed')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          double totalEarnings = 0;
          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            totalEarnings += (data['finalFare'] as num?)?.toDouble() ?? (data['estimatedFare'] as num?)?.toDouble() ?? 0.0;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total Earnings Hero Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Earnings', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(
                        '₹${totalEarnings.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${docs.length} completed rides',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const Text('Recent Completed Trips', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                if (docs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Center(child: Text('No completed trips yet', style: TextStyle(color: AppColors.textSecondary))),
                  )
                else
                  ...docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final fare = data['finalFare'] ?? data['estimatedFare'] ?? 0;
                    final pickup = data['pickup']?['address'] ?? 'Pickup';
                    final dest = data['destination']?['address'] ?? 'Destination';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(pickup, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1),
                                const SizedBox(height: 2),
                                Text(dest, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 1),
                              ],
                            ),
                          ),
                          Text(
                            '+₹$fare',
                            style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}
