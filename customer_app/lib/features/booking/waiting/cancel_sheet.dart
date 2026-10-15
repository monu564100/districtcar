import 'package:flutter/material.dart';
import '../../../../services/haptic_service.dart';
import '../../../../theme/theme.dart';

/// Modal Bottom Sheet for Booking Cancellation Confirmation
/// Presents clear reason chips, a prominent "Keep Searching" CTA to prevent churn,
/// a reassuring zero-charge cancellation guarantee, and a quiet "Cancel ride" action.
class CancelSheet extends StatefulWidget {
  final int secondsWaited;
  final void Function(String reason) onConfirmCancel;

  const CancelSheet({
    super.key,
    required this.secondsWaited,
    required this.onConfirmCancel,
  });

  static Future<void> show({
    required BuildContext context,
    required int secondsWaited,
    required void Function(String reason) onConfirmCancel,
  }) {
    HapticService.selectionClick();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CancelSheet(
        secondsWaited: secondsWaited,
        onConfirmCancel: onConfirmCancel,
      ),
    );
  }

  @override
  State<CancelSheet> createState() => _CancelSheetState();
}

class _CancelSheetState extends State<CancelSheet> {
  String _selectedReason = 'Wait too long';

  static const List<Map<String, String>> _reasons = [
    {'id': 'Wait too long', 'hi': 'ज्यादा इंतज़ार (Wait too long)'},
    {'id': 'Booked by mistake', 'hi': 'गलती से बुक हो गया (Booked by mistake)'},
    {'id': 'Changed plan', 'hi': 'प्लान बदल गया (Changed plan)'},
    {'id': 'Found another ride', 'hi': 'दूसरा साधन मिल गया (Found another ride)'},
    {'id': 'Other', 'hi': 'अन्य कारण (Other)'},
  ];

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.25),
            blurRadius: 32,
            offset: Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        14,
        24,
        mediaQuery.padding.bottom + 18,
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
                color: AppTokens.border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Title & Subtitle
          const Text(
            'Ride cancel karni hai?',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: AppTokens.ink,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Hum sabhi paas ke drivers ko alert kar rahe hain. Kripya thoda intezaar karein.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTokens.secondaryText,
            ),
          ),
          const SizedBox(height: 16),

          // Free Cancellation Assurance Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: AppTokens.primaryTint,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTokens.primary.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_user_rounded, size: 16, color: AppTokens.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Free cancellation: no charge now / बिल्कुल मुफ़्त कैंसिलेशन',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppTokens.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Reason Selection Chips
          const Text(
            'Cancel karne ka kaaran chunein:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTokens.ink,
            ),
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _reasons.map((r) {
              final isSelected = _selectedReason == r['id'];
              return ChoiceChip(
                label: Text(
                  r['hi']!,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppTokens.ink,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppTokens.primaryDark,
                backgroundColor: AppTokens.surface2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? AppTokens.primaryDark : AppTokens.border,
                  ),
                ),
                onSelected: (val) {
                  if (val) {
                    HapticService.selectionClick();
                    setState(() => _selectedReason = r['id']!);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Primary CTA: "Keep searching"
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticService.buttonPress();
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text(
                'Keep Searching / इंतज़ार जारी रखें',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTokens.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Secondary Quiet Button: "Cancel ride"
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onConfirmCancel(_selectedReason);
            },
            child: const Text(
              'Yes, cancel ride / हाँ, राइड कैंसल करें',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTokens.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
