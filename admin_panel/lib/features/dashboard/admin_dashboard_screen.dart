import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../widgets/admin_scaffold.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _statusFilter = 'all'; // all, active, completed, cancelled
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showBookingDetailsModal(Map<String, dynamic> data, String bookingId) {
    final status = (data['status'] ?? 'unknown').toString();
    final readableId = (data['readableId'] ?? bookingId).toString();
    final customerName = (data['customerName'] ?? 'Customer').toString();
    final customerPhone = (data['customerPhone'] ?? 'N/A').toString();
    final driverName = (data['driverName'] ?? 'Not Assigned').toString();
    final driverPhone = (data['driverPhone'] ?? 'N/A').toString();
    final vehicleCategory = (data['vehicleCategoryId'] ?? 'Car').toString().toUpperCase();
    final vehiclePlate = (data['vehiclePlate'] ?? 'N/A').toString();
    final pickup = (data['pickup'] is Map ? data['pickup']['address'] : null) ?? 'N/A';
    final destination = (data['destination'] is Map ? data['destination']['address'] : null) ?? 'N/A';
    final distance = (data['estimatedDistanceKm'] ?? 0.0).toString();
    final fare = (data['finalFare'] ?? data['estimatedFare'] ?? 0.0).toString();
    final otp = (data['otp'] ?? '----').toString();
    final isRoundTrip = data['isRoundTrip'] == true;
    final isTour = data['bookingType'] == 'tour';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.receipt_long, color: Color(0xFF15803D), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Booking #$readableId', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  Text(
                    status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(status),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                // Fare & OTP strip
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TOTAL FARE', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold)),
                        Text('₹$fare', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF059669))),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('START OTP', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold)),
                        Text(otp, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2, color: Color(0xFF0F172A))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Customer Info
                _buildInfoSection(
                  title: 'CUSTOMER INFORMATION',
                  icon: Icons.person_outline,
                  children: [
                    _buildInfoRow('Name:', customerName),
                    _buildInfoRow('Phone:', customerPhone),
                  ],
                ),
                const SizedBox(height: 14),

                // Driver Info
                _buildInfoSection(
                  title: 'ASSIGNED DRIVER & VEHICLE',
                  icon: Icons.directions_car_outlined,
                  children: [
                    _buildInfoRow('Driver:', driverName),
                    _buildInfoRow('Phone:', driverPhone),
                    _buildInfoRow('Vehicle Category:', vehicleCategory),
                    _buildInfoRow('Registration Plate:', vehiclePlate),
                  ],
                ),
                const SizedBox(height: 14),

                // Route details
                _buildInfoSection(
                  title: 'TRIP ROUTE',
                  icon: Icons.alt_route_rounded,
                  children: [
                    _buildInfoRow('Pickup:', pickup),
                    _buildInfoRow('Destination:', destination),
                    _buildInfoRow('Estimated Distance:', '$distance km'),
                    if (isRoundTrip) _buildInfoRow('Trip Mode:', 'Round-Trip (35% Discount Applied)'),
                    if (isTour) _buildInfoRow('Booking Category:', 'Tour & Sightseeing Package'),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          // Admin Actions
          if (status != 'completed' && status != 'cancelled') ...[
            TextButton(
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
              onPressed: () async {
                Navigator.pop(ctx);
                await _updateBookingStatus(bookingId, 'cancelled', 'Cancelled by Operations Admin');
              },
              child: const Text('Cancel Ride', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await _updateBookingStatus(bookingId, 'completed', 'Force-completed by Operations Admin');
              },
              child: const Text('Mark Completed', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF475569)),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF475569), letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12.5, color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateBookingStatus(String bookingId, String newStatus, String adminNote) async {
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
        'status': newStatus,
        'adminNote': adminNote,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking #$bookingId updated to $newStatus'),
            backgroundColor: newStatus == 'completed' ? const Color(0xFF059669) : const Color(0xFFDC2626),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating: $e')));
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'searching_driver':
        return const Color(0xFFD97706);
      case 'assigned':
      case 'driver_arrived':
        return const Color(0xFF2563EB);
      case 'trip_started':
      case 'in_progress':
        return const Color(0xFF7C3AED);
      case 'completed':
        return const Color(0xFF059669);
      case 'cancelled':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      activeRoute: '/dashboard',
      title: 'Operations Overview',
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Operations Overview',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                          SizedBox(height: 6),
                          Text('Real-time system health, live bookings, and platform performance metrics across Jharkhand.', style: TextStyle(color: Color(0xFF64748B))),
                        ],
                      ),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            onPressed: () => context.go('/notifications'),
                            icon: const Icon(Icons.campaign_outlined, size: 18),
                            label: const Text('Send Push Offer', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            onPressed: () => context.go('/driver-verification'),
                            icon: const Icon(Icons.verified_user_outlined, size: 18),
                            label: const Text('Driver Approvals', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Real-Time KPI Grid Stream
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('bookings').snapshots().handleError((e) => debugPrint('KPI bookings error: $e')),
                    builder: (context, bookingsSnap) {
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('drivers').snapshots().handleError((e) => debugPrint('KPI drivers error: $e')),
                        builder: (context, driversSnap) {
                          final bookingDocs = bookingsSnap.hasData ? bookingsSnap.data!.docs : <QueryDocumentSnapshot>[];
                          final driverDocs = driversSnap.hasData ? driversSnap.data!.docs : <QueryDocumentSnapshot>[];

                          int totalBookings = bookingDocs.length;
                          double totalRevenue = 0.0;
                          int activeOnlineDrivers = 0;
                          int pendingDriverApprovals = 0;

                          for (final doc in bookingDocs) {
                            try {
                              final d = doc.data() as Map<String, dynamic>;
                              final fare = (d['finalFare'] ?? d['estimatedFare'] ?? 0.0) as num;
                              totalRevenue += fare.toDouble();
                            } catch (_) {}
                          }

                          for (final doc in driverDocs) {
                            try {
                              final d = doc.data() as Map<String, dynamic>;
                              if (d['isOnline'] == true) activeOnlineDrivers++;
                              if (d['verificationStatus'] == 'pending') pendingDriverApprovals++;
                            } catch (_) {}
                          }

                          final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 260,
                                  child: _buildMetricCard(
                                    title: 'Total Bookings',
                                    val: '$totalBookings',
                                    sub: 'Live database count',
                                    color: const Color(0xFF2563EB),
                                    icon: Icons.local_taxi_rounded,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                SizedBox(
                                  width: 260,
                                  child: _buildMetricCard(
                                    title: 'Active Online Drivers',
                                    val: '$activeOnlineDrivers',
                                    sub: 'Available for ride match',
                                    color: const Color(0xFF059669),
                                    icon: Icons.sensors_rounded,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                SizedBox(
                                  width: 260,
                                  child: _buildMetricCard(
                                    title: 'Pending Driver Reviews',
                                    val: '$pendingDriverApprovals',
                                    sub: pendingDriverApprovals > 0 ? 'Requires attention' : 'All clear',
                                    color: pendingDriverApprovals > 0 ? const Color(0xFFD97706) : const Color(0xFF64748B),
                                    icon: Icons.assignment_ind_outlined,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                SizedBox(
                                  width: 260,
                                  child: _buildMetricCard(
                                    title: 'Gross Revenue Volume',
                                    val: currencyFmt.format(totalRevenue),
                                    sub: 'Total booking values',
                                    color: const Color(0xFF7C3AED),
                                    icon: Icons.account_balance_wallet_outlined,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 36),

                  // Operations Live Bookings Feed Container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Filter Bar & Search
                        Row(
                          children: [
                            const Text('Live Operations & Recent Bookings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            const Spacer(),
                            // Search box
                            SizedBox(
                              width: 240,
                              height: 38,
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                                decoration: InputDecoration(
                                  hintText: 'Search ID, Phone, Name...',
                                  hintStyle: const TextStyle(fontSize: 12),
                                  prefixIcon: const Icon(Icons.search, size: 18),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Filter Dropdown
                            DropdownButton<String>(
                              value: _statusFilter,
                              underline: const SizedBox(),
                              items: const [
                                DropdownMenuItem(value: 'all', child: Text('All Statuses', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                                DropdownMenuItem(value: 'active', child: Text('Active / In Transit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                                DropdownMenuItem(value: 'searching', child: Text('Searching Driver', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                                DropdownMenuItem(value: 'completed', child: Text('Completed', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                                DropdownMenuItem(value: 'cancelled', child: Text('Cancelled', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _statusFilter = val);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Stream of Live Bookings
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('bookings')
                              .orderBy('createdAt', descending: true)
                              .limit(50)
                              .snapshots()
                              .handleError((err) => debugPrint('Bookings list stream error: $err')),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(40),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.sync_problem_rounded, size: 40, color: Color(0xFF94A3B8)),
                                      const SizedBox(height: 12),
                                      const Text('Bookings database is connecting...', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                      const SizedBox(height: 4),
                                      Text('${snapshot.error}', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                                    ],
                                  ),
                                ),
                              );
                            }

                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
                            }

                            final docs = snapshot.data?.docs ?? [];
                            if (docs.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(48),
                                  child: Column(
                                    children: const [
                                      Icon(Icons.inbox_outlined, size: 48, color: Color(0xFF94A3B8)),
                                      SizedBox(height: 12),
                                      Text('No bookings found in database.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                      SizedBox(height: 4),
                                      Text('New passenger bookings will appear here in real-time.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final filteredDocs = docs.where((doc) {
                              final d = doc.data() as Map<String, dynamic>;
                              final st = (d['status'] ?? '').toString();

                              if (_statusFilter == 'active' && (st != 'assigned' && st != 'driver_arrived' && st != 'trip_started' && st != 'in_progress')) return false;
                              if (_statusFilter == 'searching' && st != 'searching_driver') return false;
                              if (_statusFilter == 'completed' && st != 'completed') return false;
                              if (_statusFilter == 'cancelled' && st != 'cancelled') return false;

                              if (_searchQuery.isNotEmpty) {
                                final rid = (d['readableId'] ?? doc.id).toString().toLowerCase();
                                final cName = (d['customerName'] ?? '').toString().toLowerCase();
                                final cPhone = (d['customerPhone'] ?? '').toString().toLowerCase();
                                final dName = (d['driverName'] ?? '').toString().toLowerCase();
                                if (!rid.contains(_searchQuery) && !cName.contains(_searchQuery) && !cPhone.contains(_searchQuery) && !dName.contains(_searchQuery)) {
                                  return false;
                                }
                              }

                              return true;
                            }).toList();

                            if (filteredDocs.isEmpty) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Text('No bookings match the selected filter/search.', style: TextStyle(color: Color(0xFF64748B))),
                                ),
                              );
                            }

                            return ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SizedBox(
                                  width: 1380,
                                  child: Column(
                                    children: [
                                      // Horizontal Table Header
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        color: const Color(0xFFF8FAFC),
                                        child: Row(
                                          children: const [
                                            SizedBox(
                                              width: 140,
                                              child: Text('BOOKING ID', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                            ),
                                            SizedBox(
                                              width: 110,
                                              child: Text('VEHICLE', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                            ),
                                            SizedBox(
                                              width: 170,
                                              child: Text('CUSTOMER', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                            ),
                                            SizedBox(
                                              width: 240,
                                              child: Text('PICKUP LOCATION', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                            ),
                                            SizedBox(
                                              width: 240,
                                              child: Text('DESTINATION LOCATION', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                            ),
                                            SizedBox(
                                              width: 170,
                                              child: Text('ASSIGNED DRIVER', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                            ),
                                            SizedBox(
                                              width: 110,
                                              child: Text('FARE', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                            ),
                                            SizedBox(
                                              width: 130,
                                              child: Text('LIVE STATUS', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                            ),
                                            SizedBox(
                                              width: 70,
                                              child: Text('ACTION', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Divider(height: 1, color: Color(0xFFE2E8F0)),

                                      // Table Rows
                                      ListView.separated(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: filteredDocs.length,
                                        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                        itemBuilder: (context, index) {
                                          final doc = filteredDocs[index];
                                          final data = doc.data() as Map<String, dynamic>;
                                          final bookingId = doc.id;
                                          final readableId = (data['readableId'] ?? bookingId).toString();
                                          final category = (data['vehicleCategoryId'] ?? 'Car').toString().toUpperCase();
                                          final customer = (data['customerName'] ?? 'Customer').toString();
                                          final driver = (data['driverName'] ?? 'Searching...').toString();
                                          final fare = (data['finalFare'] ?? data['estimatedFare'] ?? 0.0).toString();
                                          final status = (data['status'] ?? 'unknown').toString();
                                          final pickup = (data['pickup'] is Map ? data['pickup']['address'] : null) ?? '';
                                          final destination = (data['destination'] is Map ? data['destination']['address'] : null) ?? '';

                                          return InkWell(
                                            onTap: () => _showBookingDetailsModal(data, bookingId),
                                            hoverColor: const Color(0xFFF8FAFC),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                              child: Row(
                                                children: [
                                                  // ID
                                                  SizedBox(
                                                    width: 140,
                                                    child: Text(
                                                      '#$readableId',
                                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F172A)),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),

                                                  // Category
                                                  SizedBox(
                                                    width: 110,
                                                    child: Align(
                                                      alignment: Alignment.centerLeft,
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFF1F5F9),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          category,
                                                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                                        ),
                                                      ),
                                                    ),
                                                  ),

                                                  // Customer
                                                  SizedBox(
                                                    width: 170,
                                                    child: Text(
                                                      customer,
                                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),

                                                  // Pickup Address
                                                  SizedBox(
                                                    width: 240,
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.radio_button_checked, size: 12, color: Color(0xFF16A34A)),
                                                        const SizedBox(width: 6),
                                                        Expanded(
                                                          child: Text(
                                                            pickup.isNotEmpty ? pickup : 'Pickup not specified',
                                                            style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),

                                                  // Destination Address
                                                  SizedBox(
                                                    width: 240,
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.location_on, size: 13, color: Color(0xFFDC2626)),
                                                        const SizedBox(width: 6),
                                                        Expanded(
                                                          child: Text(
                                                            destination.isNotEmpty ? destination : 'Destination not specified',
                                                            style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),

                                                  // Driver
                                                  SizedBox(
                                                    width: 170,
                                                    child: Text(
                                                      driver,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 13,
                                                        color: driver == 'Searching...' ? const Color(0xFFD97706) : const Color(0xFF0F172A),
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),

                                                  // Fare
                                                  SizedBox(
                                                    width: 110,
                                                    child: Text(
                                                      '₹$fare',
                                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: Color(0xFF059669)),
                                                    ),
                                                  ),

                                                  // Status badge
                                                  SizedBox(
                                                    width: 130,
                                                    child: Align(
                                                      alignment: Alignment.centerLeft,
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: _getStatusColor(status).withOpacity(0.12),
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                        child: Text(
                                                          status.replaceAll('_', ' ').toUpperCase(),
                                                          style: TextStyle(
                                                            color: _getStatusColor(status),
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w900,
                                                            letterSpacing: 0.3,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),

                                                  // Action Chevron
                                                  const SizedBox(
                                                    width: 70,
                                                    child: Align(
                                                      alignment: Alignment.centerLeft,
                                                      child: Icon(Icons.chevron_right, size: 20, color: Color(0xFF94A3B8)),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String val,
    required String sub,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(val, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 6),
            Text(sub, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5)),
          ],
        ),
      ),
    );
  }
}
