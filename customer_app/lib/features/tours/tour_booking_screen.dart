import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:district_car_shared/models/models.dart';
import 'package:district_car_shared/services/fcm_notification_service.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import '../auth/auth_service.dart';
import 'package:district_car_shared/widgets/location_picker_sheet.dart';
import 'package:district_car_shared/services/location_search_service.dart';
import 'package:district_car_shared/services/rural_fare_calculator.dart';
import '../home/categories_provider.dart';

class TourBookingScreen extends ConsumerStatefulWidget {
  final PopularDestinationModel destination;

  const TourBookingScreen({super.key, required this.destination});

  @override
  ConsumerState<TourBookingScreen> createState() => _TourBookingScreenState();
}

class _TourBookingScreenState extends ConsumerState<TourBookingScreen> {
  late LocationModel _pickupLocation;
  late LocationModel _destinationLocation;

  String _tripType = 'round_trip'; // 'round_trip' or 'one_way'
  int _stayHours = 1; // 1 (free), 2, 3, 4, 6, 8, 24 (overnight)
  String _selectedVehicle = 'car'; // Strictly: 'car', 'suv', 'auto'
  String _scheduledDate = 'Today';
  String _scheduledTime = '08:00 AM';
  final String _paymentMethod = 'cash'; // 'cash' or 'online'
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    // Destination initialized from selected popular spot
    _destinationLocation = LocationModel(
      latitude: widget.destination.latitude,
      longitude: widget.destination.longitude,
      address: widget.destination.locationAddress.isNotEmpty
          ? widget.destination.locationAddress
          : '${widget.destination.name}, ${widget.destination.district}',
    );

    // Initial Pickup default: Ranchi City Center or Device Location
    _pickupLocation = LocationModel(
      latitude: 23.3441,
      longitude: 85.3096,
      address: 'Albert Ekka Chowk, Main Road, Ranchi, Jharkhand',
    );

