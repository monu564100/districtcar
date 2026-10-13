import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import 'package:district_car_shared/models/models.dart';
import '../auth/auth_service.dart';
import '../../widgets/premium_empty_state.dart';
import '../../widgets/trips/ghost_trip_preview.dart';
import '../../widgets/floating_bottom_dock.dart';
import '../../services/haptic_service.dart';

class TripsHistoryScreen extends ConsumerStatefulWidget {
  const TripsHistoryScreen({super.key});

  @override
  ConsumerState<TripsHistoryScreen> createState() => _TripsHistoryScreenState();
}

class _TripsHistoryScreenState extends ConsumerState<TripsHistoryScreen> with SingleTickerProviderStateMixin {
  String _selectedFilter = 'all'; // 'all', 'active', 'completed', 'tour'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _makeCall(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showTripDetailSheet(BuildContext context, BookingModel booking) {
    HapticFeedback.lightImpact();
    final isCompleted = booking.status == 'trip_completed';
    final isActive = booking.status == 'driver_assigned' || booking.status == 'driver_arrived' || booking.status == 'trip_started' || booking.status == 'searching_driver' || booking.status == 'requested';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(color: Color(0x33000000), blurRadius: 36, offset: Offset(0, -10)),
          ],
        ),
        child: Column(
          children: [
            // Handle Bar
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

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.readableId,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19, letterSpacing: -0.3, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('EEEE, dd MMMM yyyy · hh:mm a').format(booking.createdAt),
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                _buildStatusBadge(booking.status),
              ],
            ),
            const SizedBox(height: 16),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Trip Type & Travel Metric Banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: booking.isRoundTrip
                              ? [const Color(0xFF064E3B), const Color(0xFF047857)]
                              : [const Color(0xFF1E293B), const Color(0xFF334155)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDetailMetric(
                            icon: booking.isRoundTrip ? Icons.sync_alt_rounded : Icons.arrow_forward_rounded,
                            label: 'Trip Type',
                            value: booking.isRoundTrip ? 'Round Trip (2-Way)' : 'One-Way Drop',
                          ),
                          Container(width: 1, height: 28, color: Colors.white24),
                          _buildDetailMetric(
                            icon: Icons.speed_rounded,
                            label: 'Distance',
                            value: '${booking.estimatedDistanceKm.toStringAsFixed(1)} km',
                          ),
                          Container(width: 1, height: 28, color: Colors.white24),
                          _buildDetailMetric(
                            icon: Icons.payments_outlined,
                            label: 'Pay Mode',
                            value: booking.paymentMethod.toUpperCase(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Route Card with Airport Style Timeline
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'JOURNEY ROUTE (यात्रा मार्ग)',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.6),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
                                  ),
                                  Container(
                                    width: 2,
                                    height: 38,
                                    color: const Color(0xFFCBD5E1),
                                  ),
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('PICKUP LOCATION (पिकअप पता)', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text(
                                      booking.pickup.address,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 18),
                                    const Text('DESTINATION (गंतव्य)', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text(
                                      booking.destination.address,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
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

                    // Driver & Vehicle Card
                    if (booking.driverName != null || booking.vehiclePlate != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFEFF6FF),
                              ),
                              child: const Icon(Icons.person_pin_rounded, color: AppColors.primary, size: 30),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        booking.driverName ?? 'Assigned Partner Driver',
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A)),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF16A34A)),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${booking.vehicleModel ?? "District Cab"} · ${booking.vehiclePlate ?? "JH Reg"}',
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            if (booking.driverPhone != null && booking.driverPhone!.isNotEmpty)
                              IconButton(
                                onPressed: () => _makeCall(booking.driverPhone!),
                                icon: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF16A34A)),
                                style: IconButton.styleFrom(backgroundColor: const Color(0xFFDCFCE7)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Fare Breakdown Receipt
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'OFFICIAL TRIP INVOICE',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5, color: Color(0xFF94A3B8), letterSpacing: 0.8),
                              ),
                              Text('GST / Tax Compliant', style: TextStyle(fontSize: 10.5, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildFareRow('Base & Distance Tariff', '₹${(booking.estimatedFare * 0.95).round()}'),
                          _buildFareRow('Calculated Road Distance', '${booking.estimatedDistanceKm} km'),
                          if (booking.isRoundTrip)
                            _buildFareRow('Round Trip Waiting', '1st Hour Free Included 🎁'),
                          _buildFareRow('Tolls & Highway Parking', 'As per actual slips'),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Final Total Paid', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                                  Text('Payment status: ${booking.paymentStatus.toUpperCase()}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                ],
                              ),
                              Text(
                                '₹${(booking.finalFare ?? booking.estimatedFare).round()}',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Color(0xFF059669)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Quick Actions (Report Driver or Re-book)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFDC2626)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.report_problem_rounded, color: Color(0xFFDC2626), size: 18),
                            label: const Text('Report Driver', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 12.5)),
                            onPressed: () {
                              Navigator.pop(ctx);
                              context.push('/report-driver', extra: booking);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.repeat_rounded, size: 18),
                            label: const Text('Book Again', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                            onPressed: () {
                              Navigator.pop(ctx);
                              context.go('/');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (isActive)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.navigation_rounded),
                          label: const Text('Open Live Trip Screen', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                          onPressed: () {
                            Navigator.pop(ctx);
                            context.push('/active-trip/${booking.id}');
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailMetric({required IconData icon, required String label, required String value}) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white60, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildFareRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label;
    IconData icon;

    switch (status) {
      case 'trip_completed':
        bg = const Color(0xFFDCFCE7);
        text = const Color(0xFF15803D);
        label = 'COMPLETED';
        icon = Icons.check_circle_rounded;
        break;
      case 'searching_driver':
      case 'requested':
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFFB45309);
        label = 'SEARCHING';
        icon = Icons.radar_rounded;
        break;
      case 'driver_assigned':
      case 'driver_arrived':
      case 'trip_started':
        bg = const Color(0xFFDBEAFE);
        text = const Color(0xFF1D4ED8);
        label = 'ACTIVE RIDE';
        icon = Icons.navigation_rounded;
        break;
      case 'cancelled':
        bg = const Color(0xFFFEE2E2);
        text = const Color(0xFFB91C1C);
        label = 'CANCELLED';
        icon = Icons.cancel_rounded;
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        text = const Color(0xFF475569);
        label = status.toUpperCase();
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: text),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: text, fontWeight: FontWeight.w900, fontSize: 10.5, letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }

  void _onDockTabSelected(int index) {
    HapticService.selection();
    if (index == 0) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        context.go('/');
      }
    } else if (index == 1) {
      context.push('/tours');
    } else if (index == 2) {
      // Already on trips
    } else if (index == 3) {
      context.push('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false, // Match Home screen style, remove stray back arrow
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: const DecorationImage(
                  image: AssetImage('assets/images/app_logo.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'My Trips',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'District Car • Jharkhand',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Support Hotline',
            icon: const Icon(Icons.headset_mic_rounded, color: Color(0xFF3D2FD6)),
            onPressed: () => _makeCall('+918789601387'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: user == null
            ? GhostTripPreview(
                key: const ValueKey('logged_out_preview'),
                onSignInSuccess: () => setState(() {}),
              )
            : _buildLoggedInBody(user),
      ),
      bottomNavigationBar: FloatingBottomDock(
        currentIndex: 2,
        onTabSelected: _onDockTabSelected,
      ),
    );
  }

  Widget _buildLoggedInBody(DistrictUser user) {
    return Column(
        children: [
          // Top Professional Banner with Quick Stats & Search
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
            child: Column(
              children: [
                // Search Bar
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF64748B)),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      hintText: 'Search by Booking ID, destination, or driver...',
                      hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Horizontal Interactive Filter Bar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'All Trips', Icons.all_inclusive_rounded),
                      const SizedBox(width: 8),
                      _buildFilterChip('active', 'Active & Upcoming', Icons.radar_rounded),
                      const SizedBox(width: 8),
                      _buildFilterChip('completed', 'Completed', Icons.check_circle_outline_rounded),
                      const SizedBox(width: 8),
                      _buildFilterChip('tour', 'Tours & Travels', Icons.explore_outlined),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Real-time Trips Stream
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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

                // Sort newest first
                bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                // Apply filter
                final filtered = bookings.where((b) {
                  // Tab Filter
                  if (_selectedFilter == 'active') {
                    final isActive = b.status == 'searching_driver' || b.status == 'driver_assigned' || b.status == 'driver_arrived' || b.status == 'trip_started' || b.status == 'requested';
                    if (!isActive) return false;
                  } else if (_selectedFilter == 'completed') {
                    if (b.status != 'trip_completed') return false;
                  } else if (_selectedFilter == 'tour') {
                    final isTour = b.bookingType == 'tour' || (b.tourDestinationName != null && b.tourDestinationName!.isNotEmpty);
                    if (!isTour) return false;
                  }

                  // Search Query Filter
                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery;
                    final matchesId = b.readableId.toLowerCase().contains(q);
                    final matchesPickup = b.pickup.address.toLowerCase().contains(q);
                    final matchesDest = b.destination.address.toLowerCase().contains(q);
                    final matchesDriver = (b.driverName ?? '').toLowerCase().contains(q);
                    final matchesPlate = (b.vehiclePlate ?? '').toLowerCase().contains(q);
                    return matchesId || matchesPickup || matchesDest || matchesDriver || matchesPlate;
                  }

                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return _buildAtmosphericEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 90),
                  itemCount: filtered.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final booking = filtered[index];
                    return _buildTripCard(booking);
                  },
                );
              },
            ),
          ),
        ],
      );
  }

  Widget _buildFilterChip(String id, String label, IconData icon) {
    final isSelected = _selectedFilter == id;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilter = id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF475569),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAtmosphericEmptyState() {
    String title = 'No Rides Found';
    String subtitle = 'Your past and scheduled rides across Jharkhand districts will appear right here.';
    if (_selectedFilter == 'active') {
      title = 'No Active Rides';
      subtitle = 'You don\'t have any ongoing or scheduled rides right now.';
    } else if (_selectedFilter == 'completed') {
      title = 'No Completed Rides';
      subtitle = 'Your finished trips and fare invoices will show up here.';
    } else if (_selectedFilter == 'tour') {
      title = 'No Tour Packages Booked';
      subtitle = 'Explore Hundru Falls, Jonha Falls, Baidyanath Dham and Betla National Park.';
    }

    return PremiumEmptyState(
      title: title,
      subtitle: subtitle,
      imageAsset: 'assets/images/empty_state_rides.jpg',
      fallbackIcon: Icons.directions_car_filled_rounded,
      glowColor: const Color(0xFF384CF5),
      actionLabel: _selectedFilter == 'tour' ? 'Explore Tour Packages' : 'Book a Ride Now',
      onAction: () {
        if (_selectedFilter == 'tour') {
          context.push('/tours');
        } else {
          context.go('/');
        }
      },
    );
  }

  Widget _buildTripCard(BookingModel booking) {
    final isTour = booking.bookingType == 'tour' || (booking.tourDestinationName != null && booking.tourDestinationName!.isNotEmpty);
    final isRound = booking.isRoundTrip;
    final isCompleted = booking.status == 'trip_completed';

    return GestureDetector(
      onTap: () => _showTripDetailSheet(context, booking),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isTour ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
            width: isTour ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: ID, Tour Badge, Round Trip Tag, Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      booking.readableId,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A)),
                    ),
                    if (isTour) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Text(
                          'TOUR',
                          style: TextStyle(fontSize: 9.5, color: Color(0xFF15803D), fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                    if (isRound) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Text(
                          'ROUND TRIP',
                          style: TextStyle(fontSize: 9.5, color: Color(0xFFB45309), fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ],
                ),
                _buildStatusBadge(booking.status),
              ],
            ),
            const SizedBox(height: 6),

            // Date & Time Subtitle
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 13, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd MMM yyyy · hh:mm a').format(booking.createdAt),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Visual Origin & Destination
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
                    ),
                    Container(
                      width: 1.5,
                      height: 24,
                      color: const Color(0xFFCBD5E1),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.pickup.address,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        booking.destination.address,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Bottom Metric Strip: Driver/Vehicle, Distance, Fare & View Arrow
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.driverName != null ? '${booking.driverName} (${booking.vehiclePlate ?? "Cab"})' : '${booking.estimatedDistanceKm.toStringAsFixed(1)} km · ${booking.paymentMethod.toUpperCase()}',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '₹${(booking.finalFare ?? booking.estimatedFare).round()}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF059669)),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Text('Details', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w800)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
