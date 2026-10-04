import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import '../../services/driver_service.dart';

class DriverOnboardingScreen extends ConsumerStatefulWidget {
  const DriverOnboardingScreen({super.key});

  @override
  ConsumerState<DriverOnboardingScreen> createState() => _DriverOnboardingScreenState();
}

class _DriverOnboardingScreenState extends ConsumerState<DriverOnboardingScreen> {
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();

  String _selectedCategory = 'car';
  String _selectedGender = 'Male';
  File? _liveVehiclePhoto;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _plateCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  Future<void> _captureLiveVehiclePhoto() async {
    final picker = ImagePicker();
    // Enforcing camera source strictly per specification for "live vehicle photo"
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1280,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _liveVehiclePhoto = File(pickedFile.path);
      });
    }
  }

  void _submitOnboarding() async {
    final name = _nameCtrl.text.trim();
    final age = int.tryParse(_ageCtrl.text.trim());
    final make = _makeCtrl.text.trim();
    final model = _modelCtrl.text.trim();
    final plate = _plateCtrl.text.trim();

    if (name.isEmpty || age == null || make.isEmpty || model.isEmpty || plate.isEmpty) {
      setState(() => _errorMessage = 'Please fill out all required fields');
      return;
    }

    if (_liveVehiclePhoto == null) {
      setState(() => _errorMessage = 'Please take a live photo of your vehicle using camera');
      return;
    }

    final user = ref.read(driverServiceProvider).currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Upload live vehicle photo to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('drivers/${user.uid}/vehicle/live_photo_${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = await storageRef.putFile(_liveVehiclePhoto!);
      final livePhotoUrl = await uploadTask.ref.getDownloadURL();

      // 2. Register vehicle in Firestore
      final vehicleRef = FirebaseFirestore.instance.collection('vehicles').doc();
      await vehicleRef.set({
        'id': vehicleRef.id,
        'driverId': user.uid,
        'categoryId': _selectedCategory,
        'make': make,
        'model': model,
        'registrationNumber': plate,
        'color': _colorCtrl.text.trim(),
        'livePhotoUrl': livePhotoUrl,
        'verificationStatus': 'pending',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Register driver profile in Firestore with pending verification status
      await FirebaseFirestore.instance.collection('drivers').doc(user.uid).set({
        'uid': user.uid,
        'role': 'driver',
        'name': name,
        'phoneNumber': user.phoneNumber ?? '',
        'age': age,
        'gender': _selectedGender,
        'verificationStatus': 'pending',
        'isActive': true,
        'isBlocked': false,
        'isOnline': false,
        'driverStatus': 'offline',
        'vehicleId': vehicleRef.id,
        'vehicleCategoryId': _selectedCategory,
        'rating': 5.0,
        'totalTrips': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        context.go('/driver-home');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Onboarding submission failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Driver Onboarding')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Personal & Vehicle Details',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Admin will verify your vehicle and credentials before activating your account.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(hintText: 'Full Legal Name'),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ageCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Age (18+)'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedGender,
                          isExpanded: true,
                          items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                          onChanged: (v) => setState(() => _selectedGender = v!),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Vehicle Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'car', child: Text('Car')),
                      DropdownMenuItem(value: 'bike', child: Text('Bike')),
                      DropdownMenuItem(value: 'auto', child: Text('Auto')),
                      DropdownMenuItem(value: 'truck', child: Text('Truck')),
                    ],
                    onChanged: (v) => setState(() => _selectedCategory = v!),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: TextField(controller: _makeCtrl, decoration: const InputDecoration(hintText: 'Make (e.g. Maruti)'))),
                  const SizedBox(width: 14),
                  Expanded(child: TextField(controller: _modelCtrl, decoration: const InputDecoration(hintText: 'Model (e.g. Swift)'))),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: TextField(controller: _plateCtrl, decoration: const InputDecoration(hintText: 'Number Plate'))),
                  const SizedBox(width: 14),
                  Expanded(child: TextField(controller: _colorCtrl, decoration: const InputDecoration(hintText: 'Color'))),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Live Vehicle Photo (Required via Camera)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _captureLiveVehiclePhoto,
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                  ),
                  child: _liveVehiclePhoto != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(_liveVehiclePhoto!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.camera_alt_rounded, size: 40, color: AppColors.primary),
                            SizedBox(height: 8),
                            Text('Take Live Photo with Camera', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitOnboarding,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Submit Application'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
