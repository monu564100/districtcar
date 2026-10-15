import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import '../../services/driver_service.dart';

class DriverConsentScreen extends ConsumerStatefulWidget {
  const DriverConsentScreen({super.key});

  @override
  ConsumerState<DriverConsentScreen> createState() => _DriverConsentScreenState();
}

class _DriverConsentScreenState extends ConsumerState<DriverConsentScreen> {
  bool _consentLicense = false;
  bool _consentFare = false;
  bool _consentCancellation = false;
  bool _consentLocation = false;
  bool _consentCommission = false;
  bool _isSubmitting = false;

  bool get _allConsentsGiven =>
      _consentLicense && _consentFare && _consentCancellation && _consentLocation && _consentCommission;

  void _toggleSelectAll(bool? val) {
    final v = val ?? false;
    setState(() {
      _consentLicense = v;
      _consentFare = v;
      _consentCancellation = v;
      _consentLocation = v;
      _consentCommission = v;
    });
  }

  Future<void> _submitConsent() async {
    if (!_allConsentsGiven) return;
    setState(() => _isSubmitting = true);

    try {
      final user = ref.read(driverServiceProvider).currentUser;
      final uid = user?.uid ?? 'driver_demo';

      // 1. Save in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('driver_consent_given', true);
      await prefs.setString('driver_consent_timestamp', DateTime.now().toIso8601String());

      // 2. Persist in Firestore
      try {
        await FirebaseFirestore.instance.collection('drivers').doc(uid).set({
          'consentCompleted': true,
          'consentCompletedAt': FieldValue.serverTimestamp(),
          'consentVersion': '1.0',
          'consentClauses': {
            'licenseAndInsurance': true,
            'transparentPricing': true,
            'zeroCancellationCommitment': true,
            'liveGpsTracking': true,
            'platformCommission': true,
          },
        }, SetOptions(merge: true));
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consent submitted! Welcome to District Car Partner Dashboard. 🚀'),
            backgroundColor: Color(0xFF059669),
          ),
        );
        context.go('/driver-home');
      }
    } catch (e) {
      if (mounted) {
        context.go('/driver-home');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Partner Consent & Terms', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF065F46), Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF059669).withValues(alpha: 0.25),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.verified_user, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Partner Code of Conduct',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'सुरक्षित, पारदर्शी और भरोसेमंद यात्रा के लिए सहमति',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quick Select All
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Select All Agreements (सभी नियम स्वीकार करें)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          Checkbox(
                            value: _allConsentsGiven,
                            activeColor: const Color(0xFF059669),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: _toggleSelectAll,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Clause 1: License & Safety
                    _buildConsentCard(
                      icon: Icons.badge_outlined,
                      title: 'Valid Driving License & Vehicle RC',
                      hindiTitle: 'वैध ड्राइविंग लाइसेंस एवं वाहन पंजीकरण',
                      description:
                          'I declare that I possess a valid driving license, valid vehicle RC, fitness, and insurance as per Indian Motor Vehicles Act.',
                      value: _consentLicense,
                      onChanged: (v) => setState(() => _consentLicense = v ?? false),
                    ),
                    const SizedBox(height: 12),

                    // Clause 2: Transparent Fixed Pricing
                    _buildConsentCard(
                      icon: Icons.currency_rupee,
                      title: 'Transparent Fixed Rural Fares',
                      hindiTitle: 'पारदर्शी किराया — अतिरिक्त नकद नहीं मांगना',
                      description:
                          'I commit to adhering strictly to the in-app fixed fare. I will never demand surge pricing, extra offline cash, or negotiate fares with passengers.',
                      value: _consentFare,
                      onChanged: (v) => setState(() => _consentFare = v ?? false),
                    ),
                    const SizedBox(height: 12),

                    // Clause 3: Zero-Cancellation Commitment
                    _buildConsentCard(
                      icon: Icons.handshake_outlined,
                      title: 'Zero Cancellation Commitment on Accepted Rides',
                      hindiTitle: 'स्वीकार की गई सवारी रद्द न करने का वचन',
                      description:
                          'I understand that once I tap "Accept Ride", the passenger depends on me. I will reach the pickup point punctually. Unjustified cancellation damages passenger trust and leads to suspension.',
                      value: _consentCancellation,
                      onChanged: (v) => setState(() => _consentCancellation = v ?? false),
                    ),
                    const SizedBox(height: 12),

                    // Clause 4: Live GPS Tracking
                    _buildConsentCard(
                      icon: Icons.my_location,
                      title: 'Live Journey GPS Tracking',
                      hindiTitle: 'सवारी के दौरान लाइव लोकेशन शेयरिंग',
                      description:
                          'I agree to share real-time GPS location with the rider and District Car safety dispatch during active journeys for passenger safety.',
                      value: _consentLocation,
                      onChanged: (v) => setState(() => _consentLocation = v ?? false),
                    ),
                    const SizedBox(height: 12),

                    // Clause 5: Platform Commission
                    _buildConsentCard(
                      icon: Icons.account_balance_wallet_outlined,
                      title: '10% Platform Commission Agreement',
                      hindiTitle: '10% प्लेटफॉर्म कमीशन सहमति',
                      description:
                          'I understand that District Car charges a nominal 10% platform fee on completed journeys, retained or settled transparently via my Partner Wallet.',
                      value: _consentCommission,
                      onChanged: (v) => setState(() => _consentCommission = v ?? false),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom CTA
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: (_allConsentsGiven && !_isSubmitting) ? _submitConsent : null,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _allConsentsGiven ? 'I AGREE & CONTINUE (स्वीकार करें)' : 'PLEASE ACCEPT ALL CLAUSES',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: _allConsentsGiven ? Colors.white : Colors.grey.shade600,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentCard({
    required IconData icon,
    required String title,
    required String hindiTitle,
    required String description,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: value ? const Color(0xFF10B981) : Colors.grey.shade200, width: value ? 1.5 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: value ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: value ? const Color(0xFF059669) : Colors.grey.shade600, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hindiTitle,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Color(0xFF059669)),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, height: 1.35),
                  ),
                ],
              ),
            ),
            Checkbox(
              value: value,
              activeColor: const Color(0xFF059669),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
