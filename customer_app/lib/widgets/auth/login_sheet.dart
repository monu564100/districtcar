import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:district_car_shared/models/models.dart';
import '../../features/auth/auth_repository.dart';
import '../../services/haptic_service.dart';
import 'google_sign_in_button.dart';

class LoginSheet extends ConsumerStatefulWidget {
  final bool isHindi;
  final ValueChanged<DistrictUser>? onLoginSuccess;
  final VoidCallback? onDismiss;

  const LoginSheet({
    super.key,
    this.isHindi = false,
    this.onLoginSuccess,
    this.onDismiss,
  });

  static Future<DistrictUser?> show(
    BuildContext context, {
    bool isHindi = false,
  }) {
    HapticService.selection();
    return showModalBottomSheet<DistrictUser>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: LoginSheet(
              isHindi: isHindi,
              onLoginSuccess: (user) => Navigator.pop(ctx, user),
              onDismiss: () => Navigator.pop(ctx),
            ),
          ),
        ),
      ),
    );
  }

  @override
  ConsumerState<LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends ConsumerState<LoginSheet> {
  GoogleButtonStatus _buttonStatus = GoogleButtonStatus.idle;
  String? _errorMessage;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _buttonStatus = GoogleButtonStatus.loading;
      _errorMessage = null;
    });

    final user = await ref.read(authControllerProvider.notifier).signInWithGoogle();

    if (!mounted) return;

    if (user != null) {
      setState(() => _buttonStatus = GoogleButtonStatus.success);
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        widget.onLoginSuccess?.call(user);
      }
    } else {
      final authState = ref.read(authControllerProvider);
      setState(() {
        _buttonStatus = GoogleButtonStatus.error;
        if (authState is AuthStateError) {
          _errorMessage = authState.message;
        } else {
          _errorMessage = widget.isHindi
              ? 'साइन इन असफल रहा। कृपया पुनः प्रयास करें।'
              : 'Sign in failed. Please try again.';
        }
      });
    }
  }

  Future<void> _handleReviewerSignIn() async {
    setState(() {
      _buttonStatus = GoogleButtonStatus.loading;
      _errorMessage = null;
    });

    final user = await ref.read(authControllerProvider.notifier).signInAsReviewer();

    if (!mounted) return;

    if (user != null) {
      setState(() => _buttonStatus = GoogleButtonStatus.success);
      await Future.delayed(const Duration(milliseconds: 250));
      if (mounted) {
        widget.onLoginSuccess?.call(user);
      }
    } else {
      setState(() {
        _buttonStatus = GoogleButtonStatus.error;
        _errorMessage = 'Reviewer sign-in error';
      });
    }
  }

  Future<void> _launchUrlSafe(String urlString) async {
    HapticService.selection();
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title & Subtitle
          Text(
            widget.isHindi ? 'स्वागत है / Welcome' : 'Sign In or Create Account',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0B1020),
              letterSpacing: -0.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            widget.isHindi
                ? 'अपने Google खाते से सिर्फ एक टैप में सुरक्षित प्रवेश करें'
                : 'One tap sign-in with your Google account',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF5B6478),
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),

          // Google Sign-In Button
          GoogleSignInButton(
            status: _buttonStatus,
            errorMessage: _errorMessage,
            label: widget.isHindi ? 'Google से जारी रखें' : 'Continue with Google',
            loadingLabel: widget.isHindi ? 'साइन इन हो रहा है…' : 'Signing you in…',
            onPressed: _buttonStatus == GoogleButtonStatus.loading ? null : _handleGoogleSignIn,
          ),
          const SizedBox(height: 16),

          // Trust Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user_rounded, size: 15, color: Color(0xFF16A34A)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.isHindi
                      ? 'सुरक्षित एवं सत्यापित। हम कभी कुछ पोस्ट नहीं करते।'
                      : 'Encrypted & verified. We never post anything.',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF16A34A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Terms & Privacy Links
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                widget.isHindi ? 'आगे बढ़कर आप हमारी ' : 'By continuing you agree to our ',
                style: const TextStyle(fontSize: 12, color: Color(0xFF98A2B3)),
              ),
              GestureDetector(
                onTap: () => _launchUrlSafe('https://districtcar.in/terms'),
                child: const Text(
                  'Terms of Service',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3D2FD6),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const Text(' & ', style: TextStyle(fontSize: 12, color: Color(0xFF98A2B3))),
              GestureDetector(
                onTap: () => _launchUrlSafe('https://districtcar.in/privacy'),
                child: const Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3D2FD6),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Helpers for Users without Google account or needing support
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // No Google account helper
              Flexible(
                child: GestureDetector(
                  onTap: () => _launchUrlSafe('https://accounts.google.com/signup'),
                  child: Text(
                    widget.isHindi
                        ? 'Google खाता नहीं है? 2 मिनट में बनाएं'
                        : 'No Google account? Create one in 2 mins',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5B6478),
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Helpline link
              GestureDetector(
                onTap: () => _launchUrlSafe('tel:+918789601387'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.headset_mic_rounded, size: 14, color: Color(0xFF3D2FD6)),
                    SizedBox(width: 4),
                    Text(
                      'Help: +91 87896',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3D2FD6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Discrete Play Store Reviewer shortcut
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _handleReviewerSignIn,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'Play Store Reviewer Sign-In',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFFCBD5E1),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
