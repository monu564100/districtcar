import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import '../../widgets/admin_sidebar.dart';

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

  final List<Map<String, String>> _templates = [
    {
      'name': '🎉 35% Round-Trip Saver',
      'title': '🎉 35% Off Round-Trip Return Discount!',
      'body': 'Book your village return trip with District Car. Save ₹200 to ₹800 on all return journeys across Jharkhand!',
      'imageUrl': 'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?w=800&auto=format&fit=crop',
      'audience': 'customers',
    },
    {
      'name': '🚀 App Update Announcement',
      'title': '⚡ New District Car Update Available!',
      'body': 'A brand new version is live with Jharkhand 24-district village selection and instant booking. Update now!',
      'imageUrl': 'https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?w=800&auto=format&fit=crop',
      'audience': 'all',
    },
    {
      'name': '🚗 Driver 3-Trip Bonus Alert',
      'title': '💰 Driver Partner Weekly Cashback Bonus!',
      'body': 'Complete 3 trips today with zero cancellations and get 100% platform commission cashback credited to wallet.',
      'imageUrl': 'https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?w=800&auto=format&fit=crop',
      'audience': 'drivers',
    },
    {
      'name': '🌾 Gramin Darshan Outstation',
      'title': '🌾 Gramin Darshan & Long Tour Cabs!',
      'body': 'Planning pilgrimage or family visits to Deoghar, Parasnath, or Netarhat? Book direct rural cabs now on WhatsApp or app.',
      'imageUrl': 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=800&auto=format&fit=crop',
      'audience': 'customers',
    },
  ];

  void _applyTemplate(Map<String, String> template) {
    setState(() {
      _titleCtrl.text = template['title'] ?? '';
      _bodyCtrl.text = template['body'] ?? '';
      _imageUrlCtrl.text = template['imageUrl'] ?? '';
      _targetAudience = template['audience'] ?? 'all';
    });
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

    try {
      // 1. Create Broadcast in 'notifications' collection
      final notifDoc = await FirebaseFirestore.instance.collection('notifications').add({
        'title': title,
        'body': body,
        'imageUrl': imageUrl.isNotEmpty ? imageUrl : null,
        'targetAudience': _targetAudience,
        'status': 'sent',
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

      setState(() => _isSending = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Push notification broadcast sent & banner updated successfully!'),
            backgroundColor: Color(0xFF16A34A),
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

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          const AdminSidebar(activeRoute: '/notifications'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
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
                            Text('FCM Push Ready', style: TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
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

                  // Main Content: Form on Left, Live Preview on Right
                  Expanded(
                    child: Row(
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
                            child: ListView(
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
                                const Spacer(),
                                const Divider(color: Color(0xFF334155)),
                                const Text(
                                  'Audience will receive this alert instantaneously with FCM notification sound and banner badge.',
                                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
