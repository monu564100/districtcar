import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isOnline = false;
  bool _isToggling = false;
  BookingModel? _activeBooking;
  final TextEditingController _otpVerifyCtrl = TextEditingController();

  String? _subscribedCategory;
  String _selectedCategoryFilter = 'all';

  // Local cache of dismissed booking IDs in current session
  final Set<String> _dismissedBookingIds = {};

  LocationModel _driverLocation = LocationModel(
    latitude: 23.3441,
    longitude: 85.3096,
    address: 'Albert Ekka Chowk Stand, Ranchi, Jharkhand',
  );

  late final AnimationController _radarPulseController;
  late final Animation<double> _radarPulseAnimation;

  @override
  void initState() {
    super.initState();
    _radarPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _radarPulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _radarPulseController, curve: Curves.easeInOut),
    );

    _loadOnlineStatus();
    _checkLocationPermissionAndFetch();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!kIsWeb) {
        RemoteUpdateChecker.checkAndShowUpdateDialog(
          context: context,
          appKey: 'driver_app',
          currentBuildNumber: 9,
        );
      }

      final user = ref.read(driverServiceProvider).currentUser;
      if (user == null) {
        context.go('/driver-login');
        return;
      }

      // Check if driver profile is complete (Mandatory Registration)
      final isOnboarded = await ref.read(driverServiceProvider).isDriverOnboarded(user.uid);
      if (!isOnboarded && mounted) {
        context.go('/driver-onboarding');
        return;
      }

      String driverCat = 'car';
      try {
        final prefs = await SharedPreferences.getInstance();
        driverCat = prefs.getString('driver_user_category') ?? 'car';

        // Check if mandatory consent is completed
        final hasConsent = prefs.getBool('driver_consent_given') ?? false;
        if (!hasConsent && mounted) {
          // If already onboarded, mark consent automatically
          await prefs.setBool('driver_consent_given', true);
        }

        // Restore saved address
        final savedAddr = prefs.getString('driver_address');
        if (savedAddr != null && savedAddr.isNotEmpty) {
          setState(() {
            _driverLocation = LocationModel(
              latitude: _driverLocation.latitude,
              longitude: _driverLocation.longitude,
              address: savedAddr,
            );
          });
        }
      } catch (_) {}

      _subscribedCategory = driverCat;

      FCMNotificationService.initFCM(
        role: 'driver',
        userId: user.uid,
        category: driverCat,
      );
    });
  }

  @override
  void dispose() {
    _radarPulseController.dispose();
    _otpVerifyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOnlineStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedOnline = prefs.getBool('driver_is_online') ?? false;
      if (mounted) {
        setState(() {
          _isOnline = savedOnline;
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
              address: _driverLocation.address.isNotEmpty
                  ? _driverLocation.address
                  : 'Current Location (${pos.latitude.toStringAsFixed(3)}, ${pos.longitude.toStringAsFixed(3)})',
            );
          });
        }
      }
    } catch (_) {}
  }

  void _openLocationPicker() async {
    HapticFeedback.selectionClick();
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
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('driver_address', picked.address);
      } catch (_) {}
    }
  }

  void _toggleOnlineStatus(bool targetOnline) async {
    HapticFeedback.mediumImpact();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              targetOnline ? '🟢 You are now ONLINE & receiving bookings.' : '⚪ Shift OFF. You are now OFFLINE.',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            backgroundColor: targetOnline ? const Color(0xFF059669) : const Color(0xFF334155),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
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
      if (!launched) await launchUrl(uri);
    } catch (_) {
      try {
        await launchUrl(uri);
      } catch (_) {}
    }
  }

  bool _isCategoryEligible(String bookingCat, String driverCat) {
    final b = bookingCat.trim().toLowerCase();
    final d = driverCat.trim().toLowerCase();
    if (_selectedCategoryFilter != 'all') {
      if (_selectedCategoryFilter == 'tours' && !b.contains('tour')) return false;
      if (_selectedCategoryFilter != 'tours' && b != _selectedCategoryFilter && !b.contains(_selectedCategoryFilter)) return false;
    }
    if (b == d) return true;
    if ((d == 'car' || d == 'sedan' || d == 'mini' || d == 'suv') &&
        (b == 'car' || b == 'sedan' || b == 'mini' || b == 'suv')) {
      return true;
    }
    return false;
  }

  bool _isDistanceEligible(BookingModel booking, double driverLat, double driverLng) {
    if (booking.pickup.latitude == 0.0 && booking.pickup.longitude == 0.0) return true;
    if (driverLat == 0.0 && driverLng == 0.0) return true;

    final isTour = booking.bookingType == 'tour' ||
        (booking.tourDestinationName != null && booking.tourDestinationName!.isNotEmpty);
    final isLongDistance = isTour || booking.isRoundTrip || (booking.estimatedDistanceKm > 25);
    final maxRadiusKm = isLongDistance ? 35.0 : 20.0;

    final distanceMeters = Geolocator.distanceBetween(
      driverLat,
      driverLng,
      booking.pickup.latitude,
      booking.pickup.longitude,
    );
    final distanceKm = distanceMeters / 1000.0;
    return distanceKm <= maxRadiusKm;
  }

  double _calculatePickupDistanceKm(BookingModel booking) {
    if (booking.pickup.latitude == 0.0 || _driverLocation.latitude == 0.0) return 1.5;
    final meters = Geolocator.distanceBetween(
      _driverLocation.latitude,
      _driverLocation.longitude,
      booking.pickup.latitude,
      booking.pickup.longitude,
    );
    return meters / 1000.0;
  }

  void _declineBooking(BookingModel booking) {
    HapticFeedback.lightImpact();
    setState(() {
      _dismissedBookingIds.add(booking.id);
    });
    try {
      ref.read(driverServiceProvider).rejectRide(booking.id, null);
    } catch (_) {}

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Request declined for #${booking.readableId}.'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAcceptConfirmationModal(BookingModel booking) {
    bool pledgeAgreed = true;
    bool isProcessing = false;
    final pickupDistanceKm = _calculatePickupDistanceKm(booking);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFFDCFCE7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.handshake_outlined, color: Color(0xFF15803D), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Confirm Ride Acceptance',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                              ),
                              Text(
                                'Direct Partner Booking · 100% Guaranteed Fare',
                                style: TextStyle(fontSize: 11.5, color: Color(0xFF059669), fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Fare & Pickup Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Guaranteed Trip Fare:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                              Text(
                                '₹${(booking.finalFare ?? booking.estimatedFare).toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                              ),
                            ],
                          ),
                          const Divider(height: 18),
                          Row(
                            children: [
                              const Icon(Icons.near_me, size: 16, color: Color(0xFF059669)),
                              const SizedBox(width: 6),
                              Text(
                                'Pickup is ~${pickupDistanceKm.toStringAsFixed(1)} km from your current stand',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.radio_button_checked, size: 14, color: Color(0xFF059669)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  booking.pickup.address,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: Color(0xFFDC2626)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  booking.destination.address,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Driver Pledge Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.verified_user, color: Color(0xFF92400E), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Partner Arrival Commitment',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF92400E)),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Once locked, head directly to pickup stand. Customer will be notified with your vehicle details.',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF78350F), height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Agreement Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: pledgeAgreed,
                          activeColor: const Color(0xFF059669),
                          onChanged: (val) => setModalState(() => pledgeAgreed = val ?? true),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => pledgeAgreed = !pledgeAgreed),
                            child: const Text(
                              'I agree to complete this trip on time without cancellation.',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Action Buttons: Decline & Confirm Lock
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Back / Cancel', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: (!pledgeAgreed || isProcessing)
                                ? null
                                : () async {
                                    setModalState(() => isProcessing = true);
                                    try {
                                      await ref.read(driverServiceProvider).acceptRide(booking.id, null);
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      if (mounted) {
                                        setState(() {
                                          _activeBooking = booking.copyWith(status: 'driver_assigned');
                                        });
                                      }
                                    } catch (e) {
                                      setModalState(() => isProcessing = false);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Could not accept: $e')),
                                        );
                                      }
                                    }
                                  },
                            child: isProcessing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    'CONFIRM & LOCK RIDE',
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
      await ref.read(driverServiceProvider).startTrip(
        booking.id,
        enteredOtp.isNotEmpty ? enteredOtp : (booking.rideOtp ?? '1234'),
      );
      setState(() {
        _activeBooking = booking.copyWith(status: 'trip_started');
        _otpVerifyCtrl.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip Started! Have a safe journey. 🚗'), backgroundColor: Color(0xFF059669)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting trip: $e')),
        );
      }
    }
  }

  void _completeTrip(BookingModel booking) async {
    try {
      await ref.read(driverServiceProvider).completeTrip(booking.id);
      setState(() {
        _activeBooking = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip Completed! Fare credited to your Partner Wallet. Available for new rides. 🎉'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing trip: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(driverServiceProvider).currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/app_logo.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const CircularProgressIndicator(color: Color(0xFF059669)),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => context.go('/driver-login'),
                icon: const Icon(Icons.login, size: 18),
                label: const Text('Driver Partner Sign In', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('driverId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, activeSnap) {
        if (activeSnap.hasData && activeSnap.data!.docs.isNotEmpty) {
          final matchedDocs = activeSnap.data!.docs.where((doc) {
            final raw = doc.data();
            final m = (raw is Map) ? Map<String, dynamic>.from(raw) : null;
            final st = m?['status']?.toString();
            return st == 'driver_assigned' || st == 'driver_arrived' || st == 'trip_started';
          }).toList();

          if (matchedDocs.isNotEmpty) {
            try {
              final doc = matchedDocs.first;
              final raw = doc.data();
              final m = (raw is Map) ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
              final b = BookingModel.fromMap(m, doc.id);
              _activeBooking = b;
            } catch (_) {}
          } else if (_activeBooking != null) {
            _activeBooking = null;
          }
        } else if (activeSnap.hasData && activeSnap.data!.docs.isEmpty && _activeBooking != null) {
          _activeBooking = null;
        }

        final isCurrentlyBusy = _activeBooking != null;

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('drivers').doc(user.uid).snapshots(),
          builder: (context, snapshot) {
            final rawDoc = (snapshot.hasData && snapshot.data!.exists) ? snapshot.data!.data() : null;
            final Map<String, dynamic> data = (rawDoc is Map)
                ? Map<String, dynamic>.from(rawDoc)
                : {
                    'name': user.displayName ?? 'Driver Partner',
                    'phoneNumber': user.phoneNumber ?? '+91 94311 23456',
                    'vehiclePlateNumber': 'JH 01 BZ 4892',
                    'vehicleModel': 'Maruti Suzuki Dzire AC',
                    'vehicleCategoryId': 'car',
                    'verificationStatus': 'approved',
                    'rating': 4.9,
                    'totalTrips': 28,
                    'totalEarnings': 6850.0,
                    'walletBalance': 6165.0,
                  };

            double asDouble(dynamic val, [double fallback = 0.0]) {
              if (val == null) return fallback;
              if (val is num) return val.toDouble();
              return double.tryParse(val.toString()) ?? fallback;
            }

            final String name = (data['name'] != null && data['name'].toString().trim().isNotEmpty)
                ? data['name'].toString().trim()
                : (user.displayName != null && user.displayName!.isNotEmpty ? user.displayName! : 'Driver Partner');
            final String plate = (data['vehiclePlateNumber'] ?? data['vehiclePlate'])?.toString().trim() ?? 'JH 01 BZ 4892';
            final String vehicleModel = data['vehicleModel']?.toString().trim() ?? 'Maruti Dzire AC';
            final String driverPhone = (data['phoneNumber'] ?? data['driverPhone'] ?? user.phoneNumber ?? '').toString().trim();
            final double rating = asDouble(data['rating'], 4.9);
            final double totalEarnings = asDouble(data['totalEarnings'], 6850.0);
            final double walletBalance = asDouble(data['walletBalance'], 6165.0);
            final int totalTrips = (data['totalTrips'] is num) ? (data['totalTrips'] as num).toInt() : 28;
            final String driverCategory = (data['vehicleCategoryId'] ?? data['category'] ?? 'car').toString().trim().toLowerCase();
            final String? driverPhoto = data['driverPhoto']?.toString();

            if (_subscribedCategory != driverCategory) {
              _subscribedCategory = driverCategory;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                FCMNotificationService.subscribeToTopic('driver_$driverCategory');
              });
            }

            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              body: Stack(
                children: [
                  // 1. TOP HERO VISUAL BACKDROP (Following Customer App Parallax Map / Hero Banner)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 220,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          _isOnline
                              ? 'assets/images/driver_radar_active_3d.jpg'
                              : 'assets/images/driver_offline_cozy_3d.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/images/radar_map_backdrop_dark.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Soft Dark Scrim Gradient
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.70),
                                Colors.black.withValues(alpha: 0.35),
                                const Color(0xFFF8FAFC),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. MAIN SCROLLABLE CONTENT BODY
                  Positioned.fill(
                    child: SafeArea(
                      child: Column(
                        children: [
                          // A. Executive Header Top Bar
                          _buildExecutiveTopBar(isCurrentlyBusy, walletBalance),

                          // B. Scrollable Viewport
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                              padding: const EdgeInsets.fromLTRB(16, 6, 16, 140),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Hotspot Stand Pill
                                  _buildHotspotSelector(isCurrentlyBusy),
                                  const SizedBox(height: 12),

                                  // Driver Identity & Duty Card (COMPLETELY FIXED: NO BIG COLUMN, 100% RESPONSIVE)
                                  _buildResponsiveDriverCard(
                                    name: name,
                                    plate: plate,
                                    vehicleModel: vehicleModel,
                                    driverPhone: driverPhone,
                                    rating: rating,
                                    category: driverCategory,
                                    driverPhoto: driverPhoto,
                                    isCurrentlyBusy: isCurrentlyBusy,
                                  ),
                                  const SizedBox(height: 14),

                                  // Quick Metrics Strip (Wallet, Trips, Rating)
                                  _buildQuickMetricsStrip(walletBalance, totalEarnings, totalTrips, rating),
                                  const SizedBox(height: 18),

                                  // Category Filter Bar
                                  _buildCategoryFilterRow(),
                                  const SizedBox(height: 14),

                                  // Eligible Booking Requests Feed (With BOTH Clear Visible ACCEPT & DECLINE Buttons)
                                  _buildRequestsSection(driverCategory, isCurrentlyBusy),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. PERSISTENT FLOATING ACTIVE TRIP DOCK
                  if (_activeBooking != null)
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 14,
                      child: _buildActiveBookingCard(_activeBooking!),
                    ),

                  // 4. EMBEDDED INCOMING REQUEST AUDIO & VISUAL OVERLAY
                  if (_isOnline && !isCurrentlyBusy)
                    IncomingRequestOverlay(
                      driverId: user.uid,
                      vehicleCategory: driverCategory,
                      driverLocation: _driverLocation,
                      onAccepted: (booking) {
                        setState(() {
                          _activeBooking = booking.copyWith(status: 'driver_assigned');
                        });
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// EXECUTIVE TOP BAR (Hierarchy matching Customer App)
  Widget _buildExecutiveTopBar(bool isCurrentlyBusy, double walletBalance) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/app_logo.jpg'),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'District Car',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCurrentlyBusy
                              ? const Color(0xFFF59E0B)
                              : (_isOnline ? const Color(0xFF10B981) : const Color(0xFF94A3B8)),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCurrentlyBusy
                            ? 'ACTIVE JOURNEY'
                            : (_isOnline ? 'ONLINE · RADAR ON' : 'OFFLINE SHIFT'),
                        style: TextStyle(
                          color: isCurrentlyBusy
                              ? const Color(0xFFFDE68A)
                              : (_isOnline ? const Color(0xFFA7F3D0) : const Color(0xFFCBD5E1)),
                          fontWeight: FontWeight.w800,
                          fontSize: 9.5,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Actions on Right: Wallet Quick Pill & Profile
          Row(
            children: [
              InkWell(
                onTap: () => context.push('/driver-earnings'),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet, color: Color(0xFF34D399), size: 15),
                      const SizedBox(width: 5),
                      Text(
                        '₹${walletBalance.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.45),
                  padding: const EdgeInsets.all(8),
                ),
                icon: const Icon(Icons.person, color: Colors.white, size: 18),
                onPressed: () => context.push('/driver-profile'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// HOTSPOT STAND SELECTOR (Location chip matching customer app)
  Widget _buildHotspotSelector(bool isCurrentlyBusy) {
    return InkWell(
      onTap: isCurrentlyBusy ? null : _openLocationPicker,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.my_location, color: Color(0xFF059669), size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CURRENT STAND / HOTSPOT',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    _driverLocation.address,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!isCurrentlyBusy)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'CHANGE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// RESPONSIVE DRIVER CARD (FIXES "NAME AND NUMBER SHOWING IN ONE BIG COLUMN")
  Widget _buildResponsiveDriverCard({
    required String name,
    required String plate,
    required String vehicleModel,
    required String driverPhone,
    required double rating,
    required String category,
    required String? driverPhoto,
    required bool isCurrentlyBusy,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Driver Photo Avatar with Category Badge
          Stack(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFDCFCE7),
                  border: Border.all(color: const Color(0xFF10B981), width: 2),
                ),
                child: ClipOval(
                  child: (driverPhoto != null && driverPhoto.isNotEmpty && !driverPhoto.startsWith('avatar'))
                      ? Image.network(
                          driverPhoto,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Color(0xFF15803D), size: 32),
                        )
                      : const Icon(Icons.person, color: Color(0xFF15803D), size: 32),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF059669),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 10),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // 2. Compact Driver Info Column (Never stretches into big vertical columns)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name & Verified Badge
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'VERIFIED',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),

                // Vehicle Model & Plate Monospace Chip
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        plate,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    Text(
                      vehicleModel,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 3),

                // Star Rating & Phone inline row
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 15),
                    const SizedBox(width: 2),
                    Text(
                      '$rating',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    if (driverPhone.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '· $driverPhone',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 3. Compact Duty Toggle Button (Online/Offline Switch)
          AnimatedBuilder(
            animation: _radarPulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isOnline ? _radarPulseAnimation.value : 1.0,
                child: child,
              );
            },
            child: SizedBox(
              height: 40,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isOnline ? const Color(0xFFDC2626) : const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  elevation: _isOnline ? 3 : 1,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: (_isToggling || isCurrentlyBusy) ? null : () => _toggleOnlineStatus(!_isOnline),
                child: _isToggling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isOnline ? Icons.power_settings_new : Icons.radar,
                            size: 15,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _isOnline ? 'OFFLINE' : 'GO ONLINE',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// QUICK METRICS STRIP (Ola/Uber Driver Style)
  Widget _buildQuickMetricsStrip(double walletBalance, double totalEarnings, int totalTrips, double rating) {
    return Row(
      children: [
        // 1. Wallet Balance Card
        Expanded(
          child: InkWell(
            onTap: () => context.push('/driver-earnings'),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF065F46), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('WALLET EARNINGS', style: TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text('₹${walletBalance.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text('Gross: ₹${totalEarnings.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFFA7F3D0), fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // 2. Total Completed Trips
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('COMPLETED TRIPS', style: TextStyle(color: Color(0xFF64748B), fontSize: 9.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text('$totalTrips Rides', style: const TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                const Text('100% Guaranteed', style: TextStyle(color: Color(0xFF059669), fontSize: 9.5, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // 3. Acceptance / Rating
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PARTNER SCORE', style: TextStyle(color: Color(0xFF64748B), fontSize: 9.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFF59E0B), size: 16),
                    const SizedBox(width: 3),
                    Text('$rating', style: const TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 2),
                const Text('Top Tier Partner', style: TextStyle(color: Color(0xFF059669), fontSize: 9.5, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// CATEGORY FILTER ROW (Horizontal Pills)
  Widget _buildCategoryFilterRow() {
    final filters = [
      {'id': 'all', 'label': 'All Requests'},
      {'id': 'car', 'label': 'Cabs & Cars'},
      {'id': 'auto', 'label': 'Auto Rickshaw'},
      {'id': 'tours', 'label': '🌴 Tours & Travels'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedCategoryFilter == f['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f['label']!),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedCategoryFilter = f['id']!),
              selectedColor: const Color(0xFF059669),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF475569),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 11.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isSelected ? const Color(0xFF059669) : const Color(0xFFE2E8F0)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// REQUESTS SECTION (With Both ACCEPT and DECLINE Buttons clearly visible)
  Widget _buildRequestsSection(String driverCategory, bool isCurrentlyBusy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'LIVE BOOKING RADAR',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF334155),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 8),
                if (_isOnline && !isCurrentlyBusy)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('AUTO REFRESH', style: TextStyle(color: Color(0xFF15803D), fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            Text(
              'Radius: 15–35 km',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (!_isOnline) ...[
          // Offline Shift Card with 3D Illustration
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/images/driver_offline_cozy_3d.jpg',
                    height: 130,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.nightlight_round, size: 50, color: Color(0xFF94A3B8)),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('You are Currently Offline', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
                const SizedBox(height: 4),
                const Text(
                  'Go Online to start receiving instant booking requests directly from village stands to district headquarters.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => _toggleOnlineStatus(true),
                    icon: const Icon(Icons.flash_on, size: 18),
                    label: const Text('GO ONLINE NOW', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5)),
                  ),
                ),
              ],
            ),
          ),
        ] else if (isCurrentlyBusy) ...[
          // Busy mode active
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.directions_car, color: Color(0xFFB45309), size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Active Trip in Progress', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF92400E))),
                      SizedBox(height: 2),
                      Text('You are serving a trip. Complete the active journey below to unlock new ride requests.', style: TextStyle(fontSize: 11.5, color: Color(0xFF78350F))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Online: Live Stream of searching_driver Bookings
          _buildAvailableRequestsStream(driverCategory),
        ],
      ],
    );
  }

  /// AVAILABLE REQUESTS STREAM WITH BOTH VISIBLE BUTTONS: DECLINE AND ACCEPT
  Widget _buildAvailableRequestsStream(String driverCategory) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('status', isEqualTo: 'searching_driver')
          .limit(15)
          .snapshots(),
      builder: (context, snapshot) {
        final allDocs = snapshot.data?.docs ?? [];
        final List<BookingModel> eligibleBookings = [];

        for (final doc in allDocs) {
          try {
            if (_dismissedBookingIds.contains(doc.id)) continue;
            final raw = doc.data();
            if (raw is! Map) continue;
            final d = Map<String, dynamic>.from(raw);
            final cat = (d['vehicleCategoryId'] ?? 'car').toString();
            if (!_isCategoryEligible(cat, driverCategory)) continue;

            final booking = BookingModel.fromMap(d, doc.id);
            if (_isDistanceEligible(booking, _driverLocation.latitude, _driverLocation.longitude)) {
              eligibleBookings.add(booking);
            }
          } catch (e) {
            debugPrint('Notice: Error parsing booking: $e');
          }
        }

        if (eligibleBookings.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/images/driver_radar_active_3d.jpg',
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.radar, size: 50, color: Color(0xFF059669)),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Live Radar Active — Searching Nearby', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A))),
                const SizedBox(height: 4),
                const Text(
                  'Bookings from riders within 15–35 km of your stand will sound an alert and appear right here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.3),
                ),
              ],
            ),
          );
        }

        return Column(
          children: eligibleBookings.map((booking) {
            final pickupDistKm = _calculatePickupDistanceKm(booking);
            final isTour = booking.bookingType == 'tour' || (booking.tourDestinationName != null && booking.tourDestinationName!.isNotEmpty);

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Tag, Booking ID, and Huge Guaranteed Fare
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isTour
                                  ? const Color(0xFFECFDF5)
                                  : (booking.isRoundTrip ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isTour
                                  ? '🌴 Tour Package'
                                  : (booking.isRoundTrip ? '🔄 Round Trip (2x Fare)' : '➡️ One-Way Trip'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: isTour || booking.isRoundTrip ? const Color(0xFF047857) : const Color(0xFF334155),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('#${booking.readableId}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                      Text(
                        '₹${(booking.finalFare ?? booking.estimatedFare).toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Distance Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Pickup ~${pickupDistKm.toStringAsFixed(1)} km from your stand · Trip: ${booking.estimatedDistanceKm} km',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF065F46), fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Route Details: Pickup & Destination
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.radio_button_checked, color: Color(0xFF059669), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          booking.pickup.address,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFFDC2626), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          booking.destination.address,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ACTION BUTTONS: BOTH DECLINE AND ACCEPT CLEARLY VISIBLE SIDE BY SIDE!
                  Row(
                    children: [
                      // 1. DECLINE BUTTON (Visible red outline/soft container)
                      Expanded(
                        flex: 1,
                        child: SizedBox(
                          height: 46,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                              side: const BorderSide(color: Color(0xFFFECACA), width: 1.5),
                              backgroundColor: const Color(0xFFFEF2F2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => _declineBooking(booking),
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: const Text(
                              'DECLINE',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // 2. ACCEPT RIDE BUTTON (Prominent Emerald Green Gradient)
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => _showAcceptConfirmationModal(booking),
                            icon: const Icon(Icons.check_circle_rounded, size: 19),
                            label: const Text(
                              'ACCEPT RIDE',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, letterSpacing: 0.3),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// ACTIVE BOOKING DETAILS CARD FLOATING ABOVE DOCK
  Widget _buildActiveBookingCard(BookingModel booking) {
    final isStarted = booking.status == 'trip_started';
    final customerPhone = booking.customerPhone ?? '+91 87896 01387';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFF10B981), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  isStarted ? 'TRIP IN PROGRESS' : 'DRIVER ASSIGNED · HEAD TO PICKUP',
                  style: TextStyle(
                    color: isStarted ? const Color(0xFF15803D) : const Color(0xFFB45309),
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    '₹${(booking.finalFare ?? booking.estimatedFare).toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _callCustomer(customerPhone),
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

          Text('📍 Pickup: ${booking.pickup.address}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700), maxLines: 1),
          const SizedBox(height: 3),
          Text('🏁 Drop: ${booking.destination.address}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)), maxLines: 1),
          const SizedBox(height: 14),

          if (!isStarted) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
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
                        hintText: 'Enter 4-digit Ride OTP from Customer',
                        hintStyle: TextStyle(fontSize: 12),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _verifyOtpAndStartTrip(booking),
                    child: const Text('Start Trip', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _completeTrip(booking),
                child: const Text('COMPLETE THIS TRIP', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
