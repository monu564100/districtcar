import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../services/haptic_service.dart';

/// Modal bottom sheet (radius 28) summarizing route, vehicle, fare, payment & OTP preview before confirming
class BookingConfirmSheet extends StatefulWidget {
  final String pickupAddress;
  final String destinationAddress;
  final String vehicleName;
  final String vehicleImageAsset;
  final double fare;
  final double distanceKm;
  final String formattedDuration;
  final bool isRoundTrip;
  final double waitingHours;
  final String selectedDate;
  final String selectedTimeSlot;
  final String paymentMethod;
  final int passengerCount;
  final bool isHindi;

  const BookingConfirmSheet({
    super.key,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.vehicleName,
    required this.vehicleImageAsset,
    required this.fare,
    required this.distanceKm,
    required this.formattedDuration,
    required this.isRoundTrip,
    this.waitingHours = 1.0,
    required this.selectedDate,
    required this.selectedTimeSlot,
    this.paymentMethod = 'Cash / UPI',
    this.passengerCount = 1,
    this.isHindi = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String pickupAddress,
    required String destinationAddress,
    required String vehicleName,
    required String vehicleImageAsset,
    required double fare,
    required double distanceKm,
    required String formattedDuration,
    required bool isRoundTrip,
    double waitingHours = 1.0,
    required String selectedDate,
    required String selectedTimeSlot,
    String paymentMethod = 'Cash / UPI',
    int passengerCount = 1,
    bool isHindi = false,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BookingConfirmSheet(
        pickupAddress: pickupAddress,
        destinationAddress: destinationAddress,
        vehicleName: vehicleName,
        vehicleImageAsset: vehicleImageAsset,
        fare: fare,
        distanceKm: distanceKm,
        formattedDuration: formattedDuration,
        isRoundTrip: isRoundTrip,
        waitingHours: waitingHours,
        selectedDate: selectedDate,
        selectedTimeSlot: selectedTimeSlot,
        paymentMethod: paymentMethod,
        passengerCount: passengerCount,
        isHindi: isHindi,
      ),
    );
  }

  @override
  State<BookingConfirmSheet> createState() => _BookingConfirmSheetState();
}

class _BookingConfirmSheetState extends State<BookingConfirmSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusSheets)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header: Vehicle info + Fare
          Row(
            children: [
              SizedBox(
                width: 54,
                height: 44,
                child: Image.asset(
                  widget.vehicleImageAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.directions_car_rounded, size: 36, color: Color(0xFF3D2FD6)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.vehicleName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTokens.ink,
                      ),
                    ),
                    Text(
                      '${widget.distanceKm.toStringAsFixed(1)} km • ${widget.formattedDuration}',
                      style: const TextStyle(fontSize: 12, color: AppTokens.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${widget.fare.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF3D2FD6),
                    ),
                  ),
                  Text(
                    widget.paymentMethod,
                    style: const TextStyle(fontSize: 10, color: AppTokens.success, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),

          // Route Timeline Container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(AppTokens.radiusCards),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.trip_origin_rounded, size: 14, color: AppTokens.success),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.pickupAddress,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTokens.ink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(width: 2, height: 16, color: const Color(0xFFCBD5E1)),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 16, color: AppTokens.error),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.destinationAddress,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTokens.ink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Details row: Schedule + Time + Payment
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailTag(Icons.event_rounded, widget.selectedDate),
              _buildDetailTag(Icons.schedule_rounded, widget.selectedTimeSlot.split('(').first.trim()),
              _buildDetailTag(Icons.payments_rounded, widget.paymentMethod),
            ],
          ),

          const SizedBox(height: 20),

          // Primary Big Confirm Button (58h)
          SizedBox(
            width: double.infinity,
            height: AppTokens.primaryButtonHeight,
            child: ElevatedButton(
              onPressed: () {
                HapticService.bookingConfirmed();
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: const Color(0xFF0F172A).withValues(alpha: 0.25),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusButtons),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    widget.isHindi ? 'सवारी की पुष्टि करें (Confirm Ride)' : 'Confirm Booking • ₹${widget.fare.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF3D2FD6)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTokens.ink),
          ),
        ],
      ),
    );
  }
}
