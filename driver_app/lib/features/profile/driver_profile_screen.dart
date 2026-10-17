import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import '../../services/driver_service.dart';

class DriverProfileScreen extends ConsumerWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverService = ref.watch(driverServiceProvider);
    final user = driverService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.go('/driver-login'),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Driver Profile')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('drivers').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final raw = snapshot.data?.data();
          final data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
          final name = (data['name'] != null && (data['name'] as String).isNotEmpty)
              ? data['name']
              : (user.displayName != null && user.displayName!.isNotEmpty ? user.displayName! : 'Driver Partner');
          final phone = (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
              ? user.phoneNumber!
              : (data['phoneNumber'] ?? data['phone'] ?? '').toString();
          final status = data['verificationStatus'] ?? 'approved';
          final driverPhoto = (
              data['driverPhoto'] ??
              data['profilePhoto'] ??
              data['photoUrl'] ??
              data['photoURL'] ??
              data['driverImage'] ??
              data['avatarUrl'] ??
              user.profilePhotoUrl
          )?.toString();
          final vehiclePhoto = (
              data['vehicleImage'] ??
              data['vehiclePhoto'] ??
              data['vehiclePhotoUrl'] ??
              data['carPhoto'] ??
              data['carImage']
          )?.toString();
          final vehiclePlate = (data['vehiclePlateNumber'] ?? data['vehiclePlate'] ?? '').toString();
          final vehicleModel = (data['vehicleModel'] ?? '').toString();
          final standAddress = (data['currentAddress'] ?? data['address'] ?? '').toString();

          return LayoutBuilder(
            builder: (context, constraints) {
              final double maxW = constraints.maxWidth > 600 ? 600 : constraints.maxWidth;
              final double contentW = (maxW - 48).clamp(280.0, 600.0);
              return Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: maxW,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      width: contentW,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFDCFCE7),
                      border: Border.all(color: const Color(0xFF10B981), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _buildSafePhoto(driverPhoto, 96),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                Text(phone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                const SizedBox(height: 24),

                _buildInfoTile('Status', status.toString().toUpperCase()),
                if (vehiclePlate.isNotEmpty)
                  _buildInfoTile('Vehicle Plate No.', vehiclePlate),
                if (vehicleModel.isNotEmpty)
                  _buildInfoTile('Vehicle Model', vehicleModel),
                if (vehiclePhoto != null && vehiclePhoto.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Vehicle Photo', style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _buildSafePhoto(vehiclePhoto, 48, isVehicle: true),
                        ),
                      ],
                    ),
                  ),
                _buildInfoTile('Vehicle Category', (data['vehicleCategoryId'] ?? data['category'] ?? 'Car').toString().toUpperCase()),
                if (standAddress.isNotEmpty)
                  _buildInfoTile('Active Stand / Hotspot', standAddress),
                _buildInfoTile('Total Trips', '${data['totalTrips'] ?? 0} Rides'),
                _buildInfoTile('Average Rating', '${data['rating'] ?? 5.0} ★'),
                const SizedBox(height: 20),

                // Edit Profile Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.edit_note, size: 20),
                    label: const Text('Edit Vehicle & Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => context.push('/driver-onboarding'),
                  ),
                ),
                const SizedBox(height: 24),

                // Play Store Mandatory Pages Menu
                _buildMenuTile(
                  icon: Icons.policy_rounded,
                  iconColor: const Color(0xFF2563EB),
                  title: 'Privacy Policy & Driver Agreement',
                  subtitle: 'Background location and data disclosure',
                  onTap: () => context.push('/driver-legal'),
                ),
                _buildMenuTile(
                  icon: Icons.delete_outline_rounded,
                  iconColor: AppColors.error,
                  title: 'Delete Driver Account',
                  subtitle: 'Permanently erase driver profile & vehicle',
                  onTap: () => context.push('/driver-delete-account'),
                ),

                const SizedBox(height: 20),

                // App Version info
                const Center(
                  child: Text(
                    'District Car Partner · Version 1.0.0 (Build 16)\nJharkhand Rural & District Mobility',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8), height: 1.4),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      await driverService.signOut();
                      if (context.mounted) context.go('/driver-login');
                    },
                    child: const Text('Sign Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                  ),
                ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ),
  );
}


  Widget _buildSafePhoto(String? photo, double size, {bool isVehicle = false}) {
    if (photo == null || photo.isEmpty || photo.startsWith('avatar')) {
      return Icon(
        isVehicle ? Icons.directions_car_rounded : Icons.person_rounded,
        color: const Color(0xFF15803D),
        size: size * 0.6,
      );
    }
    if (photo.startsWith('data:image')) {
      try {
        final commaIdx = photo.indexOf(',');
        final raw = commaIdx != -1 ? photo.substring(commaIdx + 1) : photo;
        final bytes = base64Decode(raw.trim());
        return Image.memory(bytes, fit: BoxFit.cover, width: size, height: size);
      } catch (_) {
        return Icon(
          isVehicle ? Icons.directions_car_rounded : Icons.person_rounded,
          color: const Color(0xFF15803D),
          size: size * 0.6,
        );
      }
    }
    if (photo.startsWith('http://') || photo.startsWith('https://')) {
      return Image.network(
        photo,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => Icon(
          isVehicle ? Icons.directions_car_rounded : Icons.person_rounded,
          color: const Color(0xFF15803D),
          size: size * 0.6,
        ),
      );
    }
    if (photo.startsWith('assets/')) {
      return Image.asset(
        photo,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => Icon(
          isVehicle ? Icons.directions_car_rounded : Icons.person_rounded,
          color: const Color(0xFF15803D),
          size: size * 0.6,
        ),
      );
    }
    if (photo.length > 80 && !photo.contains('/') && !photo.contains('\\')) {
      try {
        final bytes = base64Decode(photo.trim());
        return Image.memory(bytes, fit: BoxFit.cover, width: size, height: size);
      } catch (_) {}
    }
    return Icon(
      isVehicle ? Icons.directions_car_rounded : Icons.person_rounded,
      color: const Color(0xFF15803D),
      size: size * 0.6,
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }
}
