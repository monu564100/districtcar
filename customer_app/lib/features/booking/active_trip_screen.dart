import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import 'package:district_car_shared/models/models.dart';
import 'package:url_launcher/url_launcher.dart';
import 'booking_service.dart';
import 'waiting/booking_waiting_view.dart';

class ActiveTripScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const ActiveTripScreen({super.key, required this.bookingId});

  @override
  ConsumerState<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends ConsumerState<ActiveTripScreen> {
  String? _previousStatus;
  Timer? _searchTimer;
  int _searchElapsedSeconds = 0;
  bool _isBoostingInProgress = false;
  int _boostElapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startSearchTimer();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }

  void _startSearchTimer() {
    _searchTimer?.cancel();
    _searchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _searchElapsedSeconds++;
          if (_isBoostingInProgress) {
            _boostElapsedSeconds++;
          }
        });
        if (_searchElapsedSeconds % 10 == 0) {
          _checkBookingTimeout();
        }
      }
    });
  }

  void _checkBookingTimeout() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).get();
      if (!doc.exists) return;
      final data = doc.data() ?? {};
      final status = data['status'] as String? ?? '';
      if (status != 'searching_driver') return;

      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      // If regular booking is searching for more than 10 mins without acceptance, mark as no_driver_found
      final bool isTimedOut = createdAt != null && DateTime.now().difference(createdAt).inMinutes >= 10;

      if (isTimedOut) {
        await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).update({
          'status': 'no_driver_found',
          'closedReason': 'No driver accepted before departure threshold',
          'closedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}
  }

  Widget _buildVehicleImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return Image.asset(
        'assets/images/car_blue.jpg',
        height: 75,
        width: 100,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => const Icon(Icons.directions_car, size: 60, color: AppColors.primary),
      );
    }
    if (imagePath.startsWith('data:image')) {
      try {
        final base64String = imagePath.contains(',') ? imagePath.split(',').last : imagePath;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          height: 75,
          width: 100,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => const Icon(Icons.directions_car, size: 60, color: AppColors.primary),
        );
      } catch (_) {
        return const Icon(Icons.directions_car, size: 60, color: AppColors.primary);
      }
    }
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        height: 75,
        width: 100,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => const Icon(Icons.directions_car, size: 60, color: AppColors.primary),
      );
    }
    final assetPath = imagePath.startsWith('assets/') ? imagePath : 'assets/images/$imagePath';
    return Image.asset(
      assetPath,
      height: 75,
      width: 100,
      fit: BoxFit.cover,
      errorBuilder: (ctx, err, stack) => const Icon(Icons.directions_car, size: 60, color: AppColors.primary),
    );
  }

  Widget _buildDriverPhoto(String? photoPath) {
    if (photoPath != null && photoPath.isNotEmpty) {
      if (photoPath.startsWith('data:image')) {
        try {
          final base64String = photoPath.contains(',') ? photoPath.split(',').last : photoPath;
          final bytes = base64Decode(base64String);
          return ClipOval(
            child: Image.memory(bytes, width: 58, height: 58, fit: BoxFit.cover),
          );
        } catch (_) {}
      } else if (photoPath.startsWith('http://') || photoPath.startsWith('https://')) {
        return ClipOval(
          child: Image.network(
            photoPath,
            width: 58,
            height: 58,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.person, color: AppColors.primary, size: 34),
          ),
        );
      }
    }
    return const Center(
      child: Icon(Icons.person, color: AppColors.primary, size: 34),
    );
  }
  void _callDriver(String? phoneNumber) async {
    final phone = (phoneNumber != null && phoneNumber.trim().isNotEmpty)
        ? phoneNumber.trim()
        : '+91 87896 01387';
    // Remove all whitespace, hyphens, parentheses to satisfy Android intent filter & RFC 3966
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Dialer: $phone')),
          );
        }
      }
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Ride?'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Ride'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(bookingServiceProvider).cancelBooking(
                  widget.bookingId,
                  'Customer requested cancellation',
                );
                if (mounted) context.go('/');
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to cancel: $e')),
                  );
                }
              }
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(String driverId) {
    int rating = 5;
    final reviewCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Rate Your Driver'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () => setDialogState(() => rating = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reviewCtrl,
                decoration: const InputDecoration(hintText: 'Leave a comment (optional)'),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(bookingServiceProvider).submitRating(
                  bookingId: widget.bookingId,
                  targetUserId: driverId,
                  rating: rating,
                  review: reviewCtrl.text.trim(),
                );
                if (mounted) context.go('/');
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).snapshots(),
      builder: (context, snapshot) {
        final Map<String, dynamic> rawData = (snapshot.hasData && snapshot.data?.data() != null)
            ? snapshot.data!.data() as Map<String, dynamic>
            : <String, dynamic>{};
        BookingModel booking;
        if (rawData.isNotEmpty) {
          booking = BookingModel.fromMap(rawData, widget.bookingId);
        } else {
          // Fallback initial booking representation
          booking = BookingModel(
            id: widget.bookingId,
            readableId: widget.bookingId.startsWith('DC-') ? widget.bookingId : 'DC-884920',
            customerId: 'customer',
            driverId: null,
            vehicleCategoryId: 'car',
            pickup: LocationModel(latitude: 23.3441, longitude: 85.3096, address: 'Albert Ekka Chowk, Ranchi'),
            destination: LocationModel(latitude: 23.2845, longitude: 85.3218, address: 'Birsa Munda Airport, Ranchi'),
            estimatedDistanceKm: 8.5,
            estimatedDurationMinutes: 24.0,
            estimatedFare: 220.0,
            paymentMethod: 'cash',
            paymentStatus: 'pending',
            status: 'searching_driver',
            rideOtp: '4829',
            isRoundTrip: false,
            roundTripStoppingHours: 1.0,
            scheduledDate: 'Today',
            scheduledTimeSlot: 'Now',
            createdAt: DateTime.now(),
          );
        }

        if (booking.status != _previousStatus) {
          final oldStatus = _previousStatus;
          _previousStatus = booking.status;
          if (oldStatus != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (booking.status == 'driver_assigned') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('🎉 Booking Accepted! ${booking.driverName ?? "Driver"} is coming to pick you up.'),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFF16A34A),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 4),
                  ),
                );
              } else if (booking.status == 'trip_started') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.directions_car, color: Colors.white),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text('🚗 Trip Started! Enjoy your ride with District Car.'),
                        ),
                      ],
                    ),
                    backgroundColor: Color(0xFF2563EB),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else if (booking.status == 'trip_completed') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.verified, color: Colors.white),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text('✅ Trip Completed! Hope you had a pleasant experience.'),
                        ),
                      ],
                    ),
                    backgroundColor: Color(0xFF059669),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            });
          }
        }

        final isSearching = booking.status == 'searching_driver' || booking.driverId == null;

        if (isSearching) {
          return BookingWaitingView(
            booking: booking,
            rawData: rawData,
            onCancelConfirmed: (reason) async {
              await ref.read(bookingServiceProvider).cancelBooking(widget.bookingId, reason);
              if (mounted) context.go('/');
            },
            onRetrySearch: () async {
              await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).update({
                'status': 'searching_driver',
                'createdAt': FieldValue.serverTimestamp(),
              });
            },
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFFAF8F4),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1C1B18),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.readableId,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const Text(
                  'Booking Confirmed',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E9E5B),
                  ),
                ),
              ],
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/'),
            ),
          ),
          body: _buildBookingAcceptedView(booking),
        );
      },
    );
  }

  /// 1. DEDICATED PENDING SEARCHING PAGE (WITH FINDING -> BOOST -> URGENT BOOKING FLOW)
  Widget _buildPendingSearchingView(BookingModel booking, Map<String, dynamic> rawData) {
    // Check if booking has timed out or expired
    if (booking.status == 'no_driver_found' || booking.status == 'expired') {
      return _buildNoRideFoundView(booking);
    }

    final double searchRadius = (rawData['searchRadiusKm'] as num?)?.toDouble() ?? 12.0;
    final int matchedDrivers = (rawData['matchedDriversCount'] as num?)?.toInt() ?? 0;
    final bool isFareBoosted = rawData['fareBoost'] != null || _isBoostingInProgress;

    // Check if initial finding stage is active (first 6 seconds after booking)
    final bool isInitialFinding = _searchElapsedSeconds < 6;

    // Check if boosted finding stage is active (first 6 seconds after boosting)
    final bool isBoostFinding = _isBoostingInProgress && _boostElapsedSeconds < 6;

    // Phase 1: Show Finding (either initial search or boosted search)
    if (isInitialFinding || isBoostFinding) {
      return _buildFindingView(
        booking: booking,
        isBoosted: isFareBoosted,
        searchRadius: isFareBoosted ? 25.0 : searchRadius,
      );
    }

    // Phase 2: If no drivers found in 10-12 km and NOT yet boosted:
    // Show unserviceable image + Boost Fare Button (+₹80)
    if (!isFareBoosted && (matchedDrivers == 0 || _searchElapsedSeconds >= 6)) {
      return _buildUnserviceableWithBoostButtonView(booking, searchRadius);
    }

    // Phase 3: If boosted AND still no drivers found after boosted finding:
    // HIDE boost button and show Urgent Booking with direct Call number!
    return _buildUrgentBookingView(booking);
  }

  /// Phase 1: Finding Drivers Radar View
  Widget _buildFindingView({
    required BookingModel booking,
    required bool isBoosted,
    required double searchRadius,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF38BDF8).withValues(alpha: 0.35),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/images/trip_radar_pulse.jpg',
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 110,
                          height: 110,
                          color: const Color(0xFF1E293B),
                          child: const Icon(Icons.radar_rounded, size: 48, color: Color(0xFF38BDF8)),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
                        ),
                        child: const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF38BDF8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.radar_rounded, size: 12, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 5),
                      Text(
                        isBoosted
                            ? 'EXPANDED 20-25 KM DRIVER RADAR ACTIVE'
                            : 'SEARCHING ${searchRadius.toInt()} KM NEARBY RADIUS',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Color(0xFF38BDF8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isBoosted ? 'Broadcasting to Outlying Drivers' : 'Finding Drivers Nearby...',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isBoosted
                      ? 'Fare boosted by ₹80! Connecting to drivers across outer blocks up to 25 km.'
                      : 'Searching for available cabs within 10-12 km of your pickup in Khunti / Murhu...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8), height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildTripSummaryCard(booking),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _showCancelDialog,
              child: const Text('Cancel Ride', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  /// Phase 2: Unserviceable In Immediate Radius + Boost Fare Button (+₹80)
  Widget _buildUnserviceableWithBoostButtonView(BookingModel booking, double searchRadius) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          // 3D Illustration
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              'assets/images/unserviceable_area_3d.jpg',
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.location_off_rounded, size: 70, color: Color(0xFF64748B)),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF59E0B)),
            ),
            child: const Text(
              'NO DRIVERS WITHIN 10-12 KM',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFFB45309),
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'No Drivers Nearby in 10-12 km',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'निकटवर्ती 10-12 किमी में कोई चालक उपलब्ध नहीं है',
            style: TextStyle(fontSize: 13, color: Color(0xFFB45309), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'All nearby drivers in your immediate village/block are currently busy. You can boost fare (+₹80) to find drivers in 20-25 km radius.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, height: 1.45),
          ),
          const SizedBox(height: 20),

          // Boost Fare Button Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Expand Search to 20-25 km',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF92400E)),
                          ),
                          Text(
                            'Fare Boost: +₹80 (covers driver arrival distance)',
                            style: TextStyle(fontSize: 11.5, color: Colors.amber.shade900),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                    label: const Text(
                      'Boost Fare (+₹80) & Find Drivers',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
                    ),
                    onPressed: () async {
                      final currentFare = booking.estimatedFare;
                      const boostAmount = 80.0;
                      final newFare = currentFare + boostAmount;

                      setState(() {
                        _isBoostingInProgress = true;
                        _boostElapsedSeconds = 0;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fare boosted! Expanding search to 20-25 km radius... 🚀'),
                          backgroundColor: Color(0xFFD97706),
                        ),
                      );

                      await ref.read(bookingServiceProvider).expandSearchRadiusWithHigherFare(
                        bookingId: widget.bookingId,
                        additionalFare: boostAmount,
                        newTotalFare: newFare,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildTripSummaryCard(booking),
          const SizedBox(height: 20),

          // Cancel Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _showCancelDialog,
              child: const Text('Cancel Ride', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text('Back to Home Screen', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  /// Phase 3: Boosted but Still Not Found -> Hide Boost Button, Show Urgent Booking & Call Number!
  Widget _buildUrgentBookingView(BookingModel booking) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 3D Illustration
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              'assets/images/unserviceable_area_3d.jpg',
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.location_off_rounded, size: 70, color: Color(0xFF64748B)),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEF4444)),
            ),
            child: const Text(
              'UNSERVICEABLE IN THIS RADIUS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFFB91C1C),
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'All Online Cabs Are Currently Busy',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'इस क्षेत्र में कोई भी ऑनलाइन कैब उपलब्ध नहीं है',
            style: TextStyle(fontSize: 13, color: Color(0xFFB91C1C), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'We checked all drivers up to 25 km in nearby blocks. You can arrange an offline vehicle via our 24/7 Control Room helpline.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, height: 1.45),
          ),
          const SizedBox(height: 20),

          // URGENT BOOKING CALL DESK CARD (BOOST BUTTON IS HIDDEN)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF16A34A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Need Urgent Ride? / जरूरी बुकिंग',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF14532D)),
                          ),
                          Text(
                            'District Car Central Dispatch Desk',
                            style: TextStyle(fontSize: 12, color: Color(0xFF166534), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Call our Jharkhand control room directly. Our dispatcher will connect you with available stand drivers offline.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF166534), height: 1.4),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.call, size: 20),
                    label: const Text(
                      'Call Helpline: +91 87896 01387',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                    onPressed: () => _callDriver('+91 87896 01387'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Return Home Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => context.go('/'),
              child: const Text('Back to Home Screen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _showCancelDialog,
            child: const Text('Cancel Ride Request', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  /// No Ride Found View (If Not Accepted Before Scheduled Time)
  Widget _buildNoRideFoundView(BookingModel booking) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              'assets/images/unserviceable_area_3d.jpg',
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.event_busy_rounded, size: 70, color: Color(0xFF64748B)),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEF4444)),
            ),
            child: const Text(
              'NO RIDE FOUND BEFORE SCHEDULED TIME',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                color: Color(0xFFB91C1C),
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No Ride Found',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'समय से पूर्व कोई चालक उपलब्ध नहीं मिला',
            style: TextStyle(fontSize: 13, color: Color(0xFFB91C1C), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'We could not find an available driver before your scheduled departure time (${booking.scheduledDate ?? "Today"} - ${booking.scheduledTimeSlot ?? "Now"}). No fare was charged.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.45),
          ),
          const SizedBox(height: 24),
          // Urgent Helpline Card
          Container(
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
                  child: const Icon(Icons.phone, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Need Immediate Assistance?',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF14532D)),
                      ),
                      Text(
                        'Call Helpline: +91 87896 01387',
                        style: TextStyle(fontSize: 12, color: Color(0xFF166534), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => context.go('/'),
              child: const Text('Back to Home Screen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  /// 2. BOOKING ACCEPTED & SUCCESS PAGE
  Widget _buildBookingAcceptedView(BookingModel booking) {
    final driverName = booking.driverName ?? 'Ramesh Mahto (रमेश महतो)';
    final driverPhone = booking.driverPhone ?? '+91 94311 23456';
    final vehiclePlate = booking.vehiclePlate ?? 'JH 01 BZ 4892';
    final vehicleModel = booking.vehicleModel ?? 'Maruti Suzuki Dzire AC';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner: Booking Accepted & Success
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFDCFCE7), Color(0xFFBBF7D0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFF16A34A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BOOKING ACCEPTED & SUCCESS!',
                        style: TextStyle(
                          color: Color(0xFF15803D),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'बुकिंग स्वीकार कर ली गई है',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF14532D),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Driver is on the way to pick you up',
                        style: TextStyle(fontSize: 12, color: Color(0xFF166534)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Vehicle Card (Car image & Registration Number Plate)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ASSIGNED VEHICLE',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          vehicleModel,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        // Indian High Security Number Plate Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF08A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black, width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E3A8A),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text(
                                  'IND',
                                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                vehiclePlate,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildVehicleImage(booking.vehicleImage),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Driver Profile & Call Button Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                // Driver photo avatar
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E7FF),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: _buildDriverPhoto(booking.driverPhoto),
                ),
                const SizedBox(width: 14),
                // Driver Name & Rating
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'YOUR DRIVER',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        driverName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          SizedBox(width: 4),
                          Text(
                            '4.9 · Verified Partner',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Call Driver Icon Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _callDriver(driverPhone),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF22C55E).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Icon(Icons.call, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // OTP Card for Ride Start
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF3B82F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RIDE START OTP',
                        style: TextStyle(color: Color(0xFF1D4ED8), fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'OTP: ${booking.rideOtp ?? "4829"}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      const Text(
                        'Share this OTP with driver only when entering vehicle',
                        style: TextStyle(fontSize: 11, color: Color(0xFF3B82F6)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Trip Route & Timing Summary Card
          _buildTripSummaryCard(booking),
          const SizedBox(height: 24),

          // Cancel or Completed Action
          if (booking.status != 'trip_completed') ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _showCancelDialog,
                child: const Text('Cancel Ride', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => _showRatingDialog(booking.driverId ?? 'driver'),
                child: const Text('Rate Your Driver ⭐', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTripSummaryCard(BookingModel booking) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: booking.isRoundTrip ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: booking.isRoundTrip ? const Color(0xFFA7F3D0) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Text(
                      booking.isRoundTrip ? '🔄 Round Trip (दो तरफा)' : '➡️ One-Way (एक तरफा)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: booking.isRoundTrip ? const Color(0xFF047857) : const Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                '₹${booking.finalFare ?? booking.estimatedFare}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Scheduled Date & Time Slot
          if (booking.scheduledDate != null || booking.scheduledTimeSlot != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    '${booking.scheduledDate ?? "Today"} · ${booking.scheduledTimeSlot ?? "Now"}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Pickup Location
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.radio_button_checked, color: AppColors.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pickup Location (कहाँ से)', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    Text(
                      booking.pickup.address,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 8.0, top: 4, bottom: 4),
            child: SizedBox(
              height: 16,
              child: VerticalDivider(color: Color(0xFFCBD5E1), thickness: 2),
            ),
          ),
          // Drop Location
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: AppColors.error, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Destination (कहाँ जाना है)', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    Text(
                      booking.destination.address,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
