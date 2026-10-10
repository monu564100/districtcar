import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:district_car_shared/theme/app_theme.dart';

/// Top-level background message handler for Android OS background execution
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM Background message handled: ${message.messageId} - ${message.notification?.title}');
}

class FCMNotificationService {
  static final DateTime _sessionStartTime = DateTime.now();
  static final Set<String> _shownNotifIds = {};
  static bool _isListeningBroadcasts = false;
  static String? _cachedServerKey;

  /// Live District Car Notification Worker Server URL
  static const String notificationServerBaseUrl = 'https://notification.projectmarket.in';

  /// Android high-importance notification channel definition
  static const String notificationChannelId = 'district_car_rides';

  /// Initialize Firebase Cloud Messaging tokens & topics
  static Future<void> initFCM({
    required String role, // 'customer' or 'driver'
    String? userId,
    String? category, // optional vehicle category for driver
  }) async {
    try {
      final messaging = FirebaseMessaging.instance;

      // 1. Request OS Notification Permission (Essential for Android 13+ & iOS)
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('FCM Authorization Status ($role): ${settings.authorizationStatus}');

      // 2. Fetch Device Token
      String? token;
      try {
        token = await messaging.getToken();
      } catch (e) {
        debugPrint('FCM getToken notice: $e');
      }

      if (token != null && token.isNotEmpty) {
        debugPrint('FCM Token ($role): $token');

        // Subscribe to General & Specific Topics
        try {
          if (!kIsWeb) {
            await messaging.subscribeToTopic('all_users');
            if (role == 'driver') {
              await messaging.subscribeToTopic('drivers');
              if (category != null && category.isNotEmpty) {
                await messaging.subscribeToTopic('driver_${category.toLowerCase().trim()}');
              }
              if (userId != null && userId.isNotEmpty) {
                await messaging.subscribeToTopic('driver_$userId');
              }
            } else {
              await messaging.subscribeToTopic('customers');
              if (userId != null && userId.isNotEmpty) {
                await messaging.subscribeToTopic('customer_$userId');
              }
            }
          }
        } catch (subErr) {
          debugPrint('FCM topic subscription notice: $subErr');
        }

        // Save token to Firestore profile for direct target dispatch
        if (userId != null && userId.isNotEmpty) {
          final collection = role == 'driver' ? 'drivers' : 'users';
          await FirebaseFirestore.instance.collection(collection).doc(userId).set({
            'fcmToken': token,
            'lastFCMTokenUpdate': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }

      // 3. Foreground Message Listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Foreground FCM message received: ${message.notification?.title}');
      });

      // 4. Message Click / App Open Listeners
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('User tapped notification to open app: ${message.data}');
      });
    } catch (e) {
      debugPrint('FCM initialization notice: $e');
    }
  }

  /// Subscribe to a specific FCM topic (e.g., driver_car, customer_xxx)
  static Future<void> subscribeToTopic(String topic) async {
    if (kIsWeb) return;
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic.toLowerCase().trim());
      debugPrint('FCM subscribed to topic: $topic');
    } catch (e) {
      debugPrint('FCM topic subscription notice: $e');
    }
  }

  /// Unsubscribe from a specific FCM topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    if (kIsWeb) return;
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic.toLowerCase().trim());
      debugPrint('FCM unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('FCM topic unsubscribe notice: $e');
    }
  }


  /// Manually update or cache FCM server key
  static void setStaticServerKey(String key) {
    _cachedServerKey = key.trim();
  }

  /// Store FCM server key to Firestore app_config/fcm_settings so all apps immediately have access
  static Future<void> saveServerKeyToFirestore(String key) async {
    _cachedServerKey = key.trim();
    try {
      await FirebaseFirestore.instance.collection('app_config').doc('fcm_settings').set({
        'serverKey': key.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving FCM server key: $e');
    }
  }

  /// Retrieve FCM Server Key from Firestore app_config
  static Future<String?> _getServerKey() async {
    if (_cachedServerKey != null && _cachedServerKey!.isNotEmpty) {
      return _cachedServerKey;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('fcm_settings')
          .get();
      if (doc.exists) {
        _cachedServerKey = doc.data()?['serverKey'] as String?;
      }
    } catch (e) {
      debugPrint('Failed to load FCM server key: $e');
    }
    return _cachedServerKey;
  }

  /// Low-level HTTP dispatch to Firebase Cloud Messaging API
  static Future<void> _sendFCMHttp({
    required String target, // device token or /topics/topic_name
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    final serverKey = await _getServerKey();
    if (serverKey == null || serverKey.isEmpty) {
      debugPrint('FCM dispatch notice: No FCM serverKey configured in app_config/fcm_settings.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode({
          'to': target,
          'priority': 'high',
          'notification': {
            'title': title,
            'body': body,
            'sound': 'default',
            'android_channel_id': notificationChannelId,
            if (imageUrl != null && imageUrl.isNotEmpty) 'image': imageUrl,
          },
          'data': {
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'title': title,
            'body': body,
            if (data != null) ...data,
          },
        }),
      );

      debugPrint('FCM HTTP send status to $target: ${response.statusCode}');
    } catch (e) {
      debugPrint('FCM HTTP dispatch error: $e');
    }
  }

  /// DISPATCH 1: When Customer Books a Ride -> Push Notification to all matching Drivers
  static Future<void> sendBookingOfferedNotificationToDrivers({
    required String bookingId,
    required String readableId,
    required String categoryId,
    required String pickupAddress,
    required String destinationAddress,
    required double estimatedFare,
    List<String>? driverTokens,
    List<String>? driverIds,
  }) async {
    final title = '🚖 New Ride Request! (₹${estimatedFare.toInt()})';
    final body = '$pickupAddress ➔ $destinationAddress [${categoryId.toUpperCase()}]';

    final dataPayload = {
      'type': 'new_booking_offered',
      'bookingId': bookingId,
      'readableId': readableId,
      'categoryId': categoryId,
      'fare': estimatedFare.toString(),
      'pickup': pickupAddress,
      'destination': destinationAddress,
    };

    // 1. Relay to background notification_service worker (Live Server & Localhost fallback)
    try {
      final payload = jsonEncode({
        'bookingId': bookingId,
        'readableId': readableId,
        'categoryId': categoryId,
        'pickupAddress': pickupAddress,
        'destinationAddress': destinationAddress,
        'estimatedFare': estimatedFare,
      });

      // Dispatch to live server
      await http.post(
        Uri.parse('$notificationServerBaseUrl/api/notifications/booking-created'),
        headers: {'Content-Type': 'application/json'},
        body: payload,
      ).timeout(const Duration(seconds: 4)).catchError((_) async {
        // Fallback to localhost if testing locally
        return await http.post(
          Uri.parse('http://localhost:4000/api/notifications/booking-created'),
          headers: {'Content-Type': 'application/json'},
          body: payload,
        ).timeout(const Duration(seconds: 2));
      });
    } catch (_) {}

    // 2. Write to Firestore 'notifications' collection for in-app popups & audit log
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': title,
        'body': body,
        'targetAudience': 'drivers',
        'type': 'new_booking_offered',
        'bookingId': bookingId,
        'readableId': readableId,
        'categoryId': categoryId,
        'status': 'delivered',
        'sentAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    // 2. Dispatch to each driver's personal inbox
    if (driverIds != null) {
      for (final dId in driverIds) {
        try {
          await FirebaseFirestore.instance
              .collection('drivers')
              .doc(dId)
              .collection('inbox_notifications')
              .add({
            'title': title,
            'body': body,
            'bookingId': bookingId,
            'sentAt': FieldValue.serverTimestamp(),
            'isRead': false,
          });
        } catch (_) {}
      }
    }

    // 3. Dispatch Background Push to individual device tokens
    if (driverTokens != null && driverTokens.isNotEmpty) {
      for (final token in driverTokens) {
        await _sendFCMHttp(
          target: token,
          title: title,
          body: body,
          data: dataPayload,
        );
      }
    }

    // 4. Dispatch Background Push to Category Topic & General Drivers Topic
    final catTopic = '/topics/driver_${categoryId.toLowerCase().trim()}';
    await _sendFCMHttp(
      target: catTopic,
      title: title,
      body: body,
      data: dataPayload,
    );
  }

  /// DISPATCH 2: When Driver Accepts Ride -> Push Notification to Customer
  static Future<void> sendBookingAcceptedNotificationToCustomer({
    required String bookingId,
    required String customerId,
    String? customerToken,
    required String driverName,
    required String driverPhone,
    required String vehiclePlate,
    required String vehicleModel,
    String? rideOtp,
  }) async {
    final title = '🎉 Booking Confirmed! Driver Assigned';
    final body = '$driverName is on the way in $vehicleModel ($vehiclePlate). OTP: ${rideOtp ?? ''}';

    final dataPayload = {
      'type': 'booking_accepted',
      'bookingId': bookingId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'vehiclePlate': vehiclePlate,
      'vehicleModel': vehicleModel,
      'rideOtp': rideOtp ?? '',
    };

    // 1. Relay to background notification_service worker (Live Server & Localhost fallback)
    try {
      final payload = jsonEncode({
        'bookingId': bookingId,
        'customerId': customerId,
        'driverName': driverName,
        'driverPhone': driverPhone,
        'vehiclePlate': vehiclePlate,
        'vehicleModel': vehicleModel,
        'rideOtp': rideOtp,
      });

      await http.post(
        Uri.parse('$notificationServerBaseUrl/api/notifications/booking-accepted'),
        headers: {'Content-Type': 'application/json'},
        body: payload,
      ).timeout(const Duration(seconds: 4)).catchError((_) async {
        return await http.post(
          Uri.parse('http://localhost:4000/api/notifications/booking-accepted'),
          headers: {'Content-Type': 'application/json'},
          body: payload,
        ).timeout(const Duration(seconds: 2));
      });
    } catch (_) {}

    // 2. Write to Firestore 'notifications' collection
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': title,
        'body': body,
        'targetAudience': 'customers',
        'targetUserId': customerId,
        'type': 'booking_accepted',
        'bookingId': bookingId,
        'status': 'delivered',
        'sentAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    // 2. Write to Customer's personal inbox
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(customerId)
          .collection('inbox_notifications')
          .add({
        'title': title,
        'body': body,
        'bookingId': bookingId,
        'driverName': driverName,
        'driverPhone': driverPhone,
        'vehiclePlate': vehiclePlate,
        'sentAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (_) {}

    // 3. Look up Customer Token if not supplied
    String? targetToken = customerToken;
    if (targetToken == null || targetToken.isEmpty) {
      try {
        final custDoc = await FirebaseFirestore.instance.collection('users').doc(customerId).get();
        targetToken = custDoc.data()?['fcmToken'] as String?;
      } catch (_) {}
    }

    // 4. Dispatch Background Push to Customer Token
    if (targetToken != null && targetToken.isNotEmpty) {
      await _sendFCMHttp(
        target: targetToken,
        title: title,
        body: body,
        data: dataPayload,
      );
    }

    // 5. Also dispatch to Customer personal topic
    await _sendFCMHttp(
      target: '/topics/customer_$customerId',
      title: title,
      body: body,
      data: dataPayload,
    );
  }

  /// Real-time In-App Push Notification Listener
  static void listenToLiveBroadcasts({
    required BuildContext context,
    required String role, // 'customer' or 'driver'
    String? currentUserId,
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
          final targetUser = data['targetUserId'] as String?;
          final sentAt = (data['sentAt'] as Timestamp?)?.toDate();

          // Audience check
          if (audience != 'all' && audience != targetAudience) continue;
          if (targetUser != null && currentUserId != null && targetUser != currentUserId) continue;

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
            break;
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
