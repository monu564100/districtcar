import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../services/haptic_service.dart';

/// Hero Booking Card: Glass-style elevated card for route input
/// Refined with zero-gap unified timeline and responsive inputs
class BookingCard extends StatefulWidget {
  final String pickupAddress;
  final String destinationAddress;
  final VoidCallback onPickupTap;
  final VoidCallback onDestinationTap;
  final VoidCallback onGpsPickupTap;
  final VoidCallback onSwap;
  final Function(String) onQuickPlaceSelect;
  final VoidCallback? onVoiceInput;
  final bool isHindi;

  const BookingCard({
    super.key,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.onPickupTap,
    required this.onDestinationTap,
    required this.onGpsPickupTap,
    required this.onSwap,
    required this.onQuickPlaceSelect,
    this.onVoiceInput,
    this.isHindi = false,
  });

  @override
  State<BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<BookingCard> with SingleTickerProviderStateMixin {
  late AnimationController _swapAnimController;
  late Animation<double> _swapRotation;

  @override
  void initState() {
    super.initState();
    _swapAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _swapRotation = Tween<double>(begin: 0.0, end: pi).animate(
      CurvedAnimation(parent: _swapAnimController, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _swapAnimController.dispose();
    super.dispose();
  }

  void _triggerSwap() {
    HapticService.swap();
    if (_swapAnimController.isCompleted) {
      _swapAnimController.reverse();
    } else {
      _swapAnimController.forward();
    }
    widget.onSwap();
  }

  @override
  Widget build(BuildContext context) {
    final quickChips = widget.isHindi
        ? [
            {'icon': Icons.home_rounded, 'label': 'घर'},
            {'icon': Icons.storefront_rounded, 'label': 'बाजार'},
            {'icon': Icons.directions_bus_rounded, 'label': 'बस स्टैंड'},
            {'icon': Icons.local_hospital_rounded, 'label': 'अस्पताल'},
          ]
        : [
            {'icon': Icons.home_rounded, 'label': 'Ghar'},
            {'icon': Icons.storefront_rounded, 'label': 'Bazaar'},
            {'icon': Icons.directions_bus_rounded, 'label': 'Bus Stand'},
            {'icon': Icons.local_hospital_rounded, 'label': 'Hospital'},
          ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusCards),
        border: Border.all(color: AppTokens.borderLight, width: 1),
        boxShadow: AppTokens.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Unified Route Box (One continuous surface: removes gapping & alignment issues)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            ),
            child: Column(
              children: [
                // Pickup Row
                InkWell(
                  onTap: widget.onPickupTap,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 10, 8),
                    child: Row(
                      children: [
                        // Pickup Dot (Sleek Onyx)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Pickup Address Text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.isHindi ? 'कहाँ से (पिकअप)' : 'PICKUP LOCATION',
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTokens.textHint,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.pickupAddress.isEmpty
                                    ? (widget.isHindi ? 'वर्तमान स्थान' : 'Current location')
                                    : widget.pickupAddress.split(',').first.trim(),
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTokens.ink,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // GPS Button
                        Tooltip(
                          message: widget.isHindi ? 'वर्तमान जीपीएस स्थान' : 'Use Current GPS',
                          child: InkWell(
                            onTap: widget.onGpsPickupTap,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: const Icon(
                                Icons.my_location_rounded,
                                size: 15,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Seamless Divider with Sleek Swap Button (Positioned over divider)
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                    ),
                    Positioned(
                      right: 14,
                      child: AnimatedBuilder(
                        animation: _swapRotation,
                        builder: (context, child) => Transform.rotate(
                          angle: _swapRotation.value,
                          child: child,
                        ),
                        child: InkWell(
                          onTap: _triggerSwap,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.swap_vert_rounded,
                              color: Color(0xFF0F172A),
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Drop Row (Destination)
                InkWell(
                  onTap: widget.onDestinationTap,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 10, 10),
                    child: Row(
                      children: [
                        // Red Pin / Square
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppTokens.error,
                            borderRadius: BorderRadius.circular(2.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppTokens.error.withValues(alpha: 0.4),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Destination Text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.isHindi ? 'कहाँ जाना है?' : 'DROP DESTINATION',
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTokens.textHint,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.destinationAddress.isEmpty
                                    ? (widget.isHindi ? 'स्थान चुनें (कहाँ जाना है?)' : 'Where to? (Kahan jaana hai?)')
                                    : widget.destinationAddress.split(',').first.trim(),
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: widget.destinationAddress.isEmpty
                                      ? AppTokens.textSecondary
                                      : AppTokens.ink,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Voice Input Mic Button
                        if (widget.onVoiceInput != null) ...[
                          InkWell(
                            onTap: () {
                              HapticService.selection();
                              widget.onVoiceInput!();
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.mic_rounded, color: Color(0xFF0F172A), size: 16),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        // Search Icon
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 2. Recent & Saved Places Chips (Ghar, Bazaar, Bus Stand, Hospital)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: quickChips.map((chip) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () {
                      HapticService.placePicked();
                      widget.onQuickPlaceSelect(chip['label'] as String);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(chip['icon'] as IconData, size: 12, color: const Color(0xFF0F172A)),
                          const SizedBox(width: 4),
                          Text(
                            chip['label'] as String,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTokens.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
