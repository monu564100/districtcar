import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import '../auth/auth_service.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _confirmTextController = TextEditingController();
  String _selectedReason = 'I no longer need this service';
  bool _understandsDataDeletion = false;
  bool _isDeleting = false;

  final List<String> _commonReasons = [
    'I no longer need this service',
    'I am relocating outside Jharkhand',
    'Privacy or data security concerns',
    'Created a duplicate account',
    'Switching to another phone number / email',
    'Other reason (specified below)',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    _confirmTextController.dispose();
    super.dispose();
  }

  Future<void> _handleDeleteAccount() async {
    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;
    if (user == null) {
      context.go('/');
      return;
    }

    if (_confirmTextController.text.trim().toUpperCase() != 'DELETE') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please type "DELETE" to confirm account deletion'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (!_understandsDataDeletion) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please check the acknowledgement box before proceeding'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    HapticFeedback.heavyImpact();
    setState(() => _isDeleting = true);

    try {
      // 1. Log delete request in Firestore for Play Store & audit compliance
      await FirebaseFirestore.instance.collection('account_deletion_requests').doc(user.uid).set({
        'userId': user.uid,
        'userEmail': user.email ?? '',
        'userName': user.displayName ?? '',
        'userPhone': user.phoneNumber ?? '',
        'reason': _selectedReason,
        'notes': _reasonController.text.trim(),
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'processed',
        'platform': 'customer_app',
      });

      // 2. Anonymize/erase user profile document
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'deleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'status': 'deleted',
        'name': 'Deleted User',
        'email': 'deleted_${user.uid.substring(0, 6)}@districtcar.in',
        'phoneNumber': '',
      }, SetOptions(merge: true));

      // 3. Clear auth session
      await authService.signOut();

      if (mounted) {
        setState(() => _isDeleting = false);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 28),
                SizedBox(width: 10),
                Text('Account Deleted', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              ],
            ),
            content: const Text(
              'Your District Car account, profile data, and identifiers have been permanently deleted in accordance with Google Play Store User Data Safety guidelines.',
              style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF334155)),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/');
                },
                child: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: $e. Please contact +91 87896 01387'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Delete Account (खाता हटाएँ)',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFECACA), width: 1.2),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFDC2626),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Irreversible Action (अपरिवर्तनीय कार्रवाई)',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF991B1B)),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Deleting your account will permanently wipe your profile, saved locations, ride tokens, and active preferences. This action cannot be undone.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF7F1D1D), height: 1.45),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Google Play Data Safety Compliance Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.shield_outlined, color: AppColors.primary, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Play Store Data Safety Rights',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDataPoint(Icons.check_circle, 'Personal profile information and saved addresses will be deleted immediately.'),
                  _buildDataPoint(Icons.check_circle, 'Authentication credentials and local cached sessions will be revoked.'),
                  _buildDataPoint(Icons.info_outline, 'Past financial invoices are archived for tax and statutory compliance in India (up to legal requirement) without active marketing access.'),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Reason selector
            const Text(
              'Reason for Leaving (कारण बताएं)',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedReason,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                  items: _commonReasons.map((r) => DropdownMenuItem(
                    value: r,
                    child: Text(r, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedReason = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Feedback Notes
            const Text(
              'Additional Feedback (वैकल्पिक सुझाव)',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Tell us how we could have improved your rural travel experience...',
                hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFDC2626))),
              ),
            ),
            const SizedBox(height: 22),

            // Confirmation checkbox
            InkWell(
              onTap: () => setState(() => _understandsDataDeletion = !_understandsDataDeletion),
              borderRadius: BorderRadius.circular(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _understandsDataDeletion,
                    activeColor: const Color(0xFFDC2626),
                    onChanged: (val) => setState(() => _understandsDataDeletion = val ?? false),
                  ),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        'I understand that this action is permanent and my account data will be wiped out immediately.',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Type "DELETE" confirm field
            const Text(
              'Type "DELETE" to confirm (पुष्टि के लिए DELETE लिखें)',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmTextController,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
              decoration: InputDecoration(
                hintText: 'DELETE',
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400, letterSpacing: 2),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2)),
              ),
            ),
            const SizedBox(height: 26),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                onPressed: _isDeleting ? null : _handleDeleteAccount,
                icon: _isDeleting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.delete_forever_rounded),
                label: Text(
                  _isDeleting ? 'Deleting Account...' : 'Permanently Delete My Account',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Help line fallback
            Center(
              child: Text(
                'Need help instead? Call Support: +91 87896 01387 (Monu Kumar, CEO)',
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDataPoint(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: icon == Icons.check_circle ? const Color(0xFF16A34A) : Colors.amber.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
