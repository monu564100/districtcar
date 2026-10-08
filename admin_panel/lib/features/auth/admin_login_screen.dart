import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:district_car_shared/theme/app_theme.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _pinCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _enteredPin = '';
  String? _errorMessage;
  bool _isSuccess = false;

  static const String _masterPin = '5641';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onDigitPressed(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _errorMessage = null;
        _enteredPin += digit;
      });
      if (_enteredPin.length == 4) {
        _validatePin();
      }
    }
  }

  void _onBackspacePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _errorMessage = null;
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  void _onClearPressed() {
    setState(() {
      _errorMessage = null;
      _enteredPin = '';
    });
  }

  void _validatePin() async {
    if (_enteredPin == _masterPin) {
      setState(() {
        _isSuccess = true;
        _errorMessage = null;
      });
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        context.go('/dashboard');
      }
    } else {
      setState(() {
        _errorMessage = 'Incorrect PIN! Access Denied.';
        _enteredPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark elegant security theme
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 440,
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFF334155), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Brand Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: const Icon(Icons.shield_rounded, color: AppColors.primary, size: 40),
                ),
                const SizedBox(height: 18),
                const Text(
                  'DISTRICT CAR ADMIN',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Operations & Fleet Management Console',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
                const SizedBox(height: 28),

                // Instruction & Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.lock_outline, color: Color(0xFF38BDF8), size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Enter 4-Digit Security Master PIN',
                        style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // PIN Dots Display
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final bool isFilled = index < _enteredPin.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isSuccess
                            ? const Color(0xFF10B981)
                            : (isFilled ? AppColors.primary : Colors.transparent),
                        border: Border.all(
                          color: _isSuccess
                              ? const Color(0xFF10B981)
                              : (isFilled ? AppColors.primary : const Color(0xFF64748B)),
                          width: 2.5,
                        ),
                        boxShadow: isFilled
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),

                // Error Message if any
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7F1D1D).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFEF4444)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFFCA5A5), size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // Keypad Matrix
                Column(
                  children: [
                    _buildKeypadRow(['1', '2', '3']),
                    const SizedBox(height: 14),
                    _buildKeypadRow(['4', '5', '6']),
                    const SizedBox(height: 14),
                    _buildKeypadRow(['7', '8', '9']),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSpecialKey(
                          icon: Icons.clear,
                          label: 'CLR',
                          onTap: _onClearPressed,
                        ),
                        const SizedBox(width: 14),
                        _buildKeypadButton('0'),
                        const SizedBox(width: 14),
                        _buildSpecialKey(
                          icon: Icons.backspace_outlined,
                          label: 'DEL',
                          onTap: _onBackspacePressed,
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Text(
                  'Protected System • District Car JH01',
                  style: TextStyle(color: Color(0xFF475569), fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: digits.map((digit) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7),
          child: _buildKeypadButton(digit),
        );
      }).toList(),
    );
  }

  Widget _buildKeypadButton(String digit) {
    return Material(
      color: const Color(0xFF0F172A),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _onDigitPressed(digit),
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.primary.withValues(alpha: 0.3),
        child: Container(
          width: 76,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155), width: 1.2),
          ),
          child: Text(
            digit,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialKey({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 76,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155), width: 1.2),
          ),
          child: Icon(icon, color: const Color(0xFF94A3B8), size: 22),
        ),
      ),
    );
  }
}
