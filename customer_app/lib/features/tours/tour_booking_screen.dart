import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:district_car_shared/models/models.dart';
import '../../theme/theme.dart';
import '../../services/haptic_service.dart';
import '../../widgets/tours/tour_service_area_modal.dart';
import '../../widgets/tours/branded_destination_placeholder.dart';
import '../../widgets/tours/tour_assets.dart';
import 'tour_pricing_service.dart';

/// 3-Step Tour Booking Flow (Rule 4)
/// Top Step Indicator: Trip → Vehicle → Review
/// Sticky Bottom Bar on EVERY step: Fare + Breakdown Sheet + CTA
class TourBookingScreen extends ConsumerStatefulWidget {
  final PopularDestinationModel destination;

  const TourBookingScreen({super.key, required this.destination});

  @override
  ConsumerState<TourBookingScreen> createState() => _TourBookingScreenState();
}

class _TourBookingScreenState extends ConsumerState<TourBookingScreen> {
  int _currentStep = 0; // 0: Trip, 1: Vehicle, 2: Review

  // Step 1: Trip State
  late LocationModel _pickupLocation;
  late LocationModel _destinationLocation;
  String _tripType = 'round_trip'; // 'round_trip' or 'one_way'
  int _stayHours = 1; // 1 free, 2, 3, 4...
  final List<Map<String, dynamic>> _selectedAddonStops = [];

  // Step 2: Vehicle State
  String _selectedVehicle = 'mini'; // 'auto', 'mini', 'sedan', 'suv'
  int _passengerCount = 2;

  // Step 3: Review State
  DateTime _selectedDate = DateTime.now();
  String _selectedTime = '08:00 AM';
  String _paymentMethod = 'cash'; // 'cash', 'upi', 'advance'
  final TextEditingController _pickupNoteCtrl = TextEditingController();
  bool _agreedToTerms = true;
  bool _isBookingConfirmed = false;

  @override
  void initState() {
    super.initState();
    _destinationLocation = LocationModel(
      latitude: widget.destination.latitude,
      longitude: widget.destination.longitude,
      address: widget.destination.locationAddress.isNotEmpty
          ? widget.destination.locationAddress
          : '${widget.destination.name}, ${widget.destination.district}',
    );

    // Default pickup: Ranchi Hub Center
    _pickupLocation = LocationModel(
      latitude: 23.3441,
      longitude: 85.3096,
      address: 'Albert Ekka Chowk, Main Road, Ranchi, Jharkhand',
    );
  }

  @override
  void dispose() {
    _pickupNoteCtrl.dispose();
    super.dispose();
  }

  TourPricingBreakdown _calculateCurrentPricing([String? overrideVehicle]) {
    return TourPricingService.calculateTourPackageFare(
      destination: widget.destination,
      pickupLat: _pickupLocation.latitude,
      pickupLng: _pickupLocation.longitude,
      vehicleType: overrideVehicle ?? _selectedVehicle,
      isRoundTrip: _tripType == 'round_trip',
      stayHours: _stayHours,
      passengerCount: _passengerCount,
      selectedAddonStops: _selectedAddonStops,
    );
  }

  void _checkServiceAreaAndProceed() {
    final pricing = _calculateCurrentPricing();
    if (!pricing.isServiceable) {
      TourServiceAreaModal.show(
        context: context,
        distanceKm: pricing.distanceKm,
        destinationName: widget.destination.name,
        onSelectHubCity: (hub) {
          setState(() {
            _pickupLocation = LocationModel(
              latitude: hub.latitude,
              longitude: hub.longitude,
              address: '${hub.name} City Center, ${hub.hindiName}, Jharkhand',
            );
          });
        },
        onSeeNearestPackages: () {
          context.pop();
        },
      );
      return;
    }

    HapticService.lightImpact();
    setState(() => _currentStep = 1);
  }

