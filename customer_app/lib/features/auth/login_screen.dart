import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:district_car_shared/models/models.dart';
import '../../services/haptic_service.dart';
import '../../theme/theme.dart';
import '../../widgets/auth/google_sign_in_button.dart';
import 'auth_repository.dart';
import 'auth_service.dart';

/// Top-Tier Mobility Login Screen
/// Immersive high-quality visual header with auto-advancing carousel,
/// dark gradient fade, and elevated bottom container featuring official
/// Sign in with Google container box and new-user onboarding routing.
class LoginScreen extends ConsumerStatefulWidget {
  final String? redirectPath;
  const LoginScreen({super.key, this.redirectPath});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  int _currentImageIndex = 0;
  Timer? _carouselTimer;
  GoogleButtonStatus _googleButtonStatus = GoogleButtonStatus.idle;
  String? _errorMessage;

  final List<Map<String, String>> _heroSlides = [
    {
      'image': 'assets/images/login_hero_illustration.jpg',
      'fallback': 'assets/images/hero_jharkhand_landscape.jpg',
      'tag': 'DISTRICT MOBILITY & TOURS',
      'title': 'Move Freely Across Districts',
      'subtitle': 'Doorstep verified cabs, autos & day tours across 24 districts of Jharkhand',
    },
    {
      'image': 'assets/images/promo_outstation_hills.jpg',
      'fallback': 'assets/images/district_on_the_move_seamless.jpg',
      'tag': 'INTER-DISTRICT TRAVEL',
      'title': 'Reliable Rides to Every Town',
      'subtitle': 'Fixed fares, verified local drivers & 100% return ride guarantee',
    },
    {
      'image': 'assets/images/promo_festive_prime.jpg',
      'fallback': 'assets/images/car_white.jpg',
      'tag': 'FAMILY & COMFORT',
      'title': 'Comfortable Cabs at Your Door',
      'subtitle': 'Zero surge pricing, transparent receipts and clean vehicles',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      if (_pageController.hasClients) {
        final next = (_currentImageIndex + 1) % _heroSlides.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _handleBack() {
    HapticService.selectionClick();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    context.go('/');
  }

  void _onLoginSuccess(DistrictUser user) async {
    HapticService.success();

    final firstName = user.displayName?.split(' ').first ?? 'Rider';
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                'Welcome, $firstName!',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ),
          backgroundColor: AppTokens.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Check if customer profile exists & is complete
    final profileExists = await ref.read(authRepositoryProvider).doesCustomerProfileExist(user.uid);
    if (!mounted) return;

    if (!profileExists) {
      // New user -> Onboarding screen with high-quality illustrations to enter name, number, dob, address
      context.go('/profile-setup', extra: widget.redirectPath);
    } else {
      // Existing user -> Return to intended destination
      if (widget.redirectPath != null && widget.redirectPath!.isNotEmpty) {
        context.go(widget.redirectPath!);
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        context.go('/');
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _googleButtonStatus = GoogleButtonStatus.loading;
      _errorMessage = null;
    });

    final user = await ref.read(authControllerProvider.notifier).signInWithGoogle();

    if (!mounted) return;

    if (user != null) {
      setState(() => _googleButtonStatus = GoogleButtonStatus.success);
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        _onLoginSuccess(user);
      }
    } else {
      final authState = ref.read(authControllerProvider);
      setState(() {
        _googleButtonStatus = GoogleButtonStatus.error;
        if (authState is AuthStateError) {
          _errorMessage = authState.message;
        } else {
          _errorMessage = 'Sign in failed. Please try again.';
        }
      });
    }
  }

  Future<void> _handleReviewerSignIn() async {
    setState(() {
      _googleButtonStatus = GoogleButtonStatus.loading;
      _errorMessage = null;
    });

    final user = await ref.read(authControllerProvider.notifier).signInAsReviewer();

    if (!mounted) return;

    if (user != null) {
      setState(() => _googleButtonStatus = GoogleButtonStatus.success);
      await Future.delayed(const Duration(milliseconds: 250));
      if (mounted) {
        _onLoginSuccess(user);
      }
    } else {
      setState(() {
        _googleButtonStatus = GoogleButtonStatus.error;
        _errorMessage = 'Demo sign-in could not be completed.';
      });
    }
  }

  Future<void> _launchLegalUrl(String url) async {
    HapticService.selectionClick();
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildSafeHeroImage(String primaryAsset, String fallbackAsset) {
    return Image.asset(
      primaryAsset,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.asset(
        fallbackAsset,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFF101A14),
          child: const Center(
            child: Icon(Icons.directions_car_rounded, color: Colors.white24, size: 64),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final heroHeight = (screenHeight * 0.54).clamp(320.0, 520.0);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. TOP HERO VISUAL CAROUSEL WITH GRADIENT FADE
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroHeight + 36,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image PageView
                PageView.builder(
                  controller: _pageController,
                  itemCount: _heroSlides.length,
                  onPageChanged: (i) => setState(() => _currentImageIndex = i),
                  itemBuilder: (context, index) {
                    final slide = _heroSlides[index];
                    return _buildSafeHeroImage(slide['image']!, slide['fallback']!);
                  },
                ),

                // Multi-stop cinematic gradient scrim
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black54,
                        Colors.transparent,
                        Color.fromRGBO(15, 23, 42, 0.40),
                        Color(0xFF0F172A),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 0.30, 0.70, 1.0],
                    ),
                  ),
                ),

                // Top Controls (Frosted Back/Close + Brand Chip)
                Positioned(
                  top: mediaQuery.padding.top + 10,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back/Close Button
                      Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: _handleBack,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white30),
                            ),
                            child: const Center(
                              child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ),

