import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:district_car_shared/models/models.dart';
import '../../services/haptic_service.dart';
import '../../theme/theme.dart';
import '../../widgets/auth/hero_illustration.dart';
import '../../widgets/auth/value_carousel.dart';
import '../../widgets/auth/login_sheet.dart';
import 'auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String? redirectPath;
  const LoginScreen({super.key, this.redirectPath});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  bool _isHindi = false;
  late final AnimationController _entryController;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  // Remote config flag simulation (can be driven remotely)
  final bool _allowSkip = true;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  void _onLoginSuccess(DistrictUser user) async {
    HapticService.success();

    // Show welcoming toast
    if (mounted) {
      final firstName = user.displayName?.split(' ').first ?? 'Citizen';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                _isHindi ? 'स्वागत है, $firstName!' : 'Welcome, $firstName!',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Check profile exist
    final profileExists = await ref.read(authRepositoryProvider).doesCustomerProfileExist(user.uid);
    if (!mounted) return;

    if (!profileExists) {
      context.go('/profile-setup');
    } else {
      // Return user to EXACTLY where they came from
      if (widget.redirectPath != null && widget.redirectPath!.isNotEmpty) {
        context.go(widget.redirectPath!);
      } else if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        context.go('/');
      }
    }
  }

  void _handleSkip() {
    HapticService.selection();
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: Stack(
        children: [
          // Ambient Indigo & Green radial glows
          Positioned(
            top: -40,
            left: -40,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6A5CFF).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF16A34A).withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // A. Top Bar: Optional Skip for now (left) + Language toggle (right)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Skip for now (Browse first)
                      if (_allowSkip)
                        TextButton.icon(
                          onPressed: _handleSkip,
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Color(0xFF5B6478)),
                          label: Text(
                            _isHindi ? 'बाद में करें' : 'Skip for now',
                            style: const TextStyle(
                              color: Color(0xFF5B6478),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        )
                      else
                        const SizedBox.shrink(),

                      // Language Toggle Chip (हिं / EN)
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(15, 23, 42, 0.04),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (!_isHindi) {
                                  HapticService.selection();
                                  setState(() => _isHindi = true);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _isHindi ? const Color(0xFF3D2FD6) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  'हिं',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: _isHindi ? Colors.white : const Color(0xFF5B6478),
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                if (_isHindi) {
                                  HapticService.selection();
                                  setState(() => _isHindi = false);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: !_isHindi ? const Color(0xFF3D2FD6) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  'EN',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: !_isHindi ? Colors.white : const Color(0xFF5B6478),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Scrollable Area
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // B. Hero (top ~45%): Stylized Jharkhand Landscape + Driving Auto + Glass Logo
                        const HeroJharkhandIllustration(
                          height: 250,
                          heroImageAsset: 'assets/images/hero_jharkhand_landscape.jpg',
                        ),

                        // Branding title & pill
                        Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 12),
                              const Text(
                                'District Car',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0B1020),
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFC7D2FE)),
                                ),
                                child: const Text(
                                  'RURAL & DISTRICT MOBILITY',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF3730A3),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 28),
                                child: Text(
                                  _isHindi
                                      ? 'झारखंड के सभी 24 जिलों में सुरक्षित, भरोसेमंद और पारदर्शी आवागमन सेवा'
                                      : 'Doorstep cabs, autos & bikes across all 24 districts of Jharkhand',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF5B6478),
                                    fontSize: 12.5,
                                    height: 1.35,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // C. Value Carousel (Auto-advancing 3s, swipeable, 3 slides)
                        ValueCarousel(isHindi: _isHindi),

                        const SizedBox(height: 16),

                        // D. Login Card (Bottom-sheet style, 28 top radius, animated slide-up)
                        AnimatedBuilder(
                          animation: _entryController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _slideAnimation.value),
                              child: Opacity(
                                opacity: _fadeAnimation.value,
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                              boxShadow: [
                                BoxShadow(
                                  color: Color.fromRGBO(16, 24, 40, 0.08),
                                  blurRadius: 24,
                                  offset: Offset(0, -6),
                                ),
                              ],
                            ),
                            child: LoginSheet(
                              isHindi: _isHindi,
                              onLoginSuccess: _onLoginSuccess,
                            ),
                          ),
                        ),
                      ],
                    ),
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