  void _showFareBreakdownSheet() {
    HapticService.selectionClick();
    final p = _calculateCurrentPricing();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppTokens.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusSheets)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppTokens.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Package Fare Breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTokens.ink),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTokens.primaryTint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'ALL INCLUSIVE',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTokens.primaryDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildBreakdownRow('Base Package Fare (${_tripType == 'round_trip' ? 'Round Trip' : 'One Way'})', '₹${p.basePackageFare.round()}'),
            if (p.extraWaitingFare > 0)
              _buildBreakdownRow('Extra Waiting Time (${_stayHours - 1} hr extra)', '+₹${p.extraWaitingFare.round()}'),
            if (p.nearbyStopsFare > 0)
              _buildBreakdownRow('Nearby Added Stops (${_selectedAddonStops.length})', '+₹${p.nearbyStopsFare.round()}'),
            _buildBreakdownRow('Driver & Fuel Allowance', 'Included in Package'),
            _buildBreakdownRow('Tolls, State Taxes & Parking', 'Included / ₹0 extra'),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: AppTokens.border, height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Guaranteed Fare', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTokens.ink)),
                    Text('₹${p.perPersonFare.round()} / person for $_passengerCount riders', style: const TextStyle(fontSize: 12, color: AppTokens.secondaryText)),
                  ],
                ),
                Text(
                  '₹${p.totalFare.round()}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTokens.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(String title, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 13.5, color: AppTokens.secondaryText, fontWeight: FontWeight.w500))),
          Text(amount, style: const TextStyle(fontSize: 13.5, color: AppTokens.ink, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  void _showChangePickupModal() {
    HapticService.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppTokens.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusSheets)),
        ),
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppTokens.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Choose Tour Pickup Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTokens.ink)),
            const SizedBox(height: 12),
            const Text('Major Hub Cities in Jharkhand:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTokens.secondaryText)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TourPricingService.hubCities.map((hub) {
                final isSelected = _pickupLocation.address.contains(hub.name);
                return ActionChip(
                  onPressed: () {
                    HapticService.selectionClick();
                    setState(() {
                      _pickupLocation = LocationModel(
                        latitude: hub.latitude,
                        longitude: hub.longitude,
                        address: '${hub.name} City Center, ${hub.hindiName}, Jharkhand',
                      );
                    });
                    Navigator.pop(ctx);
                  },
                  backgroundColor: isSelected ? AppTokens.primaryTint : Colors.white,
                  side: BorderSide(color: isSelected ? AppTokens.primary : AppTokens.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  label: Text(
                    '${hub.name} (${hub.hindiName})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? AppTokens.primaryDark : AppTokens.ink,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmBooking() {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the booking terms to proceed')),
      );
      return;
    }

    HapticService.success();
    setState(() => _isBookingConfirmed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isBookingConfirmed) {
      return _buildBookingConfirmationScreen();
    }

    final pricing = _calculateCurrentPricing();

    return Scaffold(
      backgroundColor: AppTokens.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTokens.ink),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.pop();
              }
            }
          },
        ),
        title: Column(
          children: [
            const Text(
              'Plan Your Tour',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppTokens.ink),
            ),
            Text(
              widget.destination.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTokens.primary),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 1. Persistent 3-Step Progress Bar
              _buildStepIndicator(),

              // Step Content Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                  child: _buildCurrentStepContent(pricing),
                ),
              ),
            ],
          ),

          // 2. Sticky Bottom Bar on EVERY Step (Rolling total + Breakdown + Primary Button)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildStickyBottomActionBar(pricing),
          ),
        ],
      ),
    );
  }

  /// Persistent 3-Step Indicator
  Widget _buildStepIndicator() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepItem(0, '1. Trip Details'),
              _buildStepDivider(0),
              _buildStepItem(1, '2. Vehicle'),
              _buildStepDivider(1),
              _buildStepItem(2, '3. Review'),
            ],
          ),
          const SizedBox(height: 8),
          // Mini Persistent Summary Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTokens.surface2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.destination.name} · ${_tripType == 'round_trip' ? 'Round Trip' : 'One Way'}',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppTokens.secondaryText),
                ),
                Text(
                  DateFormat('dd MMM').format(_selectedDate),
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppTokens.primaryDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(int stepIndex, String title) {
    final isActive = _currentStep == stepIndex;
    final isDone = _currentStep > stepIndex;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isDone || isActive ? AppTokens.primary : AppTokens.border,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                : Text(
                    '${stepIndex + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isActive ? Colors.white : AppTokens.secondaryText,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
            color: isActive ? AppTokens.primaryDark : AppTokens.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider(int afterStep) {
    final isPassed = _currentStep > afterStep;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: isPassed ? AppTokens.primary : AppTokens.border,
      ),
    );
  }

  Widget _buildCurrentStepContent(TourPricingBreakdown pricing) {
    switch (_currentStep) {
      case 0:
        return _buildStep1Trip(pricing);
      case 1:
        return _buildStep2Vehicle(pricing);
      case 2:
      default:
        return _buildStep3Review(pricing);
    }
  }

  /// Step 1: TRIP (Destination mini card, collapsed pickup with Change, Trip Type, Waiting stepper, Add-on stops)
  Widget _buildStep1Trip(TourPricingBreakdown pricing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Destination Mini Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTokens.border),
            boxShadow: AppTokens.softCardShadow,
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: (widget.destination.imageUrl.isNotEmpty && widget.destination.imageUrl.startsWith('http'))
                      ? Image.network(
                          widget.destination.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const BrandedDestinationPlaceholder(),
                        )
                      : const BrandedDestinationPlaceholder(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.destination.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTokens.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${pricing.distanceKm.round()} km · ${pricing.durationText}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTokens.primary),
                    ),
                    Text(
                      widget.destination.district,
                      style: const TextStyle(fontSize: 12, color: AppTokens.secondaryText),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Route Card with Single-Line Pickup & "Change" Button (Rule 0d)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTokens.border),
            boxShadow: AppTokens.softCardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tour Route & Pickup',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTokens.ink),
              ),
              const SizedBox(height: 12),
              // Pickup row with Change button
              Row(
                children: [
                  const Icon(Icons.radio_button_checked_rounded, color: AppTokens.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pickup Location', style: TextStyle(fontSize: 11, color: AppTokens.hint)),
                        Text(
                          _pickupLocation.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppTokens.ink),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _showChangePickupModal,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTokens.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                    child: const Text('Change', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(left: 10),
                child: SizedBox(
                  height: 18,
                  child: VerticalDivider(color: AppTokens.border, thickness: 1.5),
                ),
              ),
              // Destination Row
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: AppTokens.terracotta, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Destination', style: TextStyle(fontSize: 11, color: AppTokens.hint)),
                        Text(
                          widget.destination.locationAddress.isNotEmpty ? widget.destination.locationAddress : widget.destination.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppTokens.ink),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Trip Type Selection (Round trip RECOMMENDED vs One Way)
        const Text(
          'Select Trip Type',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTokens.ink),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildTripTypeCard(
                type: 'round_trip',
                title: 'Round Trip',
                subtitle: 'Includes Return & Wait',
                badge: 'RECOMMENDED',
                icon: Icons.sync_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTripTypeCard(
                type: 'one_way',
                title: 'One Way Drop',
                subtitle: 'Direct drop at destination',
                badge: null,
                icon: Icons.arrow_forward_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Waiting Time Stepper (1h free, +1h increments)
        if (_tripType == 'round_trip') ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTokens.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Destination Waiting Time', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTokens.ink)),
                    Text(
                      _stayHours == 1 ? '1 hour wait is included free' : '$_stayHours hours total (${_stayHours - 1}h extra waiting)',
                      style: const TextStyle(fontSize: 12, color: AppTokens.secondaryText),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded, color: AppTokens.secondaryText),
                      onPressed: _stayHours > 1
                          ? () {
                              HapticService.selectionClick();
                              setState(() => _stayHours--);
                            }
                          : null,
                    ),
                    Text(
                      '$_stayHours hr',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTokens.ink),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded, color: AppTokens.primary),
                      onPressed: _stayHours < 8
                          ? () {
                              HapticService.selectionClick();
                              setState(() => _stayHours++);
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],

        // Optional Add Nearby Stops
        if (widget.destination.nearbyStops.isNotEmpty) ...[
          const Text(
            'Add Nearby Attractions (Optional)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTokens.ink),
          ),
          const SizedBox(height: 8),
          ...widget.destination.nearbyStops.map((stop) {
            final isAdded = _selectedAddonStops.any((s) => s['id'] == stop['id']);
            return CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: AppTokens.primary,
              title: Text(stop['name'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTokens.ink)),
              subtitle: Text('+${stop['distanceKm']} km · +₹${stop['fare']}', style: const TextStyle(fontSize: 12, color: AppTokens.primary, fontWeight: FontWeight.w600)),
              value: isAdded,
              onChanged: (val) {
                HapticService.selectionClick();
                setState(() {
                  if (val == true) {
                    _selectedAddonStops.add(stop);
                  } else {
                    _selectedAddonStops.removeWhere((s) => s['id'] == stop['id']);
                  }
                });
              },
            );
          }),
        ],
      ],
    );
  }

  Widget _buildTripTypeCard({
    required String type,
    required String title,
    required String subtitle,
    required String? badge,
    required IconData icon,
  }) {
    final isSelected = _tripType == type;

    return GestureDetector(
      onTap: () {
        HapticService.selectionClick();
        setState(() => _tripType = type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppTokens.primaryTint : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppTokens.primary : AppTokens.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppTokens.elevationGlow : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: isSelected ? AppTokens.primaryDark : AppTokens.secondaryText, size: 20),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTokens.marigold,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTokens.ink),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isSelected ? AppTokens.primaryDark : AppTokens.ink)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppTokens.secondaryText)),
          ],
        ),
      ),
    );
  }

  /// Step 2: VEHICLE (Capacity stepper filter, vehicle cards with ETA, badge, and per-person price)
  Widget _buildStep2Vehicle(TourPricingBreakdown currentPricing) {
    final vehicles = [
      {
        'id': 'auto',
        'name': 'District Auto',
        'capacity': 3,
        'tag': 'Best Value',
        'desc': '3 Seats · Village roads & local sights',
        'eta': 'Arrives in 5 min',
      },
      {
        'id': 'mini',
        'name': 'District Mini Cab',
        'capacity': 4,
        'tag': 'Most Popular',
        'desc': '4 Seats · AC · 2 Luggage Bags',
        'eta': 'Arrives in 7 min',
      },
      {
        'id': 'sedan',
        'name': 'Prime Sedan (Dzire)',
        'capacity': 4,
        'tag': 'Family Choice',
        'desc': '4 Seats · AC · Spacious Boot Space',
        'eta': 'Arrives in 8 min',
      },
      {
        'id': 'suv',
        'name': 'Bolero / Scorpio SUV',
        'capacity': 7,
        'tag': 'Hill & Forest Choice',
        'desc': '6-7 Seats · AC · High Ground Clearance',
        'eta': 'Arrives in 12 min',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Passenger Stepper at the top
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTokens.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Number of Passengers', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTokens.ink)),
                  Text('Filters vehicles that fit your group', style: TextStyle(fontSize: 12, color: AppTokens.secondaryText)),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded, color: AppTokens.secondaryText),
                    onPressed: _passengerCount > 1
                        ? () {
                            HapticService.selectionClick();
                            setState(() => _passengerCount--);
                          }
                        : null,
                  ),
                  Text(
                    '$_passengerCount',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTokens.ink),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppTokens.primary),
                    onPressed: _passengerCount < 7
                        ? () {
                            HapticService.selectionClick();
                            setState(() {
                              _passengerCount++;
                              // Auto cannot fit > 3
                              if (_passengerCount > 3 && _selectedVehicle == 'auto') {
                                _selectedVehicle = 'mini';
                              }
                              // Mini/Sedan cannot fit > 4
                              if (_passengerCount > 4 && (_selectedVehicle == 'mini' || _selectedVehicle == 'sedan')) {
                                _selectedVehicle = 'suv';
                              }
                            });
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        const Text(
          'Available Tour Vehicles',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTokens.ink),
        ),
        const SizedBox(height: 10),

        ...vehicles.map((v) {
          final id = v['id'] as String;
          final capacity = v['capacity'] as int;
          final isCapacitySufficient = _passengerCount <= capacity;
          final isSelected = _selectedVehicle == id && isCapacitySufficient;
          final p = _calculateCurrentPricing(id);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: isCapacitySufficient
                  ? () {
                      HapticService.selectionClick();
                      setState(() => _selectedVehicle = id);
                    }
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCapacitySufficient
                      ? (isSelected ? AppTokens.primaryTint : Colors.white)
                      : AppTokens.surface2.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTokens.primary : AppTokens.border,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected ? AppTokens.elevationGlow : AppTokens.softCardShadow,
                ),
                child: Row(
                  children: [
                    // Vehicle Icon / Badge
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : AppTokens.surface2,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        id == 'auto'
                            ? Icons.electric_rickshaw_rounded
                            : (id == 'suv' ? Icons.directions_car_filled_rounded : Icons.directions_car_rounded),
                        size: 30,
                        color: isCapacitySufficient ? AppTokens.primaryDark : AppTokens.hint,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                v['name'] as String,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isCapacitySufficient ? AppTokens.ink : AppTokens.hint,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTokens.marigoldTint,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  v['tag'] as String,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTokens.ink),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isCapacitySufficient
                                ? '${v['desc']} · ${v['eta']}'
                                : 'Fits up to $capacity passengers (Group is $_passengerCount)',
                            style: TextStyle(
                              fontSize: 12,
                              color: isCapacitySufficient ? AppTokens.secondaryText : AppTokens.error,
                              fontWeight: isCapacitySufficient ? FontWeight.w500 : FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Fare column
                    if (isCapacitySufficient)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${p.totalFare.round()}',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppTokens.primary),
                          ),
                          if (_passengerCount > 1)
                            Text(
                              '₹${p.perPersonFare.round()}/person',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTokens.secondaryText),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  /// Step 3: REVIEW (14-day horizontal date strip, time chips, payment method, all-inclusive fare card)
  Widget _buildStep3Review(TourPricingBreakdown pricing) {
    final now = DateTime.now();
    final dates = List.generate(14, (i) => now.add(Duration(days: i)));
    final times = ['Now', '06:00 AM', '08:00 AM', '10:00 AM', '02:00 PM'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horizontal Date Strip (14 days)
        const Text('Select Departure Date', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTokens.ink)),
        const SizedBox(height: 10),
        SizedBox(
          height: 68,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: dates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, idx) {
              final d = dates[idx];
              final isSel = d.day == _selectedDate.day && d.month == _selectedDate.month;

              return GestureDetector(
                onTap: () {
                  HapticService.selectionClick();
                  setState(() => _selectedDate = d);
                },
                child: Container(
                  width: 58,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSel ? AppTokens.primary : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSel ? AppTokens.primary : AppTokens.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('E').format(d).toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSel ? Colors.white70 : AppTokens.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${d.day}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isSel ? Colors.white : AppTokens.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),

        // Departure Time Chips
        const Text('Departure Time', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTokens.ink)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: times.map((t) {
            final isSel = _selectedTime == t;
            return ChoiceChip(
              label: Text(t),
              selected: isSel,
              selectedColor: AppTokens.primary,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                fontWeight: FontWeight.w700,
                color: isSel ? Colors.white : AppTokens.ink,
              ),
              side: BorderSide(color: isSel ? AppTokens.primary : AppTokens.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (val) {
                HapticService.selectionClick();
                setState(() => _selectedTime = t);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 18),

        // Payment Method Options
        const Text('Payment Method', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTokens.ink)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildPaymentTile('cash', 'Cash to Driver', Icons.money_rounded)),
            const SizedBox(width: 8),
            Expanded(child: _buildPaymentTile('upi', 'UPI / QR Code', Icons.qr_code_2_rounded)),
            const SizedBox(width: 8),
            Expanded(child: _buildPaymentTile('advance', 'Pay 20% Advance', Icons.account_balance_wallet_rounded)),
          ],
        ),
        const SizedBox(height: 18),

        // Notes for Driver
        TextField(
          controller: _pickupNoteCtrl,
          decoration: InputDecoration(
            labelText: 'Pickup Note / Landmark for Driver (Optional)',
            hintText: 'e.g. Near Shiv Mandir, Gate 2',
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 18),

        // Fare Card in Dark Forest Gradient (Rule 4: NOT teal/blue)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppTokens.darkForestGradient,
            borderRadius: BorderRadius.circular(AppTokens.radiusCards),
            boxShadow: AppTokens.softCardShadow,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Tour Package Fare', style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        '₹${pricing.totalFare.round()}',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTokens.marigold,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'FIXED PRICE · NO SURGE',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: AppTokens.ink),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Vehicle: ${_selectedVehicle.toUpperCase()}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  Text('Trip: ${_tripType == 'round_trip' ? 'Round Trip' : 'One Way'}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Cancellation & Terms
        Row(
          children: const [
            Icon(Icons.lock_clock_rounded, color: AppTokens.primary, size: 16),
            SizedBox(width: 8),
            Text('Free cancellation up to 2 hours before trip departure', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTokens.secondaryText)),
          ],
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          activeColor: AppTokens.primary,
          title: const Text('I agree to District Car travel terms & verified rural safety guidelines', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTokens.ink)),
          value: _agreedToTerms,
          onChanged: (val) => setState(() => _agreedToTerms = val ?? true),
        ),
      ],
    );
  }

  Widget _buildPaymentTile(String id, String title, IconData icon) {
    final isSel = _paymentMethod == id;
    return GestureDetector(
      onTap: () {
        HapticService.selectionClick();
        setState(() => _paymentMethod = id);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSel ? AppTokens.primaryTint : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSel ? AppTokens.primary : AppTokens.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSel ? AppTokens.primary : AppTokens.secondaryText, size: 22),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                color: isSel ? AppTokens.primaryDark : AppTokens.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sticky Bottom Action Bar on EVERY Step
  Widget _buildStickyBottomActionBar(TourPricingBreakdown pricing) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(color: Color.fromRGBO(28, 27, 24, 0.12), blurRadius: 20, offset: Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          // Total Fare with Breakdown Tap
          GestureDetector(
            onTap: _showFareBreakdownSheet,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '₹${pricing.totalFare.round()}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTokens.ink),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.info_outline_rounded, size: 16, color: AppTokens.primary),
                  ],
                ),
                const Text('View Breakdown ↗', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTokens.primary)),
              ],
            ),
          ),
          const SizedBox(width: 20),

          // Primary Step Action Button
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (_currentStep == 0) {
                  _checkServiceAreaAndProceed();
                } else if (_currentStep == 1) {
                  HapticService.lightImpact();
                  setState(() => _currentStep = 2);
                } else {
                  _confirmBooking();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTokens.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                _currentStep == 0
                    ? 'Select Vehicle'
                    : (_currentStep == 1 ? 'Review Trip' : 'Confirm & Book'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Booking Confirmation Screen with Confetti-lite & WhatsApp share
  Widget _buildBookingConfirmationScreen() {
    final p = _calculateCurrentPricing();

    return Scaffold(
      backgroundColor: AppTokens.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 3D Confirmation Art
              Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: AppTokens.softCardShadow,
                ),
                child: ClipOval(
                  child: Image.memory(
                    kBookingConfirmedBytes,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Tour Ride Confirmed!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTokens.ink),
              ),
              const SizedBox(height: 6),
              const Text(
                'आपकी टूर राइड सफलतापूर्वक बुक हो गई है',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTokens.primary),
              ),
              const SizedBox(height: 20),

              // Itinerary Summary Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTokens.border),
                  boxShadow: AppTokens.softCardShadow,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(widget.destination.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTokens.ink)),
                        Text('₹${p.totalFare.round()}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppTokens.primary)),
                      ],
                    ),
                    const Divider(color: AppTokens.border, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Date: ${DateFormat('dd MMM yyyy').format(_selectedDate)}', style: const TextStyle(fontSize: 13, color: AppTokens.secondaryText)),
                        Text('Time: $_selectedTime', style: const TextStyle(fontSize: 13, color: AppTokens.secondaryText)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Vehicle: ${_selectedVehicle.toUpperCase()}', style: const TextStyle(fontSize: 13, color: AppTokens.secondaryText)),
                        const Text('OTP: **** (Assigned 1h before)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTokens.marigoldDark)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // WhatsApp Share Itinerary Button
              OutlinedButton.icon(
                onPressed: () async {
                  final text = 'Tour Booked to ${widget.destination.name} on ${DateFormat('dd MMM').format(_selectedDate)} at $_selectedTime. Total Fare: ₹${p.totalFare.round()} on District Car.';
                  final url = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.share_rounded, size: 18, color: AppTokens.primary),
                label: const Text('Share Itinerary on WhatsApp', style: TextStyle(color: AppTokens.primary, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  side: const BorderSide(color: AppTokens.primary, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),

              // Return Home Button
              ElevatedButton(
                onPressed: () => context.go('/'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTokens.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Back to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
