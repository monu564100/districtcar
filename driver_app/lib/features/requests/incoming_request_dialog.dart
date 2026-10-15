import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import 'package:district_car_shared/models/models.dart';
import '../../services/driver_service.dart';

class IncomingRequestOverlay extends ConsumerStatefulWidget {
  final String driverId;
  final String? vehicleCategory;
  final LocationModel? driverLocation;
  final Function(BookingModel booking)? onAccepted;

  const IncomingRequestOverlay({
    super.key,
    required this.driverId,
    this.vehicleCategory,
    this.driverLocation,
    this.onAccepted,
  });

  @override
  ConsumerState<IncomingRequestOverlay> createState() => _IncomingRequestOverlayState();
}

class _IncomingRequestOverlayState extends ConsumerState<IncomingRequestOverlay> {
  bool _isProcessing = false;
  final Set<String> _dismissedIds = {};
  String? _lastAlertedId;

  bool _isCategoryEligible(String bookingCat, String driverCat) {
    final b = bookingCat.trim().toLowerCase();
    final d = driverCat.trim().toLowerCase();
    if (b == d) return true;
    if ((d == 'car' || d == 'sedan' || d == 'mini' || d == 'suv') &&
        (b == 'car' || b == 'sedan' || b == 'mini' || b == 'suv')) {
      return true;
    }
    return false;
  }

  bool _isDistanceEligible(BookingModel booking, double driverLat, double driverLng) {
    if (booking.pickup.latitude == 0.0 && booking.pickup.longitude == 0.0) return true;
    if (driverLat == 0.0 && driverLng == 0.0) return true;

    final isTour = booking.bookingType == 'tour' ||
        (booking.tourDestinationName != null && booking.tourDestinationName!.isNotEmpty);
    final isLongDistance = isTour || booking.isRoundTrip || (booking.estimatedDistanceKm > 25);
    final maxRadiusKm = isLongDistance ? 30.0 : 15.0;

    final distanceMeters = Geolocator.distanceBetween(
      driverLat,
      driverLng,
      booking.pickup.latitude,
      booking.pickup.longitude,
    );
    final distanceKm = distanceMeters / 1000.0;
    return distanceKm <= maxRadiusKm;
  }

  double _calculatePickupDistanceKm(BookingModel booking, double driverLat, double driverLng) {
    if (booking.pickup.latitude == 0.0 || driverLat == 0.0) return 1.5;
    final meters = Geolocator.distanceBetween(
      driverLat,
      driverLng,
      booking.pickup.latitude,
      booking.pickup.longitude,
    );
    return meters / 1000.0;
  }

  void _showAcceptConfirmationModal(BookingModel booking, String? requestId, double pickupDistanceKm) {
    bool pledgeAgreed = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFFDCFCE7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.handshake_outlined, color: Color(0xFF15803D), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Confirm Ride Acceptance',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                              ),
                              Text(
                                'सवारी स्वीकार व समय पर पहुंचने की सहमति',
                                style: TextStyle(fontSize: 11.5, color: Color(0xFF059669), fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Fare & Pickup Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Trip Fare (कुल किराया):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                              Text(
                                '₹${(booking.finalFare ?? booking.estimatedFare).toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                              ),
                            ],
                          ),
                          const Divider(height: 18),
                          Row(
                            children: [
                              const Icon(Icons.near_me, size: 16, color: Color(0xFF059669)),
                              const SizedBox(width: 6),
                              Text(
                                'Pickup is ~${pickupDistanceKm.toStringAsFixed(1)} km from your stand',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.radio_button_checked, size: 14, color: Color(0xFF059669)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  booking.pickup.address,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: Color(0xFFDC2626)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  booking.destination.address,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Driver Pledge Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFF92400E), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Partner Commitment (वचन):',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF92400E)),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'स्वीकार करने के बाद यात्री आपका इंतज़ार करता है। बिना आपात स्थिति के सवारी रद्द न करें। रद्द करने पर रेटिंग प्रभावित होगी।',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF78350F), height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Interactive Pledge Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: pledgeAgreed,
                          activeColor: const Color(0xFF059669),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (v) => setModalState(() => pledgeAgreed = v ?? false),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => pledgeAgreed = !pledgeAgreed),
                            child: const Text(
                              'I agree to reach on time and complete this journey without cancellation.',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Confirm & Cancel Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Back / Decline', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: (!pledgeAgreed || _isProcessing)
                                ? null
                                : () {
                                    Navigator.pop(ctx);
                                    _executeAccept(booking, requestId);
                                  },
                            child: _isProcessing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    'CONFIRM & LOCK RIDE (कन्फर्म करें)',
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                                  ),
                          ),
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
    );
  }

