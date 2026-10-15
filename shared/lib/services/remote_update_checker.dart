import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:district_car_shared/theme/app_theme.dart';

class RemoteUpdateChecker {
  static bool _hasShown = false;

  /// Check Firestore app_config/remote_updates for Customer or Driver app
  static Future<void> checkAndShowUpdateDialog({
    required BuildContext context,
    required String appKey, // 'customer_app' or 'driver_app'
    required int currentBuildNumber,
  }) async {
    if (kIsWeb) return;
    if (_hasShown) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('app_config').doc('remote_updates').get();
      if (!doc.exists || doc.data() == null) return;

      final config = doc.data()![appKey] as Map<String, dynamic>?;
      if (config == null || config['isActive'] == false) return;

      final int targetBuild = config['buildNumber'] as int? ?? 1;
      final String updateUrl = config['updateUrl'] as String? ?? 'https://districtcarjharkhand.com';
      final String title = config['title'] as String? ?? 'Update Available';
      final String message = config['message'] as String? ??
          'A new version with important performance improvements and bug fixes is now ready.';
      final bool isForceUpdate = config['isForceUpdate'] == true;

      // If remote build is newer than installed build
      if (targetBuild > currentBuildNumber && context.mounted) {
        _hasShown = true;
        await showDialog(
          context: context,
          barrierDismissible: !isForceUpdate,
          builder: (ctx) {
            return PopScope(
              canPop: !isForceUpdate,
              child: AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.system_update, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isForceUpdate
                                  ? 'This update is mandatory to ensure uninterrupted cab booking services.'
                                  : 'Update now for the latest features.',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                actions: [
                  if (!isForceUpdate)
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Later', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
                    ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      final uri = Uri.parse(updateUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: const Text(
                      'Update Now (अपडेट करें)',
                      style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }
    } catch (_) {}
  }
}
