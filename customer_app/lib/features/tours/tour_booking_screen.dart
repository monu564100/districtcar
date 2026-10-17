import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:district_car_shared/models/models.dart';
import 'package:district_car_shared/services/location_search_service.dart';
import 'package:district_car_shared/services/fcm_notification_service.dart';
import 'package:district_car_shared/widgets/location_picker_sheet.dart';
import '../../theme/theme.dart';
import '../../services/haptic_service.dart';
import '../auth/auth_service.dart';
import '../booking/booking_service.dart';
import '../home/categories_provider.dart';
import 'tour_pricing_service.dart';

/// Single-page unified Tour Booking Screen following the exact Home Screen model.
/// Provides dynamic location routing, vehicle selection, ride now vs schedule timing,
/// round-trip sightseeing wait stepper, and dynamic package pricing driven by Admin Panel.
class TourBookingScreen extends ConsumerStatefulWidget {
  final PopularDestinationModel destination;

  const TourBookingScreen({super.key, required this.destination});

  static Future<void> open(BuildContext context, PopularDestinationModel destination) async {
    HapticService.selectionClick();
    if (!context.mounted) return;

    try {
      await context.push('/book-tour?id=${destination.id}', extra: destination);
    } catch (_) {
      if (context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TourBookingScreen(
              key: ValueKey(destination.id),
              destination: destination,
            ),
          ),
        );
      }
    }
  }

  @override
  ConsumerState<TourBookingScreen> createState() => _TourBookingScreenState();
}

class _TourBookingScreenState extends ConsumerState<TourBookingScreen> {
  // Locations
  late LocationModel _pickupLocation;
  late LocationModel _destinationLocation;

  // Selected Vehicle: 'auto', 'mini', 'sedan', 'suv'
  String _selectedVehicle = 'mini';
  int _passengerCount = 2;

  // Ride Timing (Same model as Home page)
  bool _isScheduleMode = false;
  DateTime _selectedDate = DateTime.now();
  late TimeOfDay _selectedScheduleTime;

  // Round Trip & Sightseeing hours
  bool _isRoundTrip = true;
  int _stayHours = 1; // 1 free hour included

  // Payment
  String _paymentMethod = 'Cash / UPI';

  // Distance & Duration
  double _calculatedDistanceKm = 0.0;
  String _durationText = '';
  bool _isCalculatingRoute = false;

  // Booking dispatch
  bool _isBookingLoading = false;

  @override
  void initState() {
    super.initState();
    // Destination fixed to destination coordinates
    _destinationLocation = LocationModel(
      latitude: widget.destination.latitude,
      longitude: widget.destination.longitude,
      address: widget.destination.locationAddress.isNotEmpty
          ? widget.destination.locationAddress
          : '${widget.destination.name}, ${widget.destination.district}',
    );

    // Initial default pickup: Ranchi Hub
    _pickupLocation = LocationModel(
      latitude: 23.3441,
      longitude: 85.3096,
      address: 'Albert Ekka Chowk, Main Road, Ranchi, Jharkhand',
    );

    // Initial schedule time: now + 1 hour (rounded to next 15 mins)
    final initialSchedule = DateTime.now().add(const Duration(hours: 1));
    _selectedScheduleTime = TimeOfDay(
      hour: initialSchedule.hour,
      minute: ((initialSchedule.minute / 15).ceil() * 15) % 60,
    );

    // Initial realistic distance & duration so pricing is non-zero from the very first frame
    _calculatedDistanceKm = widget.destination.approxDistanceKm > 0 ? widget.destination.approxDistanceKm : 45.0;
    _durationText = TourPricingService.formatDurationText(
      TourPricingService.calculateRuralDurationMinutes(_calculatedDistanceKm),
    );

    // Auto-detect GPS pickup & calculate distance
    _detectUserCurrentGpsOnStart();
  }

  void _detectUserCurrentGpsOnStart() async {
    try {
      final loc = await LocationSearchService().getCurrentDeviceLocation();
      if (loc != null && mounted) {
        setState(() {
          _pickupLocation = loc.toLocationModel();
        });
      }
    } catch (_) {}
    _fetchRouteDistanceAndDuration();
  }

