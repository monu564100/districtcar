import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import '../../widgets/admin_scaffold.dart';

class NotificationBroadcastScreen extends StatefulWidget {
  const NotificationBroadcastScreen({super.key});

  @override
  State<NotificationBroadcastScreen> createState() => _NotificationBroadcastScreenState();
}

class _NotificationBroadcastScreenState extends State<NotificationBroadcastScreen> {
  final TextEditingController _titleCtrl = TextEditingController(text: '🎉 35% Off Round-Trip Special!');
  final TextEditingController _bodyCtrl = TextEditingController(
    text: 'Book your village return trip with District Car and enjoy an automatic 35% discount on the return leg!',
  );
  final TextEditingController _imageUrlCtrl = TextEditingController(
    text: 'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?w=800&auto=format&fit=crop',
  );

  String _targetAudience = 'all'; // all, customers, drivers
  bool _publishAsBannerOffer = true;
  bool _isSending = false;
  String? _fcmServerKey;

  final List<Map<String, String>> _templates = [
    {
      'name': '🌄 Chalo Netarhat Ghoom Ke Aatey Hai!',
      'title': '🌄 Chalo Netarhat Ghoom Ke Aatey Hai!',
      'body': 'Bhai, laptop band kar, Maggie aur pahadon ki hawa bula rahi hai! Netarhat Magnolia Sunset Point cab book karo.\n💡 "Ghar wale pooch rahe hain shaadi kab karoge? Humne bola: pehle Netarhat ka sunset dekh aane do!"',
      'imageUrl': 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800&auto=format&fit=crop',
      'audience': 'customers',
    },
    {
      'name': '🚩 Har Har Mahadev! Deoghar Darshan',
      'title': '🚩 Har Har Mahadev! Chalo Deoghar Darshan!',
      'body': 'Peda khane aur Baba Dham ka darshan karne ka man hai? AC cab book karo - No tension, full aashirwad!\n💡 "Dost ne pucha: Itna tension kyu le rahe ho? Humne bola: Baidyanath Dham ghoom aao, sab theek ho jayega!"',
      'imageUrl': 'https://images.unsplash.com/photo-1582510003544-4d00b7f74220?w=800&auto=format&fit=crop',
      'audience': 'customers',
    },
    {
      'name': '🏎️ Patratu Valley Romantic Drive',
      'title': '🏎️ Patratu Valley ke Ghumavdaar Raaste!',
      'body': 'Bollywood style scenic drive aur lake boating! Chai, pakode aur romantic roads ka trip planned!\n💡 "Traffic se tang aa chuke ho? Patratu ki hawaon me gaadi chalao, BP apne aap normal ho jayega!"',
      'imageUrl': 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=800&auto=format&fit=crop',
      'audience': 'customers',
    },
    {
      'name': '🌊 Hundru Falls Weekend Masti',
      'title': '🌊 Weekend me Hundru Falls ka Dhamaka!',
      'body': 'Jharna dekhna hai? Chalo Ranchi ke Hundru aur Jonha Fall! Friends group ke sath instant SUV book karo.\n💡 "Gym join karne ki sochi thi, par doston ne bola Hundru Falls ki seedhiyan chadh lo, cardio ho jayega!"',
      'imageUrl': 'https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?w=800&auto=format&fit=crop',
      'audience': 'customers',
    },
    {
      'name': '🐅 Betla Jungle Safari',
      'title': '🐅 Jungle Safari @ Betla National Park!',
      'body': 'Hathi, hiran aur jungle safari ka thrill! Itihaasik Palamu kila aur jungle ka trip ready.\n💡 "Office boss tiger ki tarah daad raha ho, toh Betla aakar asli tiger dekh lo, darr nikal jayega!"',
      'imageUrl': 'https://images.unsplash.com/photo-1534567153574-2b12153a87f0?w=800&auto=format&fit=crop',
      'audience': 'customers',
    },
    {
      'name': '🎉 35% Round-Trip Saver',
      'title': '🎉 35% Off Round-Trip Return Discount!',
      'body': 'Book your village return trip with District Car. Save ₹200 to ₹800 on all return journeys across Jharkhand!',
      'imageUrl': 'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?w=800&auto=format&fit=crop',
      'audience': 'customers',
    },
    {
      'name': '🚗 Driver 3-Trip Bonus Alert',
      'title': '💰 Driver Partner Weekly Cashback Bonus!',
      'body': 'Complete 3 trips today with zero cancellations and get 100% platform commission cashback credited to wallet.',
      'imageUrl': 'https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?w=800&auto=format&fit=crop',
      'audience': 'drivers',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadFCMServerKey();
  }

  void _loadFCMServerKey() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('app_config').doc('fcm_settings').get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          _fcmServerKey = doc.data()!['serverKey'] as String?;
        });
      }
    } catch (_) {}
  }

  void _applyTemplate(Map<String, String> template) {
    setState(() {
      _titleCtrl.text = template['title'] ?? '';
      _bodyCtrl.text = template['body'] ?? '';
      _imageUrlCtrl.text = template['imageUrl'] ?? '';
      _targetAudience = template['audience'] ?? 'all';
    });
  }

  void _configureFCMKeyDialog() {
    final keyCtrl = TextEditingController(text: _fcmServerKey ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.vpn_key_rounded, color: Color(0xFF2563EB)),
            SizedBox(width: 10),
            Text('FCM Server Key Configuration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your Firebase Cloud Messaging (Legacy Server Key) to enable instant push notifications directly to background devices:',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: keyCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'FCM Server Key (AAAA...)',
                  hintText: 'Paste key from Firebase Console > Project Settings > Cloud Messaging',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tip: If left blank, notifications still deliver live to all open apps and appear in offer carousels automatically.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newKey = keyCtrl.text.trim();
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('app_config').doc('fcm_settings').set({
                'serverKey': newKey,
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
              setState(() => _fcmServerKey = newKey);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('FCM Server Key saved successfully!'), backgroundColor: Color(0xFF16A34A)),
                );
              }
            },
            child: const Text('Save Key'),
          ),
        ],
      ),
    );
  }

  void _sendNotification() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    final imageUrl = _imageUrlCtrl.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter notification title and message body.')),
      );
      return;
    }

    setState(() => _isSending = true);

    int recipientCount = 0;

    try {
      // 1. Create Broadcast in 'notifications' collection
      final notifDoc = await FirebaseFirestore.instance.collection('notifications').add({
        'title': title,
        'body': body,
        'imageUrl': imageUrl.isNotEmpty ? imageUrl : null,
        'targetAudience': _targetAudience,
        'status': 'delivered',
        'sentAt': FieldValue.serverTimestamp(),
        'type': 'broadcast',
      });

      // 2. If toggled, also publish/update in 'banner_offers' collection for customer app carousel
      if (_publishAsBannerOffer) {
        await FirebaseFirestore.instance.collection('banner_offers').doc(notifDoc.id).set({
          'title': title,
          'description': body,
          'imageUrl': imageUrl.isNotEmpty ? imageUrl : null,
          'target': _targetAudience,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // 3. Collect device tokens from users and drivers
      final List<String> deviceTokens = [];
      if (_targetAudience == 'all' || _targetAudience == 'customers') {
        final usersSnap = await FirebaseFirestore.instance.collection('users').get();
        for (final doc in usersSnap.docs) {
          final t = doc.data()['fcmToken'] as String?;
          if (t != null && t.isNotEmpty) deviceTokens.add(t);
          recipientCount++;
          // Write to user personal inbox
          try {
            await doc.reference.collection('inbox_notifications').add({
              'title': title,
              'body': body,
              'imageUrl': imageUrl.isNotEmpty ? imageUrl : null,
              'sentAt': FieldValue.serverTimestamp(),
              'isRead': false,
            });
          } catch (_) {}
        }
      }

      if (_targetAudience == 'all' || _targetAudience == 'drivers') {
        final driversSnap = await FirebaseFirestore.instance.collection('drivers').get();
        for (final doc in driversSnap.docs) {
          final t = doc.data()['fcmToken'] as String?;
          if (t != null && t.isNotEmpty) deviceTokens.add(t);
          recipientCount++;
          // Write to driver personal inbox
          try {
            await doc.reference.collection('inbox_notifications').add({
              'title': title,
              'body': body,
              'imageUrl': imageUrl.isNotEmpty ? imageUrl : null,
              'sentAt': FieldValue.serverTimestamp(),
              'isRead': false,
            });
          } catch (_) {}
        }
      }

      // 4. Relay directly to Notification Service Worker (Live Server & Localhost fallback)
      try {
        final payload = jsonEncode({
          'title': title,
          'body': body,
          'imageUrl': imageUrl.isNotEmpty ? imageUrl : null,
          'targetAudience': _targetAudience,
          'extraData': {'notificationId': notifDoc.id},
        });

        await http.post(
          Uri.parse('https://notification.projectmarket.in/api/notifications/admin-broadcast'),
          headers: {'Content-Type': 'application/json'},
          body: payload,
        ).timeout(const Duration(seconds: 4)).catchError((_) async {
          return await http.post(
            Uri.parse('http://localhost:4000/api/notifications/admin-broadcast'),
            headers: {'Content-Type': 'application/json'},
            body: payload,
          ).timeout(const Duration(seconds: 2));
        });
      } catch (workerErr) {
        debugPrint('Notification worker relay notice: $workerErr');
      }

      // 5. If FCM Server Key is present, dispatch HTTP push to topics and device tokens!
      if (_fcmServerKey != null && _fcmServerKey!.isNotEmpty) {
        final topic = _targetAudience == 'drivers'
            ? 'drivers'
            : _targetAudience == 'customers'
                ? 'customers'
                : 'all_users';

        // Send to topic
        try {
          await http.post(
            Uri.parse('https://fcm.googleapis.com/fcm/send'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'key=$_fcmServerKey',
            },
            body: jsonEncode({
              'to': '/topics/$topic',
              'notification': {
                'title': title,
                'body': body,
                if (imageUrl.isNotEmpty) 'image': imageUrl,
                'sound': 'default',
              },
              'data': {
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                'notificationId': notifDoc.id,
              },
              'priority': 'high',
            }),
          );
        } catch (fcmErr) {
          debugPrint('FCM Topic dispatch notice: $fcmErr');
        }

        // Send to individual device tokens if any
        for (final token in deviceTokens) {
          try {
            await http.post(
              Uri.parse('https://fcm.googleapis.com/fcm/send'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'key=$_fcmServerKey',
              },
              body: jsonEncode({
                'to': token,
                'notification': {
                  'title': title,
                  'body': body,
                  if (imageUrl.isNotEmpty) 'image': imageUrl,
                  'sound': 'default',
                },
                'data': {
                  'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                  'notificationId': notifDoc.id,
                },
                'priority': 'high',
              }),
            );
          } catch (_) {}
        }
      }

      setState(() => _isSending = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Push Broadcast sent successfully! Dispatched to $recipientCount devices & live in-app sync 🚀'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send broadcast: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _deleteNotification(String notifId) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').doc(notifId).delete();
      await FirebaseFirestore.instance.collection('banner_offers').doc(notifId).delete().catchError((_) {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification removed.')),
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      activeRoute: '/notifications',
      title: 'Push Notifications & Offers',
      body: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Firebase Cloud Messaging & Push Broadcast',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Broadcast instant push notifications, seasonal offers, and manage live customer app banners.',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: _configureFCMKeyDialog,
                            icon: const Icon(Icons.vpn_key, size: 16),
                            label: Text(
                              _fcmServerKey != null && _fcmServerKey!.isNotEmpty ? 'FCM Key Active 🟢' : 'Set FCM Key',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2563EB),
                              side: const BorderSide(color: Color(0xFFBFDBFE)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.notifications_active, color: Color(0xFF2563EB), size: 16),
                                SizedBox(width: 8),
                                Text('FCM Pipeline Active', style: TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Quick Templates Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '⚡ Quick Broadcast Templates (Click to fill):',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _templates.map((tpl) {
                            return ActionChip(
                              avatar: const Icon(Icons.flash_on, size: 14, color: Color(0xFF2563EB)),
                              label: Text(tpl['name']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                              backgroundColor: const Color(0xFFF1F5F9),
                              onPressed: () => _applyTemplate(tpl),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Form on Left, Live Preview on Right
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Broadcast Form
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Compose Broadcast', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),

                              // Target Audience
                              const Text('Target Audience:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569))),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _buildAudienceRadio('all', 'All Users & Drivers'),
                                  const SizedBox(width: 16),
                                  _buildAudienceRadio('customers', 'Customers Only'),
                                  const SizedBox(width: 16),
                                  _buildAudienceRadio('drivers', 'Drivers Only'),
                                ],
                              ),
                              const SizedBox(height: 18),

                              // Notification Title
                              TextField(
                                controller: _titleCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Notification Title',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Notification Body
                              TextField(
                                controller: _bodyCtrl,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  labelText: 'Message Body',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Image URL
                              TextField(
                                controller: _imageUrlCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Poster / Image URL (Optional)',
                                  prefixIcon: const Icon(Icons.image_outlined),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Checkbox: Also Publish to Customer App Banner Carousel
                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Also publish as live Customer App Banner Offer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                subtitle: const Text('Displays in the customer app home screen carousel immediately', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                value: _publishAsBannerOffer,
                                onChanged: (val) => setState(() => _publishAsBannerOffer = val ?? true),
                              ),
                              const SizedBox(height: 20),

                              // Send Button
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: _isSending ? null : _sendNotification,
                                  icon: _isSending
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Icon(Icons.send_rounded, size: 18),
                                  label: Text(
                                    _isSending ? 'Broadcasting...' : 'Send Push Broadcast Now',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),

                      // Notification Card Live Preview
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.phone_android, color: Color(0xFF38BDF8), size: 18),
                                  SizedBox(width: 8),
                                  Text('Mobile Notification Preview', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                              const SizedBox(height: 18),

                              // Notification Bubble Mockup
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Icon(Icons.directions_car, color: Colors.white, size: 12),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('DISTRICT CAR • now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _titleCtrl.text.isEmpty ? 'Notification Title' : _titleCtrl.text,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _bodyCtrl.text.isEmpty ? 'Notification message description preview' : _bodyCtrl.text,
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                                    ),
                                    if (_imageUrlCtrl.text.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          _imageUrlCtrl.text,
                                          height: 120,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            height: 60,
                                            color: Colors.grey.shade100,
                                            alignment: Alignment.center,
                                            child: const Text('Image preview unavailable', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Divider(color: Color(0xFF334155)),
                              const Text(
                                'Audience will receive this alert instantaneously with FCM sound, device badge, and in-app popup dialog.',
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Sent Broadcast History Section
                  const Text('Recent Broadcast History & Delivery Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('notifications').orderBy('sentAt', descending: true).limit(10).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
                      }

                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Center(
                            child: Column(
                              children: const [
                                Icon(Icons.inbox_outlined, size: 40, color: Color(0xFF94A3B8)),
                                SizedBox(height: 8),
                                Text('No notifications sent yet. Send your first broadcast above!', style: TextStyle(color: Color(0xFF64748B))),
                              ],
                            ),
                          ),
                        );
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: docs.length,
                            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                            itemBuilder: (context, index) {
                              final doc = docs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final title = data['title'] ?? 'Notification';
                              final body = data['body'] ?? '';
                              final audience = (data['targetAudience'] ?? 'all').toString().toUpperCase();
                              final sentAt = (data['sentAt'] as Timestamp?)?.toDate();
                              final timeStr = sentAt != null ? DateFormat('dd MMM, hh:mm a').format(sentAt) : 'Just now';

                              Color audienceColor = const Color(0xFF2563EB);
                              if (audience == 'CUSTOMERS') audienceColor = const Color(0xFF16A34A);
                              if (audience == 'DRIVERS') audienceColor = const Color(0xFF7C3AED);

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: audienceColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        audience,
                                        style: TextStyle(color: audienceColor, fontWeight: FontWeight.bold, fontSize: 11),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                                          const SizedBox(height: 2),
                                          Text(body, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(timeStr, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                                    const SizedBox(width: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('🟢 Sent Live', style: TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold, fontSize: 11)),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF94A3B8)),
                                      onPressed: () => _deleteNotification(doc.id),
                                      tooltip: 'Delete notification',
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAudienceRadio(String value, String label) {
    final isSelected = _targetAudience == value;
    return InkWell(
      onTap: () => setState(() => _targetAudience = value),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<String>(
            value: value,
            groupValue: _targetAudience,
            onChanged: (val) {
              if (val != null) setState(() => _targetAudience = val);
            },
            activeColor: const Color(0xFF2563EB),
          ),
          Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
        ],
      ),
    );
  }
}
