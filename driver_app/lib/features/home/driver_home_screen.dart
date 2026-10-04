import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import '../../services/driver_service.dart';
import '../requests/incoming_request_dialog.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  bool _isOnline = false;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  }

  void _toggleOnlineStatus(bool targetOnline) async {
    final driverService = ref.read(driverServiceProvider);
    final user = driverService.currentUser;
    if (user == null) {
      context.go('/driver-login');
      return;
    }

    setState(() => _isToggling = true);

    try {
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      } catch (_) {
        position = Position(
          longitude: 77.2090,
          latitude: 28.6139,
          timestamp: DateTime.now(),
          accuracy: 10,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }

      await driverService.updateOnlineStatus(targetOnline, position.latitude, position.longitude);
      setState(() {
        _isOnline = targetOnline;
        _isToggling = false;
      });
    } catch (e) {
      setState(() => _isToggling = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(driverServiceProvider).currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.go('/driver-login'),
            child: const Text('Driver Sign In'),
          ),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('drivers').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.go('/driver-onboarding'),
                child: const Text('Complete Driver Registration'),
              ),
            ),
          );
        }

        final verificationStatus = data['verificationStatus'] ?? 'pending';
        final isApproved = verificationStatus == 'approved';
        final name = data['name'] ?? 'Driver Partner';
        final rating = data['rating'] ?? 5.0;
        final totalTrips = data['totalTrips'] ?? 0;
        final currentBookingId = data['currentBookingId'] as String?;

        // If driver has an active assigned booking, forward to active trip screen
        if (currentBookingId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/driver-trip/$currentBookingId');
          });
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('District Car Driver'),
            actions: [
              IconButton(
                icon: const Icon(Icons.account_balance_wallet_outlined),
                onPressed: () => context.push('/driver-earnings'),
              ),
              IconButton(
                icon: const Icon(Icons.person_outline),
                onPressed: () => context.push('/driver-profile'),
              ),
            ],
          ),
          body: Stack(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Driver Info Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryLight,
                              ),
                              child: const Icon(Icons.person, color: AppColors.primary, size: 36),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 16),
                                      const SizedBox(width: 4),
                                      Text('$rating · $totalTrips Trips', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isApproved ? AppColors.success.withOpacity(0.12) : AppColors.warning.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                verificationStatus.toUpperCase(),
                                style: TextStyle(
                                  color: isApproved ? AppColors.success : AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Large Online / Offline Toggle
                      if (!isApproved)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'Your profile is awaiting admin verification. You can go online once verified.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600),
                          ),
                        )
                      else ...[
                        GestureDetector(
                          onTap: _isToggling ? null : () => _toggleOnlineStatus(!_isOnline),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: _isOnline ? AppColors.primaryGradient : null,
                              color: _isOnline ? null : const Color(0xFFE5E7EB),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isOnline ? AppColors.primary : Colors.black).withOpacity(0.18),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isToggling
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _isOnline ? Icons.power_settings_new_rounded : Icons.power_off_rounded,
                                          size: 54,
                                          color: _isOnline ? Colors.white : AppColors.textSecondary,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _isOnline ? "YOU'RE ONLINE" : "YOU'RE OFFLINE",
                                          style: TextStyle(
                                            color: _isOnline ? Colors.white : AppColors.textSecondary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _isOnline
                            ? 'Ready to receive ride requests'
                            : 'Tap to go online and receive bookings',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                      ],
                      const Spacer(),
                    ],
                  ),
                ),
              ),
              // Stream for incoming booking requests when online
              if (_isOnline)
                IncomingRequestOverlay(driverId: user.uid),
            ],
          ),
        );
      },
    );
  }
}
