import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import 'package:district_car_shared/models/models.dart';
import '../../services/driver_service.dart';

class IncomingRequestOverlay extends ConsumerStatefulWidget {
  final String driverId;

  const IncomingRequestOverlay({super.key, required this.driverId});

  @override
  ConsumerState<IncomingRequestOverlay> createState() => _IncomingRequestOverlayState();
}

class _IncomingRequestOverlayState extends ConsumerState<IncomingRequestOverlay> {
  bool _isProcessing = false;

  void _accept(String bookingId, String requestId) async {
    setState(() => _isProcessing = true);
    try {
      final res = await ref.read(driverServiceProvider).acceptRide(bookingId, requestId);
      setState(() => _isProcessing = false);
      if (mounted) {
        context.go('/driver-trip/$bookingId');
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

  void _reject(String bookingId, String requestId) async {
    setState(() => _isProcessing = true);
    try {
      await ref.read(driverServiceProvider).rejectRide(bookingId, requestId);
      setState(() => _isProcessing = false);
    } catch (e) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookingRequests')
          .where('driverId', '==', widget.driverId)
          .where('status', '==', 'offered')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final requestDoc = snapshot.data!.docs.first;
        final reqData = requestDoc.data() as Map<String, dynamic>;
        final bookingId = reqData['bookingId'] as String;
        final requestId = requestDoc.id;
        final distanceKm = (reqData['pickupDistanceKm'] as num?)?.toDouble() ?? 1.2;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('bookings').doc(bookingId).get(),
          builder: (context, bookingSnap) {
            if (!bookingSnap.hasData || !bookingSnap.data!.exists) {
              return const SizedBox.shrink();
            }

            final bData = bookingSnap.data!.data() as Map<String, dynamic>;
            final booking = BookingModel.fromMap(bData, bookingId);

            return Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'NEW RIDE REQUEST',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '₹${booking.estimatedFare}',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${booking.estimatedDistanceKm} km · $distanceKm km to pickup',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Icon(Icons.my_location, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              booking.pickup.address,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: AppColors.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              booking.destination.address,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.error),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: _isProcessing ? null : () => _reject(bookingId, requestId),
                              child: const Text('REJECT', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: _isProcessing ? null : () => _accept(bookingId, requestId),
                              child: _isProcessing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text('ACCEPT', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
