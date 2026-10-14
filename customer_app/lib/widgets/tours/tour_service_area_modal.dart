import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/theme.dart';
import '../../services/haptic_service.dart';
import '../../features/tours/tour_pricing_service.dart';

/// "Aapki location door hai" Tour Service Area Bottom Sheet (Rule 0b)
/// Shown when user pickup is > 150 km from the destination.
/// Offers 3 clear options:
/// 1. Choose a pickup hub city (Ranchi, Jamshedpur, Bokaro, Dhanbad, Deoghar)
/// 2. See nearest tour packages
/// 3. WhatsApp / Call to arrange
class TourServiceAreaModal extends StatelessWidget {
  final double distanceKm;
  final String destinationName;
  final Function(TourHubCity) onSelectHubCity;
  final VoidCallback onSeeNearestPackages;

  const TourServiceAreaModal({
    super.key,
    required this.distanceKm,
    required this.destinationName,
    required this.onSelectHubCity,
    required this.onSeeNearestPackages,
  });

  static Future<void> show({
    required BuildContext context,
    required double distanceKm,
    required String destinationName,
    required Function(TourHubCity) onSelectHubCity,
    required VoidCallback onSeeNearestPackages,
  }) {
    HapticService.heavyImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TourServiceAreaModal(
        distanceKm: distanceKm,
        destinationName: destinationName,
        onSelectHubCity: onSelectHubCity,
        onSeeNearestPackages: onSeeNearestPackages,
      ),
    );
  }

  void _launchSupportWhatsApp() async {
    final uri = Uri.parse('https://wa.me/919304133455?text=Namaste%20District%20Car,%20I%20want%20to%20arrange%20a%20long-distance%20tour%20to%20$destinationName.');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _launchSupportCall() async {
    final uri = Uri.parse('tel:+919304133455');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusSheets)),
        boxShadow: AppTokens.softCardShadow,
      ),
      padding: EdgeInsets.fromLTRB(
        AppTokens.space20,
        AppTokens.space16,
        AppTokens.space20,
        MediaQuery.of(context).padding.bottom + AppTokens.space20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: AppTokens.border,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 20),

          // Icon / Badge
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppTokens.marigoldTint,
              shape: BoxShape.circle,
              border: Border.all(color: AppTokens.marigold.withValues(alpha: 0.3), width: 2),
            ),
            child: const Center(
              child: Icon(
                Icons.location_off_rounded,
                size: 34,
                color: AppTokens.marigoldDark,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Headline
          const Text(
            'Aapki location door hai',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
              color: AppTokens.ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'आपकी पिकअप लोकेशन इस टूर गंतव्य से 150 किमी से अधिक दूर है',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTokens.secondaryText,
            ),
          ),
          const SizedBox(height: 10),

          Text(
            'Distance: ${distanceKm.toStringAsFixed(0)} km from $destinationName. Choose one of the 3 easy ways below to book your ride:',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTokens.secondaryText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),

          // Option 1: Choose a Hub City
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTokens.surface2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTokens.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTokens.primaryTint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.location_city_rounded, size: 18, color: AppTokens.primary),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Option 1: Choose a Pickup City',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTokens.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TourPricingService.hubCities.map((hub) {
                    return ActionChip(
                      onPressed: () {
                        HapticService.selectionClick();
                        Navigator.pop(context);
                        onSelectHubCity(hub);
                      },
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppTokens.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      avatar: const Icon(Icons.near_me_rounded, size: 14, color: AppTokens.primary),
                      label: Text(
                        '${hub.name} (${hub.hindiName})',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTokens.ink,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Option 2: See Nearest Tour Packages
          InkWell(
            onTap: () {
              HapticService.buttonPress();
              Navigator.pop(context);
              onSeeNearestPackages();
            },
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTokens.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTokens.marigoldTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.explore_rounded, size: 20, color: AppTokens.marigoldDark),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Option 2: Nearest Tour Packages',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTokens.ink),
                        ),
                        Text(
                          'Discover attractions closer to your current location',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTokens.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTokens.hint),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Option 3: WhatsApp or Call Support
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTokens.primaryTint.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTokens.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _launchSupportWhatsApp,
                    icon: const Icon(Icons.chat_rounded, size: 18),
                    label: const Text('WhatsApp Us'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTokens.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _launchSupportCall,
                    icon: const Icon(Icons.phone_in_talk_rounded, size: 18, color: AppTokens.primaryDark),
                    label: const Text('Call Us', style: TextStyle(color: AppTokens.primaryDark)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTokens.primary, width: 1.5),
                      backgroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
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
