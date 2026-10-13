import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/haptic_service.dart';

/// Official Full-Color Google "G" Logo Custom Painter
class GoogleLogoPainter extends CustomPainter {
  const GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final double cx = width / 2;
    final double cy = height / 2;
    final double radius = width / 2;
    final double strokeWidth = width * 0.20;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius - strokeWidth / 2);

    final paintBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final paintGreen = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final paintYellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final paintRed = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Draw Blue Arc (right side into crossbar)
    canvas.drawArc(rect, -math.pi / 4, math.pi / 2, false, paintBlue);

    // Draw Green Arc (bottom)
    canvas.drawArc(rect, math.pi / 4, math.pi / 2, false, paintGreen);

    // Draw Yellow Arc (bottom-left to left)
    canvas.drawArc(rect, 3 * math.pi / 4, math.pi / 2, false, paintYellow);

    // Draw Red Arc (top)
    canvas.drawArc(rect, 5 * math.pi / 4, math.pi / 2, false, paintRed);

    // Blue horizontal bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    final barRect = Rect.fromLTRB(
      cx - strokeWidth * 0.2,
      cy - strokeWidth / 2,
      width - strokeWidth * 0.2,
      cy + strokeWidth / 2,
    );
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GoogleGIcon extends StatelessWidget {
  final double size;
  const GoogleGIcon({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(
        painter: GoogleLogoPainter(),
      ),
    );
  }
}

enum GoogleButtonStatus { idle, loading, success, error }

class GoogleSignInButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final GoogleButtonStatus status;
  final String? label;
  final String? loadingLabel;
  final String? errorMessage;
  final double height;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.status = GoogleButtonStatus.idle,
    this.label,
    this.loadingLabel,
    this.errorMessage,
    this.height = 58,
  });

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant GoogleSignInButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == GoogleButtonStatus.error && oldWidget.status != GoogleButtonStatus.error) {
      _shakeController.forward(from: 0.0);
      HapticService.error();
    } else if (widget.status == GoogleButtonStatus.success && oldWidget.status != GoogleButtonStatus.success) {
      HapticService.success();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.status == GoogleButtonStatus.loading;
    final isSuccess = widget.status == GoogleButtonStatus.success;
    final isError = widget.status == GoogleButtonStatus.error;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: child,
            );
          },
          child: GestureDetector(
            onTapDown: (_) {
              if (!isLoading && !isSuccess && widget.onPressed != null) {
                setState(() => _isPressed = true);
              }
            },
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: () {
              if (!isLoading && !isSuccess && widget.onPressed != null) {
                HapticService.selection();
                widget.onPressed!();
              }
            },
            child: AnimatedScale(
              scale: _isPressed ? 0.97 : 1.0,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOutCubic,
              child: Container(
                height: widget.height,
                decoration: BoxDecoration(
                  color: isSuccess ? const Color(0xFF16A34A) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isError
                        ? const Color(0xFFE5484D)
                        : (isSuccess ? const Color(0xFF16A34A) : const Color(0xFFE4E7EC)),
                    width: isError ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF101828).withValues(alpha: 0.07),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLoading) ...[
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Color(0xFF3D2FD6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.loadingLabel ?? 'Signing you in…',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0B1020),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ] else if (isSuccess) ...[
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      const Text(
                        'Success! Welcome',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ] else ...[
                      const GoogleGIcon(size: 22),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          widget.label ?? 'Continue with Google',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0B1020),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (isError && widget.errorMessage != null && widget.errorMessage!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFE5484D), size: 15),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.errorMessage!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE5484D),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
