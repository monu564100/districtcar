import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import '../../widgets/admin_sidebar.dart';

class RemoteUpdateScreen extends StatefulWidget {
  const RemoteUpdateScreen({super.key});

  @override
  State<RemoteUpdateScreen> createState() => _RemoteUpdateScreenState();
}

class _RemoteUpdateScreenState extends State<RemoteUpdateScreen> {
  // Customer App Form Controllers
  final _custVersionCtrl = TextEditingController(text: '1.0.0');
  final _custBuildNumberCtrl = TextEditingController(text: '5');
  final _custUpdateUrlCtrl = TextEditingController(text: 'https://districtcarjharkhand.com/DistrictCar_Customer.apk');
  final _custTitleCtrl = TextEditingController(text: 'District Car Tours & Travels Update (Build 5)');
  final _custMessageCtrl = TextEditingController(text: 'New Tours & Travels feature: explore iconic waterfalls, Baidyanath Dham & hills with dedicated cab packages, stay duration, and live fare calculation.');
  bool _custIsForceUpdate = true;
  bool _custIsActive = true;

  // Driver App Form Controllers
  final _drvVersionCtrl = TextEditingController(text: '1.0.0');
  final _drvBuildNumberCtrl = TextEditingController(text: '5');
  final _drvUpdateUrlCtrl = TextEditingController(text: 'https://districtcarjharkhand.com/DistrictCar_Driver.apk');
  final _drvTitleCtrl = TextEditingController(text: 'Driver Partner App Update (सारथी - Build 5)');
  final _drvMessageCtrl = TextEditingController(text: 'New Tours & Travels ride offers, transparent stay waiting allowance, and enhanced push notifications.');
  bool _drvIsForceUpdate = true;
  bool _drvIsActive = true;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  void _loadCurrentConfig() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('app_config').doc('remote_updates').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final cust = data['customer_app'] as Map<String, dynamic>? ?? {};
        final drv = data['driver_app'] as Map<String, dynamic>? ?? {};

