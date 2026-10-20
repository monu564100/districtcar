import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import '../../widgets/admin_scaffold.dart';

class FareManagementScreen extends StatefulWidget {
  const FareManagementScreen({super.key});

  @override
  State<FareManagementScreen> createState() => _FareManagementScreenState();
}

class _FareManagementScreenState extends State<FareManagementScreen> {
  void _createCategoryDialog() {
    final idCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final displayNameCtrl = TextEditingController();
    final baseFareCtrl = TextEditingController(text: '0');
    final perKmCtrl = TextEditingController(text: '15');
    final minFareCtrl = TextEditingController(text: '60');
    final roundTripDiscountCtrl = TextEditingController(text: '0');
    final hourlyWaitingCtrl = TextEditingController(text: '60');
    final commissionCtrl = TextEditingController(text: '10');
    String selectedIcon = 'directions_car';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add New Vehicle Category', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: idCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Category ID (Unique key, e.g. "car", "suv", "auto", "premium")',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Short Name (e.g. Mini Cab, SUV)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: displayNameCtrl,
                    decoration: const InputDecoration(labelText: 'Display Name (e.g. Economy Mini Cab 4-Seater)'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedIcon,
                    decoration: const InputDecoration(labelText: 'Vehicle Icon'),
                    items: const [
                      DropdownMenuItem(value: 'directions_car', child: Text('🚗 Car / Sedan')),
                      DropdownMenuItem(value: 'directions_car_filled', child: Text('🚙 SUV / Bolero')),
                      DropdownMenuItem(value: 'electric_rickshaw', child: Text('🛺 Auto / E-Rickshaw')),
                      DropdownMenuItem(value: 'airport_shuttle', child: Text('🚐 Van / Shuttle')),
                      DropdownMenuItem(value: 'two_wheeler', child: Text('🛵 Bike / Two Wheeler')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedIcon = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: perKmCtrl,
                          decoration: const InputDecoration(labelText: 'Standard Rate / KM (₹)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: minFareCtrl,
                          decoration: const InputDecoration(labelText: 'Minimum Trip Fare (₹)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: baseFareCtrl,
                          decoration: const InputDecoration(labelText: 'Base Pickup (₹)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: hourlyWaitingCtrl,
                          decoration: const InputDecoration(labelText: 'Waiting Charge (₹/hr)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: roundTripDiscountCtrl,
                          decoration: const InputDecoration(labelText: 'Return Discount (%)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: commissionCtrl,
                          decoration: const InputDecoration(labelText: 'Commission (%)'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final id = idCtrl.text.trim().toLowerCase().replaceAll(' ', '_');
                final name = nameCtrl.text.trim();
                final displayName = displayNameCtrl.text.trim();
                if (id.isEmpty || name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill Category ID and Name')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                await FirebaseFirestore.instance.collection('vehicleCategories').doc(id).set({
                  'id': id,
                  'name': name,
                  'displayName': displayName.isNotEmpty ? displayName : name,
                  'icon': selectedIcon,
                  'image': '',
                  'baseFare': double.tryParse(baseFareCtrl.text.trim()) ?? 0.0,
                  'perKmRate': double.tryParse(perKmCtrl.text.trim()) ?? 15.0,
                  'perMinuteRate': 0.0,
                  'minimumFare': double.tryParse(minFareCtrl.text.trim()) ?? 60.0,
                  'bookingFee': 0.0,
                  'waitingCharge': 1.0,
                  'cancellationFee': 30.0,
                  'roundTripDiscountPercent': double.tryParse(roundTripDiscountCtrl.text.trim()) ?? 0.0,
                  'hourlyWaitingCharge': double.tryParse(hourlyWaitingCtrl.text.trim()) ?? 60.0,
                  'platformCommissionPercent': double.tryParse(commissionCtrl.text.trim()) ?? 10.0,
                  'isActive': true,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Category "$displayName" added successfully!'), backgroundColor: const Color(0xFF16A34A)),
                  );
                }
              },
              child: const Text('Add Category Live'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteCategoryDialog(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['displayName'] ?? data['name'] ?? doc.id;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Remove $name?', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
        content: Text('Are you sure you want to remove "$name" from Customer Home and Tours & Travels live app?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('vehicleCategories').doc(doc.id).delete();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Category "$name" removed successfully!'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Delete Category'),
          ),
        ],
      ),
    );
  }

  void _editFareDialog(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['displayName'] ?? data['name'] ?? 'Vehicle';
    final baseFareCtrl = TextEditingController(text: (data['baseFare'] ?? 0).toString());
    final perKmCtrl = TextEditingController(text: (data['perKmRate'] ?? 0).toString());
    final minFareCtrl = TextEditingController(text: (data['minimumFare'] ?? 0).toString());
    final roundTripDiscountCtrl = TextEditingController(text: (data['roundTripDiscountPercent'] ?? 35).toString());
    final hourlyWaitingCtrl = TextEditingController(text: (data['hourlyWaitingCharge'] ?? 60).toString());
    final commissionCtrl = TextEditingController(text: (data['platformCommissionPercent'] ?? 10).toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Dynamic Pricing: $name', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: baseFareCtrl, decoration: const InputDecoration(labelText: 'Base Pickup Fare (₹)')),
                const SizedBox(height: 12),
                TextField(controller: perKmCtrl, decoration: const InputDecoration(labelText: 'Standard Rate per KM (₹)')),
                const SizedBox(height: 12),
                TextField(controller: minFareCtrl, decoration: const InputDecoration(labelText: 'Minimum Trip Fare (₹)')),
                const SizedBox(height: 12),
                TextField(
                  controller: roundTripDiscountCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Round-Trip Return Discount (%)',
                    helperText: 'Default 35% discount applied on the return journey',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: hourlyWaitingCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Hourly Waiting Charge (₹/hr)',
                    helperText: 'Waiting charge applied after arrival at destination',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commissionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Platform Commission Share (%)',
                    helperText: 'Platform revenue percentage (Default 10%)',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('vehicleCategories').doc(doc.id).update({
                'baseFare': double.tryParse(baseFareCtrl.text.trim()) ?? data['baseFare'],
                'perKmRate': double.tryParse(perKmCtrl.text.trim()) ?? data['perKmRate'],
                'minimumFare': double.tryParse(minFareCtrl.text.trim()) ?? data['minimumFare'],
                'roundTripDiscountPercent': double.tryParse(roundTripDiscountCtrl.text.trim()) ?? 35.0,
                'hourlyWaitingCharge': double.tryParse(hourlyWaitingCtrl.text.trim()) ?? 60.0,
                'platformCommissionPercent': double.tryParse(commissionCtrl.text.trim()) ?? 10.0,
                'updatedAt': FieldValue.serverTimestamp(),
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pricing rate card updated successfully!'), backgroundColor: Color(0xFF16A34A)),
                );
              }
            },
            child: const Text('Save & Publish Live'),
          ),
        ],
      ),
    );
  }

  void _syncDefaultCategories() async {
    final categories = [
      {
        'id': 'car',
        'name': 'Mini Cab',
        'displayName': 'Economy Mini Cab',
        'icon': 'directions_car',
        'baseFare': 60.0,
        'perKmRate': 14.0,
        'minimumFare': 80.0,
        'roundTripDiscountPercent': 35.0,
        'hourlyWaitingCharge': 60.0,
        'platformCommissionPercent': 10.0,
        'isActive': true,
      },
      {
        'id': 'auto',
        'name': 'Auto / E-Rick',
        'displayName': 'Auto / E-Rickshaw',
        'icon': 'electric_rickshaw',
        'baseFare': 40.0,
        'perKmRate': 10.0,
        'minimumFare': 50.0,
        'roundTripDiscountPercent': 35.0,
        'hourlyWaitingCharge': 40.0,
        'platformCommissionPercent': 10.0,
        'isActive': true,
      },
      {
        'id': 'sedan',
        'name': 'Sedan',
        'displayName': 'Comfort Sedan',
        'icon': 'local_taxi',
        'baseFare': 80.0,
        'perKmRate': 17.0,
        'minimumFare': 120.0,
        'roundTripDiscountPercent': 35.0,
        'hourlyWaitingCharge': 60.0,
        'platformCommissionPercent': 10.0,
        'isActive': true,
      },
      {
        'id': 'suv',
        'name': 'Rural SUV',
        'displayName': 'Rural SUV (Bolero)',
        'icon': 'directions_car_filled',
        'baseFare': 120.0,
        'perKmRate': 22.0,
        'minimumFare': 180.0,
        'roundTripDiscountPercent': 35.0,
        'hourlyWaitingCharge': 80.0,
        'platformCommissionPercent': 10.0,
        'isActive': true,
      },
      {
        'id': 'bike',
        'name': 'Bike',
        'displayName': 'Gramin Bike',
        'icon': 'two_wheeler',
        'baseFare': 25.0,
        'perKmRate': 8.0,
        'minimumFare': 35.0,
        'roundTripDiscountPercent': 30.0,
        'hourlyWaitingCharge': 30.0,
        'platformCommissionPercent': 10.0,
        'isActive': true,
      },
    ];

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final cat in categories) {
        final ref = FirebaseFirestore.instance.collection('vehicleCategories').doc(cat['id'] as String);
        batch.set(ref, cat, SetOptions(merge: true));
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All Gramin Tariff categories synced with Website defaults!'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      activeRoute: '/fares',
      title: 'Dynamic Fares & Pricing',
      body: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Dynamic Pricing & Tariff Rate Cards', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                          SizedBox(height: 4),
                          Text(
                            'Control base fares, per-KM rates, round-trip discount %, waiting charges, and platform commission live.',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _createCategoryDialog,
                            icon: const Icon(Icons.add_circle_outline, size: 16),
                            label: const Text('Add Vehicle Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _syncDefaultCategories,
                            icon: const Icon(Icons.sync, size: 16),
                            label: const Text('Sync Default Tariff', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('vehicleCategories').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('No dynamic vehicle categories configured in Firestore.', style: TextStyle(color: Color(0xFF64748B))),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _syncDefaultCategories,
                                  child: const Text('Initialize Default Tariff Categories'),
                                ),
                              ],
                            ),
                          );
                        }

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: 1120,
                                child: Column(
                                  children: [
                                    // Horizontal Table Header
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                      color: const Color(0xFFF8FAFC),
                                      child: Row(
                                        children: const [
                                          SizedBox(
                                            width: 220,
                                            child: Text('VEHICLE CATEGORY', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                          ),
                                          SizedBox(
                                            width: 110,
                                            child: Text('BASE FARE', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                          ),
                                          SizedBox(
                                            width: 110,
                                            child: Text('RATE / KM', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                          ),
                                          SizedBox(
                                            width: 120,
                                            child: Text('MIN FARE', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                          ),
                                          SizedBox(
                                            width: 140,
                                            child: Text('RETURN DISCOUNT', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                          ),
                                          SizedBox(
                                            width: 140,
                                            child: Text('WAITING CHARGE', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                          ),
                                          SizedBox(
                                            width: 140,
                                            child: Text('COMMISSION', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                          ),
                                          SizedBox(
                                            width: 140,
                                            child: Text('ACTIONS', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(height: 1, color: Color(0xFFE2E8F0)),

                                    // Table Rows
                                    Expanded(
                                      child: ListView.separated(
                                        itemCount: docs.length,
                                        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                                        itemBuilder: (context, index) {
                                          final doc = docs[index];
                                          final data = doc.data() as Map<String, dynamic>;
                                          final name = data['displayName'] ?? data['name'] ?? 'Vehicle';
                                          final baseFare = (data['baseFare'] ?? 0).toString();
                                          final perKm = (data['perKmRate'] ?? 0).toString();
                                          final minFare = (data['minimumFare'] ?? 0).toString();
                                          final roundTripDiscount = (data['roundTripDiscountPercent'] ?? 35).toString();
                                          final waitingCharge = (data['hourlyWaitingCharge'] ?? 60).toString();
                                          final commission = (data['platformCommissionPercent'] ?? 10).toString();

                                          return Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                            child: Row(
                                              children: [
                                                // Category Name & Icon
                                                SizedBox(
                                                  width: 220,
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.all(7),
                                                        decoration: BoxDecoration(
                                                          color: AppColors.primary.withValues(alpha: 0.1),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: const Icon(Icons.directions_car, color: AppColors.primary, size: 18),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Text(
                                                          name,
                                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                // Base Fare
                                                SizedBox(
                                                  width: 110,
                                                  child: Text(
                                                    '₹$baseFare',
                                                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                                  ),
                                                ),

                                                // Rate / KM
                                                SizedBox(
                                                  width: 110,
                                                  child: Text(
                                                    '₹$perKm/km',
                                                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                                                  ),
                                                ),

                                                // Min Fare
                                                SizedBox(
                                                  width: 120,
                                                  child: Text(
                                                    '₹$minFare',
                                                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                                                  ),
                                                ),

                                                // Return Discount
                                                SizedBox(
                                                  width: 140,
                                                  child: Text(
                                                    '$roundTripDiscount% off',
                                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                                  ),
                                                ),

                                                // Waiting Charge
                                                SizedBox(
                                                  width: 140,
                                                  child: Text(
                                                    '₹$waitingCharge/hr',
                                                    style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                                                  ),
                                                ),

                                                // Commission
                                                SizedBox(
                                                  width: 140,
                                                  child: Text(
                                                    '$commission%',
                                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                                                  ),
                                                ),

                                                // Actions
                                                SizedBox(
                                                  width: 140,
                                                  child: Row(
                                                    children: [
                                                      OutlinedButton.icon(
                                                        onPressed: () => _editFareDialog(doc),
                                                        icon: const Icon(Icons.edit, size: 13),
                                                        label: const Text('Edit', style: TextStyle(fontSize: 11.5)),
                                                        style: OutlinedButton.styleFrom(
                                                          foregroundColor: AppColors.primary,
                                                          side: const BorderSide(color: AppColors.primary),
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                          minimumSize: Size.zero,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      IconButton(
                                                        icon: const Icon(Icons.delete_outline, size: 17, color: Color(0xFFDC2626)),
                                                        tooltip: 'Remove Category',
                                                        onPressed: () => _deleteCategoryDialog(doc),
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(),
                                                      ),
                                                    ],
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
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
