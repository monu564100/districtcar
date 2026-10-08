import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import '../../widgets/admin_sidebar.dart';

class FareManagementScreen extends StatefulWidget {
  const FareManagementScreen({super.key});

  @override
  State<FareManagementScreen> createState() => _FareManagementScreenState();
}

class _FareManagementScreenState extends State<FareManagementScreen> {
  void _editFareDialog(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['displayName'] ?? data['name'] ?? 'Vehicle';
    final baseFareCtrl = TextEditingController(text: (data['baseFare'] ?? 0).toString());
    final perKmCtrl = TextEditingController(text: (data['perKmRate'] ?? 0).toString());
    final minFareCtrl = TextEditingController(text: (data['minimumFare'] ?? 0).toString());
    final roundTripDiscountCtrl = TextEditingController(text: (data['roundTripDiscountPercent'] ?? 35).toString());
    final hourlyWaitingCtrl = TextEditingController(text: (data['hourlyWaitingCharge'] ?? 60).toString());
    final commissionCtrl = TextEditingController(text: (data['platformCommissionPercent'] ?? 10).toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Dynamic Pricing: $name', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: baseFareCtrl, decoration: const InputDecoration(labelText: 'Base Pickup Fare (₹)')),
                const SizedBox(height: 12),
                TextField(controller: perKmCtrl, decoration: const InputDecoration(labelText: 'Standard Rate per KM (₹)')),
                const SizedBox(height: 12),
                TextField(controller: minFareCtrl, decoration: const InputDecoration(labelText: 'Minimum Trip Fare (₹)')),
                const SizedBox(height: 12),
                TextField(
                  controller: roundTripDiscountCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Round-Trip Return Discount (%)',
                    helperText: 'Default 35% discount applied on the return journey',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: hourlyWaitingCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Hourly Waiting Charge (₹/hr)',
                    helperText: 'Waiting charge applied after arrival at destination',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commissionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Platform Commission Share (%)',
                    helperText: 'Platform revenue percentage (Default 10%)',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('vehicleCategories').doc(doc.id).update({
                'baseFare': double.tryParse(baseFareCtrl.text.trim()) ?? data['baseFare'],
                'perKmRate': double.tryParse(perKmCtrl.text.trim()) ?? data['perKmRate'],
                'minimumFare': double.tryParse(minFareCtrl.text.trim()) ?? data['minimumFare'],
                'roundTripDiscountPercent': double.tryParse(roundTripDiscountCtrl.text.trim()) ?? 35.0,
                'hourlyWaitingCharge': double.tryParse(hourlyWaitingCtrl.text.trim()) ?? 60.0,
                'platformCommissionPercent': double.tryParse(commissionCtrl.text.trim()) ?? 10.0,
                'updatedAt': FieldValue.serverTimestamp(),
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pricing rate card updated successfully!'), backgroundColor: Color(0xFF16A34A)),
                );
              }
            },
            child: const Text('Save & Publish Live'),
          ),
        ],
      ),
    );
  }

  void _syncDefaultCategories() async {
    final categories = [
      {
        'id': 'car',
        'name': 'Mini Cab',
        'displayName': 'Economy Mini Cab',
        'icon': 'directions_car',
        'baseFare': 60.0,
        'perKmRate': 14.0,
        'minimumFare': 80.0,
        'roundTripDiscountPercent': 35.0,
        'hourlyWaitingCharge': 60.0,
        'platformCommissionPercent': 10.0,
        'isActive': true,
      },
      {
        'id': 'auto',
        'name': 'Auto / E-Rick',
        'displayName': 'Auto / E-Rickshaw',
        'icon': 'electric_rickshaw',
        'baseFare': 40.0,
        'perKmRate': 10.0,
        'minimumFare': 50.0,
        'roundTripDiscountPercent': 35.0,
        'hourlyWaitingCharge': 40.0,
        'platformCommissionPercent': 10.0,
        'isActive': true,
      },
      {
        'id': 'sedan',
        'name': 'Sedan',
        'displayName': 'Comfort Sedan',
        'icon': 'local_taxi',
        'baseFare': 80.0,
        'perKmRate': 17.0,
        'minimumFare': 120.0,
        'roundTripDiscountPercent': 35.0,
        'hourlyWaitingCharge': 60.0,
        'platformCommissionPercent': 10.0,
        'isActive': true,
      },
      {
        'id': 'suv',
        'name': 'Rural SUV',
        'displayName': 'Rural SUV (Bolero)',
        'icon': 'directions_car_filled',
        'baseFare': 120.0,
        'perKmRate': 22.0,
        'minimumFare': 180.0,
        'roundTripDiscountPercent': 35.0,
        'hourlyWaitingCharge': 80.0,
        'platformCommissionPercent': 10.0,
        'isActive': true,
      },
      {
        'id': 'bike',
        'name': 'Bike',
        'displayName': 'Gramin Bike',
        'icon': 'two_wheeler',
        'baseFare': 25.0,
        'perKmRate': 8.0,
        'minimumFare': 35.0,
        'roundTripDiscountPercent': 30.0,
        'hourlyWaitingCharge': 30.0,
        'platformCommissionPercent': 10.0,
        'isActive': true,
      },
    ];

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final cat in categories) {
        final ref = FirebaseFirestore.instance.collection('vehicleCategories').doc(cat['id'] as String);
        batch.set(ref, cat, SetOptions(merge: true));
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All Gramin Tariff categories synced with Website defaults!'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          const AdminSidebar(activeRoute: '/fares'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Dynamic Pricing & Tariff Rate Cards', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                          SizedBox(height: 4),
                          Text(
                            'Control base fares, per-KM rates, round-trip discount %, waiting charges, and platform commission live.',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _syncDefaultCategories,
                        icon: const Icon(Icons.sync, size: 16),
                        label: const Text('Sync Landing Tariff Defaults', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('vehicleCategories').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('No dynamic vehicle categories configured in Firestore.', style: TextStyle(color: Color(0xFF64748B))),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _syncDefaultCategories,
                                  child: const Text('Initialize Default Tariff Categories'),
                                ),
                              ],
                            ),
                          );
                        }

                        return GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 2.2,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                          ),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final name = data['displayName'] ?? data['name'] ?? 'Vehicle';
                            final baseFare = (data['baseFare'] ?? 0).toString();
                            final perKm = (data['perKmRate'] ?? 0).toString();
                            final minFare = (data['minimumFare'] ?? 0).toString();
                            final roundTripDiscount = (data['roundTripDiscountPercent'] ?? 35).toString();
                            final waitingCharge = (data['hourlyWaitingCharge'] ?? 60).toString();
                            final commission = (data['platformCommissionPercent'] ?? 10).toString();

                            return Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(Icons.directions_car, color: AppColors.primary, size: 20),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            name,
                                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                                          ),
                                        ],
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () => _editFareDialog(doc),
                                        icon: const Icon(Icons.edit, size: 14),
                                        label: const Text('Edit Rate Card', style: TextStyle(fontSize: 12)),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.primary,
                                          side: const BorderSide(color: AppColors.primary),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildRatePill('Base Fare', '₹$baseFare'),
                                      _buildRatePill('Rate / KM', '₹$perKm'),
                                      _buildRatePill('Min Fare', '₹$minFare'),
                                      _buildRatePill('Return Discount', '$roundTripDiscount%'),
                                      _buildRatePill('Waiting', '₹$waitingCharge/hr'),
                                      _buildRatePill('Commission', '$commission%'),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
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

  Widget _buildRatePill(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w800)),
      ],
    );
  }
}
