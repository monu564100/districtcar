import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import '../../services/driver_service.dart';

class DriverOnboardingScreen extends ConsumerStatefulWidget {
  const DriverOnboardingScreen({super.key});

  @override
  ConsumerState<DriverOnboardingScreen> createState() => _DriverOnboardingScreenState();
}

class _DriverOnboardingScreenState extends ConsumerState<DriverOnboardingScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();

  String _selectedCategory = 'car';
  String _selectedDriverPhoto = 'avatar_1';
  Uint8List? _driverPhotoBytes;

  String _selectedVehicleImage = 'assets/images/car_blue.jpg';
  Uint8List? _vehiclePhotoBytes;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _plateCtrl.dispose();
    _modelCtrl.dispose();
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

  void _submitOnboarding() async {
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
      await ref.read(driverServiceProvider).saveDriverOnboarding(
        name: name,
        phoneNumber: phone,
        vehicleCategory: _selectedCategory,
        vehiclePlate: plate,
        vehicleModel: model,
        vehicleImage: _selectedVehicleImage,
        driverPhoto: _selectedDriverPhoto,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Onboarding completed! Welcome to District Car Partner. ✅'),
            backgroundColor: Color(0xFF059669),
          ),
        );
        context.go('/driver-home');
      }
    } catch (e) {
      if (mounted) {
        context.go('/driver-home');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildDriverPhotoPreviewWidget() {
    if (_driverPhotoBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Image.memory(_driverPhotoBytes!, width: 70, height: 70, fit: BoxFit.cover),
      );
    }
    if (_selectedDriverPhoto.startsWith('data:image')) {
      try {
        final bytes = base64Decode(_selectedDriverPhoto.split(',').last);
        return ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: Image.memory(bytes, width: 70, height: 70, fit: BoxFit.cover),
        );
      } catch (_) {}
    }
    IconData icon = Icons.person;
    if (_selectedDriverPhoto == 'avatar_2') icon = Icons.face;
    if (_selectedDriverPhoto == 'avatar_3') icon = Icons.account_circle;
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF16A34A), width: 2),
      ),
      child: Icon(icon, size: 40, color: const Color(0xFF16A34A)),
    );
  }

  Widget _buildVehiclePhotoPreviewWidget() {
    if (_vehiclePhotoBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(_vehiclePhotoBytes!, width: double.infinity, height: 120, fit: BoxFit.cover),
      );
    }
    if (_selectedVehicleImage.startsWith('data:image')) {
      try {
        final bytes = base64Decode(_selectedVehicleImage.split(',').last);
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(bytes, width: double.infinity, height: 120, fit: BoxFit.cover),
        );
      } catch (_) {}
    }
    if (_selectedVehicleImage.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(_selectedVehicleImage, width: double.infinity, height: 120, fit: BoxFit.cover),
      );
    }
    final assetPath = _selectedVehicleImage.startsWith('assets/') ? _selectedVehicleImage : 'assets/images/$_selectedVehicleImage';
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        assetPath,
        width: double.infinity,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => Container(
          height: 120,
          color: Colors.grey.shade200,
          child: const Center(child: Icon(Icons.directions_car, size: 50, color: AppColors.primary)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Driver Onboarding (चालक पंजीकरण)'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF065F46), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DISTRICT CAR PARTNER REGISTRATION',
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'झारखंड वाहन एवं चालक विवरण',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Enter your personal and vehicle details to start accepting rural and district trips.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section 1: Personal Details
              _buildSectionHeader('1. DRIVER PERSONAL DETAILS (चालक की जानकारी)'),
              const SizedBox(height: 12),

              // Driver Photo Selection + Live Preview Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildDriverPhotoPreviewWidget(),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Driver Photo Preview', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(
                                _driverPhotoBytes != null ? 'Custom photo uploaded ✓' : 'Default partner avatar selected',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.upload, size: 16),
                                label: const Text('Upload Your Photo', style: TextStyle(fontSize: 12)),
                                onPressed: _pickCustomDriverPhoto,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    const Text('Or Select Avatar:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildAvatarChoice('avatar_1', Icons.person, 'Driver 1'),
                        const SizedBox(width: 12),
                        _buildAvatarChoice('avatar_2', Icons.face, 'Driver 2'),
                        const SizedBox(width: 12),
                        _buildAvatarChoice('avatar_3', Icons.account_circle, 'Driver 3'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Full Name
              const Text('Full Legal Name (पूरा नाम)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. Ramesh Mahto',
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Mobile Number
              const Text('Driver Mobile Number (मोबाइल नंबर)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '+91 94311 23456',
                  prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 28),

              // Section 2: Vehicle Details
              _buildSectionHeader('2. VEHICLE DETAILS (वाहन की जानकारी)'),
              const SizedBox(height: 14),

              // Vehicle Category Picker
              const Text('Select Vehicle Category (श्रेणी चुनें)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildCategoryCard('car', '🚗 Car / Sedan', 'स्विफ्ट / डिजायर'),
                  const SizedBox(width: 10),
                  _buildCategoryCard('auto', '🛺 Auto', '3-व्हीलर ऑटो'),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildCategoryCard('bike', '🏍️ Bike', '2-व्हीलर बाइक'),
                  const SizedBox(width: 10),
                  _buildCategoryCard('suv', '🚙 Rural SUV', 'बोलेरो / स्कॉर्पियो'),
                ],
              ),
              const SizedBox(height: 20),

              // Vehicle Registration Number Plate
              const Text('Vehicle Number Plate (गाड़ी नंबर)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: _plateCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'e.g. JH 01 BZ 4892',
                  prefixIcon: const Icon(Icons.pin, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Vehicle Model & Make
              const Text('Vehicle Make & Model (मॉडल)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: _modelCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. Maruti Suzuki Dzire AC',
                  prefixIcon: const Icon(Icons.directions_car, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              // Vehicle Photo Selection + Live Preview Card
              const Text('Vehicle Photo & Live Preview (गाड़ी का फोटो)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildVehiclePhotoPreviewWidget(),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Current Vehicle Photo', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                        Text(
                          _vehiclePhotoBytes != null ? 'Uploaded photo active ✓' : 'Selected vehicle asset',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildVehiclePhotoCard('assets/images/car_blue.jpg', 'Dzire Blue'),
                        const SizedBox(width: 12),
                        _buildVehiclePhotoCard('assets/images/car_white.jpg', 'Swift White'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.upload, size: 18),
                        label: const Text('Upload Your Own Vehicle Photo'),
                        onPressed: _pickCustomVehiclePhoto,
                      ),
                    ),
                  ],
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ],
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isLoading ? null : _submitOnboarding,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save & Start Driving (प्रोफ़ाइल सुरक्षित करें)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: AppColors.textMuted,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildAvatarChoice(String id, IconData icon, String label) {
    final isSelected = _selectedDriverPhoto == id && _driverPhotoBytes == null;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedDriverPhoto = id;
        _driverPhotoBytes = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDCFCE7) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF16A34A) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: isSelected ? const Color(0xFF16A34A) : Colors.grey.shade700),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String id, String title, String subtitle) {
    final isSelected = _selectedCategory == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFDCFCE7) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF16A34A) : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? const Color(0xFF15803D) : Colors.black87)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehiclePhotoCard(String path, String label) {
    final isSelected = _selectedVehicleImage == path && _vehiclePhotoBytes == null;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedVehicleImage = path;
          _vehiclePhotoBytes = null;
        }),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF16A34A) : Colors.grey.shade300,
              width: isSelected ? 2.5 : 1,
            ),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  path,
                  height: 60,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => const Icon(Icons.directions_car, size: 40, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
