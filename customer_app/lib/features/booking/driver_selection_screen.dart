import 'package:flutter/material.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import '../../widgets/floating_bottom_dock.dart';

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
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Bar with back button & title matching Screen 3
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 20),
                          onPressed: () => Navigator.maybePop(context),
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Choose a driver',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 42), // Balance spacing
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Driver Card 1: Carlos Santos (Porsche Taycan / Blue Sports Car)
                  _buildDriverCard(
                    driverName: 'Carlos Santos',
                    ratingTag: '99% Smooth Ride',
                    ratePerHour: '₹300/h',
                    vehicleModel: 'Porsche Taycan',
                    durationArrival: '25 mins',
                    imageAsset: 'assets/images/car_blue.jpg',
                    onBookNow: () {},
                  ),
                  const SizedBox(height: 20),

                  // Driver Card 2: Lucas Martinez (Sedan)
                  _buildDriverCard(
                    driverName: 'Lucas Martinez',
                    ratingTag: '93% Smooth Ride',
                    ratePerHour: '₹350/h',
                    vehicleModel: 'Porsche Taycan',
                    durationArrival: '18 mins',
                    imageAsset: 'assets/images/car_white.jpg',
                    onBookNow: () {},
                  ),
                ],
              ),
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
    required VoidCallback onBookNow,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                child: const Icon(Icons.person, color: AppColors.primary, size: 28),
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