  void _fetchRouteDistanceAndDuration() async {
    setState(() => _isCalculatingRoute = true);
    try {
      final res = await LocationSearchService().getDirectionsDistanceAndDuration(
        originLat: _pickupLocation.latitude,
        originLng: _pickupLocation.longitude,
        destLat: _destinationLocation.latitude,
        destLng: _destinationLocation.longitude,
      );
      if (mounted) {
        setState(() {
          _calculatedDistanceKm = (res['distanceKm'] as num).toDouble();
          _durationText = (res['durationText'] as String?) ?? '${res['durationMinutes']} mins';
          _isCalculatingRoute = false;
        });
      }
    } catch (_) {
      if (mounted) {
        final fallbackKm = TourPricingService.calculateRoadDistanceKm(
          _pickupLocation.latitude,
          _pickupLocation.longitude,
          _destinationLocation.latitude,
          _destinationLocation.longitude,
        );
        setState(() {
          _calculatedDistanceKm = fallbackKm;
          _durationText = TourPricingService.formatDurationText(
            TourPricingService.calculateRuralDurationMinutes(fallbackKm),
          );
          _isCalculatingRoute = false;
        });
      }
    }
  }

  void _openPickupLocationPicker() async {
    HapticService.selection();
    final picked = await LocationPickerSheet.show(
      context,
      title: 'Enter Tour Pickup Address (पिकअप का पता)',
      initialValue: _pickupLocation.address,
      isPickup: true,
    );
    if (picked != null) {
      setState(() => _pickupLocation = picked);
      _fetchRouteDistanceAndDuration();
    }
  }

  void _openDestinationLocationPicker() async {
    HapticService.selection();
    final picked = await LocationPickerSheet.show(
      context,
      title: 'Change Destination (मंजिल)',
      initialValue: _destinationLocation.address,
      isPickup: false,
    );
    if (picked != null) {
      setState(() => _destinationLocation = picked);
      _fetchRouteDistanceAndDuration();
    }
  }

