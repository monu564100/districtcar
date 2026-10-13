import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import 'package:district_car_shared/models/models.dart';
import 'package:district_car_shared/widgets/location_picker_sheet.dart';
import 'package:district_car_shared/services/rural_fare_calculator.dart';
import 'package:district_car_shared/services/location_search_service.dart';
import 'package:district_car_shared/services/remote_update_checker.dart';
import 'package:district_car_shared/services/fcm_notification_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/floating_bottom_dock.dart';
import 'categories_provider.dart';
import '../booking/booking_service.dart';
import '../auth/auth_service.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  int _currentDockIndex = 0;
  String? _selectedCategory;

  String _getActiveCategoryId(List<VehicleCategoryModel> categories) {
    if (_selectedCategory != null && categories.any((c) => c.id == _selectedCategory)) {
      return _selectedCategory!;
    }
    return categories.isNotEmpty ? categories.first.id : 'car';
  }

  // Dynamic Editable Locations with sensible Jharkhand district hubs
  LocationModel _pickupLocation = LocationModel(
    latitude: 23.3700,
    longitude: 85.3250,
    address: 'Albert Ekka Chowk, Main Road, Ranchi, Jharkhand',
  );

  LocationModel _destinationLocation = LocationModel(
    latitude: 23.0740,
    longitude: 85.2780,
    address: 'Khunti District Bus Stand & Village, Jharkhand',
  );

  // Time Slot & Date Schedule State
  DateTime _selectedDate = DateTime.now();
  String _selectedTimeSlot = 'Now (Within 10 mins)';

  // Round Trip & Stopping Duration State
  bool _isRoundTrip = false;
  double _roundTripStoppingHours = 1.0;

  bool _isBookingLoading = false;

  final List<String> _timeSlots = [
    'Now (Within 10 mins)',
    '06:00 AM - 08:00 AM (Morning)',
    '08:00 AM - 10:00 AM (Office/Mandi)',
    '10:00 AM - 12:00 PM',
    '12:00 PM - 02:00 PM',
    '02:00 PM - 04:00 PM',
    '04:00 PM - 06:00 PM (Evening)',
    '06:00 PM - 08:00 PM',
    '08:00 PM - 10:00 PM (Night)',
  ];

  @override
  void initState() {
    super.initState();
    _detectUserCurrentGpsOnStart();
    _fetchGoogleDistanceAndDuration();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RemoteUpdateChecker.checkAndShowUpdateDialog(
        context: context,
        appKey: 'customer_app',
        currentBuildNumber: 10,
      );
      final user = ref.read(authServiceProvider).currentUser;
      FCMNotificationService.initFCM(
        role: 'customer',
        userId: user?.uid,
      );
      FCMNotificationService.listenToLiveBroadcasts(
        context: context,
        role: 'customer',
      );
    });
  }

  void _detectUserCurrentGpsOnStart() async {
    try {
      final loc = await LocationSearchService().getCurrentDeviceLocation();
      if (loc != null && mounted) {
        setState(() {
          // User exact GPS location in "From" (Pickup)
          _pickupLocation = loc.toLocationModel();
        });
        _fetchGoogleDistanceAndDuration();
      }
    } catch (_) {}
  }

  void _setCurrentGpsForPickup() async {
    try {
      final loc = await LocationSearchService().getCurrentDeviceLocation();
      if (loc != null && mounted) {
        setState(() {
          _pickupLocation = loc.toLocationModel();
        });
        _fetchGoogleDistanceAndDuration();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pickup set to: ${loc.title}'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  void _setCurrentGpsForDestination() async {
    try {
      final loc = await LocationSearchService().getCurrentDeviceLocation();
      if (loc != null && mounted) {
        setState(() {
          _destinationLocation = loc.toLocationModel();
        });
        _fetchGoogleDistanceAndDuration();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Drop set to: ${loc.title}'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  void _onDockTabSelected(int index) {
    setState(() => _currentDockIndex = index);
    if (index == 1) {
      context.push('/tours');
    } else if (index == 2) {
      context.push('/trips');
    } else if (index == 3) {
      context.push('/profile');
    }
  }

  void _openPickupLocationPicker() async {
    final picked = await LocationPickerSheet.show(
      context,
      title: 'Enter Pickup (From) Address',
      initialValue: _pickupLocation.address,
      isPickup: true,
    );
    if (picked != null) {
      setState(() {
        _pickupLocation = picked;
      });
      _fetchGoogleDistanceAndDuration();
    }
  }

  void _openDestinationLocationPicker() async {
    final picked = await LocationPickerSheet.show(
      context,
      title: 'Enter Destination (To) Village/Hub',
      initialValue: _destinationLocation.address,
      isPickup: false,
    );
    if (picked != null) {
      setState(() {
        _destinationLocation = picked;
      });
      _fetchGoogleDistanceAndDuration();
    }
  }

  // Real-time Google Maps Distance & Duration State
  double _googleDistanceKm = 0.0;
  int _googleDurationMinutes = 0;
  String _googleDurationText = '';
  bool _isGoogleRoutesLoading = false;

  void _fetchGoogleDistanceAndDuration() async {
    setState(() => _isGoogleRoutesLoading = true);
    try {
      final res = await LocationSearchService().getDirectionsDistanceAndDuration(
        originLat: _pickupLocation.latitude,
        originLng: _pickupLocation.longitude,
        destLat: _destinationLocation.latitude,
        destLng: _destinationLocation.longitude,
      );
      if (mounted) {
        setState(() {
          _googleDistanceKm = (res['distanceKm'] as num).toDouble();
          _googleDurationMinutes = (res['durationMinutes'] as num).toInt();
          _googleDurationText = (res['durationText'] as String?) ?? '${_googleDurationMinutes} mins';
          _isGoogleRoutesLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isGoogleRoutesLoading = false);
    }
  }

  void _swapLocations() {
    setState(() {
      final temp = _pickupLocation;
      _pickupLocation = _destinationLocation;
      _destinationLocation = temp;
    });
    _fetchGoogleDistanceAndDuration();
  }

  double _getCalculatedDistanceKm() {
    if (_googleDistanceKm > 0.0) return _googleDistanceKm;
    final distMeters = Geolocator.distanceBetween(
      _pickupLocation.latitude,
      _pickupLocation.longitude,
      _destinationLocation.latitude,
      _destinationLocation.longitude,
    );
    final km = distMeters / 1000.0;
    return km < 0.5 ? 1.0 : double.parse(km.toStringAsFixed(1));
  }

  int _getCalculatedDurationMinutes(double distanceKm) {
    if (_googleDurationMinutes > 0) return _googleDurationMinutes;
    return (distanceKm / 25.0 * 60.0).round().clamp(5, 240);
  }

  double _calculateFare(VehicleCategoryModel? category, double distanceKm) {
    if (category == null) {
      return (60.0 + (distanceKm * 18.0)).roundToDouble();
    }
    return RuralFareCalculator.calculateFare(
      category: category,
      oneWayDistanceKm: distanceKm,
      isRoundTrip: _isRoundTrip,
      stoppingHours: _roundTripStoppingHours,
    );
  }

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _selectTimeSlotModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Select Departure Time Slot',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                ),
                const Divider(),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _timeSlots.length,
                    itemBuilder: (context, index) {
                      final slot = _timeSlots[index];
                      final isSelected = slot == _selectedTimeSlot;
                      return ListTile(
                        leading: Icon(
                          index == 0 ? Icons.flash_on : Icons.access_time_rounded,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        ),
                        title: Text(
                          slot,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                        trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                        onTap: () {
                          setState(() => _selectedTimeSlot = slot);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleBookingSearch(double estimatedFare) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) {
      context.push('/login');
      return;
    }

    setState(() => _isBookingLoading = true);

    try {
      final bookingService = ref.read(bookingServiceProvider);
      final formattedDate = DateFormat('EEE, d MMM yyyy').format(_selectedDate);

      final categories = ref.read(vehicleCategoriesProvider).valueOrNull ?? defaultVehicleCategories;
      final activeCategoryId = _getActiveCategoryId(categories);

      final bookingResult = await bookingService.createBooking(
        categoryId: activeCategoryId,
        pickup: _pickupLocation,
        destination: _destinationLocation,
        customFare: estimatedFare,
        isRoundTrip: _isRoundTrip,
        roundTripStoppingHours: _roundTripStoppingHours,
        scheduledDate: formattedDate,
        scheduledTimeSlot: _selectedTimeSlot,
      );

      setState(() => _isBookingLoading = false);

      if (mounted) {
        final bookingId = bookingResult['bookingId'];
        context.push('/active-trip/$bookingId');
      }
    } catch (e) {
      setState(() => _isBookingLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(vehicleCategoriesProvider);
    final distanceKm = _getCalculatedDistanceKm();
    final durationMinutes = _getCalculatedDurationMinutes(distanceKm);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background soft atmospheric gradient
          Container(
            height: 320,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE6F4EA), Color(0xFFF0FDF4), Color(0xFFF8FAFC)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  _buildDestinationSearchInput(),
                  const SizedBox(height: 16),
                  _buildTourAndTravelsShortcutBanner(),
                  const SizedBox(height: 16),
                  _buildVehicleCategorySelector(categoriesAsync, distanceKm),
                  const SizedBox(height: 16),
                  _buildJourneyDetailsCard(distanceKm, durationMinutes, categoriesAsync),
                  const SizedBox(height: 16),
                  _buildWhatsAppHelplineCard(),
                  const SizedBox(height: 16),
                  _buildJharkhandVillagePricingBanner(),
                ],
              ),
            ),
          ),

          // Floating Bottom Navigation Dock (Home, Trips, Profile)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingBottomDock(
              currentIndex: _currentDockIndex,
              onTabSelected: _onDockTabSelected,
            ),
          ),

          // Persistent Active Booking Rectangle Popup Banner until complete trip is over
          _buildActiveTripPersistentPopup(),
        ],
      ),
    );
  }

  /// Persistent Rectangle Popup showing accepted booking status until trip completed
  Widget _buildActiveTripPersistentPopup() {
    final user = ref.watch(authServiceProvider).currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<BookingModel?>(
      stream: ref.watch(bookingServiceProvider).streamUserActiveBooking(user.uid),
      builder: (context, snapshot) {
        final booking = snapshot.data;
        if (booking == null) return const SizedBox.shrink();

        final status = booking.status;
        final isAccepted = status == 'driver_assigned' || status == 'driver_arrived' || status == 'trip_started';

        // Strictly do not show pending/searching bookings on home screen
        if (!isAccepted) return const SizedBox.shrink();

        String statusLabel = 'DRIVER ACCEPTED';
        IconData statusIcon = Icons.check_circle_rounded;
        Color statusBg = const Color(0xFF15803D);
        if (status == 'driver_arrived') {
          statusLabel = 'DRIVER AT PICKUP';
          statusIcon = Icons.near_me_rounded;
          statusBg = const Color(0xFF0284C7);
        } else if (status == 'trip_started') {
          statusLabel = 'TRIP IN PROGRESS';
          statusIcon = Icons.directions_car_rounded;
          statusBg = const Color(0xFF7C3AED);
        }

        return Positioned(
          left: 16,
          right: 16,
          bottom: 84, // Directly above floating bottom dock
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(22),
            shadowColor: Colors.black.withOpacity(0.25),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => context.push('/active-trip/${booking.id}'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isAccepted ? const Color(0xFF22C55E) : const Color(0xFFFBBF24),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Status Strip
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, color: Colors.white, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                statusLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (booking.rideOtp != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Text(
                              'OTP: ${booking.rideOtp}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primary),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Driver info / Route info row
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryLight,
                            image: const DecorationImage(
                              image: AssetImage('assets/images/app_logo.jpg'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.driverName ?? 'Nearby Partner Driver',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${booking.vehicleModel ?? "District Car"} · ${booking.vehiclePlate ?? "JH Reg"}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${(booking.finalFare ?? booking.estimatedFare).toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF059669),
                              ),
                            ),
                            const Text(
                              'Tap to View >',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Clean Top Header - No customer name shown
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // District Car Logo and Branding
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/app_logo.jpg'),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'District Car',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Row(
                    children: const [
                      Icon(Icons.location_on, size: 13, color: AppColors.primary),
                      SizedBox(width: 3),
                      Text(
                        'Jharkhand Rural & District Mobility',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Live trip shortcut & notification
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
                ],
              ),
              child: const Icon(Icons.receipt_long, color: AppColors.primary, size: 20),
            ),
            tooltip: 'My Trips',
            onPressed: () => context.push('/trips'),
          ),
        ],
      ),
    );
  }

  /// Destination prompt without customer name
  Widget _buildDestinationSearchInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Where would you like to travel?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: _openDestinationLocationPicker,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppColors.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _destinationLocation.address,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6F5EC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.location_on, color: Color(0xFF10B981), size: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCategorySelector(
    AsyncValue<List<VehicleCategoryModel>> categoriesAsync,
    double distanceKm,
  ) {
    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) return const SizedBox.shrink();
        final activeSelectedId = _getActiveCategoryId(categories);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: categories.map((cat) {
              final isSelected = cat.id == activeSelectedId;
              final estCategoryFare = _calculateFare(cat, distanceKm);
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat.id),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.25)
                            : Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? Colors.white.withOpacity(0.6) : const Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            _getVehicleIconAsset('${cat.id} ${cat.name} ${cat.displayName}'),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: isSelected ? Colors.white.withOpacity(0.2) : AppColors.surfaceSecondary,
                              child: Icon(
                                _getIconForCategory(cat.name),
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat.displayName,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '₹${estCategoryFare.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: isSelected ? Colors.white.withOpacity(0.9) : AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String _getVehicleIconAsset(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('auto') || lower.contains('rick')) {
      return 'assets/images/icon_vehicle_auto.jpg';
    } else if (lower.contains('sedan')) {
      return 'assets/images/icon_vehicle_sedan.jpg';
    } else if (lower.contains('suv') || lower.contains('bolero') || lower.contains('scorpio')) {
      return 'assets/images/icon_vehicle_suv.jpg';
    } else if (lower.contains('bike') || lower.contains('moto') || lower.contains('two')) {
      return 'assets/images/icon_vehicle_bike.jpg';
    }
    return 'assets/images/icon_vehicle_mini.jpg';
  }

  IconData _getIconForCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('bike')) return Icons.two_wheeler_rounded;
    if (lower.contains('bus')) return Icons.directions_bus_rounded;
    if (lower.contains('taxi')) return Icons.local_taxi_rounded;
    return Icons.directions_car_rounded;
  }

  /// 100% Dynamic & Editable Journey Details Card (From and To)
  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min${minutes > 1 ? "s" : ""}';
    }
    final int hours = minutes ~/ 60;
    final int remainingMins = minutes % 60;
    if (remainingMins == 0) {
      return '$hours hr${hours > 1 ? "s" : ""}';
    }
    return '$hours hr $remainingMins min';
  }

  Widget _buildJourneyDetailsCard(
    double distanceKm,
    int durationMinutes,
    AsyncValue<List<VehicleCategoryModel>> categoriesAsync,
  ) {
    VehicleCategoryModel? currentCat;
    categoriesAsync.whenData((list) {
      if (list.isNotEmpty) {
        final activeId = _getActiveCategoryId(list);
        currentCat = list.firstWhere(
          (c) => c.id == activeId,
          orElse: () => list.first,
        );
      }
    });

    // Dynamic calculation: on Round Trip, distance and travel time double + waiting hours are included
    final effectiveDistanceKm = _isRoundTrip ? (distanceKm * 2.0) : distanceKm;
    final baseDuration = _isRoundTrip ? (durationMinutes * 2) : durationMinutes;
    final waitingMins = _isRoundTrip ? (_roundTripStoppingHours * 60).round() : 0;
    final totalDurationMinutes = baseDuration + waitingMins;

    final totalFare = _calculateFare(currentCat, distanceKm);
    final formattedDuration = _formatDuration(totalDurationMinutes);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Sleek Route Pickup & Destination Section (Uber / Grab style timeline)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Visual Timeline Indicators (Green dot -> dashed line -> Red pin)
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF059669).withOpacity(0.35),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 38,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: const Color(0xFFCBD5E1),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFDC2626).withOpacity(0.35),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // From & To Address Fields
                Expanded(
                  child: Column(
                    children: [
                      // Pickup Location Row
                      InkWell(
                        onTap: _openPickupLocationPicker,
                        borderRadius: BorderRadius.circular(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'PICKUP LOCATION',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _pickupLocation.address.split(',').first,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Tooltip(
                              message: 'Use current GPS location',
                              child: InkWell(
                                onTap: _setCurrentGpsForPickup,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.my_location_rounded,
                                    size: 15,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                      ),

                      // Destination Location Row
                      InkWell(
                        onTap: _openDestinationLocationPicker,
                        borderRadius: BorderRadius.circular(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'DROP DESTINATION',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _destinationLocation.address.split(',').first,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Tooltip(
                              message: 'Use current GPS location',
                              child: InkWell(
                                onTap: _setCurrentGpsForDestination,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.my_location_rounded,
                                    size: 15,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Swap Button
                InkWell(
                  onTap: _swapLocations,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.swap_vert_rounded,
                      color: Color(0xFF059669),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 2. Journey Metrics Banner (Distance, Duration & Est. Fare)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                // Distance Metric
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DISTANCE',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${effectiveDistanceKm.toStringAsFixed(1)} km',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5),
                      ),
                    ],
                  ),
                ),

                Container(
                  height: 24,
                  width: 1,
                  color: Colors.white.withOpacity(0.15),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                ),

                // Duration Metric (Formatted: e.g. 1 hr 15 mins)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DURATION',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedDuration,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                Container(
                  height: 24,
                  width: 1,
                  color: Colors.white.withOpacity(0.15),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                ),

                // Fare Estimate
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _isRoundTrip ? 'ROUND TRIP' : 'EST. FARE',
                      style: const TextStyle(color: Color(0xFF34D399), fontSize: 9.5, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${totalFare.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 3. Departure Schedule Container (Professional, clean without instant tags or Hindi text)
          _buildEmbeddedScheduleContainer(),

          const SizedBox(height: 14),

          // 4. Round Trip Option Container with High Polish
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _isRoundTrip ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _isRoundTrip ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isRoundTrip ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.sync_alt_rounded,
                        color: _isRoundTrip ? Colors.white : const Color(0xFF64748B),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Round Trip Booking',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  '1 Hr Free Waiting',
                                  style: TextStyle(
                                    color: Color(0xFF15803D),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isRoundTrip
                                ? 'Same driver stays with you and returns'
                                : 'Return back with the same cab and driver',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _isRoundTrip,
                      activeColor: const Color(0xFF059669),
                      onChanged: (val) {
                        setState(() => _isRoundTrip = val);
                      },
                    ),
                  ],
                ),

                if (_isRoundTrip) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Driver Waiting Allowance',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            _roundTripStoppingHours <= 1.0
                                ? 'First 60 minutes included free'
                                : '+₹${((_roundTripStoppingHours - 1.0) * 60.0).toStringAsFixed(0)} (at standard ₹60/hr)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _roundTripStoppingHours <= 1.0
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_rounded, size: 16),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              onPressed: _roundTripStoppingHours > 1.0
                                  ? () {
                                      setState(() {
                                        _roundTripStoppingHours = (_roundTripStoppingHours - 1.0).clamp(1.0, 12.0);
                                      });
                                    }
                                  : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '${_roundTripStoppingHours.toInt()} hr${_roundTripStoppingHours > 1 ? "s" : ""}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF059669)),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setState(() {
                                  _roundTripStoppingHours = (_roundTripStoppingHours + 1.0).clamp(1.0, 12.0);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 5. High-Impact Call to Action Book Ride Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isBookingLoading ? null : () => _handleBookingSearch(totalFare),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isBookingLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.directions_car_rounded, size: 20, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Book Ride • ₹${totalFare.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Modern Clean Departure Schedule Container
  Widget _buildEmbeddedScheduleContainer() {
    final dayDateMonth = DateFormat('EEE, d MMM').format(_selectedDate);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFF059669)),
              SizedBox(width: 8),
              Text(
                'Departure Schedule',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Day & Date Picker
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.today_rounded, size: 16, color: Color(0xFF059669)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'DATE',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8)),
                              ),
                              Text(
                                dayDateMonth,
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down_rounded, size: 20, color: Color(0xFF64748B)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Time Slot Picker
              Expanded(
                child: InkWell(
                  onTap: _selectTimeSlotModal,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF059669)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TIME',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8)),
                              ),
                              Text(
                                _selectedTimeSlot.split('(').first.trim(),
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down_rounded, size: 20, color: Color(0xFF64748B)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  /// Jharkhand Village & Rural Mobility Pricing Transparency Banner
  Widget _buildJharkhandVillagePricingBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Village Return Guarantee',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                ),
                SizedBox(height: 2),
                Text(
                  'In rural Jharkhand, return passenger availability is low. Our fair-rate algorithm compensates driver return travel so your ride is 100% accepted without cancellations.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Launch WhatsApp with customized prefilled text
  Future<void> _openWhatsApp({required String message}) async {
    const phone = '918789601387';
    final url = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open WhatsApp: $e')),
        );
      }
    }
  }

  /// Downside WhatsApp Helpline Card Banner
  Widget _buildWhatsAppHelplineCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFF16A34A),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.call, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Quick WhatsApp & Call Booking',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF14532D)),
                ),
                SizedBox(height: 2),
                Text(
                  'Book on WhatsApp or call Ranchi control: +91 87896 01387',
                  style: TextStyle(fontSize: 11, color: Color(0xFF166534)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _openWhatsApp(
              message: 'Hello District Car Helpline, I want to book a ride / need assistance.',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Chat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  /// Tour & Travels Dedicated Popular Places Home Banner with Photography
  Widget _buildTourAndTravelsShortcutBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Realistic Tour Photography Background
            Image.asset(
              'assets/images/tour_banner_jharkhand.jpg',
              height: 124,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 124,
                color: const Color(0xFF0F766E),
              ),
            ),
            // Translucent gradient overlay for readability
            Container(
              height: 124,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.78),
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.2),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => context.push('/tours'),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.4)),
                        ),
                        child: const Icon(Icons.explore_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF08A),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'TOUR & TRAVELS',
                                    style: TextStyle(
                                      color: Color(0xFF854D0E),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 9.5,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'FEATURED',
                                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Waterfalls, Temples & Hills',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Hundru, Dassam, Baidyanath Dham, Netarhat & more',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF0F766E), size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


}


