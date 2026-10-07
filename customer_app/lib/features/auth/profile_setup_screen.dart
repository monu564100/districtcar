import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import 'auth_service.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _dobController = TextEditingController();
  DateTime? _selectedDob;
  String _selectedGender = 'Male';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _pickDateOfBirth() async {
    final now = DateTime.now();
    final initialDate = _selectedDob ?? DateTime(now.year - 20, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1930),
      lastDate: DateTime(now.year - 12, now.month, now.day),
      helpText: 'SELECT DATE OF BIRTH',
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  void _submitProfile() async {
    final name = _nameController.text.trim();
    final mobile = _mobileController.text.trim();
    final dob = _dobController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your Full Name');
      return;
    }
    if (mobile.isEmpty || mobile.replaceAll(RegExp(r'\D'), '').length < 10) {
      setState(() => _errorMessage = 'Please enter a valid 10-digit Mobile Number');
      return;
    }
    if (dob.isEmpty) {
      setState(() => _errorMessage = 'Please select your Date of Birth (DOB)');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authServiceProvider).createCustomerProfile(
        name: name,
        mobileNumber: mobile,
        dateOfBirth: dob,
        gender: _selectedGender,
      );

      if (mounted) {
        context.go('/');
      }
    } catch (_) {
      if (mounted) {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Complete Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome to District Car',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Please introduce yourself to start booking rides.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 32),
              const Text('Full Name *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Enter your full name',
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Mobile Number *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '10-digit mobile number',
                  prefixIcon: Icon(Icons.phone_iphone_outlined, color: AppColors.primary),
                  prefixText: '+91 ',
                  prefixStyle: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Date of Birth (DOB) *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDateOfBirth,
                borderRadius: BorderRadius.circular(16),
                child: IgnorePointer(
                  child: TextField(
                    controller: _dobController,
                    decoration: const InputDecoration(
                      hintText: 'DD/MM/YYYY',
                      prefixIcon: Icon(Icons.calendar_month_outlined, color: AppColors.primary),
                      suffixIcon: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Gender', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedGender,
                    isExpanded: true,
                    items: ['Male', 'Female', 'Other'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) setState(() => _selectedGender = newValue);
                    },
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 20),
                Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ],
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitProfile,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Save & Start Riding'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
