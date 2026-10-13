import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import '../../services/driver_service.dart';

class DriverDeleteAccountScreen extends ConsumerStatefulWidget {
  const DriverDeleteAccountScreen({super.key});

  @override
  ConsumerState<DriverDeleteAccountScreen> createState() => _DriverDeleteAccountScreenState();
}

class _DriverDeleteAccountScreenState extends ConsumerState<DriverDeleteAccountScreen> {
  bool _isDeleting = false;
  String _selectedReason = 'I no longer wish to drive on District Car';
  final TextEditingController _feedbackController = TextEditingController();

  final List<String> _reasons = [
    'I no longer wish to drive on District Car',
    'I am switching to another vehicle or business',
    'Relocating to another state/district',
    'Privacy or data concerns',
    'Other reasons',
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _confirmAccountDeletion() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
            SizedBox(width: 10),
            Text('Permanent Action', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Are you sure you want to permanently delete your Driver Partner account?\n\nAll registered vehicle records, trip histories, and active ratings will be erased permanently.',
          style: TextStyle(fontSize: 13.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _executeDeletion();
            },
            child: const Text('Delete My Account', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _executeDeletion() async {
    setState(() => _isDeleting = true);
    final user = ref.read(driverServiceProvider).currentUser;
    if (user != null) {
      try {
        // Record deletion request in Firestore
        await FirebaseFirestore.instance.collection('account_deletion_requests').add({
          'userId': user.uid,
          'userEmail': user.email,
          'role': 'driver',
          'reason': _selectedReason,
          'feedback': _feedbackController.text.trim(),
          'status': 'processed',
          'requestedAt': FieldValue.serverTimestamp(),
        });

        // Mark driver profile as deleted
        await FirebaseFirestore.instance.collection('drivers').doc(user.uid).update({
          'isDeleted': true,
          'isOnline': false,
          'isBlocked': true,
          'deletedAt': FieldValue.serverTimestamp(),
        }).catchError((_) {});

        await ref.read(driverServiceProvider).signOut();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your Driver Partner account and data have been permanently deleted.'),
              backgroundColor: Color(0xFF16A34A),
            ),
          );
          context.go('/driver-login');
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isDeleting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Delete Driver Account', style: TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 28),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Google Play Data Safety Disclosure',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF991B1B)),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Deleting your account will permanently remove your driver profile, vehicle details, bank/UPI references, and trip activity from District Car systems.',
                          style: TextStyle(fontSize: 12.5, color: Color(0xFFB91C1C), height: 1.45),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Please tell us why you are leaving:',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),

            ..._reasons.map((reason) {
              final isSelected = _selectedReason == reason;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.8 : 1.0,
                  ),
                ),
                child: RadioListTile<String>(
                  value: reason,
                  groupValue: _selectedReason,
                  title: Text(reason, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  activeColor: const Color(0xFF2563EB),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedReason = val);
                  },
                ),
              );
            }),

            const SizedBox(height: 16),
            const Text(
              'Additional Feedback (Optional):',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _feedbackController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Share any details to help us improve...',
                hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isDeleting ? null : _confirmAccountDeletion,
                child: _isDeleting
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Text(
                        'Permanently Delete Account',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
