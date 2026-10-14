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

import '../../theme/theme.dart';
import '../../services/haptic_service.dart';
import '../../widgets/home/booking_card.dart';
import '../../widgets/home/vehicle_card.dart';
import '../../widgets/home/fare_card.dart';
import '../../widgets/home/home_map_header.dart';
import '../../widgets/home/trust_strip.dart';
import '../../widgets/home/sticky_book_bar.dart';
import '../booking/booking_confirm_sheet.dart';
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
  bool _isHindi = false;

  // Passenger & Payment options
  int _passengerCount = 1;
  String _paymentMethod = 'Cash / UPI';

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
          _pickupLocation = loc.toLocationModel();
        });
        _fetchGoogleDistanceAndDuration();
      }
    } catch (_) {}
  }

  void _setCurrentGpsForPickup() async {
    HapticService.selection();
    try {
      final loc = await LocationSearchService().getCurrentDeviceLocation();
      if (loc != null && mounted) {
        setState(() {
          _pickupLocation = loc.toLocationModel();
        });
        _fetchGoogleDistanceAndDuration();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isHindi ? 'पिकअप सेट: ${loc.title}' : 'Pickup set to: ${loc.title}'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  void _onDockTabSelected(int index) async {
    if (index == 0) {
      if (_currentDockIndex != 0) {
        setState(() => _currentDockIndex = 0);
      }
      return;
    }
    setState(() => _currentDockIndex = index);
    if (index == 1) {
      await context.push('/tours');
    } else if (index == 2) {
      await context.push('/trips');
    } else if (index == 3) {
      await context.push('/profile');
    }
    if (mounted) {
      setState(() => _currentDockIndex = 0);
    }
  }

  void _openPickupLocationPicker() async {
    HapticService.selection();
    final picked = await LocationPickerSheet.show(
      context,
      title: _isHindi ? 'पिकअप (From) का पता चुनें' : 'Enter Pickup (From) Address',
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
    HapticService.selection();
    final picked = await LocationPickerSheet.show(
      context,
      title: _isHindi ? 'मंजिल (To) गाँव/कस्बा चुनें' : 'Enter Destination (To) Village/Hub',
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

  void _setQuickDestination(String place) {
    HapticService.selection();
    String address = 'District Main Market, Jharkhand';
    double lat = 23.3600;
    double lng = 85.3200;

    final lower = place.toLowerCase();
    if (lower.contains('ghar') || lower.contains('home')) {
      address = 'Home Village / Mohalla, Jharkhand';
      lat = 23.3500;
      lng = 85.3100;
    } else if (lower.contains('bus') || lower.contains('stand')) {
      address = 'Kanta Toli Inter-District Bus Stand, Ranchi';
      lat = 23.3690;
      lng = 85.3450;
    } else if (lower.contains('hospital') || lower.contains('aspataal')) {
      address = 'RIMS Hospital & Medical Hub, Bariatu, Ranchi';
      lat = 23.3900;
      lng = 85.3580;
    } else if (lower.contains('bazaar') || lower.contains('mandi')) {
      address = 'Daily Vegetable Mandi & Haat Bazaar, Jharkhand';
      lat = 23.3650;
      lng = 85.3240;
    }

    setState(() {
      _destinationLocation = LocationModel(
        latitude: lat,
        longitude: lng,
        address: address,
      );
    });
    _fetchGoogleDistanceAndDuration();
  }

  void _handleVoiceInput() {
    HapticService.selection();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.30),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.mic, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                _isHindi ? 'बोलकर बताएं कहाँ जाना है' : 'Speak Destination in Hindi / English',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTokens.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isHindi
                    ? 'जैसे: "खूंटी बस स्टैंड", "रिम्स अस्पताल", "कांटा टोली"'
                    : 'e.g. "Khunti Bus Stand", "RIMS Hospital", "Kanta Toli"',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppTokens.secondary),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openDestinationLocationPicker();
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(_isHindi ? 'कीबोर्ड से खोजें' : 'Type Instead'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  // Rural average speed validation: 25 to 45 km/h
  int _getCalculatedDurationMinutes(double distanceKm) {
    if (_googleDurationMinutes > 0) {
      // Validate bounds: clamp to realistic rural speed (25–45 km/h)
      final minDuration = (distanceKm / 45.0 * 60.0).round();
      final maxDuration = (distanceKm / 25.0 * 60.0).round();
      return _googleDurationMinutes.clamp(minDuration.clamp(5, 600), maxDuration.clamp(10, 720));
    }
    return (distanceKm / 32.0 * 60.0).round().clamp(5, 360);
  }

  // Geofence & Service limit validator
  bool _isVehicleServiceable(String categoryName, double distanceKm) {
    final lower = categoryName.toLowerCase();
    if (lower.contains('bike') || lower.contains('auto') || lower.contains('rick')) {
      return distanceKm <= 60.0;
    }
    // Cabs/Boleros/SUVs configurable up to 300 km inter-district
    return distanceKm <= 300.0;
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

  void _pickDate() async {
    HapticService.selection();
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
              primary: Color(0xFF0F172A),
              onPrimary: Colors.white,
              onSurface: AppTokens.ink,
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
    HapticService.selection();
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    _isHindi ? 'प्रस्थान का समय चुनें' : 'Select Departure Time Slot',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTokens.ink),
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
                          color: isSelected ? const Color(0xFF0F172A) : AppTokens.secondary,
                        ),
                        title: Text(
                          slot,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? const Color(0xFF0F172A) : AppTokens.ink,
                          ),
                        ),
                        trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF0F172A)) : null,
                        onTap: () {
                          HapticService.selection();
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

  void _showBookingConfirmSheet(double totalFare, VehicleCategoryModel? category) async {
    HapticService.selection();
    final effectiveDist = _isRoundTrip ? (_getCalculatedDistanceKm() * 2) : _getCalculatedDistanceKm();
    final effectiveDur = _isRoundTrip
        ? (_getCalculatedDurationMinutes(_getCalculatedDistanceKm()) * 2 + (_roundTripStoppingHours * 60).round())
        : _getCalculatedDurationMinutes(_getCalculatedDistanceKm());

    final confirmed = await BookingConfirmSheet.show(
      context,
      pickupAddress: _pickupLocation.address,
      destinationAddress: _destinationLocation.address,
      vehicleName: category?.displayName ?? 'District Car',
      vehicleImageAsset: _getVehicleIconAsset(category?.name ?? 'car'),
      fare: totalFare,
      distanceKm: effectiveDist,
      formattedDuration: _formatDuration(effectiveDur),
      isRoundTrip: _isRoundTrip,
      waitingHours: _roundTripStoppingHours,
      selectedDate: DateFormat('EEE, d MMM yyyy').format(_selectedDate),
      selectedTimeSlot: _selectedTimeSlot,
      paymentMethod: _paymentMethod,
      passengerCount: _passengerCount,
      isHindi: _isHindi,
    );

    if (confirmed == true) {
      _handleBookingSearch(totalFare);
    }
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

  String _getVehicleIconAsset(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('auto') || lower.contains('rick')) {
      return 'assets/images/icon_vehicle_auto.png';
    } else if (lower.contains('sedan')) {
      return 'assets/images/icon_vehicle_sedan.png';
    } else if (lower.contains('suv') || lower.contains('bolero') || lower.contains('scorpio')) {
      return 'assets/images/icon_vehicle_suv.png';
    } else if (lower.contains('bike') || lower.contains('moto') || lower.contains('two')) {
      return 'assets/images/icon_vehicle_bike.png';
    }
    return 'assets/images/icon_vehicle_mini.png';
  }

  Future<void> _makePhoneCall(String phone) async {
    final url = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } catch (_) {}
  }

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

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(vehicleCategoriesProvider);
    final distanceKm = _getCalculatedDistanceKm();
    final durationMinutes = _getCalculatedDurationMinutes(distanceKm);

    final categories = categoriesAsync.valueOrNull ?? defaultVehicleCategories;
    final activeSelectedId = _getActiveCategoryId(categories);

    VehicleCategoryModel? currentCat;
    if (categories.isNotEmpty) {
      currentCat = categories.firstWhere(
        (c) => c.id == activeSelectedId,
        orElse: () => categories.first,
      );
    }

    final isServiceable = _isVehicleServiceable(currentCat?.name ?? 'car', distanceKm);

    // Dynamic calculations for round trip
    final effectiveDistanceKm = _isRoundTrip ? (distanceKm * 2.0) : distanceKm;
    final baseDuration = _isRoundTrip ? (durationMinutes * 2) : durationMinutes;
    final waitingMins = _isRoundTrip ? (_roundTripStoppingHours * 60).round() : 0;
    final totalDurationMinutes = baseDuration + waitingMins;

    final totalFare = _calculateFare(currentCat, distanceKm);
    final formattedDuration = _formatDuration(totalDurationMinutes);

    return Scaffold(
      backgroundColor: AppTokens.background,
      body: Stack(
        children: [
          // Subtle radial glow top-right
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF59E0B).withValues(alpha: 0.05),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // A. Header (compact)
                  _buildHeader(),
                  const SizedBox(height: 10),

                  // Live Animated Map View above From and To container (Ola / Uber style)
                  HomeMapHeader(
                    pickupLocation: _pickupLocation,
                    isServiceable: isServiceable,
                    isHindi: _isHindi,
                    onRecenter: _setCurrentGpsForPickup,
                    onSupportTap: () => _makePhoneCall('918789601387'),
                  ),
                  const SizedBox(height: 14),

                  // B. Hero Booking Card (Single destination input, no duplicate search bar)
                  BookingCard(
                    pickupAddress: _pickupLocation.address,
                    destinationAddress: _destinationLocation.address,
                    onPickupTap: _openPickupLocationPicker,
                    onDestinationTap: _openDestinationLocationPicker,
                    onGpsPickupTap: _setCurrentGpsForPickup,
                    onSwap: _swapLocations,
                    onQuickPlaceSelect: _setQuickDestination,
                    onVoiceInput: _handleVoiceInput,
                    isHindi: _isHindi,
                  ),
                  const SizedBox(height: 16),

                  // C. Vehicle Selector (horizontal snap carousel, 2.3 visible)
                  _buildVehicleSelector(categoriesAsync, distanceKm),
                  const SizedBox(height: 16),

                  // Geofence / Service check: Show empty state if outside bounds
                  if (!isServiceable) ...[
                    _buildUnserviceableNotice(currentCat?.displayName ?? 'Vehicle'),
                    const SizedBox(height: 16),
                  ] else ...[
                    // D. Fare Summary (dark gradient card, collapsible)
                    FareCard(
                      totalFare: totalFare,
                      distanceKm: effectiveDistanceKm,
                      formattedDuration: formattedDuration,
                      isRoundTrip: _isRoundTrip,
                      baseFare: currentCat?.baseFare ?? 60.0,
                      distanceFare: totalFare - (currentCat?.baseFare ?? 60.0),
                      returnAllowance: _isRoundTrip ? ((_roundTripStoppingHours - 1.0).clamp(0, 10) * 60.0) : 0.0,
                      isHindi: _isHindi,
                      vehicleName: currentCat?.displayName ?? 'District Ride',
                    ),
                    const SizedBox(height: 14),
                  ],

                  // E. Options Row (compact chips: Date/Time, Passengers, Payment, Round-trip)
                  _buildOptionsRow(),
                  const SizedBox(height: 16),

                  // G. Quick WhatsApp & Call Booking
                  _buildWhatsAppHelplineCard(),
                  const SizedBox(height: 16),

                  // H. Tours & Travels Hero (height 140, below options)
                  _buildTourAndTravelsShortcutBanner(),
                  const SizedBox(height: 16),

                  // Village Return Guarantee Transparency
                  _buildJharkhandVillagePricingBanner(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Persistent Active Booking Rectangle Popup Banner
          _buildActiveTripPersistentPopup(),
        ],
      ),

      // I. Sticky Bottom Bar: Fixed 58h button + labeled bottom nav
      bottomNavigationBar: StickyBookBar(
        vehicleName: currentCat?.displayName ?? 'Auto',
        fare: totalFare,
        isServiceable: isServiceable,
        isDestinationSelected: _destinationLocation.address.isNotEmpty,
        isLoading: _isBookingLoading,
        onBook: () => _showBookingConfirmSheet(totalFare, currentCat),
        currentNavIndex: 0,
        onNavSelected: _onDockTabSelected,
        isHindi: false,
      ),
    );
  }

  /// A. Header (compact): Logo + "District Car", Greeting "Namaste, [Name]", Language toggle, Notification/Avatar
  Widget _buildHeader() {
    final user = ref.watch(authServiceProvider).currentUser;
    final userName = user?.displayName ?? (user?.phoneNumber != null ? 'Citizen' : 'Partner');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Logo & Name
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: const DecorationImage(
                image: AssetImage('assets/images/app_logo.jpg'),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isHindi ? 'नमस्ते, $userName' : 'Namaste, $userName',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTokens.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  'District Car • Jharkhand',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTokens.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Profile / Trips Bell
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF0F172A), size: 18),
            ),
            tooltip: _isHindi ? 'सफर' : 'My Trips',
            onPressed: () {
              HapticService.selection();
              context.push('/trips');
            },
          ),
        ],
      ),
    );
  }

  /// C. Vehicle Selector (horizontal snap carousel, 2.3 visible)
  Widget _buildVehicleSelector(
    AsyncValue<List<VehicleCategoryModel>> categoriesAsync,
    double distanceKm,
  ) {
    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) return const SizedBox.shrink();
        final activeSelectedId = _getActiveCategoryId(categories);

        // Find cheapest fare
        double minFare = double.infinity;
        for (final c in categories) {
          final f = _calculateFare(c, distanceKm);
          if (f < minFare) minFare = f;
        }

        return SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = cat.id == activeSelectedId;
              final estCategoryFare = _calculateFare(cat, distanceKm);
              final isCatServiceable = _isVehicleServiceable(cat.name, distanceKm);

              // Badge tag assignment
              String? tag;
              if (estCategoryFare <= minFare) {
                tag = _isHindi ? 'सबसे सस्ता' : 'Cheapest';
              } else if (cat.name.toLowerCase().contains('bike')) {
                tag = _isHindi ? 'सबसे तेज़' : 'Fastest';
              } else if (cat.name.toLowerCase().contains('cab') || cat.name.toLowerCase().contains('auto')) {
                tag = _isHindi ? 'पॉपुलर' : 'Popular';
              }

              return VehicleCard(
                id: cat.id,
                name: cat.name,
                displayName: cat.displayName,
                imageAsset: _getVehicleIconAsset('${cat.id} ${cat.name} ${cat.displayName}'),
                fare: estCategoryFare,
                eta: '${3 + index * 2} min',
                seats: cat.name.toLowerCase().contains('bike') ? 1 : (cat.name.toLowerCase().contains('auto') ? 3 : (cat.name.toLowerCase().contains('suv') ? 6 : 4)),
                badgeTag: tag,
                isSelected: isSelected,
                isServiceable: isCatServiceable,
                onSelect: () {
                  HapticService.selection();
                  setState(() => _selectedCategory = cat.id);
                },
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 110,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// Empty state notice when distance exceeds geofence (e.g. Bike/Auto > 60km)
  Widget _buildUnserviceableNotice(String vehicleName) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(AppTokens.radiusCards),
        border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Service not available in this area',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Max range for $vehicleName is 60 km. Select Cab/Bolero for long trips or contact our helpline.',
                      style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C), height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openWhatsApp(
                    message: 'Hello District Car Helpline, I need a long-distance ride outside regular service range.',
                  ),
                  icon: const Icon(Icons.chat_bubble_rounded, size: 16, color: Color(0xFF0F172A)),
                  label: const Text(
                    'WhatsApp',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 12.5),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0F172A)),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _makePhoneCall('918789601387'),
                  icon: const Icon(Icons.call_rounded, size: 16, color: Colors.white),
                  label: const Text(
                    'Call Support',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB91C1C),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// E. Options Row (compact): Date/Time chip, Passengers stepper, Payment chip, Round-trip toggle
  Widget _buildOptionsRow() {
    final dayDate = DateFormat('d MMM').format(_selectedDate);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTokens.radiusCards),
        border: Border.all(color: const Color(0xFFEEF0F6)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(16, 24, 40, 0.04),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Row 1: Date/Time + Passengers + Payment Chips
          Row(
            children: [
              // Date/Time Chip
              Expanded(
                flex: 4,
                child: InkWell(
                  onTap: () {
                    HapticService.selection();
                    _selectTimeSlotModal();
                  },
                  borderRadius: BorderRadius.circular(AppTokens.radiusChips),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(AppTokens.radiusChips),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF0F172A)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _selectedTimeSlot.startsWith('Now') ? 'Now' : '$dayDate, ${_selectedTimeSlot.split('(').first.trim()}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppTokens.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Passengers Stepper Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(AppTokens.radiusChips),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: _passengerCount > 1
                          ? () {
                              HapticService.selection();
                              setState(() => _passengerCount--);
                            }
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.remove_rounded,
                          size: 15,
                          color: _passengerCount > 1 ? AppTokens.ink : AppTokens.hint,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.person_rounded, size: 12, color: AppTokens.secondary),
                          Text(
                            '$_passengerCount',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppTokens.ink),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: _passengerCount < 6
                          ? () {
                              HapticService.selection();
                              setState(() => _passengerCount++);
                            }
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.add_rounded,
                          size: 15,
                          color: _passengerCount < 6 ? const Color(0xFF0F172A) : AppTokens.hint,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),

              // Payment Chip
              InkWell(
                onTap: () {
                  HapticService.selection();
                  setState(() {
                    _paymentMethod = _paymentMethod == 'Cash / UPI' ? 'Cash' : 'Cash / UPI';
                  });
                },
                borderRadius: BorderRadius.circular(AppTokens.radiusChips),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(AppTokens.radiusChips),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.payments_rounded, size: 13, color: Color(0xFF0F172A)),
                      const SizedBox(width: 3),
                      Text(
                        _paymentMethod == 'Cash / UPI' ? 'Cash/UPI' : _paymentMethod,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Row 2: Round Trip Toggle with 1 Hr Free Wait
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: _isRoundTrip ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(AppTokens.radiusChips),
              border: Border.all(
                color: _isRoundTrip ? const Color(0xFFD97706) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.sync_alt_rounded,
                  size: 16,
                  color: _isRoundTrip ? const Color(0xFFD97706) : AppTokens.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 2,
                        children: [
                          Text(
                            _isHindi ? 'राउंड ट्रिप' : 'Round Trip',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                              color: AppTokens.ink,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              _isHindi ? '1 घंटा फ्री' : '1 hr free wait',
                              style: const TextStyle(
                                color: Color(0xFFB45309),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _isHindi ? 'उसी गाड़ी से वापसी' : 'Same driver stays for return',
                        style: const TextStyle(fontSize: 10, color: AppTokens.secondary),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _isRoundTrip,
                  activeColor: const Color(0xFF0F172A),
                  onChanged: (val) {
                    HapticService.toggle(value: val);
                    setState(() => _isRoundTrip = val);
                  },
                ),
              ],
            ),
          ),

          // Waiting hours stepper if round trip is active
          if (_isRoundTrip) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _roundTripStoppingHours <= 1.0
                      ? (_isHindi ? 'पहला 1 घंटा फ्री' : 'First 60 mins included free')
                      : '+₹${((_roundTripStoppingHours - 1.0) * 60.0).toStringAsFixed(0)} (₹60/hr waiting)',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD97706),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _roundTripStoppingHours > 1.0
                          ? () {
                              HapticService.selection();
                              setState(() => _roundTripStoppingHours -= 1.0);
                            }
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${_roundTripStoppingHours.toInt()} hr wait',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTokens.ink),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 18, color: Color(0xFF0F172A)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        HapticService.selection();
                        setState(() => _roundTripStoppingHours += 1.0);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// G. Quick WhatsApp / Call booking (compact single-line row)
  Widget _buildWhatsAppHelplineCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Quick WhatsApp & Call Booking: +91 87896 01387',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppTokens.ink,
              ),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () {
              HapticService.selection();
              _openWhatsApp(
                message: 'Hello District Car Helpline, I want to book a ride / need assistance.',
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(5),
              child: Icon(Icons.chat_bubble_rounded, color: Color(0xFF0F172A), size: 19),
            ),
          ),
          InkWell(
            onTap: () {
              HapticService.selection();
              _makePhoneCall('918789601387');
            },
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(5),
              child: Icon(Icons.call_rounded, color: Color(0xFF0F172A), size: 19),
            ),
          ),
        ],
      ),
    );
  }

  /// H. Tours & Travels Hero (height 140, below options)
  Widget _buildTourAndTravelsShortcutBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radiusCards),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 118, 110, 0.22),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTokens.radiusCards),
        child: Stack(
          children: [
            Image.asset(
              'assets/images/tour_banner_jharkhand.jpg',
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 140,
                color: const Color(0xFF0F766E),
              ),
            ),
            Container(
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.78),
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.2),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTokens.radiusCards),
                onTap: () {
                  HapticService.selection();
                  context.push('/tours');
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.explore_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF08A),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'TOUR & TRAVELS',
                                    style: TextStyle(
                                      color: Color(0xFF854D0E),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 9,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'EXPLORE',
                                    style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isHindi ? 'झारखंड के प्रमुख पर्यटन स्थल' : 'Waterfalls, Temples & Hills',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isHindi ? 'हुंडरू, जोन्हा, बैद्यनाथ धाम, नेतरहाट व अन्य' : 'Hundru, Dassam, Baidyanath Dham, Netarhat & more',
                              style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF0F766E), size: 16),
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

  /// Village Return Guarantee Transparency Banner
  Widget _buildJharkhandVillagePricingBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppTokens.radiusCards),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_outlined, color: Color(0xFFD97706), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isHindi ? 'ग्रामीण रिटर्न गारंटी' : 'Village Return Guarantee',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: AppTokens.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  _isHindi
                      ? 'ग्रामीण इलाकों में रिटर्न सवारी की अनिश्चितता के कारण हमारे ड्राइवर साथियों को उचित मुआवज़ा दिया जाता है, जिससे आपकी राइड बिना कैंसिल हुए तुरंत स्वीकार होती है।'
                      : 'In rural Jharkhand, return trips have lower availability. Our fair-rate model compensates driver return travel so your ride is 100% accepted without cancellations.',
                  style: const TextStyle(fontSize: 10.5, color: AppTokens.secondary, height: 1.4),
                ),
              ],
            ),
          ),
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

        if (!isAccepted) return const SizedBox.shrink();

        String statusLabel = 'DRIVER ACCEPTED';
        IconData statusIcon = Icons.check_circle_rounded;
        Color statusBg = const Color(0xFF0F172A);
        if (status == 'driver_arrived') {
          statusLabel = 'DRIVER AT PICKUP';
          statusIcon = Icons.near_me_rounded;
          statusBg = const Color(0xFF334155);
        } else if (status == 'trip_started') {
          statusLabel = 'TRIP IN PROGRESS';
          statusIcon = Icons.directions_car_rounded;
          statusBg = const Color(0xFF1E293B);
        }

        return Positioned(
          left: 16,
          right: 16,
          bottom: 12,
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(22),
            shadowColor: Colors.black.withValues(alpha: 0.25),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => context.push('/active-trip/${booking.id}'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isAccepted ? const Color(0xFF0F172A) : const Color(0xFFFBBF24),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(16),
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
                                  fontSize: 10,
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Text(
                              'OTP: ${booking.rideOtp}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF0F172A)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: const DecorationImage(
                              image: AssetImage('assets/images/app_logo.jpg'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.driverName ?? 'Nearby Partner Driver',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: AppTokens.ink,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${booking.vehicleModel ?? "District Car"} · ${booking.vehiclePlate ?? "JH Reg"}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTokens.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${(booking.finalFare ?? booking.estimatedFare).toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
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
}
