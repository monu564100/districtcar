import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/haptic_service.dart';

class ValueCarouselItem {
  final IconData icon;
  final String titleEn;
  final String titleHi;
  final String? subtitleEn;
  final String? subtitleHi;
  final Color accentColor;

  const ValueCarouselItem({
    required this.icon,
    required this.titleEn,
    required this.titleHi,
    this.subtitleEn,
    this.subtitleHi,
    required this.accentColor,
  });
}

class ValueCarousel extends StatefulWidget {
  final bool isHindi;
  const ValueCarousel({super.key, this.isHindi = false});

  @override
  State<ValueCarousel> createState() => _ValueCarouselState();
}

class _ValueCarouselState extends State<ValueCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoAdvanceTimer;

  static const List<ValueCarouselItem> _items = [
    ValueCarouselItem(
      icon: Icons.sell_rounded,
      titleEn: 'Fixed price. No surge. No bargaining.',
      titleHi: 'तय किराया। कोई सर्ज नहीं। मोलभाव नहीं।',
      subtitleEn: 'Transparent district fare calculated per km',
      subtitleHi: 'प्रति किलोमीटर पारदर्शी निर्धारित किराया',
      accentColor: Color(0xFF16A34A),
    ),
    ValueCarouselItem(
      icon: Icons.shield_rounded,
      titleEn: 'Village Return Guarantee: your ride is always accepted.',
      titleHi: 'ग्रामीण रिटर्न गारंटी: आपकी सवारी हमेशा स्वीकार होगी।',
      subtitleEn: 'Dedicated round-trip drivers ready for rural pick & drop',
      subtitleHi: 'गाँव और कस्बों के लिए समर्पित वापसी यात्रा सुविधा',
      accentColor: Color(0xFFF59E0B),
    ),
    ValueCarouselItem(
      icon: Icons.support_agent_rounded,
      titleEn: 'Verified local drivers. 24x7 support.',
      titleHi: 'सत्यापित स्थानीय चालक। 24x7 हेल्पलाइन सहायता।',
      subtitleEn: 'Trained local drivers from your own district',
      subtitleHi: 'आपके अपने जिले के प्रशिक्षित व भरोसेमंद सारथी',
      accentColor: Color(0xFF3D2FD6),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startTimer();
  }

  void _startTimer() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      final nextPage = (_currentPage + 1) % _items.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 64,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _items.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              HapticService.selection();
            },
            itemBuilder: (context, index) {
              final item = _items[index];
              final title = widget.isHindi ? item.titleHi : item.titleEn;
              final subtitle = widget.isHindi ? item.subtitleHi : item.subtitleEn;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: item.accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        item.icon,
                        size: 22,
                        color: item.accentColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0B1020),
                              letterSpacing: -0.2,
                              height: 1.25,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF5B6478),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        // Dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_items.length, (index) {
            final isSelected = _currentPage == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isSelected ? 18 : 6,
              height: 5,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF3D2FD6)
                    : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}
