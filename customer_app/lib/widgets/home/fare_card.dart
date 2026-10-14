import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../theme/theme.dart';
import '../../services/haptic_service.dart';

/// Highly animated Thermal Printer Receipt Fare Card
/// When user taps the dropdown, a realistic receipt roll-outs from a printer slot
/// with animated paper uncurling, thermal printhead sweep beam, sawtooth tear edges,
/// authentic barcode, verified stamp, and complete fare breakdown.
class FareCard extends StatefulWidget {
  final double totalFare;
  final double distanceKm;
  final String formattedDuration;
  final bool isRoundTrip;
  final double baseFare;
  final double distanceFare;
  final double returnAllowance;
  final bool isHindi;
  final String vehicleName;

  const FareCard({
    super.key,
    required this.totalFare,
    required this.distanceKm,
    required this.formattedDuration,
    required this.isRoundTrip,
    this.baseFare = 60.0,
    this.distanceFare = 0.0,
    this.returnAllowance = 0.0,
    this.isHindi = false,
    this.vehicleName = 'District Ride',
  });

  @override
  State<FareCard> createState() => _FareCardState();
}

class _FareCardState extends State<FareCard> with SingleTickerProviderStateMixin {
  late AnimationController _printerController;
  late Animation<double> _expandAnimation;
  late Animation<double> _curlAnimation;
  late Animation<double> _printheadScanAnimation;
  late Animation<double> _chevronAnimation;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _printerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _expandAnimation = CurvedAnimation(
      parent: _printerController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );

    _curlAnimation = CurvedAnimation(
      parent: _printerController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
    );

