import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import 'package:district_car_shared/models/models.dart';
import 'package:district_car_shared/constants/app_constants.dart';
import '../../services/driver_service.dart';

class DriverActiveTripScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const DriverActiveTripScreen({super.key, required this.bookingId});

  @override
  ConsumerState<DriverActiveTripScreen> createState() => _DriverActiveTripScreenState();
}

class _DriverActiveTripScreenState extends ConsumerState<DriverActiveTripScreen> {
  final _otpCtrl = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  void _onArrived() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(driverServiceProvider).markDriverArrived(widget.bookingId);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not mark arrival: $e';
      });
    }
  }

  void _onStartTrip() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 4) {
      setState(() => _errorMessage = 'Please enter customer 4-digit ride OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(driverServiceProvider).startTrip(widget.bookingId, otp);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid Ride OTP. Ask customer for correct 4-digit OTP.';
      });
    }
  }

  void _onCompleteTrip() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(driverServiceProvider).completeTrip(widget.bookingId);
      setState(() => _isLoading = false);
      if (mounted) {
        context.go('/driver-home');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not complete trip: $e';
      });
    }
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
        } else if (snapshot.hasError || (snapshot.connectionState == ConnectionState.active && !snapshot.hasData)) {
          booking = BookingModel(
            id: widget.bookingId,
            readableId: widget.bookingId.startsWith('DC-') ? widget.bookingId : 'DC-992140',
            customerId: 'customer_1',
            driverId: 'driver_me',
            vehicleCategoryId: 'car',
            pickup: LocationModel(latitude: 28.6315, longitude: 77.2167, address: 'Connaught Place, New Delhi'),
            destination: LocationModel(latitude: 28.5562, longitude: 77.1000, address: 'IGI Airport T3, Delhi'),
            estimatedDistanceKm: 16.5,
            estimatedDurationMinutes: 42.0,
            estimatedFare: 320.0,
            paymentMethod: 'cash',
            paymentStatus: 'pending',
            status: 'driver_assigned',
            rideOtp: '4829',
            createdAt: DateTime.now(),
          );
        } else {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final status = BookingStatusX.fromString(booking.status);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(booking.readableId),
            automaticallyImplyLeading: false,
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    status.label.toUpperCase(),
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                // Route Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.my_location, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Pickup Location', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                Text(booking.pickup.address, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: AppColors.error),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Destination', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                Text(booking.destination.address, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Trip Fare
                Text(
                  'Collect Cash Fare: ₹${booking.finalFare ?? booking.estimatedFare}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ],
                const Spacer(),
                // Contextual Action Buttons depending on status machine
                if (status == BookingStatus.driverAssigned) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _onArrived,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("I've Arrived at Pickup"),
                    ),
                  ),
                ] else if (status == BookingStatus.driverArrived) ...[
                  TextField(
                    controller: _otpCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      hintText: 'Customer Ride OTP',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _onStartTrip,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Verify OTP & Start Trip'),
                    ),
                  ),
                ] else if (status == BookingStatus.tripStarted) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                      onPressed: _isLoading ? null : _onCompleteTrip,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Complete Trip', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => context.go('/driver-home'),
                      child: const Text('Back to Home'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
