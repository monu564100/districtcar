import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
                      width: 48,
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Update your personal information for a safer rural commute',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),

                  // Avatar Picker
                  const Text('Select Photo / Avatar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAvatarOption('avatar_1', Icons.person, selectedPhoto, () => setSheetState(() => selectedPhoto = 'avatar_1')),
                      _buildAvatarOption('avatar_2', Icons.face, selectedPhoto, () => setSheetState(() => selectedPhoto = 'avatar_2')),
                      _buildAvatarOption('avatar_3', Icons.account_circle, selectedPhoto, () => setSheetState(() => selectedPhoto = 'avatar_3')),
                      _buildAvatarOption('avatar_4', Icons.emoji_emotions, selectedPhoto, () => setSheetState(() => selectedPhoto = 'avatar_4')),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Full Name
                  const Text('Full Name (पूरा नाम)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'Enter your name',
                      prefixIcon: const Icon(Icons.badge, color: AppColors.primary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Date of Birth (DOB)
                  const Text('Date of Birth (जन्म तिथि)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: parsedDob ?? DateTime(1995, 5, 15),
                        firstDate: DateTime(1940),
                        lastDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
                      );
                      if (picked != null) {
                        setSheetState(() {
                          parsedDob = picked;
                          selectedDob = DateFormat('yyyy-MM-dd').format(picked);
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cake, color: AppColors.primary, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            parsedDob != null
                                ? DateFormat('d MMMM yyyy').format(parsedDob!)
                                : (selectedDob ?? 'Select your Date of Birth'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: parsedDob != null ? FontWeight.w700 : FontWeight.normal,
                              color: parsedDob != null ? AppColors.textPrimary : Colors.grey.shade600,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.calendar_month, color: AppColors.textSecondary, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Optional Blood Group
                  Row(
                    children: const [
                      Text('Blood Group (रक्त समूह)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      SizedBox(width: 6),
                      Text('(Optional / आपातकालीन हेतु)', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _bloodGroups.map((bg) {
                      final isSelected = selectedBloodGroup == bg;
                      return ChoiceChip(
                        label: Text(bg, style: TextStyle(fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600)),
                        selected: isSelected,
                        selectedColor: const Color(0xFFFEE2E2),
                        backgroundColor: const Color(0xFFF1F5F9),
                        labelStyle: TextStyle(color: isSelected ? const Color(0xFFDC2626) : const Color(0xFF334155)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: isSelected ? const Color(0xFFEF4444) : Colors.transparent),
                        ),
                        onSelected: (val) {
                          setSheetState(() {
                            selectedBloodGroup = val ? bg : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  Widget _buildAvatarOption(String id, IconData icon, String? selected, VoidCallback onTap) {
    final isSelected = selected == id;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : const Color(0xFFF8FAFC),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2.5 : 1,
          ),
        ),
        child: Icon(icon, size: 28, color: isSelected ? AppColors.primary : Colors.grey.shade700),
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
        title: const Text('My Profile (मेरी प्रोफ़ाइल)'),
        elevation: 0,
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
          final dob = data['dateOfBirth'] ?? user.dateOfBirth ?? 'Not specified';
          final bloodGroup = data['bloodGroup'] ?? user.bloodGroup ?? 'Not added';
          final photoId = data['profilePhotoUrl'] ?? user.profilePhotoUrl ?? 'avatar_1';

          IconData avatarIcon = Icons.person;
          if (photoId == 'avatar_2') avatarIcon = Icons.face;
          if (photoId == 'avatar_3') avatarIcon = Icons.account_circle;
          if (photoId == 'avatar_4') avatarIcon = Icons.emoji_emotions;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Top Profile Avatar Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 86,
                            height: 86,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryLight,
                              border: Border.all(color: AppColors.primary, width: 2),
                            ),
                            child: Icon(avatarIcon, size: 52, color: AppColors.primary),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit, size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      // Verified Citizen Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, size: 14, color: Color(0xFF059669)),
                            SizedBox(width: 6),
                            Text(
                              'Verified Jharkhand Commuter',
                              style: TextStyle(color: Color(0xFF047857), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Edit Profile Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                    icon: const Icon(Icons.edit_note, size: 20),
                    label: const Text('Edit Profile & Photo (संपादित करें)', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _showEditProfileSheet(user, data),
                  ),
                ),
                const SizedBox(height: 24),

                // Personal Details Info Card (Money / Wallet removed as requested)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PERSONAL INFORMATION',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(Icons.person, 'Full Name', name),
                      const Divider(height: 24),
                      _buildDetailRow(Icons.cake, 'Date of Birth (DOB)', dob),
                      const Divider(height: 24),
                      _buildDetailRow(
                        Icons.bloodtype,
                        'Blood Group (Optional)',
                        bloodGroup,
                        valueColor: bloodGroup != 'Not added' ? const Color(0xFFDC2626) : null,
                      ),
                      const Divider(height: 24),
                      _buildDetailRow(Icons.location_city, 'Region Target', 'Jharkhand Rural & District Hubs'),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Sign Out Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      await authService.signOut();
                      if (context.mounted) context.go('/');
                    },
                    child: const Text('Sign Out (लॉग आउट)', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
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
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