  void _executeAccept(BookingModel booking, String? requestId) async {
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
    final driverCat = (widget.vehicleCategory ?? 'car').trim().toLowerCase();
    final driverLat = widget.driverLocation?.latitude ?? 23.3441;
    final driverLng = widget.driverLocation?.longitude ?? 85.3096;

    // 0. STRICT: Verify driver is NOT currently busy on another ride, offline, or blocked
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('drivers').doc(widget.driverId).snapshots(),
      builder: (context, driverDocSnap) {
        if (driverDocSnap.hasData && driverDocSnap.data!.exists) {
          final dData = driverDocSnap.data!.data() as Map<String, dynamic>?;
          final isBusy = dData?['isBusy'] == true || dData?['activeBookingId'] != null;
          final isBlocked = dData?['isBlocked'] == true;
          final isOnline = dData?['isOnline'] == true;
          if (isBusy || isBlocked || !isOnline) {
            return const SizedBox.shrink();
          }
        }

        // 1. Direct targeted offers in bookingRequests (Index-free query)
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookingRequests')
              .where('driverId', isEqualTo: widget.driverId)
              .snapshots(),
          builder: (context, requestSnap) {
            final offerDocs = (requestSnap.data?.docs ?? []).where((doc) {
              final d = doc.data() as Map<String, dynamic>?;
              return d?['status'] == 'offered';
            }).toList();

            if (offerDocs.isNotEmpty) {
              final requestDoc = offerDocs.first;
              final reqData = requestDoc.data() as Map<String, dynamic>;
              final bookingId = reqData['bookingId']?.toString() ?? '';
              final requestId = requestDoc.id;

              if (bookingId.isNotEmpty && !_dismissedIds.contains(bookingId) && !_dismissedIds.contains(requestId)) {
                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('bookings').doc(bookingId).snapshots(),
                  builder: (context, bSnap) {
                    if (!bSnap.hasData || !bSnap.data!.exists) return const SizedBox.shrink();
                    try {
                      final bData = bSnap.data!.data() as Map<String, dynamic>;
                      final status = bData['status'] as String? ?? '';
                      final bookedCategory = (bData['vehicleCategoryId'] ?? 'car').toString();

                      if (!_isCategoryEligible(bookedCategory, driverCat)) {
                        return const SizedBox.shrink();
                      }
                      if (status != 'searching_driver' && status != 'requested') {
                        return const SizedBox.shrink();
                      }
                      final booking = BookingModel.fromMap(bData, bookingId);
                      if (!_isDistanceEligible(booking, driverLat, driverLng)) {
                        return const SizedBox.shrink();
                      }
                      final pickupDistKm = _calculatePickupDistanceKm(booking, driverLat, driverLng);
                      return _buildPopupCard(booking, requestId, pickupDistKm);
                    } catch (_) {
                      return const SizedBox.shrink();
                    }
                  },
                );
              }
            }

            // 2. Fallback: Universal searching_driver bookings matching category & radius
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('status', isEqualTo: 'searching_driver')
                  .limit(10)
                  .snapshots(),
              builder: (context, bookingSnap) {
                if (!bookingSnap.hasData || bookingSnap.data!.docs.isEmpty) {
                  return const SizedBox.shrink();
                }

                QueryDocumentSnapshot? matchedDoc;
                double matchedPickupDist = 0.0;

                for (final doc in bookingSnap.data!.docs) {
                  try {
                    final bData = doc.data() as Map<String, dynamic>;
                    final bookedCategory = (bData['vehicleCategoryId'] ?? 'car').toString();
                    if (_dismissedIds.contains(doc.id)) continue;

                    if (_isCategoryEligible(bookedCategory, driverCat)) {
                      final booking = BookingModel.fromMap(bData, doc.id);
                      if (_isDistanceEligible(booking, driverLat, driverLng)) {
                        matchedDoc = doc;
                        matchedPickupDist = _calculatePickupDistanceKm(booking, driverLat, driverLng);
                        break;
                      }
                    }
                  } catch (_) {}
                }

                if (matchedDoc == null) {
                  return const SizedBox.shrink();
                }

                try {
                  final bookingId = matchedDoc.id;
                  final bData = matchedDoc.data() as Map<String, dynamic>;
                  final booking = BookingModel.fromMap(bData, bookingId);
                  return _buildPopupCard(booking, null, matchedPickupDist);
                } catch (_) {
                  return const SizedBox.shrink();
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPopupCard(BookingModel booking, String? requestId, double pickupDistanceKm) {
    if (_lastAlertedId != booking.id) {
      _lastAlertedId = booking.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.heavyImpact();
      });
    }

    final isTour = booking.bookingType == 'tour' || (booking.tourDestinationName != null && booking.tourDestinationName!.isNotEmpty);
    final stayHours = booking.stayHours ?? (booking.roundTripStoppingHours > 0 ? booking.roundTripStoppingHours.toInt() : null);

    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          padding: const EdgeInsets.all(22),
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
                    color: isTour ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isTour ? const Color(0xFFA7F3D0) : const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isTour ? Icons.tour : Icons.notifications_active,
                        color: isTour ? const Color(0xFF047857) : const Color(0xFFDC2626),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isTour
                            ? (booking.isRoundTrip ? '🌴 TOURS & TRAVELS (दो तरफा टूर)' : '🌴 TOURS & TRAVELS (टूर राइड)')
                            : (booking.isRoundTrip ? '🔔 ROUND TRIP (दो तरफा राइड)' : '🔔 NEW RIDE BOOKING (नयी बुकिंग)'),
                        style: TextStyle(
                          color: isTour ? const Color(0xFF047857) : const Color(0xFFDC2626),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isTour && booking.tourDestinationName != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '📍 ${booking.tourDestinationName!}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Fare Display in ₹
                Text(
                  '₹${(booking.finalFare ?? booking.estimatedFare).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF059669),
                  ),
                ),
                Text(
                  'Trip Distance: ${booking.estimatedDistanceKm} km ${booking.isRoundTrip ? "(Round Trip)" : "(One Way)"}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Pickup ~${pickupDistanceKm.toStringAsFixed(1)} km from your stand',
                    style: const TextStyle(color: Color(0xFF047857), fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),

                // Waiting Duration Tag (if applicable)
                if (stayHours != null && stayHours > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, size: 15, color: Color(0xFF92400E)),
                        const SizedBox(width: 6),
                        Text(
                          'Waiting / Stay: $stayHours Hours Included',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Customer info preview
                if (booking.customerName != null && booking.customerName!.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person, size: 15, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Text(
                        'Customer: ${booking.customerName}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
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

                // Action Buttons: Reject & Accept (opens confirmation modal)
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
                        child: const Text('DECLINE', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
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
                        onPressed: _isProcessing
                            ? null
                            : () => _showAcceptConfirmationModal(booking, requestId, pickupDistanceKm),
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
