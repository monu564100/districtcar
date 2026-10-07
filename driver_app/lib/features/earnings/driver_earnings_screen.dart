import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import '../../services/driver_service.dart';

class DriverEarningsScreen extends ConsumerStatefulWidget {
  const DriverEarningsScreen({super.key});

  @override
  ConsumerState<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends ConsumerState<DriverEarningsScreen> {
  bool _isPaying = false;

  void _payCommissionModal(BuildContext context, String driverId, double pendingAmount, int pendingTrips) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                ),
                const SizedBox(height: 16),
                const Icon(Icons.account_balance_wallet, size: 48, color: Color(0xFF15803D)),
                const SizedBox(height: 12),
                const Text(
                  'District Car Platform Commission',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  '10% dynamic platform fee for $pendingTrips completed rides',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Payable Commission:',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      Text(
                        '₹${pendingAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF15803D)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF15803D),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _isPaying
                        ? null
                        : () async {
                            Navigator.pop(ctx);
                            setState(() => _isPaying = true);
                            try {
                              // Record commission settlement and unblock driver
                              await FirebaseFirestore.instance.collection('drivers').doc(driverId).set({
                                'pendingCommission': 0.0,
                                'unpaidTripsCount': 0,
                                'isBlockedDueToCommission': false,
                                'lastCommissionPaidAt': FieldValue.serverTimestamp(),
                              }, SetOptions(merge: true));

                              await FirebaseFirestore.instance.collection('commission_payments').add({
                                'driverId': driverId,
                                'amountPaid': pendingAmount,
                                'tripsCleared': pendingTrips,
                                'paidAt': FieldValue.serverTimestamp(),
                                'paymentMethod': 'UPI / Instant Wallet',
                              });

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Commission paid successfully! Account active.'),
                                    backgroundColor: Color(0xFF15803D),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Payment error: $e')),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => _isPaying = false);
                            }
                          },
                    child: _isPaying
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Pay via UPI / QR / NetBanking',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(driverServiceProvider).currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Earnings')),
        body: const Center(child: Text('Sign in to view earnings')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Earnings & Commission Wallet")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('drivers').doc(user.uid).snapshots(),
        builder: (context, driverSnap) {
          final driverData = driverSnap.data?.data() as Map<String, dynamic>? ?? {};

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('driverId', isEqualTo: user.uid)
                .where('status', isEqualTo: 'trip_completed')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];
              double totalEarnings = 0;
              for (final doc in docs) {
                final data = doc.data() as Map<String, dynamic>;
                totalEarnings +=
                    (data['finalFare'] as num?)?.toDouble() ?? (data['estimatedFare'] as num?)?.toDouble() ?? 0.0;
              }

              // 10% Dynamic Commission Calculation
              const double commissionRate = 0.10;
              final double platformCommission = totalEarnings * commissionRate;
              final double driverNetEarnings = totalEarnings - platformCommission;

              // 3-Trip Rule: Every 3 completed trips, driver must clear commission
              final int totalCompletedTrips = docs.length;
              final int unpaidTrips = driverData['unpaidTripsCount'] as int? ?? (totalCompletedTrips % 3);
              final double pendingCommission = (driverData['pendingCommission'] as num?)?.toDouble() ??
                  (unpaidTrips > 0 ? (totalEarnings / (totalCompletedTrips == 0 ? 1 : totalCompletedTrips) * unpaidTrips * commissionRate) : 0.0);

              final bool isBlocked = (driverData['isBlocked'] == true) ||
                  (driverData['isBlockedDueToCommission'] == true) ||
                  (unpaidTrips >= 3 && pendingCommission > 0);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Blocked Alert Banner if 3 trips exceeded without paying commission
                    if (isBlocked) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.block, color: Color(0xFFDC2626), size: 28),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'ACCOUNT TEMPORARILY BLOCKED (खाता ब्लॉक है)',
                                    style: TextStyle(
                                      color: Color(0xFF991B1B),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Rule: Pay 10% platform commission every 3 trips to receive new ride requests. Clear dues below to unblock instantly.',
                                    style: TextStyle(color: Color(0xFFB91C1C), fontSize: 11.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Total Gross Earnings Hero Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Gross Bookings', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 6),
                          Text(
                            '₹${totalEarnings.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$totalCompletedTrips completed trips in Jharkhand',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Dynamic Commission & Net Earnings Breakdown Cards
                    Row(
                      children: [
                        // Net Take-Home (90%)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFDCFCE7)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF16A34A)),
                                    SizedBox(width: 4),
                                    Text('Net Take-Home (90%)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '₹${driverNetEarnings.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // District Car Commission (10%)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFFEF3C7)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.pie_chart_outline, size: 14, color: Color(0xFFD97706)),
                                    SizedBox(width: 4),
                                    Text('Commission (10%)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '₹${platformCommission.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFD97706)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // 3-Trip Commission Settlement Box with Pay Button
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '3-Trip Commission Rule (कमीशन नियम)',
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Trips since last settlement: $unpaidTrips / 3',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: unpaidTrips >= 3 ? const Color(0xFFDC2626) : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF15803D),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => _payCommissionModal(
                                  context,
                                  user.uid,
                                  pendingCommission > 0 ? pendingCommission : (totalEarnings * 0.10),
                                  unpaidTrips > 0 ? unpaidTrips : 3,
                                ),
                                child: const Text(
                                  'Pay 10% Fee',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: (unpaidTrips / 3).clamp(0.0, 1.0),
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              unpaidTrips >= 3 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text('Recent Completed Trips', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    if (docs.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: Center(child: Text('No completed trips yet', style: TextStyle(color: AppColors.textSecondary))),
                      )
                    else
                      ...docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final fare = (data['finalFare'] as num?)?.toDouble() ??
                            (data['estimatedFare'] as num?)?.toDouble() ??
                            0.0;
                        final fee10 = fare * 0.10;
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
                                    Text(dest, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5), maxLines: 1),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Platform 10%: ₹${fee10.toStringAsFixed(1)} · Net: ₹${(fare - fee10).toStringAsFixed(1)}',
                                      style: const TextStyle(color: Color(0xFFD97706), fontSize: 10.5, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '+₹${fare.toStringAsFixed(0)}',
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
          );
        },
      ),
    );
  }
}
