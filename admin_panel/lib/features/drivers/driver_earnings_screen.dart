import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/admin_sidebar.dart';

class DriverEarningsReportScreen extends StatefulWidget {
  const DriverEarningsReportScreen({super.key});

  @override
  State<DriverEarningsReportScreen> createState() => _DriverEarningsReportScreenState();
}

class _DriverEarningsReportScreenState extends State<DriverEarningsReportScreen> {
  String _searchQuery = '';
  String _filterCategory = 'all';

  void _toggleDriverBlockStatus(String driverId, bool currentBlockedStatus) async {
    final bool newStatus = !currentBlockedStatus;
    try {
      await FirebaseFirestore.instance.collection('drivers').doc(driverId).update({
        'isBlocked': newStatus,
        'blockedReason': newStatus ? 'Blocked by Admin for pending commission or compliance' : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus ? 'Driver partner blocked successfully.' : 'Driver partner unblocked and restored.'),
            backgroundColor: newStatus ? Colors.red.shade700 : const Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _markCommissionSettled(String driverId, double amount) async {
    try {
      await FirebaseFirestore.instance.collection('drivers').doc(driverId).update({
        'pendingCommission': 0.0,
        'lastCommissionPaidAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commission marked as settled.'), backgroundColor: Color(0xFF16A34A)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          const AdminSidebar(activeRoute: '/driver-earnings'),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('drivers').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                double totalFleetGross = 0.0;
                double totalPlatformCommission = 0.0;
                int totalFleetTrips = 0;
                int totalActiveDrivers = 0;
                int totalBlockedDrivers = 0;

                for (final doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final double earnings = (data['totalEarnings'] as num?)?.toDouble() ?? 0.0;
                  final int trips = (data['totalTrips'] as num?)?.toInt() ?? 0;
                  final double commissionRate = (data['commissionRate'] as num?)?.toDouble() ?? 0.10;
                  final double commission = (data['platformCommission'] as num?)?.toDouble() ?? (earnings * commissionRate);
                  final bool isBlocked = data['isBlocked'] == true;

                  totalFleetGross += earnings;
                  totalPlatformCommission += commission;
                  totalFleetTrips += trips;
                  if (isBlocked) {
                    totalBlockedDrivers++;
                  } else {
                    totalActiveDrivers++;
                  }
                }

                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final phone = (data['phoneNumber'] ?? '').toString().toLowerCase();
                  final category = (data['vehicleCategoryId'] ?? 'car').toString().toLowerCase();

                  final matchesSearch = name.contains(_searchQuery.toLowerCase()) || phone.contains(_searchQuery.toLowerCase());
                  final matchesCat = _filterCategory == 'all' || category == _filterCategory;
                  return matchesSearch && matchesCat;
                }).toList();

                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Page Title & Subtitle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Driver Trips & Commission Ledger',
                                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Real-time financial performance: trips completed, gross fares, and platform commissions.',
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF86EFAC)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.circle, color: Color(0xFF16A34A), size: 10),
                                const SizedBox(width: 8),
                                Text(
                                  'Live Sync • ${docs.length} Drivers',
                                  style: const TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Metric Summary Cards
                      Row(
                        children: [
                          _buildSummaryCard(
                            title: 'Total Commission Earned',
                            value: '₹${totalPlatformCommission.toStringAsFixed(0)}',
                            subtitle: 'Platform 10% Share',
                            icon: Icons.account_balance_wallet,
                            color: const Color(0xFF059669),
                            bgColor: const Color(0xFFECFDF5),
                          ),
                          const SizedBox(width: 16),
                          _buildSummaryCard(
                            title: 'Gross Ride Business',
                            value: '₹${totalFleetGross.toStringAsFixed(0)}',
                            subtitle: 'Across all drivers',
                            icon: Icons.trending_up,
                            color: const Color(0xFF2563EB),
                            bgColor: const Color(0xFFEFF6FF),
                          ),
                          const SizedBox(width: 16),
                          _buildSummaryCard(
                            title: 'Total Completed Trips',
                            value: '$totalFleetTrips',
                            subtitle: 'Jharkhand rural rides',
                            icon: Icons.navigation,
                            color: const Color(0xFF7C3AED),
                            bgColor: const Color(0xFFF5F3FF),
                          ),
                          const SizedBox(width: 16),
                          _buildSummaryCard(
                            title: 'Active / Blocked Fleet',
                            value: '$totalActiveDrivers / $totalBlockedDrivers',
                            subtitle: '$totalBlockedDrivers currently suspended',
                            icon: Icons.shield,
                            color: const Color(0xFFD97706),
                            bgColor: const Color(0xFFFFFBEB),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Filter & Search Toolbar
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onChanged: (val) => setState(() => _searchQuery = val),
                              decoration: InputDecoration(
                                hintText: 'Search driver by name or phone number...',
                                prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          DropdownButton<String>(
                            value: _filterCategory,
                            underline: const SizedBox.shrink(),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All Vehicle Categories')),
                              DropdownMenuItem(value: 'car', child: Text('Mini Cab (Car)')),
                              DropdownMenuItem(value: 'auto', child: Text('Auto / E-Rick')),
                              DropdownMenuItem(value: 'sedan', child: Text('Comfort Sedan')),
                              DropdownMenuItem(value: 'suv', child: Text('Rural SUV (Bolero)')),
                              DropdownMenuItem(value: 'bike', child: Text('Bike Taxi')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _filterCategory = val);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Driver Table
                      Expanded(
                        child: filteredDocs.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.person_search, size: 48, color: Color(0xFF94A3B8)),
                                    SizedBox(height: 12),
                                    Text('No driver records match the search criteria.', style: TextStyle(color: Color(0xFF64748B))),
                                  ],
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: ListView.separated(
                                    itemCount: filteredDocs.length,
                                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                                    itemBuilder: (context, index) {
                                      final doc = filteredDocs[index];
                                      final data = doc.data() as Map<String, dynamic>;
                                      final driverId = doc.id;
                                      final name = data['name'] ?? 'Driver Partner';
                                      final phone = data['phoneNumber'] ?? 'No phone';
                                      final plate = data['vehiclePlateNumber'] ?? 'Plate not registered';
                                      final category = (data['vehicleCategoryId'] ?? 'car').toString().toUpperCase();
                                      final int trips = (data['totalTrips'] as num?)?.toInt() ?? 0;
                                      final double grossEarnings = (data['totalEarnings'] as num?)?.toDouble() ?? 0.0;
                                      final double commission = grossEarnings * 0.10; // 10% platform share
                                      final bool isBlocked = data['isBlocked'] == true;
                                      final double pendingComm = (data['pendingCommission'] as num?)?.toDouble() ?? (commission > 0 ? commission : 0.0);

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                        child: Row(
                                          children: [
                                            // Avatar & Name
                                            CircleAvatar(
                                              radius: 22,
                                              backgroundColor: isBlocked ? const Color(0xFFFEE2E2) : const Color(0xFFE0E7FF),
                                              child: Text(
                                                name.isNotEmpty ? name[0].toUpperCase() : 'D',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: isBlocked ? const Color(0xFFDC2626) : const Color(0xFF4338CA),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              flex: 3,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        name,
                                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: isBlocked ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          isBlocked ? 'BLOCKED' : 'ACTIVE',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w800,
                                                            color: isBlocked ? const Color(0xFFDC2626) : const Color(0xFF15803D),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text('$phone • $plate ($category)', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                                ],
                                              ),
                                            ),

                                            // Trips Run
                                            Expanded(
                                              flex: 2,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('$trips Trips', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                                  const Text('Completed Trips', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                                                ],
                                              ),
                                            ),

                                            // Gross Driver Fare
                                            Expanded(
                                              flex: 2,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('₹${grossEarnings.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                                  const Text('Gross Earnings', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                                                ],
                                              ),
                                            ),

                                            // 10% Platform Commission Made
                                            Expanded(
                                              flex: 2,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '₹${commission.toStringAsFixed(0)}',
                                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF059669)),
                                                  ),
                                                  const Text('Our 10% Cut', style: TextStyle(color: Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                            ),

                                            // Actions: Settle / Block Driver
                                            Row(
                                              children: [
                                                if (pendingComm > 0)
                                                  OutlinedButton.icon(
                                                    onPressed: () => _markCommissionSettled(driverId, pendingComm),
                                                    icon: const Icon(Icons.check, size: 14, color: Color(0xFF059669)),
                                                    label: const Text('Settle', style: TextStyle(fontSize: 12, color: Color(0xFF059669))),
                                                    style: OutlinedButton.styleFrom(
                                                      side: const BorderSide(color: Color(0xFF86EFAC)),
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    ),
                                                  ),
                                                const SizedBox(width: 8),
                                                ElevatedButton.icon(
                                                  onPressed: () => _toggleDriverBlockStatus(driverId, isBlocked),
                                                  icon: Icon(isBlocked ? Icons.lock_open : Icons.block, size: 14),
                                                  label: Text(isBlocked ? 'Unblock' : 'Block', style: const TextStyle(fontSize: 12)),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: isBlocked ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(value, style: TextStyle(color: const Color(0xFF0F172A), fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
