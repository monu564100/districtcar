import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import '../../widgets/admin_scaffold.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleDriverBlock(String driverId, bool currentBlocked) async {
    final next = !currentBlocked;
    try {
      await FirebaseFirestore.instance.collection('drivers').doc(driverId).set({
        'isBlocked': next,
        'blockedReason': next ? 'Blocked by Admin' : null,
        'blockedAt': next ? FieldValue.serverTimestamp() : null,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next ? 'Driver blocked successfully.' : 'Driver unblocked successfully.'),
            backgroundColor: next ? Colors.red : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _toggleCustomerBlock(String customerId, bool currentBlocked) async {
    final next = !currentBlocked;
    try {
      await FirebaseFirestore.instance.collection('users').doc(customerId).set({
        'isBlocked': next,
        'blockedReason': next ? 'Blocked by Admin' : null,
        'blockedAt': next ? FieldValue.serverTimestamp() : null,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next ? 'Customer blocked successfully.' : 'Customer unblocked successfully.'),
            backgroundColor: next ? Colors.red : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      activeRoute: '/users',
      title: 'User Moderation & Drivers',
      body: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'User & Driver Moderation',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Block or unblock drivers and customers instantly with real-time status updates.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                      // Search bar
                      SizedBox(
                        width: 320,
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                          decoration: InputDecoration(
                            hintText: 'Search by name, phone or email...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Tab Selector
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(text: 'Driver Partners (सारथी)'),
                      Tab(text: 'Customers (यात्री)'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildDriversList(),
                        _buildCustomersList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDriversList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('drivers').snapshots().handleError((e) => debugPrint('User management drivers error: $e')),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('Unable to load drivers: ${snapshot.error}', style: const TextStyle(color: Color(0xFF64748B)))));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        final filtered = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          final phone = (data['phoneNumber'] ?? data['phone'] ?? '').toString().toLowerCase();
          final plate = (data['vehiclePlateNumber'] ?? '').toString().toLowerCase();
          return _searchQuery.isEmpty || name.contains(_searchQuery) || phone.contains(_searchQuery) || plate.contains(_searchQuery);
        }).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('No drivers found.'));
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1020,
                child: Column(
                  children: [
                    // Horizontal Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      color: const Color(0xFFF8FAFC),
                      child: Row(
                        children: const [
                          SizedBox(
                            width: 240,
                            child: Text('DRIVER PARTNER', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                          ),
                          SizedBox(
                            width: 160,
                            child: Text('CONTACT PHONE', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                          ),
                          SizedBox(
                            width: 220,
                            child: Text('VEHICLE & PLATE', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                          ),
                          SizedBox(
                            width: 130,
                            child: Text('TOTAL TRIPS', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                          ),
                          SizedBox(
                            width: 120,
                            child: Text('STATUS', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                          ),
                          SizedBox(
                            width: 130,
                            child: Text('ACTION', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),

                    // Table Rows
                    Expanded(
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, index) {
                          final doc = filtered[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final isBlocked = data['isBlocked'] == true || data['isBlockedDueToCommission'] == true;
                          final name = data['name'] ?? data['fullName'] ?? 'Driver Partner';
                          final phone = data['phoneNumber'] ?? data['phone'] ?? 'No phone';
                          final plate = data['vehiclePlateNumber'] ?? 'Plate N/A';
                          final model = data['vehicleModel'] ?? 'Vehicle';
                          final trips = data['totalTrips'] ?? 0;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: Row(
                              children: [
                                // Driver Partner
                                SizedBox(
                                  width: 240,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: isBlocked ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isBlocked ? Icons.block : Icons.drive_eta,
                                          color: isBlocked ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                                          size: 19,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A)),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Contact Phone
                                SizedBox(
                                  width: 160,
                                  child: Text(
                                    phone,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                                  ),
                                ),

                                // Vehicle & Plate
                                SizedBox(
                                  width: 220,
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          plate,
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          model,
                                          style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Total Trips
                                SizedBox(
                                  width: 130,
                                  child: Text(
                                    '$trips trips',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  ),
                                ),

                                // Status
                                SizedBox(
                                  width: 120,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isBlocked ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isBlocked ? 'BLOCKED' : 'ACTIVE',
                                        style: TextStyle(
                                          color: isBlocked ? const Color(0xFFB91C1C) : const Color(0xFF15803D),
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Action
                                SizedBox(
                                  width: 130,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isBlocked ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        elevation: 0,
                                      ),
                                      onPressed: () => _toggleDriverBlock(doc.id, isBlocked),
                                      child: Text(
                                        isBlocked ? 'UNBLOCK' : 'BLOCK',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
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
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'customer').snapshots().handleError((e) => debugPrint('User management customers error: $e')),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('Unable to load customers: ${snapshot.error}', style: const TextStyle(color: Color(0xFF64748B)))));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        final filtered = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          final phone = (data['phoneNumber'] ?? data['phone'] ?? '').toString().toLowerCase();
          final email = (data['email'] ?? '').toString().toLowerCase();
          return _searchQuery.isEmpty || name.contains(_searchQuery) || phone.contains(_searchQuery) || email.contains(_searchQuery);
        }).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('No customers found.'));
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1020,
                child: Column(
                  children: [
                    // Horizontal Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      color: const Color(0xFFF8FAFC),
                      child: Row(
                        children: const [
                          SizedBox(
                            width: 240,
                            child: Text('CUSTOMER', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                          ),
                          SizedBox(
                            width: 160,
                            child: Text('CONTACT PHONE', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                          ),
                          SizedBox(
                            width: 220,
                            child: Text('EMAIL ADDRESS', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                          ),
                          SizedBox(
                            width: 130,
                            child: Text('DATE OF BIRTH', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                          ),
                          SizedBox(
                            width: 120,
                            child: Text('STATUS', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                          ),
                          SizedBox(
                            width: 130,
                            child: Text('ACTION', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),

                    // Table Rows
                    Expanded(
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, index) {
                          final doc = filtered[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final isBlocked = data['isBlocked'] == true;
                          final name = data['name'] ?? 'Customer';
                          final phone = data['phoneNumber'] ?? data['phone'] ?? 'No phone';
                          final email = data['email'] ?? 'No email';
                          final dob = data['dateOfBirth'] ?? 'DOB N/A';

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: Row(
                              children: [
                                // Customer
                                SizedBox(
                                  width: 240,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: isBlocked ? const Color(0xFFFEE2E2) : const Color(0xFFEFF6FF),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isBlocked ? Icons.block : Icons.person,
                                          color: isBlocked ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                                          size: 19,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A)),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Contact Phone
                                SizedBox(
                                  width: 160,
                                  child: Text(
                                    phone,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                                  ),
                                ),

                                // Email
                                SizedBox(
                                  width: 220,
                                  child: Text(
                                    email,
                                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                // Date of Birth
                                SizedBox(
                                  width: 130,
                                  child: Text(
                                    dob,
                                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155)),
                                  ),
                                ),

                                // Status
                                SizedBox(
                                  width: 120,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isBlocked ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isBlocked ? 'BLOCKED' : 'ACTIVE',
                                        style: TextStyle(
                                          color: isBlocked ? const Color(0xFFB91C1C) : const Color(0xFF15803D),
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Action
                                SizedBox(
                                  width: 130,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isBlocked ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        elevation: 0,
                                      ),
                                      onPressed: () => _toggleCustomerBlock(doc.id, isBlocked),
                                      child: Text(
                                        isBlocked ? 'UNBLOCK' : 'BLOCK',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
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
              ),
            ),
          ),
        );
      },
    );
  }
}