                      // District Car Brand Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.50),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTokens.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'District Car • Jharkhand',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 11.5,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Hero Text Overlay & Slide Indicators
                Positioned(
                  left: 22,
                  right: 22,
                  bottom: 48,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Category Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTokens.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _heroSlides[_currentImageIndex]['tag']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 10.5,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Headline
                      Text(
                        _heroSlides[_currentImageIndex]['title']!,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Subtitle
                      Text(
                        _heroSlides[_currentImageIndex]['subtitle']!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Carousel Dots
                      Row(
                        children: List.generate(_heroSlides.length, (idx) {
                          final isActive = idx == _currentImageIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 6),
                            width: isActive ? 22 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isActive ? AppTokens.marigold : Colors.white38,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. BOTTOM ELEVATED SIGN IN CONTAINER BOX (Top tier sheet style)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.25),
                    blurRadius: 36,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                mediaQuery.padding.bottom + 18,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Container Box Title
                  const Text(
                    'Welcome to District Car',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: AppTokens.ink,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sign in to access your trips, saved routes & manage profile',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTokens.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Error notification if sign in fails
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 16),
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
                              style: const TextStyle(
                                color: Color(0xFFB91C1C),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // SIGN IN WITH GOOGLE CONTAINER BOX
                  GoogleSignInButton(
                    onPressed: _handleGoogleSignIn,
                    status: _googleButtonStatus,
                    label: 'Continue with Google',
                    loadingLabel: 'Signing in with Google...',
                    height: 56,
                  ),
                  const SizedBox(height: 14),

                  // Demo / Reviewer 1-Tap Sign In
                  TextButton.icon(
                    onPressed: _googleButtonStatus == GoogleButtonStatus.loading
                        ? null
                        : _handleReviewerSignIn,
                    icon: const Icon(Icons.flash_on_rounded, size: 16, color: AppTokens.primary),
                    label: const Text(
                      'Explore with Instant Demo Account',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTokens.primaryDark,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Security & Terms Notice
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'By continuing, you agree to our ',
                          style: TextStyle(fontSize: 11.5, color: AppTokens.hint),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/terms'),
                          child: const Text(
                            'Terms of Service',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppTokens.primaryDark,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const Text(
                          ' & ',
                          style: TextStyle(fontSize: 11.5, color: AppTokens.hint),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/privacy'),
                          child: const Text(
                            'Privacy Policy',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppTokens.primaryDark,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
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
    );
  }
}
