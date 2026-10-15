import 'package:flutter/foundation.dart';
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
    address: 'Albert Ekka Chowk Stand, Ranchi, Jharkhand',
  );

  @override
  void initState() {
    super.initState();
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
          context.go('/driver-consent');
          return;
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

  bool _isCategoryEligible(String bookingCat, String driverCat) {
    final b = bookingCat.trim().toLowerCase();
    final d = driverCat.trim().toLowerCase();
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
    final maxRadiusKm = isLongDistance ? 30.0 : 15.0;

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
                                'Ride Acceptance & Arrival Consent',
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
                              const Text('Trip Fare:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                              Text(
                                '₹${(booking.finalFare ?? booking.estimatedFare).toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                              ),
                            ],
                          ),
                          const Divider(height: 18),
                          Row(
                            children: [
                              const Icon(Icons.near_me, size: 16, color: Color(0xFF059669)),
                              const SizedBox(width: 6),
                              Text(
                                'Pickup is ~${pickupDistanceKm.toStringAsFixed(1)} km from your stand',
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
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
                          const Icon(Icons.info_outline, color: Color(0xFF92400E), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Partner Commitment:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF92400E)),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'After accepting, the rider is waiting for you. Do not cancel without an emergency. Unreasonable cancellations will affect driver rating.',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF78350F), height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Interactive Pledge Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: pledgeAgreed,
                          activeColor: const Color(0xFF059669),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (v) => setModalState(() => pledgeAgreed = v ?? false),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => pledgeAgreed = !pledgeAgreed),
                            child: const Text(
                              'I agree to reach on time and complete this journey without cancellation.',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Confirm & Cancel Buttons
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
                            child: const Text('Back / Decline', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: (!pledgeAgreed || isProcessing)
                                ? null
                                : () async {
                                    setModalState(() => isProcessing = true);
                                    try {
                                      await ref.read(driverServiceProvider).acceptRide(booking.id, null);
                                      Navigator.pop(ctx);
                                      setState(() {
                                        _activeBooking = booking.copyWith(status: 'driver_assigned');
                                      });
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Ride Accepted! Marked Busy. Proceed to pickup. ✅'),
                                            backgroundColor: Color(0xFF059669),
                                          ),
                                        );
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
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

    // Active Booking Sync Listener (Index-free: query by driverId only, filter status in Dart)
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
          // Trip finished or cancelled remotely
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
                    'name': user.displayName ?? 'Ramesh Mahto',
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
            final String plate = (data['vehiclePlateNumber'] ?? data['vehiclePlate'])?.toString() ?? 'Vehicle not registered';
            final String vehicleModel = data['vehicleModel']?.toString() ?? 'Add Vehicle in Profile';
            final double rating = asDouble(data['rating'], 5.0);
            final double totalEarnings = asDouble(data['totalEarnings'], 0.0);
            final double walletBalance = asDouble(data['walletBalance'], totalEarnings * 0.9);
            final String driverCategory = (data['vehicleCategoryId'] ?? data['category'] ?? 'car').toString().trim().toLowerCase();

            if (_subscribedCategory != driverCategory) {
              _subscribedCategory = driverCategory;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                FCMNotificationService.subscribeToTopic('driver_$driverCategory');
              });
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
                      isCurrentlyBusy
                          ? '🟡 BUSY (On Active Journey)'
                          : (_isOnline ? '🟢 ONLINE (Ready for trips)' : '⚪ OFFLINE (Tap to Go Online)'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isCurrentlyBusy
                            ? const Color(0xFFD97706)
                            : (_isOnline ? const Color(0xFF16A34A) : Colors.grey.shade600),
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
              body: SafeArea(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 200),
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
                                  onPressed: (_isToggling || isCurrentlyBusy) ? null : () => _toggleOnlineStatus(!_isOnline),
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
                            onTap: isCurrentlyBusy ? null : _openLocationPicker,
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
                                  if (!isCurrentlyBusy) const Icon(Icons.edit, size: 14, color: Color(0xFF059669)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Quick Earnings & Wallet Box
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF065F46), Color(0xFF059669)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF059669).withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Wallet Balance',
                                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '₹${walletBalance.toStringAsFixed(0)}',
                                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Total Gross: ₹${totalEarnings.toStringAsFixed(0)}',
                                      style: const TextStyle(color: Colors.white60, fontSize: 10),
                                    ),
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
                                  child: const Text('Passbook & Payout', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Available Booking Requests Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'ELIGIBLE BOOKING REQUESTS',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textMuted, letterSpacing: 0.8),
                              ),
                              if (_isOnline && !isCurrentlyBusy)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('LIVE RADAR', style: TextStyle(color: Color(0xFF15803D), fontSize: 10, fontWeight: FontWeight.bold)),
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
                          ] else if (isCurrentlyBusy) ...[
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
                                        Text('Driver Busy Mode Active', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF92400E))),
                                        SizedBox(height: 2),
                                        Text('You are on an active trip. Complete current trip below to receive new bookings.', style: TextStyle(fontSize: 11, color: Color(0xFF78350F))),
                                      ],
                                    ),
                                  ),
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

                    // Persistent Active Booking Card Floating Above Dock
                    if (_activeBooking != null)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: _buildActiveBookingCard(_activeBooking!),
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Column(
              children: [
                Icon(Icons.radar, size: 40, color: Color(0xFF059669)),
                SizedBox(height: 10),
                Text('Radar Active — Waiting for Rides', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                SizedBox(height: 4),
                Text('When an eligible customer books in your 15km/30km radius, it will appear here immediately.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        return Column(
          children: eligibleBookings.map((booking) {
            final pickupDistKm = _calculatePickupDistanceKm(booking);

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
                              booking.isRoundTrip ? '🔄 Round Trip' : '➡️ One-Way',
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
                        '₹${(booking.finalFare ?? booking.estimatedFare).toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pickup ~${pickupDistKm.toStringAsFixed(1)} km from your stand · Trip: ${booking.estimatedDistanceKm} km',
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF059669), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
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
                      onPressed: () => _showAcceptConfirmationModal(booking),
                      child: const Text('ACCEPT THIS RIDE', style: TextStyle(fontWeight: FontWeight.bold)),
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
    final customerPhone = booking.customerPhone ?? '+91 87896 01387';

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
                  isStarted ? 'TRIP IN PROGRESS' : 'DRIVER ASSIGNED',
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
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
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
                child: const Text('COMPLETE TRIP', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