    _printheadScanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _printerController,
        curve: const Interval(0.15, 0.95, curve: Curves.linear),
      ),
    );

    _chevronAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _printerController,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _printerController.dispose();
    super.dispose();
  }

  void _togglePrinter() {
    HapticService.selection();

    if (_isExpanded) {
      _printerController.reverse();
      setState(() => _isExpanded = false);
    } else {
      _printerController.forward();
      setState(() => _isExpanded = true);

      // Play mechanical printer feed haptics (3 gentle tactile clicks)
      Future.delayed(const Duration(milliseconds: 140), () {
        if (mounted) HapticFeedback.lightImpact();
      });
      Future.delayed(const Duration(milliseconds: 280), () {
        if (mounted) HapticFeedback.lightImpact();
      });
      Future.delayed(const Duration(milliseconds: 440), () {
        if (mounted) HapticFeedback.selectionClick();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // 1. Top Dispenser Card (The "Printer Machine" Head)
          Container(
            decoration: BoxDecoration(
              gradient: AppTokens.fareDarkGradient,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppTokens.radiusCards),
                topRight: Radius.circular(AppTokens.radiusCards),
                bottomLeft: Radius.circular(_isExpanded ? 6 : AppTokens.radiusCards),
                bottomRight: Radius.circular(_isExpanded ? 6 : AppTokens.radiusCards),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(11, 16, 32, 0.35),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _togglePrinter,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppTokens.radiusCards),
                  topRight: Radius.circular(AppTokens.radiusCards),
                  bottomLeft: Radius.circular(_isExpanded ? 6 : AppTokens.radiusCards),
                  bottomRight: Radius.circular(_isExpanded ? 6 : AppTokens.radiusCards),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(
                    children: [
                      // Rolling Counter Fare
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: widget.totalFare, end: widget.totalFare),
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) {
                                    return Text(
                                      '₹${value.round()}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 25,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                        fontFeatures: [FontFeature.tabularFigures()],
                                      ),
                                    );
                                  },
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.print_rounded, size: 10, color: Color(0xFFB45309)),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.isHindi ? 'रसीद देखें' : 'View Fare Slip',
                                        style: const TextStyle(
                                          color: Color(0xFFB45309),
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.distanceKm.toStringAsFixed(1)} km  •  ${widget.formattedDuration}${widget.isRoundTrip ? (widget.isHindi ? '  •  राउंड ट्रिप' : '  •  Round trip') : ''}',
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Animated Printer Status Button
                      AnimatedBuilder(
                        animation: _chevronAnimation,
                        builder: (context, child) {
                          return Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: _isExpanded
                                  ? const Color(0xFFF59E0B).withValues(alpha: 0.25)
                                  : Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _isExpanded
                                    ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
                                    : Colors.white12,
                                width: 1.2,
                              ),
                            ),
                            child: RotationTransition(
                              turns: _chevronAnimation,
                              child: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Realistic Printer Dispenser Slit
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              if (_expandAnimation.value < 0.05) return const SizedBox.shrink();
              return Container(
                height: 4.5,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF070B14),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: const Color(0xFF1E293B),
                    width: 0.8,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.6),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              );
            },
          ),

          // 3. The Animated Thermal Printer Page (Rolls Downwards)
          SizeTransition(
            sizeFactor: _expandAnimation,
            axisAlignment: -1.0,
            child: AnimatedBuilder(
              animation: _printerController,
              builder: (context, child) {
                // 3D paper curl perspective as it leaves the roller
                final curlAngle = (1.0 - _curlAnimation.value).clamp(0.0, 1.0) * 0.16;

                return Transform(
                  alignment: Alignment.topCenter,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateX(curlAngle),
                  child: Stack(
                    children: [
                      // Thermal Receipt Slip Paper
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFBFD),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(0),
                            bottomRight: Radius.circular(0),
                          ),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(15, 23, 42, 0.10),
                              blurRadius: 18,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Receipt Top Notches & Feed Header
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                              child: Column(
                                children: [
                                  // Brand & Header Seal
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(5),
                                              image: const DecorationImage(
                                                image: AssetImage('assets/images/app_logo.jpg'),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'DISTRICT CAR',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.2,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          widget.isHindi ? 'आधिकारिक रसीद' : 'OFFICIAL SLIP',
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                            color: Color(0xFF475569),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Dotted Perforated Cut Line
                                  SizedBox(
                                    height: 1,
                                    width: double.infinity,
                                    child: CustomPaint(
                                      painter: DottedLinePainter(
                                        color: const Color(0xFFCBD5E1),
                                        dashWidth: 4,
                                        dashSpace: 3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Meta details
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'SLIP: #DC-${(widget.totalFare * 43).round().toString().padLeft(6, '0')}',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      Text(
                                        DateFormat('dd MMM, hh:mm a').format(DateTime.now()),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontFamily: 'monospace',
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'VEHICLE: ${widget.vehicleName.toUpperCase()}',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      Text(
                                        'JHARKHAND RURAL',
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFD97706),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Dotted Line
                                  SizedBox(
                                    height: 1,
                                    width: double.infinity,
                                    child: CustomPaint(
                                      painter: DottedLinePainter(
                                        color: const Color(0xFFCBD5E1),
                                        dashWidth: 4,
                                        dashSpace: 3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Itemized Fare Table (Thermal Print Style)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Column(
                                children: [
                                  _buildReceiptRow(
                                    title: widget.isHindi ? 'न्यूनतम बेस किराया (Base Fare)' : 'Base Fare (First 2 km)',
                                    value: '₹${widget.baseFare.round()}',
                                  ),
                                  const SizedBox(height: 6),
                                  _buildReceiptRow(
                                    title: widget.isHindi
                                        ? 'दूरी शुल्क (${widget.distanceKm.toStringAsFixed(1)} km)'
                                        : 'Distance Rate (${widget.distanceKm.toStringAsFixed(1)} km)',
                                    value: '₹${(widget.totalFare - widget.baseFare - widget.returnAllowance).clamp(0, 99999).round()}',
                                  ),
                                  const SizedBox(height: 6),
                                  _buildReceiptRow(
                                    title: widget.isHindi
                                        ? 'गाँव वापसी गारंटी (Return Guarantee)'
                                        : 'Village Return Guarantee',
                                    value: 'FREE (100% Accepted)',
                                    valueColor: const Color(0xFFD97706),
                                    isBold: true,
                                  ),
                                  if (widget.isRoundTrip && widget.returnAllowance > 0) ...[
                                    const SizedBox(height: 6),
                                    _buildReceiptRow(
                                      title: widget.isHindi ? 'राउंड ट्रिप ठहराव भत्ता' : 'Round Trip Waiting Allowance',
                                      value: '₹${widget.returnAllowance.round()}',
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  _buildReceiptRow(
                                    title: widget.isHindi ? 'पीक / सर्ज शुल्क (Surge Pricing)' : 'Surge & Peak Surcharge',
                                    value: '₹0.00 (Zero Surge Always)',
                                    valueColor: const Color(0xFFD97706),
                                  ),
                                  const SizedBox(height: 6),
                                  _buildReceiptRow(
                                    title: widget.isHindi ? 'जीएसटी एवं टोल टैक्स' : 'Taxes, Platform & Safety Fee',
                                    value: '₹0.00 (Inclusive)',
                                  ),
                                ],
                              ),
                            ),

                            // Bold Perforated Total Line
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 1.5,
                                    width: double.infinity,
                                    child: CustomPaint(
                                      painter: DottedLinePainter(
                                        color: const Color(0xFF94A3B8),
                                        dashWidth: 5,
                                        dashSpace: 3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Big Stamp Total
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.isHindi ? 'कुल अनुमानित किराया' : 'ESTIMATED TOTAL',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          Text(
                                            widget.isHindi ? 'नकद / यूपीआई द्वारा भुगतान करें' : 'Pay driver via Cash or UPI',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF64748B),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '₹${widget.totalFare.round()}',
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF0F172A),
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Verified Stamp Badge (Amber / Onyx)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.verified_rounded, size: 14, color: Color(0xFFD97706)),
                                        const SizedBox(width: 6),
                                        Text(
                                          widget.isHindi
                                              ? '100% फिक्स रेट गारंटी • कोई मोलभाव नहीं'
                                              : '100% FIXED PRICE GUARANTEE • NO BARGAINING',
                                          style: const TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFFB45309),
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Realistic Barcode Vector
                                  SizedBox(
                                    height: 32,
                                    width: double.infinity,
                                    child: CustomPaint(
                                      painter: BarcodePainter(
                                        color: const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Center(
                                    child: Text(
                                      '* 8 7 8 9 6 0 1 3 8 7 *',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontFamily: 'monospace',
                                        letterSpacing: 2.5,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                ],
                              ),
                            ),

                            // Sawtooth Jagged Tear Edge at Bottom of Receipt
                            SizedBox(
                              height: 7,
                              width: double.infinity,
                              child: CustomPaint(
                                painter: ReceiptSawtoothPainter(
                                  color: const Color(0xFFFAFBFD),
                                  borderColor: const Color(0xFFE2E8F0),
                                  toothWidth: 10.0,
                                  toothHeight: 6.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Laser Thermal Printhead Scan Beam (while animating)
                      if (_printerController.isAnimating &&
                          _printerController.status == AnimationStatus.forward)
                        Positioned(
                          top: _printheadScanAnimation.value * 280,
                          left: 10,
                          right: 10,
                          child: Container(
                            height: 2.5,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Color(0xFFF59E0B),
                                  Color(0xFFFBBF24),
                                  Color(0xFFF59E0B),
                                  Colors.transparent,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow({
    required String title,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? const Color(0xFF0F172A),
            fontSize: 12,
            fontFamily: 'monospace',
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Custom painter for sawtooth / jagged receipt tear edge at the bottom
class ReceiptSawtoothPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final double toothWidth;
  final double toothHeight;

  ReceiptSawtoothPainter({
    required this.color,
    this.borderColor = const Color(0xFFCBD5E1),
    this.toothWidth = 10.0,
    this.toothHeight = 6.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    path.moveTo(0, 0);

    final teethCount = (size.width / toothWidth).ceil();
    final actualToothWidth = size.width / teethCount;

    for (int i = 0; i < teethCount; i++) {
      final x1 = i * actualToothWidth + actualToothWidth / 2;
      final y1 = toothHeight;
      final x2 = (i + 1) * actualToothWidth;
      final y2 = 0.0;
      path.lineTo(x1, y1);
      path.lineTo(x2, y2);
    }

    path.close();
    canvas.drawPath(path, fillPaint);

    final borderPath = Path();
    borderPath.moveTo(0, 0);
    for (int i = 0; i < teethCount; i++) {
      final x1 = i * actualToothWidth + actualToothWidth / 2;
      final y1 = toothHeight;
      final x2 = (i + 1) * actualToothWidth;
      final y2 = 0.0;
      borderPath.lineTo(x1, y1);
      borderPath.lineTo(x2, y2);
    }
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for dotted perforated lines on receipt
class DottedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;

  DottedLinePainter({
    this.color = const Color(0xFFCBD5E1),
    this.dashWidth = 4.0,
    this.dashSpace = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for authentic thermal ticket barcode
class BarcodePainter extends CustomPainter {
  final Color color;

  BarcodePainter({this.color = const Color(0xFF1E293B)});

  @override
  void paint(Canvas canvas, Size size) {
    // Relative bar pattern with varying line thicknesses
    const pattern = [
      3, 1, 2, 4, 1, 2, 3, 1, 1, 2, 4, 1, 3, 2, 1, 1, 4, 2, 1, 3, 2, 1, 4, 1,
      2, 3, 1, 1, 4, 2, 1, 3, 1, 2, 4, 2, 1, 3, 1, 2, 4, 1, 3, 2, 1, 1, 4, 2
    ];

    double totalUnits = 0;
    for (final p in pattern) {
      totalUnits += p;
    }

    final unitWidth = size.width / totalUnits;
    double currentX = 0;

    for (int i = 0; i < pattern.length; i++) {
      final width = pattern[i] * unitWidth;
      if (i % 2 == 0) {
        canvas.drawRect(
          Rect.fromLTWH(currentX, 0, width, size.height),
          Paint()..color = color,
        );
      }
      currentX += width;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
