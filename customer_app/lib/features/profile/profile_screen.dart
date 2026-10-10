import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import 'package:district_car_shared/models/models.dart';
import '../auth/auth_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  Future<void> _makeCall(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showEditProfileSheet(DistrictUser user, Map<String, dynamic> firestoreData) {
    final nameCtrl = TextEditingController(
      text: (firestoreData['name'] as String?)?.isNotEmpty == true
          ? firestoreData['name']
          : (user.displayName ?? 'District Rider'),
    );

    String? selectedDob = firestoreData['dateOfBirth'] ?? user.dateOfBirth;
    String? selectedBloodGroup = firestoreData['bloodGroup'] ?? user.bloodGroup;
    String? selectedPhoto = firestoreData['profilePhotoUrl'] ?? user.profilePhotoUrl ?? 'avatar_1';

    DateTime? parsedDob;
    if (selectedDob != null && selectedDob.isNotEmpty) {
      try {
        parsedDob = DateTime.parse(selectedDob);
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Edit Profile (प्रोफ़ाइल संपादित करें)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Update your verified information for comfortable and secure transit',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 20),

                  // Avatar Picker
                  const Text('Select Commuter Avatar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAvatarOption('avatar_1', 'assets/images/avatar_commuter_3d.jpg', selectedPhoto, () => setSheetState(() => selectedPhoto = 'avatar_1')),
                      _buildAvatarOption('avatar_2', 'assets/images/app_logo.jpg', selectedPhoto, () => setSheetState(() => selectedPhoto = 'avatar_2')),
                      _buildAvatarOption('avatar_3', 'assets/images/car_white.jpg', selectedPhoto, () => setSheetState(() => selectedPhoto = 'avatar_3')),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Full Name
                  const Text('Full Name (पूरा नाम)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'Enter your full name',
                      prefixIcon: const Icon(Icons.person_outline, size: 20, color: Color(0xFF059669)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF059669), width: 2)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date of Birth
                  const Text('Date of Birth (जन्म तिथि)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: parsedDob ?? DateTime(1995, 1, 1),
                        firstDate: DateTime(1940),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setSheetState(() {
                          parsedDob = picked;
                          selectedDob = DateFormat('yyyy-MM-dd').format(picked);
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 20, color: Color(0xFF059669)),
                          const SizedBox(width: 12),
                          Text(
                            parsedDob != null ? DateFormat('dd MMMM yyyy').format(parsedDob!) : 'Select Date of Birth',
                            style: TextStyle(
                              fontSize: 14,
                              color: parsedDob != null ? const Color(0xFF0F172A) : Colors.grey.shade500,
                              fontWeight: parsedDob != null ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Blood Group
                  const Text('Blood Group (रक्त समूह - Emergency SOS)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedBloodGroup,
                        isExpanded: true,
                        hint: const Text('Select Blood Group'),
                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF059669)),
                        items: _bloodGroups.map((bg) => DropdownMenuItem(value: bg, child: Text(bg, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                        onChanged: (val) => setSheetState(() => selectedBloodGroup = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final newName = nameCtrl.text.trim();
                        if (newName.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter your name')),
                          );
                          return;
                        }

                        Navigator.pop(ctx);
                        await ref.read(authServiceProvider).updateCustomerProfile(
                          name: newName,
                          dateOfBirth: selectedDob,
                          bloodGroup: selectedBloodGroup,
                          profilePhotoUrl: selectedPhoto,
                        );

                        if (mounted) {
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile updated successfully! ✅')),
                          );
                        }
                      },
                      child: const Text('Save Changes (सुरक्षित करें)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarOption(String id, String assetPath, String? selected, VoidCallback onTap) {
    final isSelected = selected == id;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDCFCE7) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? const Color(0xFF059669) : Colors.grey.shade300,
            width: isSelected ? 3 : 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Image.asset(
            assetPath,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 56,
              height: 56,
              color: const Color(0xFFDCFCE7),
              child: const Icon(Icons.person, color: Color(0xFF059669), size: 28),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);
    final user = authService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.push('/login'),
            child: const Text('Sign In to view profile'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'My Profile & Settings',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A)),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            tooltip: 'Call Support Helpline',
            icon: const Icon(Icons.headset_mic_rounded, color: Color(0xFF059669)),
            onPressed: () => _makeCall('+918789601387'),
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          final data = (snapshot.hasData && snapshot.data!.exists)
              ? snapshot.data!.data() as Map<String, dynamic>? ?? {}
              : <String, dynamic>{};

          final name = (data['name'] as String?)?.isNotEmpty == true
              ? data['name']
              : (user.displayName ?? 'District Rider');
          final email = user.email ?? data['email'] ?? 'rider@districtcar.app';
          final phone = user.phoneNumber ?? data['phoneNumber'] ?? '+91 87896 01387';
          final dob = data['dateOfBirth'] ?? user.dateOfBirth ?? 'Not specified';
          final bloodGroup = data['bloodGroup'] ?? user.bloodGroup ?? 'Not added';
          final photoId = data['profilePhotoUrl'] ?? user.profilePhotoUrl ?? 'avatar_1';

          String avatarAsset = 'assets/images/avatar_commuter_3d.jpg';
          if (photoId == 'avatar_2') avatarAsset = 'assets/images/app_logo.jpg';
          if (photoId == 'avatar_3') avatarAsset = 'assets/images/car_white.jpg';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Premium Atmospheric Card with 3D Image Avatar & Emerald Finish
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            padding: const EdgeInsets.all(3.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF065F46), Color(0xFF10B981), Color(0xFF047857)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF059669).withValues(alpha: 0.25),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(48),
                              child: Image.asset(
                                avatarAsset,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 50, color: Colors.white),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: () => _showEditProfileSheet(user, data),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF059669),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6),
                                  ],
                                ),
                                child: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        name,
                        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.4),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        phone.isNotEmpty ? '$email · $phone' : email,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      // Verified Citizen Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded, size: 14, color: Color(0xFF059669)),
                            SizedBox(width: 6),
                            Text(
                              'Verified Jharkhand Commuter',
                              style: TextStyle(color: Color(0xFF047857), fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Edit Profile Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF059669),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFA7F3D0), width: 1.4),
                      ),
                    ),
                    icon: const Icon(Icons.edit_note_rounded, size: 20),
                    label: const Text('Edit Profile & Information', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                    onPressed: () => _showEditProfileSheet(user, data),
                  ),
                ),
                const SizedBox(height: 22),

                // 2. Personal Information Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PERSONAL INFORMATION (व्यक्तिगत विवरण)',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(Icons.person_outline_rounded, 'Full Name', name),
                      const Divider(height: 22),
                      _buildDetailRow(Icons.cake_outlined, 'Date of Birth (DOB)', dob),
                      const Divider(height: 22),
                      _buildDetailRow(
                        Icons.bloodtype_outlined,
                        'Blood Group',
                        bloodGroup,
                        valueColor: bloodGroup != 'Not added' ? const Color(0xFFDC2626) : null,
                      ),
                      const Divider(height: 22),
                      _buildDetailRow(Icons.location_city_outlined, 'Service Coverage', 'Jharkhand 24 District Hubs & Rural Routes'),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // 3. Quick Action Interactive Hub with High-Quality 3D Rendered Image Icons
                const Text(
                  'SUPPORT & SERVICES (मदद एवं सेवाएं)',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.8),
                ),
                const SizedBox(height: 12),

                // Action Cards 2x2 Grid with 3D Icons
                Row(
                  children: [
                    Expanded(
                      child: _build3DActionTile(
                        imageAsset: 'assets/images/icon_report_3d.jpg',
                        title: 'Report Driver',
                        subtitle: 'File ride concern',
                        fallbackIcon: Icons.shield_rounded,
                        fallbackGradient: const [Color(0xFFE11D48), Color(0xFFF43F5E)],
                        onTap: () => context.push('/report-driver'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _build3DActionTile(
                        imageAsset: 'assets/images/icon_trips_3d.jpg',
                        title: 'My Trips',
                        subtitle: 'Invoices & status',
                        fallbackIcon: Icons.receipt_long_rounded,
                        fallbackGradient: const [Color(0xFF059669), Color(0xFF10B981)],
                        onTap: () => context.push('/trips'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _build3DActionTile(
                        imageAsset: 'assets/images/icon_about_3d.jpg',
                        title: 'About Us',
                        subtitle: 'Founders & Office',
                        fallbackIcon: Icons.apartment_rounded,
                        fallbackGradient: const [Color(0xFF0D9488), Color(0xFF14B8A6)],
                        onTap: () => context.push('/about-us'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _build3DActionTile(
                        imageAsset: 'assets/images/icon_support_3d.jpg',
                        title: 'Call Support',
                        subtitle: '+91 87896 01387',
                        fallbackIcon: Icons.headset_mic_rounded,
                        fallbackGradient: const [Color(0xFFD97706), Color(0xFFF59E0B)],
                        onTap: () => _makeCall('+918789601387'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // 4. Play Store Compliance & Legal Section with 3D Icons
                const Text(
                  'LEGAL & COMPLIANCE (कानूनी एवं अनुपालन)',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.8),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildSettingsImageRow(
                        imageAsset: 'assets/images/icon_legal_3d.jpg',
                        title: 'Terms & Conditions',
                        subtitle: 'Passenger agreement, fare rules & tariff structure',
                        fallbackIcon: Icons.gavel_rounded,
                        fallbackColor: const Color(0xFF059669),
                        onTap: () => context.push('/terms'),
                      ),
                      const Divider(height: 1, indent: 64),
                      _buildSettingsImageRow(
                        imageAsset: 'assets/images/icon_privacy_3d.jpg',
                        title: 'Privacy Policy',
                        subtitle: 'Google Play safe, data protection & rights',
                        fallbackIcon: Icons.verified_user_rounded,
                        fallbackColor: const Color(0xFF0D9488),
                        onTap: () => context.push('/privacy'),
                      ),
                      const Divider(height: 1, indent: 64),
                      _buildSettingsImageRow(
                        imageAsset: 'assets/images/icon_delete_3d.jpg',
                        title: 'Delete Account (खाता हटाएँ)',
                        subtitle: 'Permanently erase account & profile data',
                        titleColor: const Color(0xFFDC2626),
                        fallbackIcon: Icons.delete_forever_rounded,
                        fallbackColor: const Color(0xFFDC2626),
                        onTap: () => context.push('/delete-account'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // 5. Company & Founder Credentials Inset
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.business_rounded, size: 16, color: Color(0xFF059669)),
                          SizedBox(width: 8),
                          Text(
                            'District Car Mobility Private Limited',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Operational HQ: Nichey Chowk, Khunti, Jharkhand - 835210\nLeadership: Monu Kumar (CEO) · Sonu Kumar (Co-Founder)\nHotline: +91 87896 01387 · Email: support@districtcar.in',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 6. Sign Out Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.shade300, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 18),
                    onPressed: () async {
                      await authService.signOut();
                      if (context.mounted) context.go('/');
                    },
                    label: const Text('Sign Out', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w800, fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 36),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _build3DActionTile({
    required String imageAsset,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    IconData fallbackIcon = Icons.stars_rounded,
    List<Color> fallbackGradient = const [Color(0xFF065F46), Color(0xFF10B981)],
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: fallbackGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Icon(fallbackIcon, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsImageRow({
    required String imageAsset,
    required String title,
    required String subtitle,
    Color? titleColor,
    required VoidCallback onTap,
    IconData fallbackIcon = Icons.security_rounded,
    Color fallbackColor = const Color(0xFF059669),
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            imageAsset,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              decoration: BoxDecoration(
                color: fallbackColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(fallbackIcon, color: fallbackColor, size: 20),
              ),
            ),
          ),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: titleColor ?? const Color(0xFF0F172A)),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF059669)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
