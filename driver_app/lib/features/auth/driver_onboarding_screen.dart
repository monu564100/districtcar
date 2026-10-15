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
  bool _showingRegistrationForm = true;
  final PageController _pageController = PageController();

  // Registration Form Controllers
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _locationAddressCtrl = TextEditingController();

  String _selectedDistrict = 'Khunti';
  String _selectedBlock = 'Murhu';
  String _selectedCategory = 'car';

  String? _selectedDriverPhoto;
  Uint8List? _driverPhotoBytes;

  String? _selectedVehicleImage;
  Uint8List? _vehiclePhotoBytes;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final user = ref.read(driverServiceProvider).currentUser;
    if (user != null) {
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        _nameCtrl.text = user.displayName!;
      }
      if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
        _phoneCtrl.text = user.phoneNumber!;
      }
    }
    _locationAddressCtrl.text = '$_selectedBlock Stand / Chowk, $_selectedDistrict';
    _modelCtrl.text = 'Maruti WagonR / Alto';
  }

  final List<Map<String, String>> _onboardingSlides = [
    {
      'image': 'assets/images/driver_onboarding_1_earn.jpg',
      'title': 'Guaranteed Daily Earnings',
      'subtitle': 'Unlimited Daily Earnings & Direct Bookings',
      'description':
          'Receive continuous bookings from rural villages to district headquarters without any middlemen or unfair deductions.',
    },
    {
      'image': 'assets/images/driver_onboarding_2_rural.jpg',
      'title': 'Stand to Hospital & Town Connectivity',
      'subtitle': 'Village Stand to District Hospital & Town',
      'description':
          'Accept trips directly from your local stand or chowk. Enjoy round-trip and tour packages with double return earnings.',
    },
    {
      'image': 'assets/images/driver_onboarding_3_wallet.jpg',
      'title': 'Instant Wallet Credit & Transparent Fares',
      'subtitle': 'Instant Wallet Credit & Transparent Fares',
      'description':
          'Trips credit directly to your partner wallet upon completion. 100% transparent rates and 24x7 local partner support.',
    },
  ];

  final List<Map<String, dynamic>> _vehicleCategories = [
    {
      'id': 'car',
      'name': 'Economy Mini',
      'category': 'Hatchback (Alto, WagonR)',
      'image': 'assets/images/icon_vehicle_mini.jpg',
      'defaultModel': 'Maruti WagonR / Alto',
    },
    {
      'id': 'sedan',
      'name': 'Prime Sedan',
      'category': 'Sedan (Dzire, Etios, Aura)',
      'image': 'assets/images/icon_vehicle_sedan.jpg',
      'defaultModel': 'Maruti Suzuki Dzire AC',
    },
    {
      'id': 'suv',
      'name': 'Rural SUV',
      'category': 'Bolero, Scorpio, Ertiga',
      'image': 'assets/images/icon_vehicle_suv.jpg',
      'defaultModel': 'Mahindra Bolero Neo AC',
    },
    {
      'id': 'auto',
      'name': 'Auto Rickshaw',
      'category': '3-Seater Passenger Auto',
      'image': 'assets/images/icon_vehicle_auto.jpg',
      'defaultModel': 'Bajaj Compact Auto',
    },
    {
      'id': 'bike',
      'name': 'Moto Bike',
      'category': 'Commuter Motorcycle',
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
          _errorMessage = null;
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
          _errorMessage = null;
        });
      }
    } catch (_) {}
  }

  void _submitRegistration() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final plate = _plateCtrl.text.trim().toUpperCase();
    final model = _modelCtrl.text.trim();
    final address = _locationAddressCtrl.text.trim();

    // 1. Mandatory Profile Photo Check
    if (_driverPhotoBytes == null && (_selectedDriverPhoto == null || _selectedDriverPhoto!.isEmpty)) {
      setState(() => _errorMessage = 'Driver profile photo is required. Please upload your photo.');
      return;
    }

    // 2. Name Check
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Full Name is required. Please enter your name.');
      return;
    }

    // 3. Phone Check
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.length < 10) {
      setState(() => _errorMessage = 'Valid 10-digit mobile number is required.');
      return;
    }

    // 4. Address Check
    if (address.isEmpty) {
      setState(() => _errorMessage = 'Fixed stand / hotspot location address is required.');
      return;
    }

    // 5. Plate Check
    if (plate.isEmpty) {
      setState(() => _errorMessage = 'Vehicle plate registration number is required (e.g. JH 01 BZ 4892).');
      return;
    }

    // 6. Model Check
    if (model.isEmpty) {
      setState(() => _errorMessage = 'Vehicle model name is required (e.g. Maruti Dzire, Bolero, Auto).');
      return;
    }

    // 7. Mandatory Car Photo Check ("car photo must")
    if (_vehiclePhotoBytes == null && (_selectedVehicleImage == null || _selectedVehicleImage!.isEmpty)) {
      setState(() => _errorMessage = 'Car/Vehicle photo is required. Please upload your vehicle photo.');
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
        vehicleImage: _selectedVehicleImage ?? 'assets/images/car_blue.jpg',
        driverPhoto: _selectedDriverPhoto ?? 'avatar_1',
        district: _selectedDistrict,
        block: _selectedBlock,
        locationAddress: address,
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

  // VIEW 1: SWIPEABLE 3-IMAGE CAROUSEL ONBOARDING (INFORMATIONAL)
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
              'Proceed to Register',
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
                                      ? 'NEXT'
                                      : 'REGISTER VEHICLE',
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

  // VIEW 2: MANDATORY PARTNER & VEHICLE REGISTRATION FORM
  Widget _buildRegistrationView() {
    final blocks = JharkhandDistrictData.getBlocksForDistrict(_selectedDistrict);
    if (!blocks.contains(_selectedBlock)) {
      _selectedBlock = blocks.isNotEmpty ? blocks.first : '';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Partner Registration', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF065F46), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.assignment_ind, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Complete Your Driver Profile',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Upload your profile photo and car photo to start receiving trips.',
                            style: TextStyle(color: Colors.white70, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

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
              _buildSectionTitle('1. DRIVER PARTNER DETAILS'),
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
                            children: [
                              Row(
                                children: [
                                  const Text('Driver Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _driverPhotoBytes != null ? const Color(0xFFDCFCE7) : const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _driverPhotoBytes != null ? 'Uploaded ✅' : 'Required *',
                                      style: TextStyle(
                                        color: _driverPhotoBytes != null ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              const Text('Tap to capture or upload profile photo', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Driver Full Name *',
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

              // Section 2: Fixed Stand Address & Location
              _buildSectionTitle('2. FIXED STAND & HOTSPOT LOCATION'),
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
                        labelText: 'Home District *',
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
                        labelText: 'Block / Tehsil *',
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
                        labelText: 'Fixed Stand / Chowk Location *',
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

              // Section 3: Vehicle Category & Car Photo Upload
              _buildSectionTitle('3. VEHICLE CATEGORY & DETAILS'),
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
                    const Text('Select Vehicle Category:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                                  cat['category'],
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
                        labelText: 'Vehicle Plate Number (e.g. JH 01 BZ 4892) *',
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
                        labelText: 'Vehicle Model & Name (e.g. Maruti Dzire AC) *',
                        prefixIcon: const Icon(Icons.directions_car, color: Color(0xFF059669)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Car Image Upload (MANDATORY)
                    InkWell(
                      onTap: _pickCustomVehiclePhoto,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _vehiclePhotoBytes != null ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _vehiclePhotoBytes != null ? const Color(0xFF059669) : Colors.grey.shade300,
                            width: _vehiclePhotoBytes != null ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            if (_vehiclePhotoBytes != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(_vehiclePhotoBytes!, width: 54, height: 54, fit: BoxFit.cover),
                              )
                            else
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.add_a_photo, color: Color(0xFFDC2626), size: 28),
                              ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        _vehiclePhotoBytes != null ? 'Vehicle Photo Uploaded ✅' : 'Upload Vehicle Photo',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: _vehiclePhotoBytes != null ? const Color(0xFF065F46) : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _vehiclePhotoBytes != null ? const Color(0xFFDCFCE7) : const Color(0xFFFEF2F2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          _vehiclePhotoBytes != null ? 'Ready' : 'Mandatory *',
                                          style: TextStyle(
                                            color: _vehiclePhotoBytes != null ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _vehiclePhotoBytes != null
                                        ? 'Tap to change vehicle photo'
                                        : 'Tap to capture or upload car photo from gallery',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                  ),
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
                              'PROCEED TO PARTNER CONSENT',
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