        if (mounted) {
          setState(() {
            if (cust['latestVersion'] != null) _custVersionCtrl.text = cust['latestVersion'];
            if (cust['buildNumber'] != null) _custBuildNumberCtrl.text = cust['buildNumber'].toString();
            if (cust['updateUrl'] != null) _custUpdateUrlCtrl.text = cust['updateUrl'];
            if (cust['title'] != null) _custTitleCtrl.text = cust['title'];
            if (cust['message'] != null) _custMessageCtrl.text = cust['message'];
            _custIsForceUpdate = cust['isForceUpdate'] == true;
            _custIsActive = cust['isActive'] ?? true;

            if (drv['latestVersion'] != null) _drvVersionCtrl.text = drv['latestVersion'];
            if (drv['buildNumber'] != null) _drvBuildNumberCtrl.text = drv['buildNumber'].toString();
            if (drv['updateUrl'] != null) _drvUpdateUrlCtrl.text = drv['updateUrl'];
            if (drv['title'] != null) _drvTitleCtrl.text = drv['title'];
            if (drv['message'] != null) _drvMessageCtrl.text = drv['message'];
            _drvIsForceUpdate = drv['isForceUpdate'] == true;
            _drvIsActive = drv['isActive'] ?? true;
          });
        }
      }
    } catch (_) {}
  }

  void _saveRemoteUpdates() async {
    setState(() => _isLoading = true);

    try {
      final updateData = {
        'customer_app': {
          'latestVersion': _custVersionCtrl.text.trim(),
          'buildNumber': int.tryParse(_custBuildNumberCtrl.text.trim()) ?? 1,
          'updateUrl': _custUpdateUrlCtrl.text.trim(),
          'title': _custTitleCtrl.text.trim(),
          'message': _custMessageCtrl.text.trim(),
          'isForceUpdate': _custIsForceUpdate,
          'isActive': _custIsActive,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'driver_app': {
          'latestVersion': _drvVersionCtrl.text.trim(),
          'buildNumber': int.tryParse(_drvBuildNumberCtrl.text.trim()) ?? 1,
          'updateUrl': _drvUpdateUrlCtrl.text.trim(),
          'title': _drvTitleCtrl.text.trim(),
          'message': _drvMessageCtrl.text.trim(),
          'isForceUpdate': _drvIsForceUpdate,
          'isActive': _drvIsActive,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'pushedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('app_config').doc('remote_updates').set(
        updateData,
        SetOptions(merge: true),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Remote update configuration pushed successfully to all live apps! 🚀'),
            backgroundColor: Color(0xFF15803D),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error pushing update: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const AdminSidebar(activeRoute: '/remote-updates'),
          Expanded(
            child: SingleChildScrollView(
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
                            'Remote App Updates (OTA Push)',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Push mandatory or optional updates to Customer & Driver apps. Users see an instant update popup.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _isLoading ? null : _saveRemoteUpdates,
                        icon: _isLoading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.cloud_upload_outlined, size: 20),
                        label: Text(_isLoading ? 'Pushing...' : 'Push Live Update', style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer App Configuration Box
                      Expanded(
                        child: _buildAppUpdateCard(
                          title: 'Customer App (District Car)',
                          appType: 'Customer',
                          versionCtrl: _custVersionCtrl,
                          buildCtrl: _custBuildNumberCtrl,
                          urlCtrl: _custUpdateUrlCtrl,
                          titleCtrl: _custTitleCtrl,
                          msgCtrl: _custMessageCtrl,
                          isForce: _custIsForceUpdate,
                          isActive: _custIsActive,
                          onForceChanged: (v) => setState(() => _custIsForceUpdate = v),
                          onActiveChanged: (v) => setState(() => _custIsActive = v),
                          accentColor: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Driver App Configuration Box
                      Expanded(
                        child: _buildAppUpdateCard(
                          title: 'Driver Partner App (सारथी)',
                          appType: 'Driver',
                          versionCtrl: _drvVersionCtrl,
                          buildCtrl: _drvBuildNumberCtrl,
                          urlCtrl: _drvUpdateUrlCtrl,
                          titleCtrl: _drvTitleCtrl,
                          msgCtrl: _drvMessageCtrl,
                          isForce: _drvIsForceUpdate,
                          isActive: _drvIsActive,
                          onForceChanged: (v) => setState(() => _drvIsForceUpdate = v),
                          onActiveChanged: (v) => setState(() => _drvIsActive = v),
                          accentColor: const Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppUpdateCard({
    required String title,
    required String appType,
    required TextEditingController versionCtrl,
    required TextEditingController buildCtrl,
    required TextEditingController urlCtrl,
    required TextEditingController titleCtrl,
    required TextEditingController msgCtrl,
    required bool isForce,
    required bool isActive,
    required ValueChanged<bool> onForceChanged,
    required ValueChanged<bool> onActiveChanged,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: accentColor.withOpacity(0.12), shape: BoxShape.circle),
                    child: Icon(Icons.system_update_alt, color: accentColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                ],
              ),
              Switch(value: isActive, activeColor: accentColor, onChanged: onActiveChanged),
            ],
          ),
          const Divider(height: 24),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Latest Version Tag', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: versionCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. 1.0.3',
                        filled: true,
                        fillColor: AppColors.surfaceSecondary,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Build Number (Integer)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: buildCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'e.g. 4',
                        filled: true,
                        fillColor: AppColors.surfaceSecondary,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text('Update Download / Store URL', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
          const SizedBox(height: 6),
          TextField(
            controller: urlCtrl,
            decoration: InputDecoration(
              hintText: 'https://districtcarjharkhand.com/app.apk or Play Store link',
              prefixIcon: const Icon(Icons.link, size: 20),
              filled: true,
              fillColor: AppColors.surfaceSecondary,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),

          const Text('Popup Dialog Title', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
          const SizedBox(height: 6),
          TextField(
            controller: titleCtrl,
            decoration: InputDecoration(
              hintText: 'New Update Available',
              filled: true,
              fillColor: AppColors.surfaceSecondary,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),

          const Text('Update Release Notes / Message', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
          const SizedBox(height: 6),
          TextField(
            controller: msgCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Describe fixes, features and improvements...',
              filled: true,
              fillColor: AppColors.surfaceSecondary,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isForce ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isForce ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mandatory Force Update (अनिवार्य अपडेट)',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: isForce ? const Color(0xFFB91C1C) : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Cannot dismiss dialog until application is updated.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Switch(value: isForce, activeColor: const Color(0xFFDC2626), onChanged: onForceChanged),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
