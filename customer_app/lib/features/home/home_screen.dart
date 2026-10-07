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
  }

  void _detectUserCurrentGpsOnStart() async {
    try {
      final loc = await LocationSearchService().getCurrentDeviceLocation();
      if (loc != null && mounted) {
        setState(() {
          // As requested: user exact location in "To" (Drop)
          _destinationLocation = loc.toLocationModel();
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
      context.push('/trips');
    } else if (index == 2) {
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
                  _buildVehicleCategorySelector(categoriesAsync, distanceKm),
                  const SizedBox(height: 16),
                  _buildJourneyDetailsCard(distanceKm, durationMinutes, categoriesAsync),
                  const SizedBox(height: 16),
                  _buildTimeSlotAndScheduleCard(),
                  const SizedBox(height: 16),
                  _buildRoundTripOptionCard(categoriesAsync, distanceKm),
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
        ],
      ),
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
}
