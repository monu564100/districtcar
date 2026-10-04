import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import 'package:district_car_shared/models/models.dart';
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

  final _pickupController = TextEditingController(text: 'PITX, Parañaque City');
  final _destinationController = TextEditingController(text: 'Cubao, Quezon City');
  final _dateController = TextEditingController(text: 'Select Date');
  final _passengersController = TextEditingController(text: '1 Passenger');

  bool _isBookingLoading = false;

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _dateController.dispose();
    _passengersController.dispose();
    super.dispose();
  }

  void _onDockTabSelected(int index) {
    setState(() => _currentDockIndex = index);
    if (index == 1) {
      context.push('/trips');
    } else if (index == 3) {
      context.push('/profile');
    }
  }

  void _handleBookingSearch() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) {
      context.push('/login');
      return;
    }

    setState(() => _isBookingLoading = true);

    try {
      final bookingService = ref.read(bookingServiceProvider);
      // Hardcoded sensible test coords for PITX to Cubao (approx 18 km)
      final bookingResult = await bookingService.createBooking(
        categoryId: _selectedCategory,
        pickup: LocationModel(
          latitude: 14.5098,
          longitude: 120.9934,
          address: _pickupController.text,
        ),
        destination: LocationModel(
          latitude: 14.6195,
          longitude: 121.0537,
          address: _destinationController.text,
        ),
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background soft gradient matching screenshot
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
                  const SizedBox(height: 16),
                  _buildDestinationSearchInput(),
                  const SizedBox(height: 20),
                  _buildVehicleCategorySelector(categoriesAsync),
                  const SizedBox(height: 20),
                  _buildJourneyDetailsCard(),
                  const SizedBox(height: 20),
                  _buildPromotionBanner(),
                ],
              ),
            ),
          ),
          // Floating Bottom Navigation Dock matching UI design
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // User Avatar & Balance
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryLight,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.person, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '100.00\$',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: const [
                      Icon(Icons.credit_card_outlined, size: 13, color: AppColors.textSecondary),
                      SizedBox(width: 4),
                      Text(
                        'Top up credit',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Notification Bell
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ],
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: 22),
                Positioned(
                  top: 10,
                  right: 12,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationSearchInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hello Muhammad,',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          const Text(
            'Where to go?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          // Pill search bar with map pin preview
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            ],
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.textMuted, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Enter destination',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.w500),
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
        ],
      ),
    );
  }

  Widget _buildVehicleCategorySelector(AsyncValue<List<VehicleCategoryModel>> categoriesAsync) {
    return categoriesAsync.when(
      data: (categories) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: categories.map((cat) {
              final isSelected = _selectedCategory == cat.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat.id),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 76,
                  child: Column(
                    children: [
                      // Pill Label
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.black : Colors.black87,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          cat.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Rounded Box Icon
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF8C98F7) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getIconForCategory(cat.name),
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          size: 28,
                        ),
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

  Widget _buildJourneyDetailsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // From & To Dual Section with Swap Icon
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('From', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      _pickupController.text.split(',').first,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    Text(
                      _pickupController.text.split(',').length > 1
                          ? _pickupController.text.split(',')[1].trim()
                          : '',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.swap_horiz, color: AppColors.textSecondary, size: 20),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('To', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      _destinationController.text.split(',').first,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    Text(
                      _destinationController.text.split(',').length > 1
                          ? _destinationController.text.split(',')[1].trim()
                          : '',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28, color: AppColors.borderLight),
          // Date & Passengers Selectors
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Departing on', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(
                      children: const [
                        Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textPrimary),
                        SizedBox(width: 6),
                        Text('Select Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Passengers', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(
                      children: const [
                        Icon(Icons.person_outline, size: 18, color: AppColors.textPrimary),
                        SizedBox(width: 6),
                        Text('1 Passenger', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Black Search / Book Button matching UI screenshot
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _isBookingLoading ? null : _handleBookingSearch,
              child: _isBookingLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Search',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFD6DBFD),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Ready for Smooth ride?',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Book verified drivers near you.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Explore',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
