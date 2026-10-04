import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import '../../widgets/admin_sidebar.dart';

class DriverVerificationScreen extends StatefulWidget {
  const DriverVerificationScreen({super.key});

  @override
  State<DriverVerificationScreen> createState() => _DriverVerificationScreenState();
}

class _DriverVerificationScreenState extends State<DriverVerificationScreen> {
  bool _isProcessing = false;

  void _verifyDriver(String driverId, String status, {String? reason}) async {
    setState(() => _isProcessing = true);
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('verifyDriver');
      await callable.call({
        'driverId': driverId,
        'status': status,
        'rejectionReason': reason,
      });
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Driver marked as $status')),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error verifying driver: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const AdminSidebar(activeRoute: '/driver-verification'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Driver Partner Approvals',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  const Text('Review applicant details, live vehicle camera photos, and approve or reject access.', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 28),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('drivers')
                          .where('verificationStatus', '==', 'pending')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return const Center(
                            child: Text('No pending driver applications at this time.', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                          );
                        }

                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data = docs[index].data() as Map<String, dynamic>;
                            final driverId = docs[index].id;
                            final name = data['name'] ?? 'Driver Applicant';
                            final phone = data['phoneNumber'] ?? '';
                            final vehicleCategory = data['vehicleCategoryId'] ?? 'Car';
                            final age = data['age'] ?? '';

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
                                    width: 60,
                                    height: 60,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primaryLight,
                                    ),
                                    child: const Icon(Icons.person, color: AppColors.primary, size: 36),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                                        const SizedBox(height: 4),
                                        Text('$phone · Age: $age · Category: $vehicleCategory', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppColors.error),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: _isProcessing
                                        ? null
                                        : () => _verifyDriver(driverId, 'rejected', reason: 'Documents did not meet criteria'),
                                    child: const Text('REJECT', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 14),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: _isProcessing ? null : () => _verifyDriver(driverId, 'approved'),
                                    child: const Text('APPROVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
