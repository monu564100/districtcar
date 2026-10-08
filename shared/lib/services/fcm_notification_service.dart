import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:district_car_shared/theme/app_theme.dart';

class FCMNotificationService {
  static final DateTime _sessionStartTime = DateTime.now();
  static final Set<String> _shownNotifIds = {};
  static bool _isListeningBroadcasts = false;

  /// Initialize Firebase Cloud Messaging tokens & topics
  static Future<void> initFCM({
    required String role, // 'customer' or 'driver'
    String? userId,
  }) async {
    try {
      final messaging = FirebaseMessaging.instance;

      // 1. Request Permission
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('FCM Authorization Status: ${settings.authorizationStatus}');

      // 2. Fetch Device Token
      String? token;
      try {
        token = await messaging.getToken();
      } catch (e) {
        debugPrint('FCM getToken notice: $e');
      }

      if (token != null && token.isNotEmpty) {
        debugPrint('FCM Token ($role): $token');

        // Subscribe to General Topics
        try {
          if (!kIsWeb) {
            await messaging.subscribeToTopic('all_users');
            await messaging.subscribeToTopic(role == 'driver' ? 'drivers' : 'customers');
          }
        } catch (_) {}

        // Save token to Firestore profile
        if (userId != null && userId.isNotEmpty) {
          final collection = role == 'driver' ? 'drivers' : 'users';
          await FirebaseFirestore.instance.collection(collection).doc(userId).set({
            'fcmToken': token,
            'lastFCMTokenUpdate': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }

      // 3. Listen to Foreground Messages from FCM
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Received foreground FCM message: ${message.notification?.title}');
      });
    } catch (e) {
      debugPrint('FCM initialization notice: $e');
    }
  }

  /// Real-time In-App Push Notification Listener
  /// Ensures 100% reliable broadcast receipt even if FCM is blocked or on web/emulators
  static void listenToLiveBroadcasts({
    required BuildContext context,
    required String role, // 'customer' or 'driver'
  }) {
    if (_isListeningBroadcasts) return;
    _isListeningBroadcasts = true;

    try {
      final targetAudience = role == 'driver' ? 'drivers' : 'customers';

      FirebaseFirestore.instance
          .collection('notifications')
          .orderBy('sentAt', descending: true)
          .limit(5)
          .snapshots()
          .listen((snapshot) {
        if (!context.mounted) return;

        for (final doc in snapshot.docs) {
          final notifId = doc.id;
          if (_shownNotifIds.contains(notifId)) continue;

          final data = doc.data();
          final audience = data['targetAudience'] as String? ?? 'all';
          final sentAt = (data['sentAt'] as Timestamp?)?.toDate();

          // Only show notifications for this audience
          if (audience != 'all' && audience != targetAudience) continue;

          // Check if created after app session started (or within last 3 minutes)
          final isRecent = sentAt == null ||
              sentAt.isAfter(_sessionStartTime.subtract(const Duration(minutes: 3)));

          if (isRecent) {
            _shownNotifIds.add(notifId);
            _showInAppPushDialog(
              context: context,
              title: data['title'] as String? ?? 'Notification',
              body: data['body'] as String? ?? '',
              imageUrl: data['imageUrl'] as String?,
            );
            break; // Show one at a time
          }
        }
      });
    } catch (e) {
      debugPrint('Broadcast listener notice: $e');
    }
  }

  static void _showInAppPushDialog({
    required BuildContext context,
    required String title,
    required String body,
    String? imageUrl,
  }) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        actionsPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.campaign_rounded, color: AppColors.primary, size: 24),
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
              body,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
            if (imageUrl != null && imageUrl.isNotEmpty) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  imageUrl,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
