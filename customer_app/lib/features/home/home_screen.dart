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
  String _selectedCategory = 'car';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RemoteUpdateChecker.checkAndShowUpdateDialog(
        context: context,
        appKey: 'customer_app',
        currentBuildNumber: 4,
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
    }
  }

  void _swapLocations() {
    setState(() {
      final temp = _pickupLocation;
      _pickupLocation = _destinationLocation;
      _destinationLocation = temp;
    });
  }

  double _getCalculatedDistanceKm() {
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

      final bookingResult = await bookingService.createBooking(
        categoryId: _selectedCategory,
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
          // Background soft gradient
          Container(
            height: 280,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE4E7FD), Color(0xFFF7F8FD)],
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
                  _buildPromotionalOffersCarousel(),
                  const SizedBox(height: 16),
                  _buildVehicleCategorySelector(categoriesAsync, distanceKm),
                  const SizedBox(height: 16),
                  _buildJourneyDetailsCard(distanceKm, durationMinutes, categoriesAsync),
                  const SizedBox(height: 16),
                  _buildTimeSlotAndScheduleCard(),
                  const SizedBox(height: 16),
                  _buildRoundTripOptionCard(categoriesAsync, distanceKm),
                  const SizedBox(height: 16),
                  _buildWhatsAppHelplineCard(),
                  const SizedBox(height: 16),
                  _buildJharkhandVillagePricingBanner(),
                ],
              ),
            ),
          ),
          // Floating WhatsApp Quick Action Button above dock
          Positioned(
            right: 20,
            bottom: 84,
            child: _buildWhatsAppFloatingButton(),
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
        final isSearching = status == 'searching_driver';

        if (!isAccepted && !isSearching) return const SizedBox.shrink();

        String statusLabel = '🔔 DRIVER ACCEPTED (ड्राइवर मिल गया)';
        Color statusBg = const Color(0xFF15803D);
        if (status == 'driver_arrived') {
          statusLabel = '📍 DRIVER ARRIVED AT PICKUP (ड्राइवर पहुँच गया)';
          statusBg = const Color(0xFF0284C7);
        } else if (status == 'trip_started') {
          statusLabel = '🚗 TRIP IN PROGRESS (सफ़र जारी है)';
          statusBg = const Color(0xFF7C3AED);
        } else if (isSearching) {
          statusLabel = '🔍 CONNECTING NEARBY DRIVER (ड्राइवर खोज रहे हैं)';
          statusBg = const Color(0xFFD97706);
        }

        return Positioned(
          left: 16,
          right: 16,
          bottom: 84, // Directly above floating bottom dock
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(20),
            shadowColor: Colors.black.withOpacity(0.35),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => context.push('/active-trip/${booking.id}'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isAccepted ? const Color(0xFF22C55E) : const Color(0xFFFBBF24),
                    width: 2,
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
                          child: Text(
                            statusLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
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
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: categories.map((cat) {
              final isSelected = cat.id == _selectedCategory;
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withOpacity(0.2) : AppColors.surfaceSecondary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIconForCategory(cat.name),
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          size: 20,
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

  IconData _getIconForCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('bike')) return Icons.two_wheeler_rounded;
    if (lower.contains('bus')) return Icons.directions_bus_rounded;
    if (lower.contains('taxi')) return Icons.local_taxi_rounded;
    return Icons.directions_car_rounded;
  }

  /// 100% Dynamic & Editable Journey Details Card (From and To)
  Widget _buildJourneyDetailsCard(
    double distanceKm,
    int durationMinutes,
    AsyncValue<List<VehicleCategoryModel>> categoriesAsync,
  ) {
    VehicleCategoryModel? currentCat;
    categoriesAsync.whenData((list) {
      currentCat = list.firstWhere(
        (c) => c.id == _selectedCategory,
        orElse: () => list.first,
      );
    });

    final totalFare = _calculateFare(currentCat, distanceKm);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // From & To Dual Editable Sections with Swap Button
          Row(
            children: [
              // FROM (PICKUP) - Fully Interactive & Typeable
              Expanded(
                child: InkWell(
                  onTap: _openPickupLocationPicker,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.trip_origin, size: 14, color: Color(0xFF10B981)),
                            const SizedBox(width: 4),
                            const Text('Pickup (From)', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Tooltip(
                              message: 'Use current GPS location',
                              child: InkWell(
                                onTap: _setCurrentGpsForPickup,
                                child: const Padding(
                                  padding: EdgeInsets.all(2.0),
                                  child: Icon(Icons.my_location, size: 14, color: Color(0xFF10B981)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.edit, size: 13, color: AppColors.primary),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _pickupLocation.address.split(',').first,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _pickupLocation.address.split(',').length > 1
                              ? _pickupLocation.address.split(',')[1].trim()
                              : 'Tap to type address',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Swap Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: InkWell(
                  onTap: _swapLocations,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.swap_horiz, color: AppColors.primary, size: 18),
                  ),
                ),
              ),

              // TO (DESTINATION) - Fully Interactive & Typeable
              Expanded(
                child: InkWell(
                  onTap: _openDestinationLocationPicker,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: AppColors.error),
                            const SizedBox(width: 4),
                            const Text('Drop (To)', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Tooltip(
                              message: 'Use current GPS location',
                              child: InkWell(
                                onTap: _setCurrentGpsForDestination,
                                child: const Padding(
                                  padding: EdgeInsets.all(2.0),
                                  child: Icon(Icons.my_location, size: 14, color: AppColors.error),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.edit, size: 13, color: AppColors.primary),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _destinationLocation.address.split(',').first,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _destinationLocation.address.split(',').length > 1
                              ? _destinationLocation.address.split(',')[1].trim()
                              : 'Tap to type address',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          // Dynamic Metrics Strip: Distance, Duration, Price in INR ₹
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('Distance', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('$distanceKm km', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary)),
                  ],
                ),
                Container(height: 20, width: 1, color: AppColors.borderLight),
                Column(
                  children: [
                    const Text('Duration', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('$durationMinutes mins', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary)),
                  ],
                ),
                Container(height: 20, width: 1, color: AppColors.borderLight),
                Column(
                  children: [
                    Text(_isRoundTrip ? 'Round Trip' : 'One-Way', style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('₹${totalFare.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.primary)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          // Book Ride Action Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isBookingLoading ? null : () => _handleBookingSearch(totalFare),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isBookingLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Book Ride • ₹${totalFare.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Time Slot, Day, Date & Month Selector Card
  Widget _buildTimeSlotAndScheduleCard() {
    final dayDateMonth = DateFormat('EEEE, d MMMM yyyy').format(_selectedDate);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'Schedule Date & Departure Time Slot',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Day, Date, Month Picker
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DAY & DATE',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          dayDateMonth,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TIME SLOT',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _selectedTimeSlot,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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

  /// Round Trip with Discount & Free Stopping Time
  Widget _buildRoundTripOptionCard(
    AsyncValue<List<VehicleCategoryModel>> categoriesAsync,
    double distanceKm,
  ) {
    VehicleCategoryModel? currentCat;
    categoriesAsync.whenData((list) {
      currentCat = list.firstWhere(
        (c) => c.id == _selectedCategory,
        orElse: () => list.first,
      );
    });

    final savings = currentCat != null
        ? RuralFareCalculator.calculateSavings(category: currentCat!, oneWayDistanceKm: distanceKm)
        : 80.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _isRoundTrip ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _isRoundTrip ? const Color(0xFF86EFAC) : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _isRoundTrip ? const Color(0xFF22C55E) : AppColors.surfaceSecondary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.sync_alt_rounded,
                      color: _isRoundTrip ? Colors.white : AppColors.textSecondary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Book as Round Trip (दो तरफा)',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary),
                      ),
                      Text(
                        'Save ₹${savings.toStringAsFixed(0)} • Return with same driver',
                        style: TextStyle(
                          fontSize: 11,
                          color: _isRoundTrip ? const Color(0xFF15803D) : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Switch(
                value: _isRoundTrip,
                activeColor: const Color(0xFF22C55E),
                onChanged: (val) {
                  setState(() => _isRoundTrip = val);
                },
              ),
            ],
          ),
          if (_isRoundTrip) ...[
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Included Stop Time:',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_roundTripStoppingHours.toStringAsFixed(0)} Hr Free Waiting',
                    style: const TextStyle(color: Color(0xFF166534), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Driver stays at your village destination during hospital, market, or family visit.',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
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

  /// Interactive WhatsApp Support & Booking Modal Sheet
  void _showWhatsAppHelpModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF16A34A), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'District Car WhatsApp 24x7',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        'Official Helpline: +91 87896 01387',
                        style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Select an option for instant one-tap WhatsApp assistance:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),

            _buildWhatsAppOptionTile(
              icon: Icons.local_taxi,
              title: '🚕 Quick Instant Ride (तुरंत बुकिंग)',
              subtitle: 'From: ${_pickupLocation.address.split(',').first} → ${_destinationLocation.address.split(',').first}',
              onTap: () {
                Navigator.pop(ctx);
                _openWhatsApp(
                  message:
                      'Hello District Car Control Room,\nI want to book an instant cab ride.\n📍 Pickup: ${_pickupLocation.address}\n🏁 Drop: ${_destinationLocation.address}\n🚗 Category: ${_selectedCategory.toUpperCase()}\nPlease send an available driver right now.',
                );
              },
            ),
            const SizedBox(height: 10),

            _buildWhatsAppOptionTile(
              icon: Icons.map_outlined,
              title: '🗺️ Long Tour / Outstation (लंबी यात्रा & टूर पैकेज)',
              subtitle: 'Inter-district & rural multi-day tour cabs across Jharkhand',
              color: const Color(0xFF2563EB),
              onTap: () {
                Navigator.pop(ctx);
                _openWhatsApp(
                  message:
                      'Hello District Car Support,\nI need a car for a Long Tour / Outstation journey in Jharkhand.\n📍 From: ${_pickupLocation.address}\n🏁 Destination: ${_destinationLocation.address}\nPlease share vehicle choices (Bolero/Scorpio/Sedan) and tour package rates.',
                );
              },
            ),
            const SizedBox(height: 10),

            _buildWhatsAppOptionTile(
              icon: Icons.report_problem_outlined,
              title: '⚠️ Report Live Ride Issue (सवारी में समस्या)',
              subtitle: 'Driver delay, route concern, or urgent SOS assistance',
              color: const Color(0xFFEA580C),
              onTap: () {
                Navigator.pop(ctx);
                _openWhatsApp(
                  message:
                      'Hello District Car Emergency Helpdesk,\nI want to report an issue with my ride.\n📍 Current Location: ${_pickupLocation.address}\nPlease assist me immediately.',
                );
              },
            ),
            const SizedBox(height: 10),

            _buildWhatsAppOptionTile(
              icon: Icons.feedback_outlined,
              title: '📝 Complain / Grievance (शिकायत व सुझाव)',
              subtitle: 'Fare dispute, lost item, or driver feedback',
              color: const Color(0xFF6366F1),
              onTap: () {
                Navigator.pop(ctx);
                _openWhatsApp(
                  message:
                      'Hello District Car Grievance Team,\nI would like to file a complaint/feedback regarding my recent trip experience with District Car.',
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsAppOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color color = const Color(0xFF16A34A),
  }) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }

  /// Floating WhatsApp Helpline FAB button
  Widget _buildWhatsAppFloatingButton() {
    return FloatingActionButton.extended(
      heroTag: 'fab_whatsapp_btn',
      onPressed: _showWhatsAppHelpModal,
      backgroundColor: const Color(0xFF16A34A),
      elevation: 6,
      icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18),
      label: const Text(
        'WhatsApp Help',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
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
            onPressed: _showWhatsAppHelpModal,
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

  /// Tour & Travels Dedicated Popular Places Home Banner
  Widget _buildTourAndTravelsShortcutBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => context.push('/tours'),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('🌊', style: TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                              'TOUR & TRAVELS 🚖',
                              style: TextStyle(
                                color: Color(0xFF854D0E),
                                fontWeight: FontWeight.w900,
                                fontSize: 9.5,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'NEW',
                            style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Popular Waterfalls, Temples & Hills',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
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
    );
  }

  /// Live Promotional Offers & Seasonal Discount Banner Carousel
  Widget _buildPromotionalOffersCarousel() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('banner_offers')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final List<Map<String, String>> banners = [];

        if (docs.isNotEmpty) {
          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            banners.add({
              'tag': 'SPECIAL OFFER',
              'title': data['title'] ?? 'District Car Offer',
              'subtitle': data['description'] ?? '',
              'badgeColor': '0xFF2563EB',
            });
          }
        }

        // Fallback default rich promotional banners if Firestore is empty
        if (banners.isEmpty) {
          banners.addAll([
            {
              'tag': 'ROUND TRIP SAVER',
              'title': '🎉 35% Off Return Journey!',
              'subtitle': 'Save ₹200 to ₹800 on all return rides across Jharkhand 24 districts.',
              'badgeColor': '0xFF059669',
            },
            {
              'tag': 'RURAL SPECIAL',
              'title': '🚗 Rural Bolero & SUV Fleet',
              'subtitle': 'Rugged 4x4 Bolero & Scorpio for village hatia, hospital & court visits.',
              'badgeColor': '0xFFD97706',
            },
            {
              'tag': 'OUTSTATION',
              'title': '🌾 Gramin Darshan & Pilgrimage',
              'subtitle': 'Full-day tours to Parasnath, Deoghar, Rajrappa & Netarhat with top drivers.',
              'badgeColor': '0xFF7C3AED',
            },
          ]);
        }

        return Container(
          height: 98,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: PageView.builder(
            itemCount: banners.length,
            controller: PageController(viewportFraction: 0.96),
            itemBuilder: (context, index) {
              final banner = banners[index];
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Color(int.parse(banner['badgeColor'] ?? '0xFF2563EB')),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              banner['tag']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 9.5,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            banner['title']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            banner['subtitle']!,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                            ),
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
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

