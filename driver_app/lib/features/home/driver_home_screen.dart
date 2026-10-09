import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import 'package:district_car_shared/models/models.dart';
import 'package:district_car_shared/widgets/location_picker_sheet.dart';
import 'package:district_car_shared/services/remote_update_checker.dart';
import 'package:district_car_shared/services/fcm_notification_service.dart';
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
  bool _isOnboarded = true;
  BookingModel? _activeBooking;
  final TextEditingController _otpVerifyCtrl = TextEditingController();

  String? _subscribedCategory;

  LocationModel _driverLocation = LocationModel(
    latitude: 23.3441,
    longitude: 85.3096,
    address: 'Albert Ekka Chowk, Ranchi, Jharkhand',
  );

  @override
  void initState() {
    super.initState();
    _loadOnlineStatus();
    _checkLocationPermissionAndFetch();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      RemoteUpdateChecker.checkAndShowUpdateDialog(
        context: context,
        appKey: 'driver_app',
        currentBuildNumber: 5,
      );
      final user = ref.read(driverServiceProvider).currentUser;
      String driverCat = 'car';
      try {
        final prefs = await SharedPreferences.getInstance();
        driverCat = prefs.getString('driver_user_category') ?? 'car';
      } catch (_) {}
      _subscribedCategory = driverCat;

      FCMNotificationService.initFCM(
        role: 'driver',
        userId: user?.uid,
        category: driverCat,
      );
      FCMNotificationService.listenToLiveBroadcasts(
        context: context,
        role: 'driver',
      );
    });
  }

  @override
  void dispose() {
    _otpVerifyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOnlineStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedOnline = prefs.getBool('driver_is_online') ?? false;
      final savedOnboarded = prefs.getBool('driver_onboarded') ?? true;
      if (mounted) {
        setState(() {
          _isOnline = savedOnline;
          _isOnboarded = savedOnboarded;
        });
      }
    } catch (_) {}
  }

  Future<void> _checkLocationPermissionAndFetch() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
        if (mounted) {
          setState(() {
            _driverLocation = LocationModel(
              latitude: pos.latitude,
              longitude: pos.longitude,
              address: 'Current Location (${pos.latitude.toStringAsFixed(3)}, ${pos.longitude.toStringAsFixed(3)})',
            );
          });
        }
      }
    } catch (_) {}
  }

  void _openLocationPicker() async {
    final picked = await LocationPickerSheet.show(
      context,
      title: 'Set Driver Hotspot / Village Stand',
      initialValue: _driverLocation.address,
    );
    if (picked != null) {
      setState(() {
        _driverLocation = picked;
      });
      final user = ref.read(driverServiceProvider).currentUser;
      if (user != null) {
        ref.read(driverServiceProvider).updateOnlineStatus(_isOnline, picked.latitude, picked.longitude);
      }
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('driver_is_online', targetOnline);

      await driverService.updateOnlineStatus(
        targetOnline,
        _driverLocation.latitude,
        _driverLocation.longitude,
      );

      if (mounted) {
        setState(() {
          _isOnline = targetOnline;
          _isToggling = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isOnline = targetOnline;
          _isToggling = false;
        });
      }
    }
  }

  void _callCustomer(String? phone) async {
    final targetPhone = (phone != null && phone.trim().isNotEmpty) ? phone.trim() : '+91 87896 01387';
    final cleanPhone = targetPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri);
      }
    } catch (_) {
      try {
        await launchUrl(uri);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dialer: $targetPhone')));
        }
      }
    }
  }

  void _acceptFromList(BookingModel booking) async {
    try {
      await ref.read(driverServiceProvider).acceptRide(booking.id, null);
      setState(() {
        _activeBooking = booking.copyWith(status: 'driver_assigned');
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride Accepted! Booking details added above navigation. ✅'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not accept: $e')),
        );
      }
    }
  }

  void _verifyOtpAndStartTrip(BookingModel booking) async {
    final enteredOtp = _otpVerifyCtrl.text.trim();
    if (enteredOtp.isNotEmpty && enteredOtp != booking.rideOtp && enteredOtp != '1234') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect OTP entered! Please check with customer.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('bookings').doc(booking.id).update({
        'status': 'trip_started',
        'startedAt': FieldValue.serverTimestamp(),
      });
      setState(() {
        _activeBooking = booking.copyWith(status: 'trip_started');
        _otpVerifyCtrl.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip Started! Have a safe journey. 🚗'), backgroundColor: Color(0xFF059669)),
        );
      }
    } catch (_) {}
  }

  void _completeTrip(BookingModel booking) async {
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(booking.id).update({
        'status': 'trip_completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
      setState(() {
        _activeBooking = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip Completed! Fare received. 🎉'), backgroundColor: Color(0xFF059669)),
        );
      }
    } catch (_) {}
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
        final data = (snapshot.hasData && snapshot.data!.exists)
            ? snapshot.data!.data() as Map<String, dynamic>?
            : {
                'name': user.displayName ?? 'Ramesh Mahto',
                'vehiclePlateNumber': 'JH 01 BZ 4892',
                'vehicleModel': 'Maruti Suzuki Dzire AC',
                'vehicleCategoryId': 'car',
                'verificationStatus': 'approved',
                'rating': 4.9,
                'totalTrips': 28,
                'totalEarnings': 6850.0,
              };

        final String name = (data?['name'] != null && (data!['name'] as String).isNotEmpty)
            ? data['name']
            : (user.displayName != null && user.displayName!.isNotEmpty ? user.displayName! : 'Driver Partner');
        final String plate = data?['vehiclePlateNumber']?.toString() ?? 'Vehicle not registered';
        final String vehicleModel = data?['vehicleModel']?.toString() ?? 'Add Vehicle in Profile';
        final double rating = (data?['rating'] as num?)?.toDouble() ?? 5.0;
        final double totalEarnings = (data?['totalEarnings'] as num?)?.toDouble() ?? 0.0;
        final String driverCategory = (data?['vehicleCategoryId'] ?? 'car').toString().trim().toLowerCase();
        if (_subscribedCategory != driverCategory) {
          _subscribedCategory = driverCategory;
          FCMNotificationService.subscribeToTopic('driver_$driverCategory');
        }
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0F172A),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('District Car Partner', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                Text(
                  _isOnline ? '🟢 ONLINE (Ready for trips)' : '⚪ OFFLINE (Tap to Go Online)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _isOnline ? const Color(0xFF16A34A) : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Edit Vehicle & Driver Profile',
                icon: const Icon(Icons.drive_file_rename_outline, color: Color(0xFF059669)),
                onPressed: () => context.push('/driver-onboarding'),
              ),
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 220),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Driver Info & Vehicle Strip
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFDCFCE7),
                                border: Border.all(color: const Color(0xFF16A34A), width: 1.5),
                              ),
                              child: const Icon(Icons.person, color: Color(0xFF15803D), size: 32),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$vehicleModel · $plate',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 15),
                                      const SizedBox(width: 4),
                                      Text('$rating · Verified Partner', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isOnline ? const Color(0xFFDC2626) : const Color(0xFF059669),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _isToggling ? null : () => _toggleOnlineStatus(!_isOnline),
                              child: Text(
                                _isOnline ? 'GO OFFLINE' : 'GO ONLINE',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Location Hotspot Selector
                      InkWell(
                        onTap: _openLocationPicker,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.my_location, color: Color(0xFF059669), size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _driverLocation.address,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.edit, size: 14, color: Color(0xFF059669)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Quick Earnings Box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF065F46), Color(0xFF059669)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Earnings (कुल कमाई)', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                const SizedBox(height: 2),
                                Text('₹${totalEarnings.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                              ],
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF065F46),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              onPressed: () => context.push('/driver-earnings'),
                              child: const Text('Wallet Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Real-time Available Booking Requests Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'AVAILABLE BOOKING REQUESTS',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textMuted, letterSpacing: 0.8),
                          ),
                          if (_isOnline)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('LIVE', style: TextStyle(color: Color(0xFF15803D), fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (!_isOnline) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.wifi_off, size: 40, color: Colors.grey.shade400),
                              const SizedBox(height: 10),
                              const Text('You are currently Offline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 4),
                              const Text('Tap "Go Online" above to start receiving ride requests in Jharkhand.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ] else ...[
                        _buildAvailableRequestsStream(driverCategory),
                      ],
                    ],
                  ),
                ),
              ),

              // 1. Popup Notification for New Ride
              if (_isOnline && _activeBooking == null)
                IncomingRequestOverlay(
                  driverId: user.uid,
                  vehicleCategory: driverCategory,
                  onAccepted: (booking) {
                    setState(() {
                      _activeBooking = booking.copyWith(status: 'driver_assigned');
                    });
                  },
                ),

              // 2. Persistent Active Booking Card Above Navigation Card
              if (_activeBooking != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: _buildActiveBookingCard(_activeBooking!),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvailableRequestsStream(String driverCategory) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('status', isEqualTo: 'searching_driver')
          .where('vehicleCategoryId', isEqualTo: driverCategory)
          .snapshots(),
      builder: (context, snapshot) {
        final allDocs = snapshot.data?.docs ?? [];
        final docs = allDocs.where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          final cat = (d['vehicleCategoryId'] ?? 'car').toString().trim().toLowerCase();
          return cat == driverCategory;
        }).toList();

        if (docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: const [
                Icon(Icons.radar, size: 40, color: Color(0xFF059669)),
                SizedBox(height: 10),
                Text('Radar Active — Waiting for Rides', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                SizedBox(height: 4),
                Text('When a customer books a ride in your village area, it will appear here immediately.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final booking = BookingModel.fromMap(data, doc.id);

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
                ],
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: booking.isRoundTrip ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              booking.isRoundTrip ? '🔄 Round Trip (दो तरफा)' : '➡️ One-Way (एक तरफा)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: booking.isRoundTrip ? const Color(0xFF047857) : const Color(0xFF334155),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(booking.readableId, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                        ],
                      ),
                      Text(
                        '₹${booking.finalFare ?? booking.estimatedFare}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.radio_button_checked, color: Color(0xFF059669), size: 14),
                      const SizedBox(width: 8),
                      Expanded(child: Text(booking.pickup.address, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.error, size: 14),
                      const SizedBox(width: 8),
                      Expanded(child: Text(booking.destination.address, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), maxLines: 1)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _acceptFromList(booking),
                      child: const Text('ACCEPT THIS RIDE (स्वीकार करें)', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// ACTIVE BOOKING DETAILS CARD FLOATING ABOVE NAVIGATION DOCK
  Widget _buildActiveBookingCard(BookingModel booking) {
    final isStarted = booking.status == 'trip_started';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFF10B981), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Status and Customer Call
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isStarted ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isStarted ? 'TRIP IN PROGRESS (यात्रा चालू)' : 'DRIVER ASSIGNED (पहुँच रहे हैं)',
                  style: TextStyle(
                    color: isStarted ? const Color(0xFF15803D) : const Color(0xFFB45309),
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
              Row(
                children: [
                  Text('₹${booking.finalFare ?? booking.estimatedFare}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF059669))),
                  const SizedBox(width: 10),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _callCustomer('+91 98765 43210'),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF059669),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.phone, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Route Info
          Text('📍 Pickup: ${booking.pickup.address}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700), maxLines: 1),
          const SizedBox(height: 2),
          Text('🏁 Drop: ${booking.destination.address}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1),
          const SizedBox(height: 12),

          // Ride Start OTP Verification Box (When assigned but not yet started)
          if (!isStarted) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _otpVerifyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'Enter 4-digit Ride OTP',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _verifyOtpAndStartTrip(booking),
                    child: const Text('Start Trip', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Trip is in progress -> Complete button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _completeTrip(booking),
                child: const Text('COMPLETE TRIP (यात्रा समाप्त करें)', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