  void _setCurrentGpsForPickup() async {
    HapticService.selection();
    try {
      final loc = await LocationSearchService().getCurrentDeviceLocation();
      if (loc != null && mounted) {
        setState(() => _pickupLocation = loc.toLocationModel());
        _fetchRouteDistanceAndDuration();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pickup set to current GPS location'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  void _swapLocations() {
    HapticService.selection();
    setState(() {
      final temp = _pickupLocation;
      _pickupLocation = _destinationLocation;
      _destinationLocation = temp;
    });
    _fetchRouteDistanceAndDuration();
  }

  TourPricingBreakdown _calculatePricing([String? overrideVehicle]) {
    final effectiveDist = _calculatedDistanceKm > 0
        ? _calculatedDistanceKm
        : (widget.destination.approxDistanceKm > 0 ? widget.destination.approxDistanceKm : 45.0);

    var p = TourPricingService.calculateTourPackageFare(
      destination: widget.destination,
      pickupLat: _pickupLocation.latitude,
      pickupLng: _pickupLocation.longitude,
      vehicleType: overrideVehicle ?? _selectedVehicle,
      isRoundTrip: _isRoundTrip,
      stayHours: _stayHours,
      passengerCount: _passengerCount,
      overrideDistanceKm: effectiveDist,
    );

    if (p.totalFare <= 0 || !p.isServiceable) {
      final nearestHub = TourPricingService.findNearestHubCity(
        widget.destination.latitude,
        widget.destination.longitude,
      );
      final hubDist = TourPricingService.calculateRoadDistanceKm(
        nearestHub.latitude,
        nearestHub.longitude,
        widget.destination.latitude,
        widget.destination.longitude,
      );
      p = TourPricingService.calculateTourPackageFare(
        destination: widget.destination,
        pickupLat: nearestHub.latitude,
        pickupLng: nearestHub.longitude,
        vehicleType: overrideVehicle ?? _selectedVehicle,
        isRoundTrip: _isRoundTrip,
        stayHours: _stayHours,
        passengerCount: _passengerCount,
        overrideDistanceKm: hubDist > 0 ? hubDist : 45.0,
      );
    }

    if (p.totalFare <= 0) {
      final fallbackBase = widget.destination.startingFare > 0 ? widget.destination.startingFare : 1299.0;
      return TourPricingBreakdown(
        basePackageFare: fallbackBase,
        extraWaitingFare: 0,
        nearbyStopsFare: 0,
        driverAllowance: 0,
        tollsAndTaxes: 0,
        totalFare: fallbackBase,
        perPersonFare: (fallbackBase / max(1, _passengerCount)).roundToDouble(),
        distanceKm: effectiveDist,
        durationMinutes: 75,
        durationText: '1 hr 15 mins',
        isServiceable: true,
        hubCityName: 'Ranchi',
        stayHours: _stayHours,
      );
    }

    return p;
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatTimeOfDay(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    return DateFormat('hh:mm a').format(dt);
  }

  void _validateAndSetScheduleTime(TimeOfDay picked) {
    final now = DateTime.now();
    if (_isSameDay(_selectedDate, now)) {
      final minimumAllowed = now.add(const Duration(hours: 1));
      final pickedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        picked.hour,
        picked.minute,
      );
      if (pickedDateTime.isBefore(minimumAllowed)) {
        final clampedMinutes = ((minimumAllowed.minute / 5).ceil() * 5);
        final clampedHour = minimumAllowed.hour + (clampedMinutes >= 60 ? 1 : 0);
        final finalMin = clampedMinutes % 60;
        final clampedTime = TimeOfDay(hour: clampedHour % 24, minute: finalMin);

        setState(() => _selectedScheduleTime = clampedTime);
        HapticService.selection();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('For today, schedule must be at least 1 hour in advance (${_formatTimeOfDay(clampedTime)}).'),
            duration: const Duration(seconds: 3),
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }
    setState(() => _selectedScheduleTime = picked);
  }

  Future<void> _pickScheduleTime() async {
    HapticService.selection();
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedScheduleTime,
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
      _validateAndSetScheduleTime(picked);
    }
  }

  void _pickDate() async {
    HapticService.selection();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 45)),
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
      _validateAndSetScheduleTime(_selectedScheduleTime);
    }
  }

  bool _isLocationServiceable(LocationModel loc) {
    final addr = loc.address.toLowerCase();
    const jharkhandKeywords = [
      'jharkhand', 'ranchi', 'khunti', 'ramgarh', 'hazaribagh', 'bokaro', 'dhanbad',
      'jamshedpur', 'singhbhum', 'saraikela', 'gumla', 'simdega', 'lohardaga', 'latehar',
      'palamu', 'garhwa', 'chatra', 'koderma', 'giridih', 'deoghar', 'dumka', 'godda',
      'sahibganj', 'pakur', 'jamtara', 'patratu', 'netarhat', 'betla', 'parasmath',
      'hundru', 'dassam', 'jonha'
    ];
    for (final kw in jharkhandKeywords) {
      if (addr.contains(kw)) return true;
    }
    // Check Jharkhand Geo Bounding Box (Lat: 21.8 - 25.5, Lng: 83.2 - 88.0)
    if (loc.latitude >= 21.8 && loc.latitude <= 25.5 &&
        loc.longitude >= 83.2 && loc.longitude <= 88.0) {
      return true;
    }
    return false;
  }

  void _showUnserviceableDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_off_rounded, color: Color(0xFFDC2626), size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Location Not Serviceable',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your pickup location:\n"${_pickupLocation.address}"\nis currently outside District Car\'s operational area.',
              style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFF16A34A), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'District Car operates across all districts of Jharkhand and nearby tourist hotspots.',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF166534)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Change Location', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }

  void _handleBookingSubmit(double totalFare) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) {
      context.push('/login');
      return;
    }

    // Check if pickup location is in operational service area
    if (!_isLocationServiceable(_pickupLocation)) {
      _showUnserviceableDialog();
      return;
    }

    setState(() => _isBookingLoading = true);

    try {
      final bookingService = ref.read(bookingServiceProvider);
      final now = DateTime.now();
      String formattedDate;
      String timeSlot;

      if (_isScheduleMode) {
        if (_isSameDay(_selectedDate, now)) {
          final minimumAllowed = now.add(const Duration(hours: 1));
          final selectedDt = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            _selectedScheduleTime.hour,
            _selectedScheduleTime.minute,
          );
          if (selectedDt.isBefore(minimumAllowed)) {
            _selectedScheduleTime = TimeOfDay(
              hour: minimumAllowed.hour,
              minute: minimumAllowed.minute,
            );
          }
        }
        formattedDate = DateFormat('EEE, d MMM yyyy').format(_selectedDate);
        final dateLabel = _isSameDay(_selectedDate, now) ? 'Today' : DateFormat('d MMM').format(_selectedDate);
        timeSlot = '$dateLabel at ${_formatTimeOfDay(_selectedScheduleTime)}';
      } else {
        formattedDate = 'Today';
        timeSlot = 'Now (Within 30 mins)';
      }

      // Map vehicle selection to active category ID
      String categoryId;
      switch (_selectedVehicle) {
        case 'auto':
          categoryId = 'auto';
          break;
        case 'sedan':
          categoryId = 'sedan';
          break;
        case 'suv':
          categoryId = 'suv';
          break;
        case 'mini':
        default:
          categoryId = 'car';
          break;
      }

      final bookingResult = await bookingService.createBooking(
        categoryId: categoryId,
        pickup: _pickupLocation,
        destination: _destinationLocation,
        customFare: totalFare,
        isRoundTrip: _isRoundTrip,
        roundTripStoppingHours: _stayHours.toDouble(),
        scheduledDate: formattedDate,
        scheduledTimeSlot: timeSlot,
      );

      try {
        await FCMNotificationService.sendCustomerSearchingNotification(
          bookingId: bookingResult['bookingId'],
          customerId: user.uid,
          isScheduled: _isScheduleMode,
          scheduledInfo: _isScheduleMode ? timeSlot : null,
          pickupAddress: _pickupLocation.address,
          destinationAddress: _destinationLocation.address,
        );
      } catch (_) {}

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
    final pricing = _calculatePricing();
    final totalFare = pricing.totalFare;
    final dayDate = DateFormat('d MMM').format(_selectedDate);
    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final isTomorrow = _isSameDay(_selectedDate, DateTime.now().add(const Duration(days: 1)));

    return Scaffold(
      backgroundColor: AppTokens.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTokens.ink, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Plan Your Tour',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTokens.ink),
            ),
            Text(
              '${widget.destination.name} • ${widget.destination.district}',
              style: const TextStyle(fontSize: 11.5, color: AppTokens.secondaryText, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTokens.primaryTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                'Tour Package',
                style: TextStyle(color: AppTokens.primaryDark, fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Pickup to Destination Route Card (Same model as Home page)
                _buildRouteCard(),

                const SizedBox(height: 18),

                // 2. Vehicle Selector Section (Same model as Home page)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Select Vehicle',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTokens.ink),
                    ),
                    Text(
                      'Admin Dynamic Fare',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTokens.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildVehicleCategorySelector(),

                const SizedBox(height: 18),

                // 3. Ride Timing: Ride Now vs Schedule Ride (Exact Home page model)
                _buildRideTimingSection(dayDate, isToday, isTomorrow),

                const SizedBox(height: 18),

                // 4. Round Trip & Sightseeing Wait Section
                _buildRoundTripSection(),

                const SizedBox(height: 18),

                // 5. All-Inclusive Package Fare Breakdown
                _buildFareBreakdownCard(pricing),
              ],
            ),
          ),

          // Sticky Bottom Booking Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildStickyBottomBar(totalFare),
          ),
        ],
      ),
    );
  }

  /// 1. Pickup to Destination Route Card
  Widget _buildRouteCard() {
    final distText = _calculatedDistanceKm > 0
        ? '${_calculatedDistanceKm.toStringAsFixed(1)} km • $_durationText'
        : 'Calculating route distance...';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTokens.border),
        boxShadow: AppTokens.softCardShadow,
      ),
      child: Column(
        children: [
          // Pickup Row
          InkWell(
            onTap: _openPickupLocationPicker,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.my_location_rounded, color: Color(0xFF16A34A), size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pickup Point (पिकअप)',
                        style: TextStyle(fontSize: 11, color: AppTokens.secondaryText, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _pickupLocation.address,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTokens.ink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.gps_fixed_rounded, size: 18, color: AppTokens.primary),
                  tooltip: 'Use current GPS location',
                  onPressed: _setCurrentGpsForPickup,
                ),
              ],
            ),
          ),

          // Divider with Swap button
          Row(
            children: [
              const SizedBox(width: 15),
              Container(width: 2, height: 16, color: Colors.grey.shade300),
              const Spacer(),
              InkWell(
                onTap: _swapLocations,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.swap_vert_rounded, size: 14, color: AppTokens.ink),
                      SizedBox(width: 3),
                      Text('Swap', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppTokens.ink)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Destination Row
          InkWell(
            onTap: _openDestinationLocationPicker,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on_rounded, color: Color(0xFFDC2626), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tour Destination (मंजिल)',
                        style: TextStyle(fontSize: 11, color: AppTokens.secondaryText, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _destinationLocation.address,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTokens.ink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.edit_location_alt_rounded, size: 18, color: AppTokens.secondaryText),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Distance and Duration Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.route_rounded, size: 14, color: AppTokens.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    distText,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTokens.ink),
                  ),
                ),
                if (_isCalculatingRoute)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Vehicle Selector (Dynamic pricing from Admin Panel)
  Widget _buildVehicleCategorySelector() {
    final vehicles = [
      {
        'id': 'mini',
        'title': 'Mini Cab',
        'seats': '4 Seats',
        'asset': 'assets/images/icon_vehicle_mini.png',
        'desc': 'WagonR / Alto AC',
      },
      {
        'id': 'sedan',
        'title': 'Prime Sedan',
        'seats': '4 Seats',
        'asset': 'assets/images/icon_vehicle_sedan.png',
        'desc': 'Dzire / Etios AC',
      },
      {
        'id': 'suv',
        'title': 'Spacious SUV',
        'seats': '6-7 Seats',
        'asset': 'assets/images/icon_vehicle_suv.png',
        'desc': 'Bolero / Ertiga AC',
      },
      {
        'id': 'auto',
        'title': 'Auto Rickshaw',
        'seats': '3 Seats',
        'asset': 'assets/images/icon_vehicle_auto.png',
        'desc': 'Local Sightseeing',
      },
    ];

    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: vehicles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final v = vehicles[index];
          final vid = v['id']! as String;
          final isSel = _selectedVehicle == vid;
          final vPricing = _calculatePricing(vid);

          return InkWell(
            onTap: () {
              HapticService.selection();
              setState(() => _selectedVehicle = vid);
            },
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 138,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isSel ? const Color(0xFFF0FDF4) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSel ? AppTokens.primary : AppTokens.border,
                  width: isSel ? 2 : 1,
                ),
                boxShadow: isSel
                    ? [
                        BoxShadow(
                          color: AppTokens.primary.withOpacity(0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : AppTokens.softCardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
                        v['asset']! as String,
                        width: 32,
                        height: 32,
                        errorBuilder: (_, __, ___) => const Icon(Icons.directions_car_rounded, size: 28, color: AppTokens.primary),
                      ),
                      Flexible(
                        child: Text(
                          v['seats']! as String,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTokens.secondaryText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v['title']! as String,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTokens.ink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${vPricing.totalFare.toInt()}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: isSel ? AppTokens.primary : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 3. Ride Timing Section (Same model as Home screen)
  Widget _buildRideTimingSection(String dayDate, bool isToday, bool isTomorrow) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTokens.border),
        boxShadow: AppTokens.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 16, color: Color(0xFF0F172A)),
              const SizedBox(width: 6),
              const Text(
                'Tour Ride Timing (यात्रा का समय)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTokens.ink),
              ),
              const Spacer(),
              if (!_isScheduleMode)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '⚡ 30 Min Search',
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Segmented Toggle
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      HapticService.selection();
                      setState(() => _isScheduleMode = false);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !_isScheduleMode ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: !_isScheduleMode
                            ? const [
                                BoxShadow(
                                  color: Color.fromRGBO(0, 0, 0, 0.06),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            size: 16,
                            color: !_isScheduleMode ? const Color(0xFFD97706) : AppTokens.secondaryText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Ride Now (तुरंत)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: !_isScheduleMode ? FontWeight.w800 : FontWeight.w600,
                              color: !_isScheduleMode ? const Color(0xFF0F172A) : AppTokens.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      HapticService.selection();
                      setState(() => _isScheduleMode = true);
                      _validateAndSetScheduleTime(_selectedScheduleTime);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _isScheduleMode ? const Color(0xFF0F172A) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _isScheduleMode
                            ? const [
                                BoxShadow(
                                  color: Color.fromRGBO(15, 23, 42, 0.20),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            size: 15,
                            color: _isScheduleMode ? Colors.white : AppTokens.secondaryText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Schedule Ride',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _isScheduleMode ? FontWeight.w800 : FontWeight.w600,
                              color: _isScheduleMode ? Colors.white : AppTokens.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Date & Time Picker when Schedule Mode is Active
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 240),
            crossFadeState: _isScheduleMode ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Today
                      InkWell(
                        onTap: () {
                          HapticService.selection();
                          setState(() => _selectedDate = DateTime.now());
                          _validateAndSetScheduleTime(_selectedScheduleTime);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isToday ? const Color(0xFF0F172A) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isToday ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1)),
                          ),
                          child: Text(
                            'Today',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isToday ? Colors.white : AppTokens.ink,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Tomorrow
                      InkWell(
                        onTap: () {
                          HapticService.selection();
                          setState(() => _selectedDate = DateTime.now().add(const Duration(days: 1)));
                          _validateAndSetScheduleTime(_selectedScheduleTime);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isTomorrow ? const Color(0xFF0F172A) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isTomorrow ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1)),
                          ),
                          child: Text(
                            'Tomorrow',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isTomorrow ? Colors.white : AppTokens.ink,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Pick other date
                      Expanded(
                        child: InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: (!isToday && !isTomorrow) ? const Color(0xFF0F172A) : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: (!isToday && !isTomorrow) ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit_calendar_rounded, size: 13, color: (!isToday && !isTomorrow) ? Colors.white : AppTokens.ink),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    dayDate,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: (!isToday && !isTomorrow) ? Colors.white : AppTokens.ink,
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
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Departure Time Picker
                  InkWell(
                    onTap: _pickScheduleTime,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_filled_rounded, size: 16, color: Color(0xFFD97706)),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Departure Time (प्रस्थान)',
                                style: TextStyle(fontSize: 10, color: AppTokens.secondaryText, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                _formatTimeOfDay(_selectedScheduleTime),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: const [
                                Text('Change', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                SizedBox(width: 3),
                                Icon(Icons.edit_rounded, size: 12, color: Color(0xFF0F172A)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (isToday) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: const [
                        Icon(Icons.info_outline_rounded, size: 12, color: Color(0xFFD97706)),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Note: Same-day schedules require at least 1 hour advance notice.',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFB45309)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 4. Round Trip & Sightseeing Section
  Widget _buildRoundTripSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTokens.border),
        boxShadow: AppTokens.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.repeat_rounded, size: 18, color: AppTokens.primary),
                  SizedBox(width: 8),
                  Text(
                    'Round Trip Package (आना-जाना)',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppTokens.ink),
                  ),
                ],
              ),
              Switch.adaptive(
                value: _isRoundTrip,
                activeColor: AppTokens.primary,
                onChanged: (val) {
                  HapticService.selection();
                  setState(() => _isRoundTrip = val);
                },
              ),
            ],
          ),
          if (_isRoundTrip) ...[
            const Divider(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Sightseeing & Waiting Hours',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTokens.ink),
                    ),
                    Text(
                      '1st hour free included in tour package',
                      style: TextStyle(fontSize: 10.5, color: AppTokens.secondaryText),
                    ),
                  ],
                ),
                // Stepper
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded, size: 22, color: AppTokens.primary),
                      onPressed: _stayHours > 1
                          ? () {
                              HapticService.selection();
                              setState(() => _stayHours--);
                            }
                          : null,
                    ),
                    Text(
                      '$_stayHours hr${_stayHours > 1 ? "s" : ""}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTokens.ink),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 22, color: AppTokens.primary),
                      onPressed: _stayHours < 8
                          ? () {
                              HapticService.selection();
                              setState(() => _stayHours++);
                            }
                          : null,
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

  /// 5. Fare Breakdown Card
  Widget _buildFareBreakdownCard(TourPricingBreakdown p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTokens.border),
        boxShadow: AppTokens.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tour Package Breakdown',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTokens.ink),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ALL-INCLUSIVE',
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF16A34A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBreakdownRow('Base Package (${_isRoundTrip ? "Round Trip" : "One Way"})', '₹${p.basePackageFare.toInt()}'),
          if (p.extraWaitingFare > 0)
            _buildBreakdownRow('Sightseeing Waiting (${_stayHours - 1} hr extra)', '+₹${p.extraWaitingFare.toInt()}'),
          _buildBreakdownRow('Tolls, State Tax & Parking', 'Included / ₹0 Extra'),
          _buildBreakdownRow('Driver & Fuel Allowance', 'Included in Package'),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Tour Fare',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTokens.ink),
              ),
              Text(
                '₹${p.totalFare.toInt()}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTokens.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTokens.secondaryText)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTokens.ink)),
        ],
      ),
    );
  }

  /// Sticky Bottom Bar
  Widget _buildStickyBottomBar(double totalFare) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTokens.border.withOpacity(0.8))),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.08),
            blurRadius: 14,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Estimated Fare',
                style: TextStyle(fontSize: 11, color: AppTokens.secondaryText, fontWeight: FontWeight.w600),
              ),
              Text(
                '₹${totalFare.toInt()}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTokens.ink),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isBookingLoading ? null : () => _handleBookingSubmit(totalFare),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTokens.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isBookingLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isScheduleMode ? Icons.calendar_month_rounded : Icons.directions_car_rounded,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isScheduleMode ? 'Schedule Tour Ride' : 'Book Tour Ride',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
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
}
