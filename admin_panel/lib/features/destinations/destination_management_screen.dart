import 'package:flutter/material.dart';
import 'package:district_car_shared/models/models.dart';
import 'package:district_car_shared/services/destinations_service.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import '../../widgets/admin_sidebar.dart';

class DestinationManagementScreen extends StatefulWidget {
  const DestinationManagementScreen({super.key});

  @override
  State<DestinationManagementScreen> createState() => _DestinationManagementScreenState();
}

class _DestinationManagementScreenState extends State<DestinationManagementScreen> {
  String _filterCategory = 'all';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  final List<String> _jharkhandDistricts = [
    'Ranchi', 'Deoghar', 'Dhanbad', 'Bokaro', 'East Singhbhum', 'West Singhbhum',
    'Hazaribagh', 'Giridih', 'Ramgarh', 'Latehar', 'Khunti', 'Gumla', 'Lohardaga',
    'Palamu', 'Garhwa', 'Chatra', 'Koderma', 'Dumka', 'Godda', 'Jamtara', 'Pakur',
    'Sahebganj', 'Seraikela Kharsawan', 'Simdega'
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddEditDialog({PopularDestinationModel? existing, bool isComboPreselect = false}) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final addressCtrl = TextEditingController(text: existing?.locationAddress ?? '');
    final imgUrlCtrl = TextEditingController(text: existing?.imageUrl ?? '');
    final List<String> galleryUrls = List<String>.from(existing?.galleryImages ?? []);
    final newGalleryUrlCtrl = TextEditingController();
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final highlightsCtrl = TextEditingController(text: existing?.highlights.join(', ') ?? '');
    final bestTimeCtrl = TextEditingController(text: existing?.bestTimeToVisit ?? 'October to March');
    final timingsCtrl = TextEditingController(text: existing?.timings ?? '06:00 AM – 06:00 PM');
    final distKmCtrl = TextEditingController(text: existing?.approxDistanceKm.toString() ?? '45');
    final fareCtrl = TextEditingController(text: existing?.startingFare.toString() ?? '799');
    final ratingCtrl = TextEditingController(text: existing?.rating.toString() ?? '4.8');
    final latCtrl = TextEditingController(text: existing?.latitude.toString() ?? '23.3441');
    final lngCtrl = TextEditingController(text: existing?.longitude.toString() ?? '85.3096');

    // Combo Package & Extra Details
    bool isCombo = existing?.isCombo ?? (existing?.category == 'combo' || isComboPreselect);
    final packageTypeCtrl = TextEditingController(text: existing?.packageType ?? (isComboPreselect ? 'Full Day 3-in-1 Combo' : ''));
    final comboSpotsCtrl = TextEditingController(text: existing?.comboDestinations.join(', ') ?? '');
    final entryFeeCtrl = TextEditingController(text: existing?.entryFee ?? 'Free Entry');
    final timeNeededCtrl = TextEditingController(text: existing?.timeNeeded ?? 'Half Day');
    final parkingCtrl = TextEditingController(text: existing?.stepsOrParking ?? 'Parking available');
    final safetyTipsCtrl = TextEditingController(text: existing?.safetyTips.join('; ') ?? '');

    String selectedCategory = existing?.category ?? (isComboPreselect ? 'combo' : 'waterfall');
    String selectedDistrict = existing?.district ?? 'Ranchi';
    bool isTrending = existing?.isTrending ?? true;
    bool isPopular = existing?.isPopular ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(isEdit ? Icons.edit_location_alt : Icons.add_location_alt, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                isEdit ? 'Edit Tour Destination' : 'Add New Tour Destination',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ],
          ),
          content: SizedBox(
            width: 650,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Basic Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Destination Name (English & Hindi)',
                      hintText: 'e.g. Hundru Falls (हुंडरू जलप्रपात)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'combo', child: Text('Combo Package (कॉम्बो टूर पैकेज)')),
                            DropdownMenuItem(value: 'waterfall', child: Text('Waterfall (जलप्रपात)')),
                            DropdownMenuItem(value: 'temple', child: Text('Temple / Religious (मंदिर)')),
                            DropdownMenuItem(value: 'hill_station', child: Text('Hill Station (पर्वत)')),
                            DropdownMenuItem(value: 'nature', child: Text('Nature / Wildlife (प्रकृति)')),
                            DropdownMenuItem(value: 'heritage', child: Text('Historical / Heritage (धरोहर)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setDialogState(() => selectedCategory = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _jharkhandDistricts.contains(selectedDistrict) ? selectedDistrict : 'Ranchi',
                          decoration: InputDecoration(
                            labelText: 'District',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: _jharkhandDistricts
                              .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => selectedDistrict = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressCtrl,
                    decoration: InputDecoration(
                      labelText: 'Full Location Address & Landmark',
                      hintText: 'e.g. Taimara, Bundu, Ranchi-Tata Highway NH 33',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Images & Media Gallery (फोटो व गैलरी)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: imgUrlCtrl,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Primary Cover Image URL',
                      hintText: 'https://images.unsplash.com/...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  if (imgUrlCtrl.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imgUrlCtrl.text.trim(),
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Text('Invalid image link preview', style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Multiple Gallery Images Section
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: newGalleryUrlCtrl,
                          decoration: InputDecoration(
                            labelText: 'Add Additional Gallery Image URL',
                            hintText: 'Paste image link and tap Add...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onPressed: () {
                          final url = newGalleryUrlCtrl.text.trim();
                          if (url.isNotEmpty) {
                            setDialogState(() {
                              galleryUrls.add(url);
                              newGalleryUrlCtrl.clear();
                            });
                          }
                        },
                        icon: const Icon(Icons.add_photo_alternate, size: 18),
                        label: const Text('Add Image'),
                      ),
                    ],
                  ),
                  if (galleryUrls.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text('Gallery Images (${galleryUrls.length} added):', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 85,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: galleryUrls.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, gIdx) {
                          final gUrl = galleryUrls[gIdx];
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  gUrl,
                                  width: 85,
                                  height: 85,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 85,
                                    height: 85,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.broken_image, size: 20),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: InkWell(
                                  onTap: () {
                                    setDialogState(() {
                                      galleryUrls.removeAt(gIdx);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 12, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  const Text('Details & Description (विस्तृत विवरण)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descCtrl,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'Full Destination Description',
                      hintText: 'Enter comprehensive details, history, sights, nature, visiting tips...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: highlightsCtrl,
                    decoration: InputDecoration(
                      labelText: 'Key Highlights (comma-separated)',
                      hintText: '98m Drop, Subarnarekha River, Boating, Rock Picnic',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: bestTimeCtrl,
                          decoration: InputDecoration(
                            labelText: 'Best Time to Visit',
                            hintText: 'October to March',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: timingsCtrl,
                          decoration: InputDecoration(
                            labelText: 'Visiting Timings',
                            hintText: '06:00 AM – 06:00 PM',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: distKmCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Approx Distance (km)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: fareCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Starting Tour Fare (₹)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: ratingCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Rating (e.g. 4.8)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: isTrending,
                        onChanged: (v) => setDialogState(() => isTrending = v ?? false),
                      ),
                      const Text('Mark as Trending 🔥', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 20),
                      Checkbox(
                        value: isPopular,
                        onChanged: (v) => setDialogState(() => isPopular = v ?? true),
                      ),
                      const Text('Active & Visible in App', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter destination name')),
                  );
                  return;
                }

                final highlights = highlightsCtrl.text
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();

                final comboSpots = comboSpotsCtrl.text
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();

                final safetyTips = safetyTipsCtrl.text
                    .split(';')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();

                final model = PopularDestinationModel(
                  id: existing?.id ?? '',
                  name: name,
                  category: selectedCategory,
                  district: selectedDistrict,
                  locationAddress: addressCtrl.text.trim(),
                  latitude: double.tryParse(latCtrl.text.trim()) ?? 23.3441,
                  longitude: double.tryParse(lngCtrl.text.trim()) ?? 85.3096,
                  imageUrl: imgUrlCtrl.text.trim().isNotEmpty
                      ? imgUrlCtrl.text.trim()
                      : 'https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?auto=format&fit=crop&w=1200&q=80',
                  description: descCtrl.text.trim(),
                  bestTimeToVisit: bestTimeCtrl.text.trim(),
                  timings: timingsCtrl.text.trim(),
                  rating: double.tryParse(ratingCtrl.text.trim()) ?? 4.8,
                  approxDistanceKm: double.tryParse(distKmCtrl.text.trim()) ?? 45.0,
                  startingFare: double.tryParse(fareCtrl.text.trim()) ?? 799.0,
                  isTrending: isTrending,
                  isPopular: isPopular,
                  highlights: highlights,
                  galleryImages: galleryUrls,
                  isCombo: isCombo || selectedCategory == 'combo',
                  comboDestinations: comboSpots,
                  packageType: packageTypeCtrl.text.trim(),
                  entryFee: entryFeeCtrl.text.trim(),
                  timeNeeded: timeNeededCtrl.text.trim(),
                  stepsOrParking: parkingCtrl.text.trim(),
                  safetyTips: safetyTips,
                  imageCredit: 'District Car Verified Partner / Tourism Dept',
                );

                Navigator.pop(ctx);
                if (isEdit) {
                  await DestinationsService.updateDestination(model);
                } else {
                  await DestinationsService.addDestination(model);
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEdit ? 'Destination updated!' : 'New destination added successfully! ✅'),
                      backgroundColor: const Color(0xFF16A34A),
                    ),
                  );
                }
              },
              child: Text(isEdit ? 'Save Changes' : 'Add Destination'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(PopularDestinationModel dest) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${dest.name}"?'),
        content: const Text('Are you sure you want to remove this tour destination?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await DestinationsService.deleteDestination(dest.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Destination deleted!')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _seedDefaultDestinations() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sync Default Destinations'),
        content: const Text('This will populate Firestore with 13+ authentic Jharkhand tourist spots (Waterfalls, Baidyanath Dham, Netarhat, etc.). Proceed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await DestinationsService.seedDefaultDestinations();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Synced 13+ default destinations successfully! ✅'), backgroundColor: Color(0xFF16A34A)),
                );
              }
            },
            child: const Text('Sync Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Row(
        children: [
          const AdminSidebar(activeRoute: '/destinations'),
          Expanded(
            child: Column(
              children: [
                // Top Header Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Tours & Popular Places (पर्यटन स्थल प्रबंधन)',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Manage waterfalls, temples, hill stations, description, images & tour pricing',
                            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: _seedDefaultDestinations,
                            icon: const Icon(Icons.sync_rounded, size: 18),
                            label: const Text('Sync Default 13+ Spots'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0F766E),
                              side: const BorderSide(color: Color(0xFF0F766E)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          ElevatedButton.icon(
                            onPressed: () => _showAddEditDialog(isComboPreselect: true),
                            icon: const Icon(Icons.card_giftcard_rounded, size: 18),
                            label: const Text('Launch Combo Package'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD97706),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: () => _showAddEditDialog(),
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: const Text('Add Destination'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Filters & Search Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  color: Colors.white,
                  child: Row(
                    children: [
                      // Search
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Search by name, district, or address...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Filter by category
                      DropdownButton<String>(
                        value: _filterCategory,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Categories')),
                          DropdownMenuItem(value: 'combo', child: Text('Combo Packages (कॉम्बो पैकेज)')),
                          DropdownMenuItem(value: 'waterfall', child: Text('Waterfalls (जलप्रपात)')),
                          DropdownMenuItem(value: 'temple', child: Text('Temples (मंदिर)')),
                          DropdownMenuItem(value: 'hill_station', child: Text('Hill Stations (पर्वत)')),
                          DropdownMenuItem(value: 'nature', child: Text('Nature (प्रकृति)')),
                          DropdownMenuItem(value: 'heritage', child: Text('Heritage (धरोहर)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _filterCategory = val);
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Destinations List Stream
                Expanded(
                  child: StreamBuilder<List<PopularDestinationModel>>(
                    stream: DestinationsService.streamDestinations(),
                    builder: (context, snapshot) {
                      final list = snapshot.data ?? DestinationsService.defaultDestinations;

                      final filtered = list.where((d) {
                        final catMatch = _filterCategory == 'all' || d.category == _filterCategory || (_filterCategory == 'combo' && (d.isCombo || d.category == 'combo'));
                        final q = _searchQuery.toLowerCase().trim();
                        final qMatch = q.isEmpty ||
                            d.name.toLowerCase().contains(q) ||
                            d.district.toLowerCase().contains(q) ||
                            d.locationAddress.toLowerCase().contains(q);
                        return catMatch && qMatch;
                      }).toList();

                      if (filtered.isEmpty) {
                        return const Center(child: Text('No destinations found'));
                      }

                      return Container(
                        margin: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
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
                                          width: 80,
                                          child: Text('PHOTO', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                        ),
                                        SizedBox(
                                          width: 240,
                                          child: Text('DESTINATION NAME & LOCATION', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                        ),
                                        SizedBox(
                                          width: 140,
                                          child: Text('CATEGORY', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                        ),
                                        SizedBox(
                                          width: 130,
                                          child: Text('DISTRICT', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                        ),
                                        SizedBox(
                                          width: 130,
                                          child: Text('DISTANCE', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                        ),
                                        SizedBox(
                                          width: 140,
                                          child: Text('STARTING FARE', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                        ),
                                        SizedBox(
                                          width: 130,
                                          child: Text('POPULARITY', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                        ),
                                        SizedBox(
                                          width: 100,
                                          child: Text('ACTIONS', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
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
                                        final item = filtered[index];
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          child: Row(
                                            children: [
                                              // Photo
                                              SizedBox(
                                                width: 80,
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(10),
                                                  child: Image.network(
                                                    item.imageUrl,
                                                    width: 52,
                                                    height: 52,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => Container(
                                                      width: 52,
                                                      height: 52,
                                                      color: Colors.grey.shade300,
                                                      child: const Icon(Icons.image, size: 20),
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              // Name & Location
                                              SizedBox(
                                                width: 240,
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.name,
                                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      item.locationAddress,
                                                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // Category
                                              SizedBox(
                                                width: 140,
                                                child: Align(
                                                  alignment: Alignment.centerLeft,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFDCFCE7),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      item.category.toUpperCase(),
                                                      style: const TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold, fontSize: 10.5),
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              // District
                                              SizedBox(
                                                width: 130,
                                                child: Text(
                                                  item.district,
                                                  style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                                                ),
                                              ),

                                              // Distance
                                              SizedBox(
                                                width: 130,
                                                child: Text(
                                                  '~${item.approxDistanceKm.toInt()} km',
                                                  style: const TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.bold),
                                                ),
                                              ),

                                              // Starting Fare
                                              SizedBox(
                                                width: 140,
                                                child: Text(
                                                  '₹${item.startingFare.toInt()}',
                                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: Color(0xFF059669)),
                                                ),
                                              ),

                                              // Popularity
                                              SizedBox(
                                                width: 130,
                                                child: item.isTrending
                                                    ? Row(
                                                        children: const [
                                                          Text('🔥 Trending', style: TextStyle(color: Colors.orange, fontSize: 11.5, fontWeight: FontWeight.bold)),
                                                        ],
                                                      )
                                                    : const Text('Standard', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5)),
                                              ),

                                              // Actions
                                              SizedBox(
                                                width: 100,
                                                child: Row(
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(Icons.edit, size: 18, color: AppColors.primary),
                                                      tooltip: 'Edit Destination',
                                                      onPressed: () => _showAddEditDialog(existing: item),
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    IconButton(
                                                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                                      tooltip: 'Delete Destination',
                                                      onPressed: () => _confirmDelete(item),
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
        ],
      ),
    );
  }
}
