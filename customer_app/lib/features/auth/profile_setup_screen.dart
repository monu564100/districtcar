import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:district_car_shared/services/location_search_service.dart';
import '../../theme/theme.dart';
import '../../services/haptic_service.dart';
import 'auth_service.dart';

/// New User Onboarding Screen
/// Displays high-quality 3D onboarding welcome illustration,
/// and collects Name, Phone Number, Date of Birth (DOB), and Address
/// with 1-tap GPS auto-fill before routing to the rider's destination.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  final String? redirectPath;
  const ProfileSetupScreen({super.key, this.redirectPath});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();

  DateTime? _selectedDob;
  bool _isLoading = false;
  bool _isDetectingGps = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authServiceProvider).currentUser;
      if (user != null) {
        if (user.displayName != null && user.displayName!.isNotEmpty && user.displayName != 'Customer') {
          _nameController.text = user.displayName!;
        }
        if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
          final rawPhone = user.phoneNumber!.replaceAll('+91', '').replaceAll(' ', '');
          if (rawPhone.length >= 10) {
            _mobileController.text = rawPhone.substring(rawPhone.length - 10);
          }
        }
        if (user.dateOfBirth != null && user.dateOfBirth!.isNotEmpty) {
          _dobController.text = user.dateOfBirth!;
        }
        if (user.address != null && user.address!.isNotEmpty) {
          _addressController.text = user.address!;
        }
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _pickDateOfBirth() async {
    HapticService.selectionClick();
    final now = DateTime.now();
    final initialDate = _selectedDob ?? DateTime(now.year - 20, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1930),
      lastDate: DateTime(now.year - 12, now.month, now.day),
      helpText: 'SELECT DATE OF BIRTH',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTokens.primary,
              onPrimary: Colors.white,
              onSurface: AppTokens.ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  void _detectGpsAddress() async {
    HapticService.selectionClick();
    setState(() => _isDetectingGps = true);
    try {
      final loc = await LocationSearchService().getCurrentDeviceLocation();
      if (!mounted) return;
      if (loc != null) {
        final detected = loc.toLocationModel().address;
        if (detected.isNotEmpty) {
          setState(() {
            _addressController.text = detected;
            _isDetectingGps = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.my_location_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Address detected from current GPS location!'),
                ],
              ),
              backgroundColor: AppTokens.primary,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          setState(() => _isDetectingGps = false);
        }
      } else {
        setState(() => _isDetectingGps = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isDetectingGps = false);
    }
  }

  void _submitProfile() async {
    final name = _nameController.text.trim();
    final mobile = _mobileController.text.trim();
    final dob = _dobController.text.trim();
    final address = _addressController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your Full Name');
      return;
    }
    final rawDigits = mobile.replaceAll(RegExp(r'\D'), '');
    if (mobile.isEmpty || rawDigits.length < 10) {
      setState(() => _errorMessage = 'Please enter a valid 10-digit Mobile Number');
      return;
    }
    if (dob.isEmpty) {
      setState(() => _errorMessage = 'Please select your Date of Birth (DOB)');
      return;
    }
    if (address.isEmpty) {
      setState(() => _errorMessage = 'Please enter your Address / District');
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
        address: address,
        gender: 'Not specified',
      );

      HapticService.success();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.stars_rounded, color: AppTokens.marigold, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Profile completed! ₹500 welcome credit added.',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTokens.darkSurface,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );

        if (widget.redirectPath != null && widget.redirectPath!.isNotEmpty) {
          context.go(widget.redirectPath!);
        } else {
          context.go('/');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not save profile. Please try again.';
        });
      }
    }
  }

  Widget _buildSafeIllustration() {
    return Image.asset(
      'assets/images/onboarding_welcome_illustration.jpg',
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/images/avatar_commuter_3d.jpg',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            color: AppTokens.primaryTint,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.person_rounded, size: 64, color: AppTokens.primary),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.background,
      appBar: AppBar(
        title: const Text(
          'Onboarding Profile',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppTokens.ink),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              if (widget.redirectPath != null && widget.redirectPath!.isNotEmpty) {
                context.go(widget.redirectPath!);
              } else {
                context.go('/');
              }
            },
            child: const Text(
              'Skip for now',
              style: TextStyle(color: AppTokens.secondaryText, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. High-Quality 3D Illustration Header
              Center(
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: AppTokens.softCardShadow,
                  ),
                  child: ClipOval(
                    child: _buildSafeIllustration(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Step Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTokens.primaryTint,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTokens.primary.withValues(alpha: 0.2)),
                ),
                child: const Text(
                  'WELCOME TO DISTRICT CAR',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: AppTokens.primaryDark,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              const Text(
                'Complete Your Profile',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTokens.ink,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Enter your details to enable doorstep pickup coordination and safety alerts across Jharkhand',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppTokens.secondaryText,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 24),

              // 2. Form Inset Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppTokens.border),
                  boxShadow: AppTokens.softCardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A. Full Name
                    const Text('Full Name', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTokens.ink)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTokens.ink),
                      decoration: InputDecoration(
                        hintText: 'e.g. Ramesh Kumar',
                        hintStyle: const TextStyle(color: AppTokens.hint, fontSize: 13.5, fontWeight: FontWeight.w500),
                        prefixIcon: const Icon(Icons.person_rounded, color: AppTokens.primary, size: 20),
                        filled: true,
                        fillColor: AppTokens.surface2,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTokens.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTokens.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTokens.primary, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // B. Mobile Number
                    const Text('Mobile Number', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTokens.ink)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTokens.ink),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '10-digit mobile number',
                        hintStyle: const TextStyle(color: AppTokens.hint, fontSize: 13.5, fontWeight: FontWeight.w500),
                        prefixIcon: const Icon(Icons.phone_iphone_rounded, color: AppTokens.primary, size: 20),
                        prefixText: '+91 ',
                        prefixStyle: const TextStyle(fontWeight: FontWeight.w900, color: AppTokens.ink, fontSize: 14),
                        filled: true,
                        fillColor: AppTokens.surface2,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTokens.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTokens.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTokens.primary, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // C. Date of Birth (DOB)
                    const Text('Date of Birth (DOB)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTokens.ink)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickDateOfBirth,
                      borderRadius: BorderRadius.circular(14),
                      child: IgnorePointer(
                        child: TextField(
                          controller: _dobController,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTokens.ink),
                          decoration: InputDecoration(
                            hintText: 'DD / MM / YYYY',
                            hintStyle: const TextStyle(color: AppTokens.hint, fontSize: 13.5, fontWeight: FontWeight.w500),
                            prefixIcon: const Icon(Icons.cake_rounded, color: AppTokens.primary, size: 20),
                            suffixIcon: const Icon(Icons.calendar_month_rounded, color: AppTokens.secondaryText, size: 20),
                            filled: true,
                            fillColor: AppTokens.surface2,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTokens.border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTokens.border)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTokens.primary, width: 1.5)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // D. Address / Home Location
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Home Address / District', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTokens.ink)),
                        GestureDetector(
                          onTap: _isDetectingGps ? null : _detectGpsAddress,
                          child: Row(
                            children: [
                              _isDetectingGps
                                  ? const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTokens.primary),
                                    )
                                  : const Icon(Icons.my_location_rounded, size: 14, color: AppTokens.primary),
                              const SizedBox(width: 4),
                              Text(
                                _isDetectingGps ? 'Detecting...' : 'Use GPS',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppTokens.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _addressController,
                      maxLines: 2,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: AppTokens.ink),
                      decoration: InputDecoration(
                        hintText: 'e.g. Circular Road, Lalpur, Ranchi, Jharkhand',
                        hintStyle: const TextStyle(color: AppTokens.hint, fontSize: 13, fontWeight: FontWeight.w500),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 24),
                          child: Icon(Icons.home_work_rounded, color: AppTokens.primary, size: 20),
                        ),
                        filled: true,
                        fillColor: AppTokens.surface2,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTokens.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTokens.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTokens.primary, width: 1.5)),
                      ),
                    ),
                  ],
                ),
              ),

              // Error notification
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // 3. Complete Setup & Continue Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTokens.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isLoading ? null : _submitProfile,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Save & Start Riding',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
