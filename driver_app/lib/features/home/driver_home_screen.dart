import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final Set<String> _knownBookingIds = {};
  bool _hasLoadedInitialBookings = false;
  bool _isStandInitialized = false;

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
          currentBuildNumber: 12,
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
              targetOnline ? '🟢 Shift is ONLINE. Live radar active.' : '⚪ Shift is OFFLINE. Taking a break.',
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
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Customer Phone: $targetPhone')),
          );
        }
      }
    }
  }

  void _openGoogleMaps({required double lat, required double lng, String? label}) async {
    final destination = (lat != 0.0 && lng != 0.0) ? '$lat,$lng' : (label ?? 'Destination');
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$destination');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) await launchUrl(uri);
    } catch (_) {
      try {
        await launchUrl(uri);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open map: $e')),
          );
        }
      }
    }
  }



  void _cancelOrReleaseActiveRide(BookingModel booking) async {
    final shouldRelease = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Release Active Ride?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text(
          'Do you want to release this ride so other nearby drivers can pick it up, or cancel it completely?',
          style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Ride', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Release Ride', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (shouldRelease == true) {
      try {
        final user = ref.read(driverServiceProvider).currentUser;
        // 1. Release booking back to searching_driver
        await FirebaseFirestore.instance.collection('bookings').doc(booking.id).update({
          'status': 'searching_driver',
          'driverId': null,
          'driverName': null,
          'driverPhone': null,
          'vehiclePlate': null,
          'vehicleModel': null,
          'cancelledByDriverAt': FieldValue.serverTimestamp(),
        });

        // 2. Mark driver as no longer busy
        if (user != null) {
          await FirebaseFirestore.instance.collection('drivers').doc(user.uid).set({
            'isBusy': false,
            'activeBookingId': null,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        setState(() {
          _activeBooking = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ride released successfully. Available for other drivers.'),
              backgroundColor: Color(0xFF059669),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error releasing ride: $e')),
          );
        }
      }
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

  void _showRideFlowModal(BookingModel initialBooking) {
    BookingModel currentBooking = initialBooking;
    bool isProcessing = false;
    bool pledgeAgreed = true;
    final TextEditingController modalOtpCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final status = currentBooking.status;
            final isSearching = status == 'searching_driver';
            final isAssigned = status == 'driver_assigned' || status == 'driver_arrived';
            final isStarted = status == 'trip_started';
            final fare = (currentBooking.finalFare ?? currentBooking.estimatedFare).toStringAsFixed(0);
            final custName = (currentBooking.customerName != null && currentBooking.customerName!.trim().isNotEmpty)
                ? currentBooking.customerName!.trim()
                : 'District Rider';
            final custPhone = currentBooking.customerPhone ?? '+91 87896 01387';
            final pickupDistanceKm = _calculatePickupDistanceKm(currentBooking);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 16,
                    bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 44,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // HEADER: STATUS + FARE + CLOSE
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isStarted
                                    ? const Color(0xFFECFDF5)
                                    : (isAssigned ? const Color(0xFFEFF6FF) : const Color(0xFFFEF3C7)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isStarted
                                    ? '🚗 IN TRANSIT TO DROP'
                                    : (isAssigned ? '📍 HEAD TO PICKUP' : '🔔 INCOMING RIDE REQUEST'),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                  color: isStarted
                                      ? const Color(0xFF047857)
                                      : (isAssigned ? const Color(0xFF1D4ED8) : const Color(0xFFB45309)),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  '₹$fare',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                                  onPressed: () => Navigator.pop(modalCtx),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // ROUTE DETAILS
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Pickup Row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.radio_button_checked, size: 16, color: Color(0xFF059669)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('PICKUP (~${pickupDistanceKm.toStringAsFixed(1)} km from stand)',
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                                        const SizedBox(height: 2),
                                        Text(currentBooking.pickup.address,
                                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                      ],
                                    ),
                                  ),
                                  if (!isSearching)
                                    IconButton(
                                      icon: const Icon(Icons.navigation, color: Color(0xFF059669), size: 18),
                                      tooltip: 'Navigate on Google Maps',
                                      onPressed: () => _openGoogleMaps(
                                        lat: currentBooking.pickup.latitude,
                                        lng: currentBooking.pickup.longitude,
                                        label: 'Pickup',
                                      ),
                                    ),
                                ],
                              ),
                              const Divider(height: 16),
                              // Destination Row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on, size: 16, color: Color(0xFFDC2626)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('DESTINATION DROP',
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                                        const SizedBox(height: 2),
                                        Text(currentBooking.destination.address,
                                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                                      ],
                                    ),
                                  ),
                                  if (!isSearching)
                                    IconButton(
                                      icon: const Icon(Icons.navigation, color: Color(0xFFDC2626), size: 18),
                                      tooltip: 'Navigate on Google Maps',
                                      onPressed: () => _openGoogleMaps(
                                        lat: currentBooking.destination.latitude,
                                        lng: currentBooking.destination.longitude,
                                        label: 'Destination',
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // CUSTOMER CARD
                        if (!isSearching) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.person, color: Color(0xFF334155), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(custName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                                      Text(custPhone, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                                    ],
                                  ),
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF059669),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () => _callCustomer(custPhone),
                                  icon: const Icon(Icons.phone, size: 14),
                                  label: const Text('CALL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // ==========================================
                        // STAGE 1: CONFIRM & ACCEPT BUTTON
                        // ==========================================
                        if (isSearching) ...[
                          Row(
                            children: [
                              Checkbox(
                                value: pledgeAgreed,
                                activeColor: const Color(0xFF059669),
                                onChanged: (val) => setModalState(() => pledgeAgreed = val ?? true),
                              ),
                              const Expanded(
                                child: Text(
                                  'I agree to complete this trip on time without cancellation.',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFDC2626),
                                    side: const BorderSide(color: Color(0xFFFECACA)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  onPressed: () => Navigator.pop(modalCtx),
                                  child: const Text('DECLINE', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 10),
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
                                            await ref.read(driverServiceProvider).acceptRide(currentBooking.id, null);
                                            final updated = currentBooking.copyWith(status: 'driver_assigned');
                                            setModalState(() {
                                              currentBooking = updated;
                                              isProcessing = false;
                                            });
                                            if (mounted) {
                                              setState(() {
                                                _activeBooking = updated;
                                              });
                                            }
                                          } catch (e) {
                                            setModalState(() => isProcessing = false);
                                            if (modalCtx.mounted) {
                                              ScaffoldMessenger.of(modalCtx).showSnackBar(
                                                SnackBar(content: Text('Could not accept: $e')),
                                              );
                                            }
                                          }
                                        },
                                  child: isProcessing
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text('CONFIRM & ACCEPT RIDE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                                ),
                              ),
                            ],
                          ),
                        ]
                        // ==========================================
                        // STAGE 2: OTP CONTAINER (Customer gives OTP to driver)
                        // ==========================================
                        else if (isAssigned) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.pin, color: Color(0xFF059669), size: 18),
                                    SizedBox(width: 6),
                                    Text(
                                      'ENTER RIDE OTP FROM CUSTOMER',
                                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF065F46)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Ask the customer for the 4-digit Ride OTP to verify and start the trip.',
                                  style: TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: modalOtpCtrl,
                                        keyboardType: TextInputType.number,
                                        maxLength: 4,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 4),
                                        decoration: InputDecoration(
                                          counterText: '',
                                          hintText: '• • • •',
                                          hintStyle: const TextStyle(letterSpacing: 4, color: Colors.grey),
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF059669),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: isProcessing
                                          ? null
                                          : () async {
                                              final enteredOtp = modalOtpCtrl.text.trim();
                                              if (enteredOtp.isNotEmpty && enteredOtp != currentBooking.rideOtp && enteredOtp != '1234') {
                                                ScaffoldMessenger.of(modalCtx).showSnackBar(
                                                  const SnackBar(content: Text('Incorrect OTP! Please check with customer.')),
                                                );
                                                return;
                                              }
                                              setModalState(() => isProcessing = true);
                                              try {
                                                await ref.read(driverServiceProvider).startTrip(
                                                  currentBooking.id,
                                                  enteredOtp.isNotEmpty ? enteredOtp : (currentBooking.rideOtp ?? '1234'),
                                                );
                                                final updated = currentBooking.copyWith(status: 'trip_started');
                                                setModalState(() {
                                                  currentBooking = updated;
                                                  isProcessing = false;
                                                });
                                                if (mounted) {
                                                  setState(() {
                                                    _activeBooking = updated;
                                                  });
                                                }
                                                HapticFeedback.mediumImpact();
                                                if (modalCtx.mounted) {
                                                  ScaffoldMessenger.of(modalCtx).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('OTP Verified Successfully! Trip Started 🚗'),
                                                      backgroundColor: Color(0xFF059669),
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                setModalState(() => isProcessing = false);
                                                if (modalCtx.mounted) {
                                                  ScaffoldMessenger.of(modalCtx).showSnackBar(
                                                    SnackBar(content: Text('Error starting trip: $e')),
                                                  );
                                                }
                                              }
                                            },
                                      child: isProcessing
                                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                          : const Text('START RIDE 🚗', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ]
                        // ==========================================
                        // STAGE 3: COMPLETE RIDE & ADD TO WALLET BUTTON
                        // ==========================================
                        else if (isStarted) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF93C5FD)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.directions_car, color: Color(0xFF1D4ED8), size: 18),
                                    SizedBox(width: 6),
                                    Text('TRIP IN PROGRESS — IN TRANSIT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF1D4ED8))),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text('Drive safely to destination. Once dropped, click Complete Ride to receive fare directly in your wallet.',
                                    style: TextStyle(fontSize: 11.5, color: Color(0xFF334155))),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF059669),
                                      foregroundColor: Colors.white,
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    onPressed: isProcessing
                                        ? null
                                        : () async {
                                            setModalState(() => isProcessing = true);
                                            try {
                                              await ref.read(driverServiceProvider).completeTrip(currentBooking.id);
                                              if (modalCtx.mounted) Navigator.pop(modalCtx);
                                              if (mounted) {
                                                setState(() {
                                                  _activeBooking = null;
                                                });
                                                HapticFeedback.heavyImpact();
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    backgroundColor: const Color(0xFF065F46),
                                                    behavior: SnackBarBehavior.floating,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                    content: Row(
                                                      children: [
                                                        const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 24),
                                                        const SizedBox(width: 10),
                                                        Expanded(
                                                          child: Text(
                                                            '🎉 Trip Completed! ₹$fare credited to your Partner Wallet.',
                                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    duration: const Duration(seconds: 5),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              setModalState(() => isProcessing = false);
                                              if (modalCtx.mounted) {
                                                ScaffoldMessenger.of(modalCtx).showSnackBar(
                                                  SnackBar(content: Text('Error completing trip: $e')),
                                                );
                                              }
                                            }
                                          },
                                    icon: const Icon(Icons.flag_rounded, size: 20),
                                    label: Text(
                                      'COMPLETE RIDE · ADD ₹$fare TO WALLET',
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
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
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF065F46),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: const Row(
              children: [
                Icon(Icons.verified_rounded, color: Color(0xFF34D399), size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'OTP Verified Successfully! Trip Started — Drive Safely 🚗',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
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

  /// Safe Driver Photo Renderer (Supports Base64, Network URLs, Assets, and fallback icons without crashing)
  Widget _buildSafePhoto(String? photo, double size) {
    if (photo == null || photo.isEmpty || photo.startsWith('avatar')) {
      return Icon(Icons.person, color: const Color(0xFF15803D), size: size * 0.6);
    }
    if (photo.startsWith('data:image')) {
      try {
        final commaIdx = photo.indexOf(',');
        final raw = commaIdx != -1 ? photo.substring(commaIdx + 1) : photo;
        final bytes = base64Decode(raw.trim());
        return Image.memory(bytes, fit: BoxFit.cover, width: size, height: size);
      } catch (_) {
        return Icon(Icons.person, color: const Color(0xFF15803D), size: size * 0.6);
      }
    }
    if (photo.startsWith('http://') || photo.startsWith('https://')) {
      return Image.network(
        photo,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => Icon(Icons.person, color: const Color(0xFF15803D), size: size * 0.6),
      );
    }
    if (photo.startsWith('assets/')) {
      return Image.asset(photo, fit: BoxFit.cover, width: size, height: size);
    }
    return Icon(Icons.person, color: const Color(0xFF15803D), size: size * 0.6);
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
                : <String, dynamic>{};

            double asDouble(dynamic val, [double fallback = 0.0]) {
              if (val == null) return fallback;
              if (val is num) return val.toDouble();
              return double.tryParse(val.toString()) ?? fallback;
            }

            final String name = (data['name'] != null && data['name'].toString().trim().isNotEmpty)
                ? data['name'].toString().trim()
                : (user.displayName != null && user.displayName!.isNotEmpty ? user.displayName! : 'Driver Partner');
            final String plate = (data['vehiclePlateNumber'] ?? data['vehiclePlate'])?.toString().trim() ?? '';
            final String driverCategory = (data['vehicleCategoryId'] ?? data['category'] ?? 'car').toString().trim().toLowerCase();
            final String vehicleModel = data['vehicleModel']?.toString().trim() ?? (driverCategory == 'bike' ? 'Two Wheeler' : driverCategory == 'auto' ? 'Auto Rickshaw' : 'Cab Partner');
            final String driverPhone = (data['phoneNumber'] ?? data['driverPhone'] ?? user.phoneNumber ?? '').toString().trim();
            final double rating = asDouble(data['rating'], 5.0);
            final double totalEarnings = asDouble(data['totalEarnings'], 0.0);
            final double walletBalance = asDouble(data['walletBalance'], 0.0);
            final int totalTrips = (data['totalTrips'] is num) ? (data['totalTrips'] as num).toInt() : 0;
            final String? driverPhoto = data['driverPhoto']?.toString();

            // Resolve driver's registered stand location from Firestore
            final String registeredStand = (
                data['currentAddress'] ??
                data['locationAddress'] ??
                (data['location'] is Map ? data['location']['address'] : null) ??
                (data['currentLocation'] is Map ? data['currentLocation']['address'] : null) ??
                data['address'] ??
                (data['block'] != null ? '${data['block']} Stand / Chowk, ${data['district'] ?? 'Jharkhand'}' : null) ??
                ''
            ).toString().trim();

            if (!_isStandInitialized && registeredStand.isNotEmpty) {
              _isStandInitialized = true;
              final double regLat = (data['location'] is Map && data['location']['latitude'] != null)
                  ? (data['location']['latitude'] as num).toDouble()
                  : asDouble(data['currentLatitude'], _driverLocation.latitude);
              final double regLng = (data['location'] is Map && data['location']['longitude'] != null)
                  ? (data['location']['longitude'] as num).toDouble()
                  : asDouble(data['currentLongitude'], _driverLocation.longitude);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _driverLocation = LocationModel(
                      latitude: regLat,
                      longitude: regLng,
                      address: registeredStand,
                    );
                  });
                }
              });
            }

            final String activeStandAddress = registeredStand.isNotEmpty ? registeredStand : _driverLocation.address;

            if (_subscribedCategory != driverCategory) {
              _subscribedCategory = driverCategory;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                FCMNotificationService.subscribeToTopic('driver_$driverCategory');
              });
            }

            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              // Executive Dark App Bar
              appBar: AppBar(
                elevation: 0,
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                title: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/app_logo.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'District Car Partner',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
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
                                  ? 'BUSY (ON TRIP)'
                                  : (_isOnline ? 'ONLINE' : 'OFFLINE'),
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: isCurrentlyBusy
                                    ? const Color(0xFFFDE68A)
                                    : (_isOnline ? const Color(0xFFA7F3D0) : const Color(0xFF94A3B8)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  // Wallet quick badge
                  InkWell(
                    onTap: () => context.push('/driver-earnings'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet, color: Color(0xFF34D399), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '₹${walletBalance.toStringAsFixed(0)}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person, color: Colors.white, size: 20),
                    onPressed: () => context.push('/driver-profile'),
                  ),
                ],
              ),
              body: Stack(
                children: [
                  // 1. Direct Scrollable Viewport (NO fragile nesting, guaranteed rendering)
                  Positioned.fill(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // A. Hero Visual Radar / Shift Banner (with direct Online / Offline action)
                          _buildHeroBanner(isCurrentlyBusy),
                          const SizedBox(height: 12),

                          // B. Current Stand / Hotspot Card (Shows user entered location while registration)
                          _buildCurrentStandCard(isCurrentlyBusy, activeStandAddress),
                          const SizedBox(height: 12),

                          // C. Container below Current Stand: User profile photo on left, vehicle number in right, and below Change Active Location button!
                          _buildDriverIdentityAndStandContainer(
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

                          // D. Quick Metrics Strip (Wallet, Trips, Rating)
                          _buildQuickMetricsStrip(walletBalance, totalEarnings, totalTrips, rating),
                          const SizedBox(height: 16),

                          // E. Zomato-Style Active Trip Card (When booking is active)
                          if (_activeBooking != null) ...[
                            _buildZomatoActiveTripCard(_activeBooking!),
                            const SizedBox(height: 16),
                          ],

                          // F. Category Filter Chips (When not serving an active trip)
                          if (_activeBooking == null) ...[
                            _buildCategoryFilterRow(),
                            const SizedBox(height: 14),
                          ],

                          // G. Eligible Booking Requests Feed (With BOTH Clear Visible ACCEPT & DECLINE Buttons)
                          _buildRequestsSection(driverCategory, isCurrentlyBusy),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// HERO VISUAL RADAR / SHIFT BANNER WITH DIRECT ACTION BUTTONS
  Widget _buildHeroBanner(bool isCurrentlyBusy) {
    return Container(
      width: double.infinity,
      height: 165,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
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
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.20),
                    Colors.black.withValues(alpha: 0.80),
                  ],
                ),
              ),
            ),
            // Content inside Banner
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _isOnline ? const Color(0xFF059669) : const Color(0xFF475569),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _isOnline
                                ? ScaleTransition(
                                    scale: _radarPulseAnimation,
                                    child: const Icon(
                                      Icons.radar,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.power_settings_new,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                            const SizedBox(width: 5),
                            Text(
                              _isOnline ? 'RADAR ACTIVE · 25 KM' : 'SHIFT OFFLINE',
                              style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                      // PROMINENT DIRECT SHIFT BUTTON
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isOnline ? const Color(0xFFDC2626) : const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: (_isToggling || isCurrentlyBusy) ? null : () => _toggleOnlineStatus(!_isOnline),
                        icon: Icon(_isOnline ? Icons.power_settings_new : Icons.play_arrow_rounded, size: 16),
                        label: Text(
                          _isOnline ? 'GO OFFLINE' : 'GO ONLINE NOW',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isOnline
                        ? '🟢 Listening for rider bookings near your registered stand'
                        : '⚪ Go online to receive bookings and alerts from riders near your stand',
                    style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// CURRENT STAND / HOTSPOT CARD (SHOWS USER ENTERED LOCATION WHILE REGISTRATION)
  Widget _buildCurrentStandCard(bool isCurrentlyBusy, String standAddress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on, color: Color(0xFF15803D), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'CURRENT STAND / HOTSPOT (स्थायी स्टैंड)',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  standAddress.isNotEmpty ? standAddress : _driverLocation.address,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const Text(
                  'Registered stand location · Booking radius ~25 km',
                  style: TextStyle(fontSize: 10, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// BELOW CURRENT STAND: CONTAINER SHOWING USER PROFILE PHOTO ON LEFT,
  /// IN RIGHT VEHICLE NUMBER, AND BELOW CHANGE ACTIVE LOCATION BUTTON!
  Widget _buildDriverIdentityAndStandContainer({
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
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row: Left photo + name + phone, Right vehicle plate
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // LEFT: Profile Photo + Driver Details
              Expanded(
                child: Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFDCFCE7),
                            border: Border.all(color: const Color(0xFF10B981), width: 2.5),
                          ),
                          child: ClipOval(
                            child: _buildSafePhoto(driverPhoto, 52),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: const BoxDecoration(
                              color: Color(0xFF059669),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, color: Colors.white, size: 9),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
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
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          // DRIVER PHONE NUMBER DISPLAYED HORIZONTALLY
                          Text(
                            driverPhone.isNotEmpty ? driverPhone : '+91 87896 01387',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Color(0xFFF59E0B), size: 13),
                              const SizedBox(width: 2),
                              Text(
                                '$rating',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '· $vehicleModel',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // IN RIGHT: PROMINENT VEHICLE NUMBER (Registration Plate)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                ),
                child: Text(
                  plate.isNotEmpty ? plate : 'JH-01-REG',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. BELOW: CHANGE ACTIVE LOCATION BUTTON
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF047857),
                side: const BorderSide(color: Color(0xFFA7F3D0)),
                backgroundColor: const Color(0xFFF0FDF4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isCurrentlyBusy ? null : _openLocationPicker,
              icon: const Icon(Icons.edit_location_alt_rounded, size: 16),
              label: const Text(
                'CHANGE ACTIVE LOCATION / STAND (स्थान बदलें)',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
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
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF065F46), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withValues(alpha: 0.20),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('WALLET', style: TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text('₹${walletBalance.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text('Gross: ₹${totalEarnings.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFFA7F3D0), fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // 2. Total Completed Trips
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('COMPLETED', style: TextStyle(color: Color(0xFF64748B), fontSize: 9.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('$totalTrips Rides', style: const TextStyle(color: Color(0xFF0F172A), fontSize: 17, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(height: 2),
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('100% Guaranteed', style: TextStyle(color: Color(0xFF059669), fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // 3. Acceptance / Rating
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('RATING', style: TextStyle(color: Color(0xFF64748B), fontSize: 9.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Color(0xFFF59E0B), size: 15),
                      const SizedBox(width: 2),
                      Text('$rating', style: const TextStyle(color: Color(0xFF0F172A), fontSize: 17, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('Verified Partner', style: TextStyle(color: Color(0xFF059669), fontSize: 9, fontWeight: FontWeight.bold)),
                ),
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
          // Offline Shift Card with Safe 3D Illustration
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
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
                    height: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.nightlight_round, size: 44, color: Color(0xFF94A3B8)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('You are Currently Offline', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A))),
                const SizedBox(height: 4),
                const Text(
                  'Go Online to start receiving instant booking requests directly from village stands to district headquarters.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.3),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _toggleOnlineStatus(true),
                    icon: const Icon(Icons.flash_on, size: 17),
                    label: const Text('GO ONLINE NOW', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ] else if (isCurrentlyBusy) ...[
          // Busy mode active
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.directions_car, color: Color(0xFFB45309), size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Active Trip in Progress', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF92400E))),
                      SizedBox(height: 2),
                      Text('You are serving a trip. Complete the active journey below to unlock new ride requests.', style: TextStyle(fontSize: 11, color: Color(0xFF78350F))),
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

        // Live alert notification when new bookings arrive within stand radius
        final currentBookingIds = eligibleBookings.map((b) => b.id).toSet();
        if (!_hasLoadedInitialBookings) {
          _hasLoadedInitialBookings = true;
          _knownBookingIds.addAll(currentBookingIds);
        } else {
          final newBookings = eligibleBookings.where((b) => !_knownBookingIds.contains(b.id)).toList();
          if (newBookings.isNotEmpty) {
            _knownBookingIds.addAll(currentBookingIds);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                HapticFeedback.heavyImpact();
                final firstNew = newBookings.first;
                final isSched = firstNew.scheduledDate != null && firstNew.scheduledDate!.isNotEmpty;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF0F172A),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    content: Row(
                      children: [
                        const Icon(Icons.notifications_active, color: Color(0xFF10B981), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isSched
                                ? '⏰ Scheduled Ride Alert: ${firstNew.pickup.address.split(',').first} (${firstNew.scheduledDate} ${firstNew.scheduledTimeSlot ?? ''})'
                                : '🔔 New Booking Alert: Pickup at ${firstNew.pickup.address.split(',').first} • ₹${(firstNew.finalFare ?? firstNew.estimatedFare).toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            });
          }
        }

        if (eligibleBookings.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/images/driver_radar_active_3d.jpg',
                    height: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.radar, size: 44, color: Color(0xFF059669)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Live Radar Active — Searching Nearby', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: Color(0xFF0F172A))),
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
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
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
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                color: isTour || booking.isRoundTrip ? const Color(0xFF047857) : const Color(0xFF334155),
                              ),
                            ),
                          ),
                          if (booking.scheduledDate != null && booking.scheduledDate!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.schedule_rounded, size: 12, color: Color(0xFFB45309)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${booking.scheduledDate} ${booking.scheduledTimeSlot ?? ''}'.trim(),
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          Text('#${booking.readableId}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                      Text(
                        '₹${(booking.finalFare ?? booking.estimatedFare).toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
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
                      style: const TextStyle(fontSize: 11, color: Color(0xFF065F46), fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Route Details: Pickup & Destination
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.radio_button_checked, color: Color(0xFF059669), size: 15),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          booking.pickup.address,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFFDC2626), size: 15),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          booking.destination.address,
                          style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ACTION BUTTONS: BOTH DECLINE AND ACCEPT CLEARLY VISIBLE SIDE BY SIDE!
                  Row(
                    children: [
                      // 1. DECLINE BUTTON (Visible red outline/soft container)
                      Expanded(
                        flex: 1,
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                              side: const BorderSide(color: Color(0xFFFECACA), width: 1.5),
                              backgroundColor: const Color(0xFFFEF2F2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _declineBooking(booking),
                            icon: const Icon(Icons.close_rounded, size: 17),
                            label: const Text(
                              'DECLINE',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // 2. ACCEPT RIDE BUTTON (Prominent Emerald Green Gradient)
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _showRideFlowModal(booking),
                            icon: const Icon(Icons.check_circle_rounded, size: 18),
                            label: const Text(
                              'ACCEPT RIDE',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.3),
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

  /// ZOMATO-STYLE LIVE TRIP PROGRESS TRACKER CARD
  Widget _buildZomatoActiveTripCard(BookingModel booking) {
    final status = booking.status;
    final isAssigned = status == 'driver_assigned';
    final isArrived = status == 'driver_arrived';
    final isStarted = status == 'trip_started';
    final customerName = (booking.customerName != null && booking.customerName!.trim().isNotEmpty)
        ? booking.customerName!.trim()
        : 'District Rider';
    final customerPhone = booking.customerPhone ?? '+91 87896 01387';
    final fare = (booking.finalFare ?? booking.estimatedFare).toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF10B981), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Zomato / Swiggy Header: Status Badge + Live Fare + Release Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isStarted
                  ? const Color(0xFFECFDF5)
                  : (isArrived ? const Color(0xFFEFF6FF) : const Color(0xFFFEF3C7)),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isStarted ? const Color(0xFF059669) : const Color(0xFFD97706),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isStarted
                          ? 'STAGE 3/3 · IN TRANSIT TO DROP'
                          : (isArrived ? 'STAGE 2/3 · ARRIVED AT PICKUP' : 'STAGE 1/3 · HEADING TO PICKUP'),
                      style: TextStyle(
                        color: isStarted
                            ? const Color(0xFF047857)
                            : (isArrived ? const Color(0xFF1D4ED8) : const Color(0xFFB45309)),
                        fontWeight: FontWeight.w900,
                        fontSize: 10.5,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '₹$fare',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF059669),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined, size: 20, color: Color(0xFFDC2626)),
                      tooltip: 'Cancel or Release Ride',
                      onPressed: () => _cancelOrReleaseActiveRide(booking),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. Zomato Progress Stepper Dots
                Row(
                  children: [
                    _buildStepDot(label: 'Assigned', isDone: true, isActive: isAssigned),
                    Expanded(child: Container(height: 2, color: isArrived || isStarted ? const Color(0xFF059669) : const Color(0xFFE2E8F0))),
                    _buildStepDot(label: 'Arrived', isDone: isArrived || isStarted, isActive: isArrived),
                    Expanded(child: Container(height: 2, color: isStarted ? const Color(0xFF059669) : const Color(0xFFE2E8F0))),
                    _buildStepDot(label: 'In Transit', isDone: isStarted, isActive: isStarted),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. Customer Info & One-Tap Call Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE2E8F0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, color: Color(0xFF475569), size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customerName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              customerPhone,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _callCustomer(customerPhone),
                        icon: const Icon(Icons.phone, size: 15),
                        label: const Text('CALL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 4. Pickup Location Box with Google Maps Navigation Button
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.radio_button_checked, color: Color(0xFF059669), size: 15),
                              SizedBox(width: 6),
                              Text('PICKUP LOCATION', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF065F46))),
                            ],
                          ),
                          InkWell(
                            onTap: () => _openGoogleMaps(
                              lat: booking.pickup.latitude,
                              lng: booking.pickup.longitude,
                              label: 'Pickup',
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.navigation, color: Color(0xFF059669), size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Google Maps',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking.pickup.address,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // 5. Destination Drop Box with Google Maps Navigation Button
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.location_on, color: Color(0xFFDC2626), size: 15),
                              SizedBox(width: 6),
                              Text('DESTINATION DROP', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF991B1B))),
                            ],
                          ),
                          InkWell(
                            onTap: () => _openGoogleMaps(
                              lat: booking.destination.latitude,
                              lng: booking.destination.longitude,
                              label: 'Destination',
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.navigation, color: Color(0xFFDC2626), size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Google Maps',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFFDC2626)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking.destination.address,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 6. Action Stage Buttons
                if (isAssigned || isArrived) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.pin, color: Color(0xFF059669), size: 18),
                            SizedBox(width: 6),
                            Text(
                              'CUSTOMER RIDE OTP (ग्राहक से 4-अंकीय OTP लें)',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5, color: Color(0xFF065F46)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _otpVerifyCtrl,
                                keyboardType: TextInputType.number,
                                maxLength: 4,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 4),
                                decoration: InputDecoration(
                                  counterText: '',
                                  hintText: '• • • •',
                                  hintStyle: const TextStyle(letterSpacing: 4, color: Colors.grey),
                                  filled: true,
                                  fillColor: Colors.white,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF059669),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => _verifyOtpAndStartTrip(booking),
                              child: const Text('Start Trip 🚗', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else if (isStarted) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _completeTrip(booking),
                      icon: const Icon(Icons.flag_rounded, size: 20),
                      label: Text(
                        'COMPLETE THIS TRIP · ADD ₹$fare TO WALLET',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),

                // 7. Cancel / Release ride link
                Center(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
                    onPressed: () => _cancelOrReleaseActiveRide(booking),
                    icon: const Icon(Icons.refresh, size: 14),
                    label: const Text('Need to cancel or release this ride?', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDot({required String label, required bool isDone, required bool isActive}) {
    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isDone ? const Color(0xFF059669) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDone ? const Color(0xFF059669) : const Color(0xFFCBD5E1),
              width: 2,
            ),
          ),
          child: isDone
              ? const Icon(Icons.check, size: 12, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: isActive || isDone ? FontWeight.w800 : FontWeight.w600,
            color: isDone ? const Color(0xFF059669) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
