import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../widgets/admin_sidebar.dart';

class DriverVerificationScreen extends StatefulWidget {
  const DriverVerificationScreen({super.key});

  @override
  State<DriverVerificationScreen> createState() => _DriverVerificationScreenState();
}

class _DriverVerificationScreenState extends State<DriverVerificationScreen> {
  String _selectedStatus = 'pending'; // pending, approved, rejected
  bool _isProcessing = false;

  void _verifyDriver(String driverId, String status, {String? reason}) async {
    setState(() => _isProcessing = true);
    try {
      // 1. Direct Firestore update for guaranteed execution
      await FirebaseFirestore.instance.collection('drivers').doc(driverId).set({
        'verificationStatus': status,
        'isVerified': status == 'approved',
        if (reason != null) 'rejectionReason': reason,
        'verifiedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Attempt optional Cloud Function trigger
      try {
        final callable = FirebaseFunctions.instance.httpsCallable('verifyDriver');
        await callable.call({
          'driverId': driverId,
          'status': status,
          'rejectionReason': reason,
        });
      } catch (_) {
        // Cloud Function is optional if direct Firestore update already succeeded
      }

      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Driver partner marked as ${status.toUpperCase()}'),
            backgroundColor: status == 'approved' ? const Color(0xFF059669) : const Color(0xFFDC2626),
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating driver: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showDriverDossierDialog(Map<String, dynamic> data, String driverId) {
    final name = (data['name'] ?? 'Driver Applicant').toString();
    final phone = (data['phoneNumber'] ?? data['phone'] ?? 'N/A').toString();
    final category = (data['vehicleCategoryId'] ?? 'Car').toString().toUpperCase();
    final plate = (data['vehiclePlate'] ?? data['licensePlate'] ?? 'JH 01 XX 0000').toString();
    final model = (data['vehicleModel'] ?? 'Standard').toString();
    final driverPhoto = data['driverPhoto']?.toString();
    final vehiclePhoto = data['vehiclePhoto']?.toString();
    final stand = (data['currentAddress'] ?? data['locationAddress'] ?? data['stand'] ?? data['block'] ?? 'Jharkhand Stand').toString();
    final age = (data['age'] ?? 'N/A').toString();
    final currentStatus = (data['verificationStatus'] ?? 'pending').toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.badge_outlined, color: Color(0xFF059669)),
            const SizedBox(width: 10),
            Text('Driver Dossier: $name', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 580,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photos Row
                Row(
                  children: [
                    // Driver Photo
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DRIVER PHOTO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          const SizedBox(height: 6),
                          Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: driverPhoto != null && driverPhoto.isNotEmpty
                                ? Image.network(
                                    driverPhoto,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.person, size: 48, color: Color(0xFF94A3B8))),
                                  )
                                : const Center(child: Icon(Icons.person, size: 48, color: Color(0xFF94A3B8))),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Vehicle Photo
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('VEHICLE PHOTO & NUMBER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          const SizedBox(height: 6),
                          Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: vehiclePhoto != null && vehiclePhoto.isNotEmpty
                                ? Image.network(
                                    vehiclePhoto,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.directions_car, size: 48, color: Color(0xFF94A3B8))),
                                  )
                                : const Center(child: Icon(Icons.directions_car, size: 48, color: Color(0xFF94A3B8))),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Details Card - 2-Column Horizontal Grid
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column
                      Expanded(
                        child: Column(
                          children: [
                            _dossierRow('Full Name:', name),
                            _dossierRow('Contact Phone:', phone),
                            _dossierRow('Age:', age),
                            _dossierRow('Permanent Stand:', stand),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Right Column
                      Expanded(
                        child: Column(
                          children: [
                            _dossierRow('Vehicle Category:', category),
                            _dossierRow('Vehicle Model:', model),
                            _dossierRow('Registration Plate:', plate),
                            _dossierRow('Verification Status:', currentStatus.toUpperCase()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (currentStatus != 'approved')
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _verifyDriver(driverId, 'approved');
              },
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('APPROVE PARTNER', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          if (currentStatus != 'rejected')
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFFCA5A5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _verifyDriver(driverId, 'rejected', reason: 'Documents did not meet criteria');
              },
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('REJECT / SUSPEND', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _dossierRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          const AdminSidebar(activeRoute: '/driver-verification'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Driver Partner Approvals & Fleet Roster',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                          SizedBox(height: 6),
                          Text('Review driver KYC, live uploaded selfies, vehicle number plate, and manage fleet authorization.', style: TextStyle(color: Color(0xFF64748B))),
                        ],
                      ),
                      // Status Segmented Controls
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _buildTabButton('Pending Review', 'pending', Icons.hourglass_top_rounded),
                            _buildTabButton('Approved Partners', 'approved', Icons.verified_rounded),
                            _buildTabButton('Rejected / Suspended', 'rejected', Icons.block_rounded),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Drivers list stream
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('drivers')
                          .where('verificationStatus', isEqualTo: _selectedStatus)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _selectedStatus == 'pending' ? Icons.check_circle_outline : Icons.group_outlined,
                                    size: 52,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    _selectedStatus == 'pending'
                                        ? 'No pending driver applications awaiting review.'
                                        : 'No drivers found under $_selectedStatus status.',
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3)),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: 1200,
                                child: Column(
                                  children: [
                                    // Horizontal Table Header
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                      color: const Color(0xFFF8FAFC),
                                      child: Row(
                                        children: const [
                                          SizedBox(
                                            width: 70,
                                            child: Text('PHOTO', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                          ),
                                          SizedBox(
                                            width: 190,
                                            child: Text('APPLICANT NAME', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                          ),
                                          SizedBox(
                                            width: 120,
                                            child: Text('CATEGORY', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                          ),
                                          SizedBox(
                                            width: 150,
                                            child: Text('CONTACT PHONE', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                          ),
                                          SizedBox(
                                            width: 160,
                                            child: Text('VEHICLE PLATE', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                          ),
                                          SizedBox(
                                            width: 180,
                                            child: Text('STAND / LOCATION', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                          ),
                                          SizedBox(
                                            width: 120,
                                            child: Text('DOSSIER', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                          ),
                                          SizedBox(
                                            width: 210,
                                            child: Text('VERIFICATION ACTION', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(height: 1, color: Color(0xFFE2E8F0)),

                                    // Table Rows
                                    Expanded(
                                      child: ListView.separated(
                                        itemCount: docs.length,
                                        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                                        itemBuilder: (context, index) {
                                          final data = docs[index].data() as Map<String, dynamic>;
                                          final driverId = docs[index].id;
                                          final name = (data['name'] ?? 'Driver Applicant').toString();
                                          final phone = (data['phoneNumber'] ?? data['phone'] ?? '').toString();
                                          final vehicleCategory = (data['vehicleCategoryId'] ?? 'Car').toString().toUpperCase();
                                          final plate = (data['vehiclePlate'] ?? data['licensePlate'] ?? '').toString();
                                          final stand = (data['currentAddress'] ?? data['locationAddress'] ?? data['stand'] ?? data['block'] ?? 'Jharkhand Stand').toString();
                                          final driverPhoto = data['driverPhoto']?.toString();

                                          return Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                            child: Row(
                                              children: [
                                                // Driver Photo
                                                SizedBox(
                                                  width: 70,
                                                  child: Container(
                                                    width: 42,
                                                    height: 42,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: const Color(0xFFE2E8F0),
                                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                                    ),
                                                    clipBehavior: Clip.antiAlias,
                                                    child: driverPhoto != null && driverPhoto.isNotEmpty
                                                        ? Image.network(
                                                            driverPhoto,
                                                            fit: BoxFit.cover,
                                                            errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Color(0xFF475569), size: 22),
                                                          )
                                                        : const Icon(Icons.person, color: Color(0xFF475569), size: 22),
                                                  ),
                                                ),

                                                // Applicant Name
                                                SizedBox(
                                                  width: 190,
                                                  child: Text(
                                                    name,
                                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),

                                                // Category
                                                SizedBox(
                                                  width: 120,
                                                  child: Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFF1F5F9),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(vehicleCategory, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                                    ),
                                                  ),
                                                ),

                                                // Phone Number
                                                SizedBox(
                                                  width: 150,
                                                  child: Text(
                                                    phone,
                                                    style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                                                  ),
                                                ),

                                                // Vehicle Plate
                                                SizedBox(
                                                  width: 160,
                                                  child: Text(
                                                    plate.isNotEmpty ? plate : 'Not Provided',
                                                    style: TextStyle(
                                                      fontSize: 12.5,
                                                      fontWeight: FontWeight.bold,
                                                      color: plate.isNotEmpty ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                                                    ),
                                                  ),
                                                ),

                                                // Stand / Location
                                                SizedBox(
                                                  width: 180,
                                                  child: Text(
                                                    stand.split(',').first,
                                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),

                                                // Dossier Button
                                                SizedBox(
                                                  width: 120,
                                                  child: Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: TextButton.icon(
                                                      onPressed: () => _showDriverDossierDialog(data, driverId),
                                                      icon: const Icon(Icons.visibility_outlined, size: 15),
                                                      label: const Text('Dossier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4)),
                                                    ),
                                                  ),
                                                ),

                                                // Action buttons
                                                SizedBox(
                                                  width: 210,
                                                  child: Row(
                                                    children: [
                                                      if (_selectedStatus == 'pending') ...[
                                                        OutlinedButton(
                                                          style: OutlinedButton.styleFrom(
                                                            foregroundColor: const Color(0xFFDC2626),
                                                            side: const BorderSide(color: Color(0xFFFECACA)),
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                            minimumSize: Size.zero,
                                                          ),
                                                          onPressed: _isProcessing
                                                              ? null
                                                              : () => _verifyDriver(driverId, 'rejected', reason: 'Documents rejected by Admin'),
                                                          child: const Text('REJECT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        ElevatedButton(
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: const Color(0xFF059669),
                                                            foregroundColor: Colors.white,
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                            minimumSize: Size.zero,
                                                            elevation: 0,
                                                          ),
                                                          onPressed: _isProcessing ? null : () => _verifyDriver(driverId, 'approved'),
                                                          child: const Text('APPROVE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                                        ),
                                                      ] else if (_selectedStatus == 'approved') ...[
                                                        OutlinedButton(
                                                          style: OutlinedButton.styleFrom(
                                                            foregroundColor: const Color(0xFFDC2626),
                                                            side: const BorderSide(color: Color(0xFFFECACA)),
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                            minimumSize: Size.zero,
                                                          ),
                                                          onPressed: _isProcessing
                                                              ? null
                                                              : () => _verifyDriver(driverId, 'rejected', reason: 'Suspended by Operations Admin'),
                                                          child: const Text('SUSPEND', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                                        ),
                                                      ] else ...[
                                                        ElevatedButton(
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: const Color(0xFF059669),
                                                            foregroundColor: Colors.white,
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                            minimumSize: Size.zero,
                                                            elevation: 0,
                                                          ),
                                                          onPressed: _isProcessing ? null : () => _verifyDriver(driverId, 'approved'),
                                                          child: const Text('RE-APPROVE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
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

  Widget _buildTabButton(String label, String statusKey, IconData icon) {
    final isSelected = _selectedStatus == statusKey;
    return InkWell(
      onTap: () => setState(() => _selectedStatus = statusKey),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)] : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
