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
    final name = data['name'] ?? '';
    final baseFareCtrl = TextEditingController(text: (data['baseFare'] ?? 0).toString());
    final perKmCtrl = TextEditingController(text: (data['perKmRate'] ?? 0).toString());
    final minFareCtrl = TextEditingController(text: (data['minimumFare'] ?? 0).toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Configure Fare: $name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: baseFareCtrl, decoration: const InputDecoration(labelText: 'Base Fare (₹)')),
            const SizedBox(height: 12),
            TextField(controller: perKmCtrl, decoration: const InputDecoration(labelText: 'Rate per KM (₹)')),
            const SizedBox(height: 12),
            TextField(controller: minFareCtrl, decoration: const InputDecoration(labelText: 'Minimum Fare (₹)')),
          ],
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
                'updatedAt': FieldValue.serverTimestamp(),
              });
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const AdminSidebar(activeRoute: '/fares'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Vehicle Pricing & Rate Cards', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  const Text('Configure dynamic base fares, per-kilometer pricing, and minimum trip thresholds.', style: TextStyle(color: AppColors.textSecondary)),
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
                          return const Center(child: Text('No vehicle categories available.'));
                        }

                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data = docs[index].data() as Map<String, dynamic>;
                            final name = data['name'] ?? 'Vehicle';
                            final baseFare = data['baseFare'] ?? 0;
                            final perKm = data['perKmRate'] ?? 0;
                            final minFare = data['minimumFare'] ?? 0;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(Icons.directions_car, color: AppColors.primary, size: 28),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                                        const SizedBox(height: 4),
                                        Text('Base: ₹$baseFare · Per KM: ₹$perKm · Minimum: ₹$minFare', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _editFareDialog(docs[index]),
                                    child: const Text('Update Pricing'),
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
}
