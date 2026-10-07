import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import 'package:district_car_shared/models/models.dart';
import '../auth/auth_service.dart';

class TripsHistoryScreen extends ConsumerWidget {
  const TripsHistoryScreen({super.key});

  void _showTripDetailSheet(BuildContext context, BookingModel booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.readableId,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                      Text(
                        'Booking Details',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: booking.status == 'searching_driver'
                          ? const Color(0xFFFFF7ED)
                          : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: booking.status == 'searching_driver'
                            ? const Color(0xFFFDBA74)
                            : const Color(0xFF86EFAC),
                      ),
                    ),
                    child: Text(
                      booking.status.toUpperCase(),
                      style: TextStyle(
                        color: booking.status == 'searching_driver'
                            ? const Color(0xFFC2410C)
                            : const Color(0xFF15803D),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),

              // Trip Type & Scheduled Time
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: booking.isRoundTrip ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
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
                  const Spacer(),
                  const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${booking.scheduledDate ?? "Today"} · ${booking.scheduledTimeSlot ?? "Now"}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Route Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
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
                              Text(booking.pickup.address, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0, top: 4, bottom: 4),
                      child: SizedBox(
                        height: 14,
                        child: VerticalDivider(color: Color(0xFFCBD5E1), thickness: 2),
                      ),
                    ),
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
                              Text(booking.destination.address, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Vehicle & Driver Details if available
              if (booking.driverName != null || booking.vehiclePlate != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      ClipOval(
                        child: (booking.driverPhoto != null && booking.driverPhoto!.startsWith('data:image'))
                            ? Image.memory(
                                base64Decode(booking.driverPhoto!.split(',').last),
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                              )
                            : (booking.driverPhoto != null && booking.driverPhoto!.startsWith('http'))
                                ? Image.network(
                                    booking.driverPhoto!,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 48,
                                      height: 48,
                                      color: AppColors.primaryLight,
                                      child: const Icon(Icons.person, color: AppColors.primary, size: 28),
                                    ),
                                  )
                                : Container(
                                    width: 48,
                                    height: 48,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primaryLight,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.person, color: AppColors.primary, size: 28),
                                  ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.driverName ?? 'District Partner Driver',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                            Text(
                              '${booking.vehicleModel ?? "Maruti Dzire"} · ${booking.vehiclePlate ?? "JH 01 BZ 4892"}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (booking.rideOtp != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Text(
                            'OTP: ${booking.rideOtp}',
                            style: const TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Fare Breakdown
              const Text('Fare Breakdown', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              const SizedBox(height: 8),
              _buildFareRow('Base Fare', '₹50.00'),
              _buildFareRow('Distance (${booking.estimatedDistanceKm} km)', '₹${(booking.estimatedDistanceKm * 15.0).toStringAsFixed(2)}'),
              if (booking.isRoundTrip)
                _buildFareRow('Round Trip Discount (25% off return)', '- ₹${(booking.estimatedDistanceKm * 5.0).toStringAsFixed(2)}', isDiscount: true)
              else
                _buildFareRow('Village Return Guarantee Factor', '+ ₹35.00'),
              if (booking.isRoundTrip)
                _buildFareRow('Included Stopping Time (1 Hour)', 'FREE', isHighlight: true),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Fare', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  Text(
                    '₹${booking.finalFare ?? booking.estimatedFare}',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/active-trip/${booking.id}');
                  },
                  child: const Text('View Active Trip Status', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFareRow(String title, String value, {bool isDiscount = false, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: isDiscount ? const Color(0xFF047857) : AppColors.textSecondary, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: isDiscount ? const Color(0xFF047857) : (isHighlight ? AppColors.primary : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Trips')),
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.push('/login'),
            child: const Text('Sign In to view trips'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Trips (मेरी यात्राएं)'),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('customerId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          final List<BookingModel> bookings = [];

          for (final doc in docs) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              bookings.add(BookingModel.fromMap(data, doc.id));
            } catch (_) {}
          }

          if (bookings.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 14),
                    const Text('No trips found yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text('Your bookings will appear here after you book a ride.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13), textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];

              return GestureDetector(
                onTap: () => _showTripDetailSheet(context, booking),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
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
                              Text(
                                booking.readableId,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                              ),
                              const SizedBox(width: 8),
                              if (booking.isRoundTrip)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    '🔄 Round Trip',
                                    style: TextStyle(fontSize: 10, color: Color(0xFF047857), fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: booking.status == 'searching_driver'
                                  ? const Color(0xFFFFF7ED)
                                  : (booking.status == 'trip_completed' ? const Color(0xFFF1F5F9) : const Color(0xFFDCFCE7)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              booking.status == 'searching_driver' ? 'PENDING' : booking.status.toUpperCase(),
                              style: TextStyle(
                                color: booking.status == 'searching_driver'
                                    ? const Color(0xFFC2410C)
                                    : (booking.status == 'trip_completed' ? const Color(0xFF475569) : const Color(0xFF15803D)),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.radio_button_checked, color: AppColors.primary, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              booking.pickup.address,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: AppColors.error, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              booking.destination.address,
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Fare: ₹${booking.finalFare ?? booking.estimatedFare}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primary),
                          ),
                          Row(
                            children: const [
                              Text('View Details', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primary),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
