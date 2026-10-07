import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import 'package:district_car_shared/models/models.dart';
import '../../services/driver_service.dart';

class IncomingRequestOverlay extends ConsumerStatefulWidget {
  final String driverId;
  final Function(BookingModel booking)? onAccepted;

  const IncomingRequestOverlay({
    super.key,
    required this.driverId,
    this.onAccepted,
  });

  @override
  ConsumerState<IncomingRequestOverlay> createState() => _IncomingRequestOverlayState();
}

class _IncomingRequestOverlayState extends ConsumerState<IncomingRequestOverlay> {
  bool _isProcessing = false;
  final Set<String> _dismissedIds = {};
  String? _lastAlertedId;

  void _accept(BookingModel booking, String? requestId) async {
    setState(() => _isProcessing = true);
    try {
      await ref.read(driverServiceProvider).acceptRide(booking.id, requestId);
      setState(() => _isProcessing = false);

      if (widget.onAccepted != null) {
        widget.onAccepted!(booking);
      } else {
        if (mounted) context.go('/driver-trip/${booking.id}');
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not accept: $e')),
        );
      }
    }
  }

  void _reject(String bookingId, String? requestId) async {
    setState(() {
      _dismissedIds.add(bookingId);
      if (requestId != null) _dismissedIds.add(requestId);
    });
    try {
      if (requestId != null) {
        await ref.read(driverServiceProvider).rejectRide(bookingId, requestId);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // 1. First listen to direct driver offers
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookingRequests')
          .where('driverId', isEqualTo: widget.driverId)
          .where('status', isEqualTo: 'offered')
          .snapshots(),
      builder: (context, requestSnap) {
        if (requestSnap.hasData && requestSnap.data!.docs.isNotEmpty) {
          final requestDoc = requestSnap.data!.docs.first;
          final reqData = requestDoc.data() as Map<String, dynamic>;
          final bookingId = reqData['bookingId'] as String;
          final requestId = requestDoc.id;

          if (!_dismissedIds.contains(bookingId) && !_dismissedIds.contains(requestId)) {
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('bookings').doc(bookingId).snapshots(),
              builder: (context, bSnap) {
                if (!bSnap.hasData || !bSnap.data!.exists) return const SizedBox.shrink();
                final bData = bSnap.data!.data() as Map<String, dynamic>;
                final status = bData['status'] as String? ?? '';
                // If ride is claimed by other, accepted, completed, or cancelled, do not show popup
                if (status != 'searching_driver' && status != 'requested') {
                  return const SizedBox.shrink();
                }
                final booking = BookingModel.fromMap(bData, bookingId);
                return _buildPopupCard(booking, requestId);
              },
            );
          }
        }

        // 2. Fallback / Universal listener: Listen to all searching_driver bookings so driver never misses a customer in Chrome!
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('status', isEqualTo: 'searching_driver')
              .limit(1)
              .snapshots(),
          builder: (context, bookingSnap) {
            if (!bookingSnap.hasData || bookingSnap.data!.docs.isEmpty) {
              return const SizedBox.shrink();
            }

            final bDoc = bookingSnap.data!.docs.first;
            final bookingId = bDoc.id;
            if (_dismissedIds.contains(bookingId)) {
              return const SizedBox.shrink();
            }

            final bData = bDoc.data() as Map<String, dynamic>;
            final booking = BookingModel.fromMap(bData, bookingId);
            return _buildPopupCard(booking, null);
          },
        );
      },
    );
  }

  Widget _buildPopupCard(BookingModel booking, String? requestId) {
    if (_lastAlertedId != booking.id) {
      _lastAlertedId = booking.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.heavyImpact();
      });
    }

    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ringing alert bell tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.notifications_active, color: Color(0xFFDC2626), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        booking.isRoundTrip ? '🔔 NEW ROUND TRIP (दो तरफा राइड)' : '🔔 NEW RIDE BOOKING (नयी बुकिंग)',
                        style: const TextStyle(
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Fare Display in ₹
                Text(
                  '₹${booking.finalFare ?? booking.estimatedFare}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF059669),
                  ),
                ),
                Text(
                  'Estimated Distance: ${booking.estimatedDistanceKm} km',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                // Date & Time Slot
                if (booking.scheduledDate != null || booking.scheduledTimeSlot != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '📅 ${booking.scheduledDate ?? "Today"} · ⏰ ${booking.scheduledTimeSlot ?? "Now"}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Route Details
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.radio_button_checked, color: Color(0xFF059669), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              booking.pickup.address,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0, top: 2, bottom: 2),
                        child: SizedBox(
                          height: 10,
                          child: VerticalDivider(color: Color(0xFFCBD5E1), thickness: 2),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: AppColors.error, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              booking.destination.address,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons: Reject & Accept
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _isProcessing ? null : () => _reject(booking.id, requestId),
                        child: const Text('REJECT', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _isProcessing ? null : () => _accept(booking, requestId),
                        child: _isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('ACCEPT RIDE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
