import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import 'package:district_car_shared/models/models.dart';
import '../auth/auth_service.dart';

class ReportDriverScreen extends ConsumerStatefulWidget {
  final BookingModel? initialBooking;

  const ReportDriverScreen({super.key, this.initialBooking});

  @override
  ConsumerState<ReportDriverScreen> createState() => _ReportDriverScreenState();
}

class _ReportDriverScreenState extends ConsumerState<ReportDriverScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  String _selectedIssue = 'Overcharging / Demanded Extra Cash';
  BookingModel? _selectedBooking;
  bool _isSubmitting = false;

  final List<String> _issueCategories = [
    'Overcharging / Demanded Extra Cash',
    'Unprofessional / Rude Driver Behavior',
    'Reckless Driving / Over-speeding',
    'Driver Demanded Offline Payment / Refused UPI',
    'Car Unclean / AC Not Working',
    'Driver Left Before Completed Trip',
    'Lost Belongings / Items in Car',
    'Driver Cancelled Without Reason',
    'Other Issue',
  ];

  @override
  void initState() {
    super.initState();
    _selectedBooking = widget.initialBooking;
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null && user.phoneNumber != null) {
      _contactPhoneController.text = user.phoneNumber!;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first to file a report')),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe the issue in detail'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);

    try {
      final docRef = FirebaseFirestore.instance.collection('driver_reports').doc();
      final reportData = {
        'id': docRef.id,
        'reportId': 'REP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        'customerId': user.uid,
        'customerName': user.displayName ?? 'Customer',
        'customerEmail': user.email ?? '',
        'contactPhone': _contactPhoneController.text.trim().isNotEmpty
            ? _contactPhoneController.text.trim()
            : (user.phoneNumber ?? '+918789601387'),
        'issueCategory': _selectedIssue,
        'description': _descriptionController.text.trim(),
        'status': 'open', // open, investigating, resolved
        'createdAt': FieldValue.serverTimestamp(),
        // Booking & Driver details if linked
        'bookingId': _selectedBooking?.id,
        'readableBookingId': _selectedBooking?.readableId,
        'driverId': _selectedBooking?.driverId,
        'driverName': _selectedBooking?.driverName,
        'driverPhone': _selectedBooking?.driverPhone,
        'vehiclePlate': _selectedBooking?.vehiclePlate,
        'vehicleModel': _selectedBooking?.vehicleModel,
        'pickupAddress': _selectedBooking?.pickup.address,
        'destAddress': _selectedBooking?.destination.address,
        'tripFare': _selectedBooking?.finalFare ?? _selectedBooking?.estimatedFare,
        'tripDate': _selectedBooking != null ? DateFormat('dd MMM yyyy, hh:mm a').format(_selectedBooking!.createdAt) : null,
      };

      await docRef.set(reportData);

      if (mounted) {
        setState(() => _isSubmitting = false);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 28),
                SizedBox(width: 10),
                Text('Report Submitted', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your grievance has been logged successfully under Ticket #${reportData['reportId']}.',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.headset_mic_rounded, color: Color(0xFF16A34A), size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Our Founder Monu Kumar & Safety Team will inspect this driver within 2 hours. Helpline: +91 87896 01387.',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF166534), height: 1.4, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit report: $e'),
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
          'Report Driver (ड्राइवर की शिकायत)',
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
            // Top safety advisory card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.security_update_warning_rounded, color: Color(0xFFFBBF24), size: 26),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zero-Tolerance Commuter Safety',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'District Car strictly enforces fair fares, polite rural conduct, and zero over-speeding. Every report is audited directly by leadership.',
                          style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11.5, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Select Recent Booking Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Recent Booked Trip',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                ),
                Text(
                  _selectedBooking != null ? 'Selected: #${_selectedBooking!.readableId}' : 'Required',
                  style: TextStyle(fontSize: 11.5, color: _selectedBooking != null ? const Color(0xFF16A34A) : const Color(0xFFDC2626), fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Fetch recent bookings from Firestore for this user
            if (user != null)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('customerId', isEqualTo: user.uid)
                    .orderBy('createdAt', descending: true)
                    .limit(5)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Color(0xFF64748B), size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'No recent trips found in your account. You can still report a driver below by mentioning their vehicle or phone in the notes.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final bookings = docs.map((d) => BookingModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();

                  return Column(
                    children: bookings.map((b) {
                      final isSelected = _selectedBooking?.id == b.id;
                      final isCompleted = b.status == 'completed';

                      return InkWell(
                        onTap: () => setState(() => _selectedBooking = b),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF16A34A) : Colors.grey.shade200,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isCompleted ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isCompleted ? Icons.check_circle_outline : Icons.local_taxi_rounded,
                                  color: isCompleted ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          b.driverName ?? 'Assigned Driver',
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A)),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            b.vehiclePlate ?? 'Plate N/A',
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${b.pickup.address} ➔ ${b.destination.address}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${DateFormat('dd MMM, hh:mm a').format(b.createdAt)} · ₹${(b.finalFare ?? b.estimatedFare).toInt()} · Status: ${b.status.toUpperCase()}',
                                      style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              Radio<String>(
                                value: b.id,
                                groupValue: _selectedBooking?.id,
                                activeColor: const Color(0xFF16A34A),
                                onChanged: (val) => setState(() => _selectedBooking = b),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

            const SizedBox(height: 18),

            // Grievance / Report Category
            const Text(
              'Select Issue Category (शिकायत का प्रकार)',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedIssue,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                  items: _issueCategories.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedIssue = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Detailed Description
            const Text(
              'Describe What Happened (पूरी घटना का विवरण)',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Please detail what happened during your trip, exact driver words, route diverted, or disputed fare amounts...',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
              ),
            ),
            const SizedBox(height: 18),

            // Contact Phone for callbacks
            const Text(
              'Contact Phone for Follow-Up Call',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contactPhoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.phone_android_rounded, size: 20, color: AppColors.primary),
                hintText: '+918789601387',
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
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
                onPressed: _isSubmitting ? null : _submitReport,
                icon: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.report_problem_rounded),
                label: Text(
                  _isSubmitting ? 'Submitting Report...' : 'Submit Driver Grievance',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Emergency direct dial
            Center(
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.phone_in_talk_rounded, color: AppColors.primary, size: 18),
                label: const Text(
                  'Immediate Emergency? Call Safety Desk: +91 87896 01387',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
