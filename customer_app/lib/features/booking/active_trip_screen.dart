import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import 'package:district_car_shared/models/models.dart';
import 'package:url_launcher/url_launcher.dart';
import 'booking_service.dart';

class ActiveTripScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const ActiveTripScreen({super.key, required this.bookingId});

  @override
  ConsumerState<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends ConsumerState<ActiveTripScreen> {
  String? _previousStatus;

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
    final phone = (phoneNumber != null && phoneNumber.isNotEmpty) ? phoneNumber : '+91 94311 23456';
    final uri = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Calling driver at $phone')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Call driver: $phone')),
        );
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
        BookingModel booking;
        if (snapshot.hasData && snapshot.data?.data() != null) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          booking = BookingModel.fromMap(data, widget.bookingId);
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

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0F172A),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.readableId,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                Text(
                  isSearching ? 'Booking is Pending...' : 'Booking Confirmed',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSearching ? const Color(0xFFE65100) : const Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/'),
            ),
          ),
          body: isSearching
              ? _buildPendingSearchingView(booking)
              : _buildBookingAcceptedView(booking),
        );
      },
    );
  }

  /// 1. DEDICATED PENDING SEARCHING PAGE
  Widget _buildPendingSearchingView(BookingModel booking) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          // Animated Pulse / Searching Indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFDBA74), width: 1.5),
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316).withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(
                      width: 65,
                      height: 65,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        color: Color(0xFFEA580C),
                      ),
                    ),
                    const Icon(Icons.radar, size: 34, color: Color(0xFFEA580C)),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'BOOKING IS PENDING',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Color(0xFFC2410C),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'आपकी राइड पेंडिंग है...',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF7C2D12),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Searching for nearest drivers in your Jharkhand area. When a driver accepts, vehicle and driver details will appear immediately.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF9A3412), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Trip summary card
          _buildTripSummaryCard(booking),
          const SizedBox(height: 24),

          // Cancel button
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
