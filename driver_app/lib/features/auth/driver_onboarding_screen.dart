import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import 'package:district_car_shared/services/jharkhand_district_data.dart';
import '../../services/driver_service.dart';

class DriverOnboardingScreen extends ConsumerStatefulWidget {
  const DriverOnboardingScreen({super.key});

  @override
  ConsumerState<DriverOnboardingScreen> createState() => _DriverOnboardingScreenState();
}

class _DriverOnboardingScreenState extends ConsumerState<DriverOnboardingScreen> {
  int _currentSlide = 0;
  bool _showingRegistrationForm = false;
  final PageController _pageController = PageController();

  // Registration Form Controllers
  final _nameCtrl = TextEditingController(text: 'Ramesh Mahto');
  final _phoneCtrl = TextEditingController(text: '+91 94311 23456');
  final _plateCtrl = TextEditingController(text: 'JH 01 BZ 4892');
  final _modelCtrl = TextEditingController(text: 'Maruti Suzuki Dzire AC');
  final _locationAddressCtrl = TextEditingController(text: 'Murhu Chowk / Lac Stand, Khunti');

  String _selectedDistrict = 'Khunti';
  String _selectedBlock = 'Murhu';
  String _selectedCategory = 'car';
  String _selectedDriverPhoto = 'avatar_1';
  Uint8List? _driverPhotoBytes;

  String _selectedVehicleImage = 'assets/images/car_blue.jpg';
  Uint8List? _vehiclePhotoBytes;

  bool _isLoading = false;
  String? _errorMessage;

  final List<Map<String, String>> _onboardingSlides = [
    {
      'image': 'assets/images/driver_onboarding_1_earn.jpg',
      'title': 'झारखंड में रोज़ाना पक्की कमाई',
      'subtitle': 'Unlimited Daily Earnings & Direct Bookings',
      'description':
          'गांव-कस्बे से जिला मुख्यालय तक बिना किसी बिचौलिए या कमीशन कटौती के लगातार बुकिंग्स पाएं।',
    },
    {
      'image': 'assets/images/driver_onboarding_2_rural.jpg',
      'title': 'गांव से अस्पताल व शहर तक कनेक्टिविटी',
      'subtitle': 'Village Stand to District Hospital & Town',
      'description':
          'अपने गांव के स्टैंड या चौक से ही ट्रिप्स पाएं। राउंड-ट्रिप और टूर पैकेजों पर डबल रिटर्न फायदा।',
    },
    {
      'image': 'assets/images/driver_onboarding_3_wallet.jpg',
      'title': 'वॉलेट में तुरंत क्रेडिट व पारदर्शी किराया',
      'subtitle': 'Instant Wallet Credit & Transparent Fares',
      'description':
          'ट्रिप पूरी होते ही पैसा सीधे आपके पार्टनर वॉलेट में। 100% पारदर्शी दरें और 24x7 स्थानीय सपोर्ट।',
    },
  ];

