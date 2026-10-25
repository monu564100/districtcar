import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final _activeTripOtpFocusNode = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _otpCtrl.dispose();
    _activeTripOtpFocusNode.dispose();
    super.dispose();
  }

  void _callCustomer(String? phoneNumber) async {
    final phone = (phoneNumber != null && phoneNumber.trim().isNotEmpty) ? phoneNumber.trim() : '';
    if (phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer phone number not available')),
        );
      }
      return;
    }

    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(uri);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open phone dialer for: $cleanPhone')),
          );
        }
      }
    }
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
          final raw = snapshot.data!.data();
          final data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
          booking = BookingModel.fromMap(data, widget.bookingId);
        } else if (snapshot.hasError || (snapshot.connectionState == ConnectionState.active && !snapshot.hasData)) {
          booking = BookingModel(
            id: widget.bookingId,
            readableId: widget.bookingId.startsWith('DC-') || widget.bookingId.startsWith('TR-') ? widget.bookingId : 'DC-992140',
            customerId: 'customer_1',
            customerName: 'Customer',
            customerPhone: '+91 94311 00000',
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
        final isTour = booking.bookingType == 'tour' || (booking.tourDestinationName != null && booking.tourDestinationName!.isNotEmpty);
        final customerPhone = (booking.customerPhone != null && booking.customerPhone!.trim().isNotEmpty)
            ? booking.customerPhone!.trim()
            : '+91 87896 01387';

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
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                Text(
                  isTour ? '🌴 Tours & Travels Ride' : '🚖 Regular Ride',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isTour ? const Color(0xFF059669) : AppColors.primary,
                  ),
                ),
              ],
            ),
            automaticallyImplyLeading: false,
            actions: [
              // Direct 1-Tap Customer Call Action
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: IconButton(
                    tooltip: 'Call Customer',
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFECFDF5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.call, color: Color(0xFF059669), size: 20),
                    ),
                    onPressed: () => _callCustomer(customerPhone),
                  ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Badge & OTP Reminder
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: status == BookingStatus.tripStarted
                            ? const Color(0xFFDCFCE7)
                            : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: status == BookingStatus.tripStarted
                              ? const Color(0xFF86EFAC)
                              : AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        status.label.toUpperCase(),
                        style: TextStyle(
                          color: status == BookingStatus.tripStarted ? const Color(0xFF15803D) : AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (isTour)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Text(
                          booking.isRoundTrip ? '🔄 Round Trip' : '➡️ One Way',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Customer Contact Card with Direct Call Button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF059669).withValues(alpha: 0.1),
                        child: const Icon(Icons.person, color: Color(0xFF059669), size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (booking.customerName != null && booking.customerName!.isNotEmpty)
                                  ? booking.customerName!
                                  : 'District Customer',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              customerPhone,
                              style: TextStyle(
                                fontSize: 13,
                                color: const Color(0xFF475569),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: () => _callCustomer(customerPhone),
                        icon: const Icon(Icons.call, size: 16),
                        label: const Text('Call', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tour Specific Details Card (if applicable)
                if (isTour || booking.isRoundTrip || (booking.stayHours != null && booking.stayHours! > 0)) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF065F46), Color(0xFF047857)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF059669).withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.tour, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                booking.tourDestinationName ?? 'Jharkhand Tourist Destination',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white24, height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.route, color: Color(0xFF6EE7B7), size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${booking.estimatedDistanceKm} km total',
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            if (booking.isRoundTrip)
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(Icons.timer_outlined, color: Color(0xFF6EE7B7), size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${booking.stayHours ?? booking.roundTripStoppingHours.toInt()} hr Stay/Wait',
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        if (booking.scheduledDate != null || booking.scheduledTimeSlot != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_month, color: Color(0xFF6EE7B7), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Scheduled: ${booking.scheduledDate ?? "Today"} at ${booking.scheduledTimeSlot ?? "Now"}',
                                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Route Pickup & Destination Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.my_location, color: Color(0xFF059669), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Pickup Location (बैठने का स्थान)', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(booking.pickup.address, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 9.0, top: 4, bottom: 4),
                        child: SizedBox(
                          height: 14,
                          child: VerticalDivider(color: Color(0xFFCBD5E1), thickness: 2),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, color: AppColors.error, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Destination (पहुंचने का स्थान)', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(booking.destination.address, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Trip Fare & Distance Overview Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fare to Collect (${booking.paymentMethod.toUpperCase()})',
                            style: const TextStyle(color: Color(0xFF065F46), fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${(booking.finalFare ?? booking.estimatedFare).toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF047857)),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Trip Distance', style: TextStyle(color: Color(0xFF065F46), fontSize: 11, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF047857),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${booking.estimatedDistanceKm} km',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                  ),
                ],

                const SizedBox(height: 24),

                // Contextual Action Buttons depending on status machine
                if (status == BookingStatus.driverAssigned) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _isLoading ? null : _onArrived,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("I've Arrived at Pickup (पिकअप पर पहुंच गए)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ] else if (status == BookingStatus.driverArrived) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF059669).withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.pin, color: Color(0xFF059669), size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Ask customer for 4-digit Ride OTP',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF065F46)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _otpCtrl,
                          focusNode: _activeTripOtpFocusNode,
                          enabled: true,
                          readOnly: false,
                          autofocus: false,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          maxLength: 4,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 26, letterSpacing: 12, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                          decoration: InputDecoration(
                            hintText: '• • • •',
                            counterText: '',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF059669), width: 2)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _isLoading ? null : _onStartTrip,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Verify OTP & Start Trip (सत्यापित करें)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ] else if (status == BookingStatus.tripStarted) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _isLoading ? null : _onCompleteTrip,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Complete Trip (राइड समाप्त करें)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => context.go('/driver-home'),
                      child: const Text('Back to Home (होम पर जाएं)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

