import 'package:flutter/material.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/floating_bottom_dock.dart';
import '../../widgets/premium_empty_state.dart';

class DriverSelectionScreen extends StatefulWidget {
  const DriverSelectionScreen({super.key});

  @override
  State<DriverSelectionScreen> createState() => _DriverSelectionScreenState();
}

class _DriverSelectionScreenState extends State<DriverSelectionScreen> {
  int _currentDockIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top App Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
                          onPressed: () => Navigator.maybePop(context),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available Drivers',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'Verified Partners Nearby',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Live Drivers Stream
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('drivers')
                        .where('isOnline', isEqualTo: true)
                        .where('isBlocked', isEqualTo: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data?.docs ?? [];
                      final availableDocs = docs.where((d) {
                        final data = d.data() as Map<String, dynamic>;
                        return data['isBusy'] != true && data['activeBookingId'] == null;
                      }).toList();

                      if (availableDocs.isEmpty) {
                        return Center(
                          child: PremiumEmptyState(
                            title: 'No Drivers Nearby Right Now',
                            subtitle: 'All partner drivers in your area are currently completing trips. Book instantly or check back in a few minutes.',
                            imageAsset: 'assets/images/trip_radar_pulse.jpg',
                            fallbackIcon: Icons.directions_car_filled_rounded,
                            glowColor: const Color(0xFF384CF5),
                            actionLabel: 'Return to Home',
                            onAction: () => Navigator.maybePop(context),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                        itemCount: availableDocs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final data = availableDocs[index].data() as Map<String, dynamic>;
                          final name = data['name'] ?? 'District Partner Driver';
                          final plate = data['vehiclePlate'] ?? 'JH Registered';
                          final model = data['vehicleModel'] ?? 'District Sedan AC';
                          final photo = data['profilePhotoUrl'] ?? data['photoUrl'];

                          return _buildDriverCard(
                            driverName: name,
                            ratingTag: '4.9 ★ Top Rated Commute',
                            ratePerHour: 'Available Now',
                            vehicleModel: '$model · $plate',
                            durationArrival: '~5-10 mins away',
                            imageAsset: 'assets/images/car_blue.jpg',
                            driverPhoto: photo,
                            onBookNow: () => Navigator.maybePop(context),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Floating Bottom Navigation Dock matching Screen 3
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingBottomDock(
              currentIndex: _currentDockIndex,
              onTabSelected: (idx) => setState(() => _currentDockIndex = idx),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard({
    required String driverName,
    required String ratingTag,
    required String ratePerHour,
    required String vehicleModel,
    required String durationArrival,
    required String imageAsset,
    String? driverPhoto,
    required VoidCallback onBookNow,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Driver Info Row
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryLight,
                ),
                child: driverPhoto != null && driverPhoto.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          driverPhoto,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person, color: AppColors.primary, size: 28),
                        ),
                      )
                    : const Icon(Icons.person, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ratingTag,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  ratePerHour,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // High Quality Vehicle Visual Container
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 170,
              width: double.infinity,
              color: const Color(0xFFF3F5FA),
              child: Image.asset(
                imageAsset,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.directions_car_filled, size: 64, color: AppColors.primary),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Vehicle Model, Arrival Duration, and Book Now Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicleModel,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time_filled, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        durationArrival,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: onBookNow,
                child: const Text(
                  'Book Now',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