    _detectExactDeviceLocation();
    _fetchGoogleDistanceAndDuration();
  }

  // Real-time Google Maps Directions Distance & Duration
  double _googleDistanceKm = 0.0;
  int _googleDurationMinutes = 0;
  String _googleDurationText = '';

  void _fetchGoogleDistanceAndDuration() async {
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
          _googleDurationText = (res['durationText'] as String?) ?? '$_googleDurationMinutes mins';
        });
      }
    } catch (_) {}
  }

  void _detectExactDeviceLocation() async {
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

  void _editPickupLocation() async {
    final picked = await LocationPickerSheet.show(
      context,
      title: 'Choose Tour Pickup Address',
      initialValue: _pickupLocation.address,
      isPickup: true,
    );
    if (picked != null) {
      setState(() => _pickupLocation = picked);
      _fetchGoogleDistanceAndDuration();
    }
  }

  void _editDestinationLocation() async {
    final picked = await LocationPickerSheet.show(
      context,
      title: 'Edit Tour Destination',
      initialValue: _destinationLocation.address,
      isPickup: false,
    );
    if (picked != null) {
      setState(() => _destinationLocation = picked);
      _fetchGoogleDistanceAndDuration();
    }
  }

  double _calculateDistanceKm() {
    if (_googleDistanceKm > 0.0) return _googleDistanceKm;
    final distMeters = Geolocator.distanceBetween(
      _pickupLocation.latitude,
      _pickupLocation.longitude,
      _destinationLocation.latitude,
      _destinationLocation.longitude,
    );
    double oneWayKm = distMeters / 1000.0;
    if (oneWayKm < 5.0) {
      oneWayKm = widget.destination.approxDistanceKm;
    }
    return double.parse(oneWayKm.toStringAsFixed(1));
  }

  int _calculateDurationMinutes() {
    if (_googleDurationMinutes > 0) return _googleDurationMinutes;
    final km = _calculateDistanceKm();
    return (km / 28.0 * 60.0).round().clamp(10, 720);
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

  IconData _getIconForCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('bike')) return Icons.two_wheeler_rounded;
    if (lower.contains('auto') || lower.contains('rick')) return Icons.electric_rickshaw;
    if (lower.contains('suv') || lower.contains('bolero')) return Icons.airport_shuttle;
    return Icons.directions_car_filled_outlined;
  }

  String _getCapacityForCategory(VehicleCategoryModel cat) {
    final lower = '${cat.id} ${cat.name} ${cat.displayName}'.toLowerCase();
    if (lower.contains('bike')) return '1 Seater';
    if (lower.contains('auto') || lower.contains('rick')) return '3 Seater';
    if (lower.contains('suv') || lower.contains('bolero')) return '6-7 Seater AC';
    return '4 Seater AC';
  }

  double _calculateDynamicVehicleFare(VehicleCategoryModel cat) {
    final oneWayKm = _calculateDistanceKm();
    final isRound = _tripType == 'round_trip';
    final isLong = oneWayKm >= 25.0;

    final double shortRate = RuralFareCalculator.getRatePerKm(
      categoryIdOrName: '${cat.id} ${cat.name} ${cat.displayName}',
      oneWayDistanceKm: oneWayKm,
      isRoundTrip: false,
    );
    final double longRoundRate = RuralFareCalculator.getRatePerKm(
      categoryIdOrName: '${cat.id} ${cat.name} ${cat.displayName}',
      oneWayDistanceKm: oneWayKm,
      isRoundTrip: true,
    );
    final double ratePerKm = (isLong && isRound) ? longRoundRate : shortRate;

    // Formula:
    // Round-trip: Target Distance * 2 * Price per km
    // One-way:    Target Distance * Price per km
    double distanceFare = isRound
        ? (oneWayKm * 2.0 * ratePerKm)
        : (oneWayKm * ratePerKm);

    // 1 Hour Free Waiting included on Round Trips! User can increase waiting hours based on pricing.
    double waitingFee = 0.0;
    if (isRound && _stayHours > 1) {
      if (_stayHours == 24) {
        waitingFee = 500.0; // Overnight driver allowance
      } else {
        final double hourlyRate = cat.hourlyWaitingCharge > 0 ? cat.hourlyWaitingCharge : 60.0;
        waitingFee = (_stayHours - 1) * hourlyRate;
      }
    }

    final total = distanceFare + waitingFee;
    return total < cat.minimumFare ? cat.minimumFare : total.roundToDouble();
  }

  double _calculateTotalFare(List<VehicleCategoryModel> categories) {
    final selectedCat = categories.firstWhere(
      (c) => c.id == _selectedVehicle,
      orElse: () => categories.first,
    );
    return _calculateDynamicVehicleFare(selectedCat);
  }

  void _confirmAndBookTourRide(List<VehicleCategoryModel> categories) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first to book tour ride.')),
      );
      context.push('/login');
      return;
    }

    setState(() => _isBooking = true);

    try {
      final oneWayKm = _calculateDistanceKm();
      final totalFare = _calculateTotalFare(categories);
      final readableId = 'TR-${100000 + Random().nextInt(900000)}';
      final rideOtp = (1000 + Random().nextInt(9000)).toString();

      final bookingRef = FirebaseFirestore.instance.collection('bookings').doc();

      final bookingData = {
        'id': bookingRef.id,
        'readableId': readableId,
        'customerId': user.uid,
        'customerName': (user.displayName != null && user.displayName!.isNotEmpty)
            ? user.displayName!
            : 'Valued Customer',
        'customerPhone': user.phoneNumber ?? '',
        'bookingType': 'tour',
        'tourDestinationId': widget.destination.id,
        'tourDestinationName': widget.destination.name,
        'tripType': _tripType,
        'isRoundTrip': _tripType == 'round_trip',
        'roundTripStoppingHours': _tripType == 'round_trip' ? _stayHours.toDouble() : 0.0,
        'stayHours': _tripType == 'round_trip' ? _stayHours : 0,
        'vehicleCategoryId': _selectedVehicle,
        'vehicleType': _selectedVehicle,
        'pickup': _pickupLocation.toMap(),
        'destination': _destinationLocation.toMap(),
        'estimatedDistanceKm': _tripType == 'round_trip' ? (oneWayKm * 2) : oneWayKm,
        'estimatedDurationMinutes': (_googleDurationMinutes > 0 ? _googleDurationMinutes : (oneWayKm / 35.0 * 60.0).round()).toDouble(),
        'estimatedFare': totalFare,
        'finalFare': totalFare,
        'paymentMethod': _paymentMethod,
        'paymentStatus': 'pending',
        'status': 'searching_driver',
        'rideOtp': rideOtp,
        'scheduledDate': _scheduledDate,
        'scheduledTimeSlot': _scheduledTime,
        'searchRadiusKm': 35.0,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await bookingRef.set(bookingData);

      // Notify matching available drivers strictly of this selected vehicle category within 30-35km radius
      try {
        final categoryQuery = _selectedVehicle;
        final driversSnapshot = await FirebaseFirestore.instance.collection('drivers').get();
        final List<String> tokens = [];
        final List<String> driverIds = [];
        const double maxSearchRadiusKm = 35.0;

        for (final doc in driversSnapshot.docs) {
          final data = doc.data();
          final isBusy = data['isBusy'] == true || data['activeBookingId'] != null;
          final isBlocked = data['isBlocked'] == true;
          final cat = (data['vehicleCategoryId'] ?? data['category'] ?? 'car').toString().trim().toLowerCase();

          // Strictly filter drivers matching the booked vehicle category (car, suv, auto)
          if (!isBusy && !isBlocked && cat == categoryQuery) {
            // Extract driver coordinates (currentLocation, location, or defaults)
            double driverLat = 23.0740;
            double driverLng = 85.2780;
            if (data['currentLocation'] != null && data['currentLocation']['latitude'] != null) {
              driverLat = (data['currentLocation']['latitude'] as num).toDouble();
              driverLng = (data['currentLocation']['longitude'] as num).toDouble();
            } else if (data['location'] != null && data['location']['latitude'] != null) {
              driverLat = (data['location']['latitude'] as num).toDouble();
              driverLng = (data['location']['longitude'] as num).toDouble();
            } else if (data['latitude'] != null) {
              driverLat = (data['latitude'] as num).toDouble();
              driverLng = (data['longitude'] as num).toDouble();
            }

            final distToDriverMeters = Geolocator.distanceBetween(
              _pickupLocation.latitude,
              _pickupLocation.longitude,
              driverLat,
              driverLng,
            );
            final distToDriverKm = distToDriverMeters / 1000.0;

            // Only notify drivers within up to 35 km for tours & travels
            if (distToDriverKm <= maxSearchRadiusKm) {
              driverIds.add(doc.id);
              final tok = data['fcmToken'] as String?;
              if (tok != null && tok.isNotEmpty) tokens.add(tok);

              await FirebaseFirestore.instance.collection('bookingRequests').add({
                'bookingId': bookingRef.id,
                'driverId': doc.id,
                'vehicleCategoryId': cat,
                'pickupDistanceKm': double.parse(distToDriverKm.toStringAsFixed(1)),
                'status': 'offered',
                'isTourBooking': true,
                'createdAt': FieldValue.serverTimestamp(),
              });
            }
          }
        }

        await bookingRef.update({
          'searchRadiusKm': maxSearchRadiusKm,
          'matchedDriversCount': driverIds.length,
          'hasNearDrivers': driverIds.isNotEmpty,
        }).catchError((_) {});

        await FCMNotificationService.sendBookingOfferedNotificationToDrivers(
          bookingId: bookingRef.id,
          readableId: readableId,
          categoryId: categoryQuery,
          pickupAddress: _pickupLocation.address,
          destinationAddress: widget.destination.name,
          estimatedFare: totalFare,
          driverTokens: tokens,
          driverIds: driverIds,
        );
      } catch (err) {
        debugPrint('Driver push notification dispatch notice: $err');
      }

      if (mounted) {
        setState(() => _isBooking = false);
        // Show success and route to active trip
        context.pushReplacement('/active-trip/${bookingRef.id}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBooking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to book tour: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(vehicleCategoriesProvider);
    final categories = categoriesAsync.asData?.value ?? defaultVehicleCategories;
    final oneWayKm = _calculateDistanceKm();
    final totalFare = _calculateTotalFare(categories);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Book Tour & Travel Ride',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            Text(
              widget.destination.name,
              style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Destination Snapshot Header
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF065F46), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF059669).withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      widget.destination.imageUrl,
                      width: 65,
                      height: 65,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.white, size: 40),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.destination.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${widget.destination.district} · ~${oneWayKm.toInt()} km one-way',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.destination.rating} · ${widget.destination.category.toUpperCase()}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 1. ROUTE PICKUP & DROP LOCATIONS
            const Text(
              'Tour Route (पिकअप एवं गंतव्य)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  // From: Exact User GPS Location
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'FROM (पिकअप पता - Exact Location)',
                              style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _pickupLocation.address,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _editPickupLocation,
                        icon: const Icon(Icons.edit_location_alt_rounded, size: 16),
                        label: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1),
                  ),
                  // To: Selected Tour Destination
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TO (पर्यटन स्थल - Destination)',
                              style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _destinationLocation.address,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _editDestinationLocation,
                        icon: const Icon(Icons.edit_location_alt_rounded, size: 16),
                        label: const Text('Change', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. TRIP TYPE SELECTOR (Round Trip vs One Way)
            const Text(
              'Trip Type (यात्रा प्रकार)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildTripTypeCard(
                    id: 'round_trip',
                    title: 'Round Trip 🔄',
                    subtitle: 'आना-जाना & वापसी (Driver stays)',
                    badge: 'RECOMMENDED',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTripTypeCard(
                    id: 'one_way',
                    title: 'One Way ➡️',
                    subtitle: 'एक तरफा ड्रॉप (Only Drop)',
                    badge: null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. STAY & WAITING DURATION (Only for Round Trip)
            if (_tripType == 'round_trip') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Stay & Sightseeing Duration (रुकने का समय)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'How long do you want the cab & driver to wait at the spot?',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildDurationChip(hours: 1, label: '1 Hour (Free Waiting 🎁)'),
                  _buildDurationChip(hours: 2, label: '2 Hours (+₹60)'),
                  _buildDurationChip(hours: 3, label: '3 Hours (+₹120)'),
                  _buildDurationChip(hours: 4, label: '4 Hours (+₹180)'),
                  _buildDurationChip(hours: 6, label: '6 Hours (+₹300)'),
                  _buildDurationChip(hours: 8, label: '8 Hours (+₹420)'),
                  _buildDurationChip(hours: 24, label: 'Overnight (+₹500)'),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // 4. LIVE FARE CALCULATION CARD (Based on Distance, Waiting Time & Round Trip)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF064E3B), Color(0xFF047857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withOpacity(0.25),
                    blurRadius: 12,
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
                        children: const [
                          Icon(Icons.calculate_rounded, color: Color(0xFF6EE7B7), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Live Fare Calculation',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _tripType == 'round_trip' ? '🔄 Round Trip Package' : '➡️ One Way Drop',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Breakdown metrics in four columns (Distance, Travel Time, Waiting Time, Package Benefit)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildCalculationMetric(
                          icon: Icons.alt_route_rounded,
                          title: 'Distance',
                          value: _tripType == 'round_trip'
                              ? '${(oneWayKm * 2).toInt()} km (Round)'
                              : '${oneWayKm.toInt()} km (Drop)',
                        ),
                        Container(width: 1, height: 30, color: Colors.white24),
                        _buildCalculationMetric(
                          icon: Icons.access_time_rounded,
                          title: 'Travel Time',
                          value: _googleDurationText.isNotEmpty
                              ? (_tripType == 'round_trip' ? '${_calculateDurationMinutes() * 2} mins' : _googleDurationText)
                              : '${_calculateDurationMinutes()} mins',
                        ),
                        Container(width: 1, height: 30, color: Colors.white24),
                        _buildCalculationMetric(
                          icon: Icons.timer_outlined,
                          title: 'Waiting Time',
                          value: _tripType == 'round_trip'
                              ? (_stayHours == 24 ? 'Overnight (24h)' : '$_stayHours Hours')
                              : 'Direct Drop',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Fare for selected vehicle:',
                        style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '₹${totalFare.toInt()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(top: 8),
                      iconColor: Colors.white70,
                      collapsedIconColor: Colors.white70,
                      title: const Text(
                        'View Detailed Calculation Breakdown',
                        style: TextStyle(color: Color(0xFF6EE7B7), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _buildFareRow(
                                label: 'Distance (${_tripType == 'round_trip' ? '${(oneWayKm * 2).toInt()} km' : '${oneWayKm.toInt()} km'})',
                                value: 'Included',
                              ),
                              _buildFareRow(
                                label: 'Driver Sightseeing Waiting',
                                value: _tripType == 'round_trip' && _stayHours > 0
                                    ? (_stayHours == 24 ? 'Overnight Allowance' : '$_stayHours Hours included')
                                    : 'None',
                              ),
                              _buildFareRow(
                                label: 'Doorstep Pickup & Return',
                                value: 'FREE',
                              ),
                              if (_tripType == 'round_trip')
                                _buildFareRow(
                                  label: 'Round-Trip Package Discount',
                                  value: '10% Return Savings',
                                ),
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Estimated Fare:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                                  Text('₹${totalFare.toInt()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF16A34A))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 5. VEHICLE CATEGORY SELECTION (Showing Live Prices on Each Vehicle)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Vehicle (गाड़ी चुनें)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                Text(
                  'Live calculated fare',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Column(
              children: categories.map((cat) {
                final isSelected = _selectedVehicle == cat.id;
                final vFare = _calculateDynamicVehicleFare(cat);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF16A34A) : Colors.grey.shade200,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    onTap: () => setState(() => _selectedVehicle = cat.id),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.asset(
                          _getVehicleIconAsset('${cat.id} ${cat.name} ${cat.displayName}'),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: isSelected ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                            child: Icon(_getIconForCategory(cat.name), color: isSelected ? const Color(0xFF16A34A) : const Color(0xFF475569)),
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      cat.displayName.isNotEmpty ? cat.displayName : cat.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: isSelected ? const Color(0xFF14532D) : const Color(0xFF0F172A),
                      ),
                    ),
                    subtitle: Text(
                      '${_getCapacityForCategory(cat)} · ₹${cat.perKmRate}/km',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${vFare.toInt()}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: isSelected ? const Color(0xFF15803D) : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          isSelected ? 'Selected' : 'Tap to select',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? const Color(0xFF16A34A) : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // 6. SCHEDULE DATE & TIME
            const Text(
              'Schedule Date & Departure Time',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _scheduledDate,
                        isDense: true,
                        items: ['Today', 'Tomorrow', 'This Weekend', 'Next Monday']
                            .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _scheduledDate = val);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _scheduledTime,
                        isDense: true,
                        items: ['06:00 AM', '07:00 AM', '08:00 AM', '09:00 AM', '10:00 AM', '01:00 PM']
                            .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _scheduledTime = val);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),

      // Fixed Bottom Action Button
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, -4)),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            onPressed: _isBooking ? null : () => _confirmAndBookTourRide(categories),
            child: _isBooking
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.explore_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Confirm & Book Tour Ride (₹${totalFare.toInt()})',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTripTypeCard({
    required String id,
    required String title,
    required String subtitle,
    String? badge,
  }) {
    final isSelected = _tripType == id;
    return GestureDetector(
      onTap: () => setState(() => _tripType = id),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF16A34A) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: isSelected ? const Color(0xFF14532D) : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationChip({required int hours, required String label}) {
    final isSelected = _stayHours == hours;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF334155),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF059669),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isSelected ? const Color(0xFF059669) : Colors.grey.shade300),
      ),
      onSelected: (_) => setState(() => _stayHours = hours),
    );
  }

  Widget _buildCalculationMetric({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF6EE7B7), size: 16),
        const SizedBox(height: 3),
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
        const SizedBox(height: 1),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5)),
      ],
    );
  }

  Widget _buildFareRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}