  final List<Map<String, dynamic>> _vehicleCategories = [
    {
      'id': 'car',
      'name': 'Economy Mini',
      'hindi': 'मिनी कैब (Alto/WagonR)',
      'image': 'assets/images/icon_vehicle_mini.jpg',
      'defaultModel': 'Maruti WagonR / Alto',
    },
    {
      'id': 'sedan',
      'name': 'Prime Sedan',
      'hindi': 'सेडान (Dzire/Etios)',
      'image': 'assets/images/icon_vehicle_sedan.jpg',
      'defaultModel': 'Maruti Suzuki Dzire AC',
    },
    {
      'id': 'suv',
      'name': 'Rural SUV / Bolero',
      'hindi': 'बोलेरो / स्कॉर्पियो',
      'image': 'assets/images/icon_vehicle_suv.jpg',
      'defaultModel': 'Mahindra Bolero Neo AC',
    },
    {
      'id': 'auto',
      'name': 'Auto Rickshaw',
      'hindi': 'ऑटो रिक्शा (3-सीटर)',
      'image': 'assets/images/icon_vehicle_auto.jpg',
      'defaultModel': 'Bajaj Compact Auto',
    },
    {
      'id': 'bike',
      'name': 'Moto Bike',
      'hindi': 'बाइक राइड (1 पैसेंजर)',
      'image': 'assets/images/icon_vehicle_bike.jpg',
      'defaultModel': 'Hero Splendor / Honda Shine',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _plateCtrl.dispose();
    _modelCtrl.dispose();
    _locationAddressCtrl.dispose();
    super.dispose();
  }

  void _pickCustomDriverPhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 600, imageQuality: 80);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _driverPhotoBytes = bytes;
          _selectedDriverPhoto = base64Image;
        });
      }
    } catch (_) {}
  }

  void _pickCustomVehiclePhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 80);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _vehiclePhotoBytes = bytes;
          _selectedVehicleImage = base64Image;
        });
      }
    } catch (_) {}
  }

  void _submitRegistration() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final plate = _plateCtrl.text.trim();
    final model = _modelCtrl.text.trim();

    if (name.isEmpty || phone.isEmpty || plate.isEmpty || model.isEmpty) {
      setState(() => _errorMessage = 'कृपया सभी आवश्यक फ़ील्ड भरें (Please fill all required fields)');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final blockLoc = JharkhandDistrictData.getBlockLocation(_selectedDistrict, _selectedBlock);
      await ref.read(driverServiceProvider).saveDriverOnboarding(
        name: name,
        phoneNumber: phone,
        vehicleCategory: _selectedCategory,
        vehiclePlate: plate,
        vehicleModel: model,
        vehicleImage: _selectedVehicleImage,
        driverPhoto: _selectedDriverPhoto,
        district: _selectedDistrict,
        block: _selectedBlock,
        locationAddress: _locationAddressCtrl.text.trim().isNotEmpty
            ? _locationAddressCtrl.text.trim()
            : '$_selectedBlock, $_selectedDistrict, Jharkhand',
        latitude: blockLoc.latitude,
        longitude: blockLoc.longitude,
      );

      if (mounted) {
        // Direct to Mandatory Consent Screen
        context.go('/driver-consent');
      }
    } catch (e) {
      if (mounted) {
        context.go('/driver-consent');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showingRegistrationForm) {
      return _buildRegistrationView();
    }
    return _buildCarouselView();
  }

  // VIEW 1: SWIPEABLE 3-IMAGE CAROUSEL ONBOARDING
  Widget _buildCarouselView() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => setState(() => _showingRegistrationForm = true),
            child: const Text(
              'Skip to Register (स्किप करें)',
              style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingSlides.length,
                onPageChanged: (i) => setState(() => _currentSlide = i),
                itemBuilder: (context, index) {
                  final slide = _onboardingSlides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // High-Quality 3D Graphic Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            height: 290,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              slide['image']!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.drive_eta, size: 70, color: Color(0xFF059669)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Title & Subtitle
                        Text(
                          slide['title']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          slide['subtitle']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            slide['description']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Colors.grey.shade600,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Dots Indicator & Action Buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingSlides.length,
                      (idx) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentSlide == idx ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentSlide == idx ? const Color(0xFF059669) : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      if (_currentSlide > 0)
                        IconButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          icon: const Icon(Icons.arrow_back),
                        ),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () {
                              if (_currentSlide < _onboardingSlides.length - 1) {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              } else {
                                setState(() => _showingRegistrationForm = true);
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentSlide < _onboardingSlides.length - 1
                                      ? 'NEXT (आगे बढ़ें)'
                                      : 'REGISTER VEHICLE (पंजीकरण शुरू करें)',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, letterSpacing: 0.5),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // VIEW 2: PREMIUM REGISTRATION & CAR LOCATION FORM
  Widget _buildRegistrationView() {
    final blocks = JharkhandDistrictData.getBlocksForDistrict(_selectedDistrict);
    if (!blocks.contains(_selectedBlock)) {
      _selectedBlock = blocks.isNotEmpty ? blocks.first : '';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Partner Registration (वाहन पंजीकरण)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _showingRegistrationForm = false),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error banner
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Section 1: Driver Details
              _buildSectionTitle('1. DRIVER PARTNER DETAILS (चालक विवरण)'),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: _pickCustomDriverPhoto,
                          borderRadius: BorderRadius.circular(40),
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: const Color(0xFFDCFCE7),
                                backgroundImage: _driverPhotoBytes != null
                                    ? MemoryImage(_driverPhotoBytes!)
                                    : const AssetImage('assets/images/avatar_commuter_3d.jpg') as ImageProvider,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF059669),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Driver Photo / सेल्फी', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              SizedBox(height: 2),
                              Text('Tap icon to upload custom profile photo', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Driver Full Name (पूरा नाम) *',
                        prefixIcon: const Icon(Icons.person, color: Color(0xFF059669)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'WhatsApp / Mobile Number *',
                        prefixIcon: const Icon(Icons.phone, color: Color(0xFF059669)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section 2: Fixed Car-Address & Stand Location
              _buildSectionTitle('2. FIXED CAR ADDRESS & STAND (गाड़ी का मुख्य स्टैंड / हॉटस्पॉट)'),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
                  ],
                ),
                child: Column(
                  children: [
                    // District Dropdown (24 Districts of Jharkhand)
                    DropdownButtonFormField<String>(
                      value: _selectedDistrict,
                      decoration: InputDecoration(
                        labelText: 'Home District (जिला) *',
                        prefixIcon: const Icon(Icons.map, color: Color(0xFF059669)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                      items: JharkhandDistrictData.allDistricts.map((d) {
                        return DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13.5)));
                      }).toList(),
                      onChanged: (newDist) {
                        if (newDist != null) {
                          setState(() {
                            _selectedDistrict = newDist;
                            final newBlocks = JharkhandDistrictData.getBlocksForDistrict(newDist);
                            _selectedBlock = newBlocks.isNotEmpty ? newBlocks.first : '';
                            _locationAddressCtrl.text = '$_selectedBlock Stand / Chowk, $newDist';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Block Dropdown
                    DropdownButtonFormField<String>(
                      value: blocks.contains(_selectedBlock) ? _selectedBlock : (blocks.isNotEmpty ? blocks.first : null),
                      decoration: InputDecoration(
                        labelText: 'Block / Tehsil (प्रखंड / ब्लॉक) *',
                        prefixIcon: const Icon(Icons.location_city, color: Color(0xFF059669)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                      items: blocks.map((b) {
                        return DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13.5)));
                      }).toList(),
                      onChanged: (newBlk) {
                        if (newBlk != null) {
                          setState(() {
                            _selectedBlock = newBlk;
                            _locationAddressCtrl.text = '$newBlk Stand / Chowk, $_selectedDistrict';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Fixed Stand / Hotspot Address
                    TextField(
                      controller: _locationAddressCtrl,
                      decoration: InputDecoration(
                        labelText: 'Fixed Stand / Chowk Address (गाड़ी रुकने का स्थान) *',
                        prefixIcon: const Icon(Icons.my_location, color: Color(0xFF059669)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section 3: Dynamic Category Selection with Car Images
              _buildSectionTitle('3. VEHICLE CATEGORY & DETAILS (वाहन श्रेणी व फोटो)'),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Your Vehicle Category (श्रेणी चुनें):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 12),

                    // Horizontal / Wrap Category Cards
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _vehicleCategories.map((cat) {
                        final isSelected = _selectedCategory == cat['id'];
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCategory = cat['id'];
                              _modelCtrl.text = cat['defaultModel'];
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: (MediaQuery.of(context).size.width - 70) / 2,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF059669) : Colors.grey.shade200,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    cat['image'],
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.directions_car, color: Color(0xFF059669), size: 36),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  cat['name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    color: isSelected ? const Color(0xFF065F46) : const Color(0xFF0F172A),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  cat['hindi'],
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isSelected ? const Color(0xFF059669) : Colors.grey.shade600,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Plate Number
                    TextField(
                      controller: _plateCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Vehicle Plate Number (गाड़ी नंबर, उदा. JH 01 BZ 4892) *',
                        prefixIcon: const Icon(Icons.pin, color: Color(0xFF059669)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Vehicle Model
                    TextField(
                      controller: _modelCtrl,
                      decoration: InputDecoration(
                        labelText: 'Car Model / Name (गाड़ी का मॉडल) *',
                        prefixIcon: const Icon(Icons.directions_car, color: Color(0xFF059669)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Car Image Upload
                    InkWell(
                      onTap: _pickCustomVehiclePhoto,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                        ),
                        child: Row(
                          children: [
                            if (_vehiclePhotoBytes != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(_vehiclePhotoBytes!, width: 50, height: 50, fit: BoxFit.cover),
                              )
                            else
                              const Icon(Icons.add_a_photo, color: Color(0xFF059669), size: 32),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _vehiclePhotoBytes != null ? 'Custom Vehicle Photo Added ✅' : 'Upload Vehicle Photo (गाड़ी की फोटो)',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text('Tap to capture or upload from gallery', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit & Proceed to Consent Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isLoading ? null : _submitRegistration,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'PROCEED TO PARTNER CONSENT (सहमति पत्र)',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, letterSpacing: 0.5),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.8),
      ),
    );
  }
}
