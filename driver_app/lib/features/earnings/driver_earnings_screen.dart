import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/driver_service.dart';

class DriverEarningsScreen extends ConsumerStatefulWidget {
  const DriverEarningsScreen({super.key});

  @override
  ConsumerState<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends ConsumerState<DriverEarningsScreen> {
  bool _isProcessing = false;

  void _callCustomer(String? phone) async {
    final targetPhone = (phone != null && phone.trim().isNotEmpty) ? phone.trim() : '+91 87896 01387';
    final cleanPhone = targetPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) await launchUrl(uri);
    } catch (_) {
      try {
        await launchUrl(uri);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Customer Phone: $targetPhone')),
          );
        }
      }
    }
  }

  void _payCommissionModal(BuildContext context, String driverId, double pendingAmount, int pendingTrips, double walletBalance) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final double amountToPay = pendingAmount > 0 ? pendingAmount : 10.0;
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 20,
                  bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                    ),
                    const SizedBox(height: 16),
                    const Icon(Icons.account_balance_wallet, size: 48, color: Color(0xFF059669)),
                    const SizedBox(height: 10),
                    const Text(
                      'Clear Platform Commission',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '10% dynamic platform fee for $pendingTrips completed rides in Jharkhand',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Payable 10% Fee:',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF065F46)),
                          ),
                          Text(
                            '₹${amountToPay.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFF047857)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Option 1: Settle from Wallet Balance if sufficient
                    if (walletBalance >= amountToPay) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF047857),
                            side: const BorderSide(color: Color(0xFF059669), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _isProcessing
                              ? null
                              : () async {
                                  Navigator.pop(ctx);
                                  setState(() => _isProcessing = true);
                                  try {
                                    final newBal = (walletBalance - amountToPay).clamp(0.0, double.infinity);
                                    await FirebaseFirestore.instance.collection('drivers').doc(driverId).set({
                                      'pendingCommission': 0.0,
                                      'unpaidTripsCount': 0,
                                      'isBlockedDueToCommission': false,
                                      'walletBalance': newBal,
                                      'lastCommissionPaidAt': FieldValue.serverTimestamp(),
                                    }, SetOptions(merge: true));

                                    await FirebaseFirestore.instance.collection('commission_payments').add({
                                      'driverId': driverId,
                                      'amountPaid': amountToPay,
                                      'tripsCleared': pendingTrips,
                                      'paidAt': FieldValue.serverTimestamp(),
                                      'paymentMethod': 'Deducted from Wallet Balance',
                                    });

                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Commission cleared from wallet balance! Account 100% active.'),
                                          backgroundColor: Color(0xFF059669),
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
                                    if (mounted) setState(() => _isProcessing = false);
                                  }
                                },
                          icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                          label: Text(
                            'Deduct from Wallet (Bal: ₹${walletBalance.toStringAsFixed(0)})',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Option 2: Pay via UPI / QR
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _isProcessing
                            ? null
                            : () async {
                                Navigator.pop(ctx);
                                setState(() => _isProcessing = true);
                                try {
                                  await FirebaseFirestore.instance.collection('drivers').doc(driverId).set({
                                    'pendingCommission': 0.0,
                                    'unpaidTripsCount': 0,
                                    'isBlockedDueToCommission': false,
                                    'lastCommissionPaidAt': FieldValue.serverTimestamp(),
                                  }, SetOptions(merge: true));

                                  await FirebaseFirestore.instance.collection('commission_payments').add({
                                    'driverId': driverId,
                                    'amountPaid': amountToPay,
                                    'tripsCleared': pendingTrips,
                                    'paidAt': FieldValue.serverTimestamp(),
                                    'paymentMethod': 'UPI / NetBanking / QR',
                                  });

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Commission paid successfully! Account active.'),
                                        backgroundColor: Color(0xFF059669),
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
                                  if (mounted) setState(() => _isProcessing = false);
                                }
                              },
                        icon: _isProcessing
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.qr_code_scanner, size: 18),
                        label: const Text(
                          'Pay via UPI / GPay / PhonePe / Paytm',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _withdrawModal(BuildContext context, String driverId, double walletBalance, String driverPhone) {
    final upiCtrl = TextEditingController(text: driverPhone.isNotEmpty ? '${driverPhone.replaceAll(RegExp(r'[^0-9]'), '')}@upi' : '');
    final amountCtrl = TextEditingController(text: walletBalance > 0 ? walletBalance.toStringAsFixed(0) : '0');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.account_balance, color: Color(0xFF047857), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Instant Bank / UPI Payout',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          'Available to Withdraw: ₹${walletBalance.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text('Transfer Amount (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569))),
                const SizedBox(height: 6),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('UPI ID / VPA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569))),
                const SizedBox(height: 6),
                TextField(
                  controller: upiCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. 8789601387@okaxis / @paytm',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      final val = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                      if (val <= 0 || val > walletBalance) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invalid withdrawal amount')),
                        );
                        return;
                      }
                      Navigator.pop(ctx);
                      try {
                        await FirebaseFirestore.instance.collection('payout_requests').add({
                          'driverId': driverId,
                          'amount': val,
                          'upiId': upiCtrl.text.trim(),
                          'status': 'processing',
                          'requestedAt': FieldValue.serverTimestamp(),
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Payout request of ₹${val.toStringAsFixed(0)} initiated via UPI!'),
                              backgroundColor: const Color(0xFF059669),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Payout notice: $e')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Transfer to UPI Immediately', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
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
        appBar: AppBar(title: const Text('Earnings & Commission Wallet')),
        body: const Center(child: Text('Sign in to view earnings')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Earnings & Commission Wallet",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0.5,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('drivers').doc(user.uid).snapshots(),
        builder: (context, driverSnap) {
          final rawDriver = driverSnap.data?.data();
          final driverData = rawDriver is Map ? Map<String, dynamic>.from(rawDriver) : <String, dynamic>{};
          final driverPhone = (driverData['phoneNumber'] ?? driverData['phone'] ?? user.phoneNumber ?? '').toString().trim();

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('driverId', isEqualTo: user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF059669)));
              }

              final allDocs = snapshot.data?.docs ?? [];
              final completedDocs = allDocs.where((doc) {
                final raw = doc.data();
                final data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
                final st = data['status']?.toString();
                return st == 'trip_completed' || st == 'completed';
              }).toList()
                ..sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>? ?? {};
                  final bData = b.data() as Map<String, dynamic>? ?? {};
                  final aDate = (aData['createdAt'] is Timestamp)
                      ? (aData['createdAt'] as Timestamp).toDate()
                      : DateTime.tryParse(aData['createdAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
                  final bDate = (bData['createdAt'] is Timestamp)
                      ? (bData['createdAt'] as Timestamp).toDate()
                      : DateTime.tryParse(bData['createdAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
                  return bDate.compareTo(aDate);
                });

              double completedTripsGross = 0.0;
              for (final doc in completedDocs) {
                final raw = doc.data();
                final data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
                final fareVal = (data['finalFare'] as num?)?.toDouble() ??
                    (data['estimatedFare'] as num?)?.toDouble() ??
                    0.0;
                completedTripsGross += fareVal;
              }

              final int totalCompletedTrips = completedDocs.length;
              const double commissionRate = 0.10;
              final double platformCommission = completedTripsGross * commissionRate;
              final double dynamicNetEarnings = completedTripsGross - platformCommission;

              final double storedWallet = (driverData['walletBalance'] as num?)?.toDouble() ?? 0.0;
              final double walletBalance = (storedWallet > dynamicNetEarnings)
                  ? storedWallet
                  : (dynamicNetEarnings > 0 ? dynamicNetEarnings : storedWallet);

              final double storedTotal = (driverData['totalEarnings'] as num?)?.toDouble() ?? 0.0;
              final double totalEarnings = (storedTotal > completedTripsGross)
                  ? storedTotal
                  : (completedTripsGross > 0 ? completedTripsGross : storedTotal);

              // 3-Trip Rule: Every 3 completed trips, driver clears 10% platform commission
              final int storedUnpaid = (driverData['unpaidTripsCount'] as num?)?.toInt() ?? 0;
              final int unpaidTrips = storedUnpaid > 0
                  ? storedUnpaid
                  : (totalCompletedTrips > 0 ? (totalCompletedTrips >= 3 ? 3 : totalCompletedTrips) : 0);

              final double storedPending = (driverData['pendingCommission'] as num?)?.toDouble() ?? 0.0;
              final double pendingCommission = storedPending > 0
                  ? storedPending
                  : (unpaidTrips > 0 && totalCompletedTrips > 0
                      ? (completedTripsGross / totalCompletedTrips * unpaidTrips * commissionRate)
                      : (totalCompletedTrips > 0 ? (completedTripsGross * commissionRate) : 0.0));

              final bool isBlocked = (driverData['isBlocked'] == true) ||
                  (driverData['isBlockedDueToCommission'] == true) ||
                  (unpaidTrips >= 3 && pendingCommission > 0);

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Blocked Alert Banner if 3 trips exceeded without paying commission
                    if (isBlocked) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.block, color: Color(0xFFDC2626), size: 26),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ACCOUNT TEMPORARILY BLOCKED (खाता ब्लॉक है)',
                                    style: TextStyle(
                                      color: Color(0xFF991B1B),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Rule: Pay 10% platform commission every 3 trips to receive new rides. Clear pending fee of ₹${pendingCommission.toStringAsFixed(0)} below to unblock instantly.',
                                    style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 11.5, height: 1.3),
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFDC2626),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () => _payCommissionModal(
                                      context,
                                      user.uid,
                                      pendingCommission,
                                      unpaidTrips,
                                      walletBalance,
                                    ),
                                    child: const Text('Unblock Account Now · Pay Fee', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // HERO WALLET BALANCE CARD: Dynamic Real Balance (Net 90% Take-Home)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF065F46), Color(0xFF047857), Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF059669).withValues(alpha: 0.25),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.account_balance_wallet_rounded, color: Color(0xFFA7F3D0), size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'AVAILABLE WALLET BALANCE',
                                    style: TextStyle(
                                      color: Color(0xFFA7F3D0),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'NET 90%',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '₹${walletBalance.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Take-Home',
                                style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Earned from $totalCompletedTrips completed rides across Jharkhand',
                            style: const TextStyle(color: Color(0xFFD1FAE5), fontSize: 11.5),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF065F46),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 11),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () => _withdrawModal(context, user.uid, walletBalance, driverPhone),
                                  icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                                  label: const Text(
                                    'Withdraw Payout',
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF59E0B),
                                    foregroundColor: const Color(0xFF78350F),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 11),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () => _payCommissionModal(
                                    context,
                                    user.uid,
                                    pendingCommission,
                                    unpaidTrips,
                                    walletBalance,
                                  ),
                                  icon: const Icon(Icons.receipt_long_rounded, size: 16),
                                  label: Text(
                                    'Pay Fee (₹${pendingCommission.toStringAsFixed(0)})',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 2 METRIC CARDS: Gross Total & Platform Commission
                    Row(
                      children: [
                        // Card A: Total Gross Bookings
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.payments_outlined, size: 15, color: Color(0xFF059669)),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Gross Fares',
                                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '₹${totalEarnings.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$totalCompletedTrips completed rides',
                                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF059669), fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Card B: District Car Commission (10%)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFFEF3C7)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.pie_chart_outline_rounded, size: 15, color: Color(0xFFD97706)),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Platform 10%',
                                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '₹${platformCommission.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFD97706)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Pending: ₹${pendingCommission.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: pendingCommission > 0 ? const Color(0xFFDC2626) : const Color(0xFF059669),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 3-TRIP COMMISSION SETTLEMENT PROGRESS CARD
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
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
                                    '3-Trip Settlement Rule (कमीशन नियम)',
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Unpaid rides count: $unpaidTrips / 3 completed',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: unpaidTrips >= 3 ? const Color(0xFFDC2626) : const Color(0xFF059669),
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF059669),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                                onPressed: () => _payCommissionModal(
                                  context,
                                  user.uid,
                                  pendingCommission,
                                  unpaidTrips,
                                  walletBalance,
                                ),
                                child: Text(
                                  'Pay ₹${pendingCommission.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: (unpaidTrips / 3).clamp(0.0, 1.0),
                              minHeight: 7,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                unpaidTrips >= 3 ? const Color(0xFFDC2626) : const Color(0xFF059669),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            unpaidTrips >= 3
                                ? '⚠️ 3-ride threshold reached. Clear pending ₹${pendingCommission.toStringAsFixed(0)} commission to avoid ride pauses.'
                                : 'Pay 10% platform fee after every 3 rides to keep your account online continuously.',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // SECTION 4: RECENT COMPLETED TRIPS FEED
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Completed Trips (${completedDocs.length})',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                        if (completedDocs.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${completedDocs.length} Rides',
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF047857)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (completedDocs.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: const [
                            Icon(Icons.directions_car_outlined, size: 40, color: Color(0xFF94A3B8)),
                            SizedBox(height: 10),
                            Text(
                              'No completed trips yet',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF334155)),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Turn online on the home screen to accept bookings. Your completed fares will show here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    else
                      ...completedDocs.map((doc) {
                        final raw = doc.data();
                        final data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
                        final fare = (data['finalFare'] as num?)?.toDouble() ??
                            (data['estimatedFare'] as num?)?.toDouble() ??
                            0.0;
                        final fee10 = (fare * 0.10).roundToDouble();
                        final netTakeHome = fare - fee10;
                        final readableId = data['readableId']?.toString() ?? doc.id.substring(0, 8);
                        final pickup = data['pickup']?['address']?.toString() ?? 'Pickup Location';
                        final dest = data['destination']?['address']?.toString() ?? 'Destination Drop';
                        final customerName = (data['customerName'] ?? data['riderName'] ?? data['name'])?.toString().trim() ?? 'District Customer';
                        final customerPhone = (data['customerPhone'] ?? data['riderPhone'] ?? data['phone'])?.toString().trim() ?? '+91 87896 01387';
                        final paymentMethod = data['paymentMethod']?.toString().toUpperCase() ?? 'CASH';

                        DateTime tripDate = DateTime.now();
                        if (data['createdAt'] is Timestamp) {
                          tripDate = (data['createdAt'] as Timestamp).toDate();
                        } else if (data['createdAt'] != null) {
                          tripDate = DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now();
                        }
                        final formattedDate = DateFormat('dd MMM yyyy · hh:mm a').format(tripDate);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Strip: Status Badge + Booking ID + Date
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFECFDF5),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFFA7F3D0)),
                                        ),
                                        child: const Text(
                                          'COMPLETED ✓',
                                          style: TextStyle(
                                            color: Color(0xFF047857),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '#$readableId',
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF334155)),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    formattedDate,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Customer Details Strip with Direct Calling Action
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFDCFCE7),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.person, color: Color(0xFF047857), size: 15),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            customerName,
                                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            customerPhone,
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _callCustomer(customerPhone),
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF059669),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF059669).withValues(alpha: 0.3),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Center(child: Icon(Icons.call, color: Colors.white, size: 16)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Route: Pickup and Destination
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.radio_button_checked, size: 14, color: Color(0xFF059669)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      pickup,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF0F172A)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on, size: 14, color: Color(0xFFDC2626)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      dest,
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Financial Breakdown Strip
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Gross Fare', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                                        Text('₹${fare.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        const Text('10% Platform', style: TextStyle(fontSize: 10, color: Color(0xFFB45309), fontWeight: FontWeight.bold)),
                                        Text('-₹${fee10.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFD97706))),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text('Take-Home Net', style: TextStyle(fontSize: 10, color: Color(0xFF047857), fontWeight: FontWeight.bold)),
                                        Text('₹${netTakeHome.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF059669))),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFCBD5E1)),
                                      ),
                                      child: Text(
                                        paymentMethod,
                                        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFF334155)),
                                      ),
                                    ),
                                  ],
                                ),
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
