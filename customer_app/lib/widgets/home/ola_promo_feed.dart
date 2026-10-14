import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/haptic_service.dart';
import '../../theme/theme.dart';

/// Ola-Style High Graphic Promotional Feed & Brand Footer
/// Placed directly below the options row on the Home Screen.
/// Follows the user's reference design with:
/// 1. "NO MORE BOOT-SPACE SURPRISES" Prime Luggage Card
/// 2. "More festive trips, less driving" Prime Plus Card
/// 3. "Vacations, totally exciting!" Outstation Tours Card
/// 4. "#DistrictCarOnTheMove" Moving Jharkhand Brand Footer
class OlaPromoFeed extends StatelessWidget {
  final bool isHindi;
  final VoidCallback? onLuggageTap;
  final VoidCallback? onPrimePlusTap;

  const OlaPromoFeed({
    super.key,
    this.isHindi = false,
    this.onLuggageTap,
    this.onPrimePlusTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Prime Luggage Card (Open Boot Space)
        _buildLuggageCard(context),
        const SizedBox(height: 16),

        // 2. Prime Plus Cinematic Interior Card
        _buildFestivePrimePlusCard(context),
        const SizedBox(height: 16),

        // 3. Outstation Roadtrip Scenic Card
        _buildOutstationToursCard(context),
        const SizedBox(height: 24),

        // 4. #DistrictCarOnTheMove Footer
        _buildDistrictCarOnTheMoveFooter(),
        const SizedBox(height: 90), // Generous padding above floating sticky dock
      ],
    );
  }

  /// Card 1: Prime Luggage with 3D open boot graphic
  Widget _buildLuggageCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.05),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () {
            HapticService.selection();
            onLuggageTap?.call();
          },
          child: Stack(
            children: [
              // Subtle background gradient
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Text Column
                    Expanded(
                      flex: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isHindi
                                ? 'सामान के लिए\nपूरी डिक्की स्पेस'
                                : 'NO MORE\nBOOT-SPACE\nSURPRISES.',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                              letterSpacing: -0.4,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Introducing Badge (Warm Amber/Gold)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 12, color: Color(0xFFD97706)),
                                const SizedBox(width: 4),
                                Text(
                                  isHindi ? 'नया फीचर' : 'INTRODUCING',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFB45309),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Brand & Tagline
                          const Text(
                            'DISTRICT PRIME LUGGAGE',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isHindi
                                ? 'हर बार पक्की डिक्की स्पेस गारंटी।'
                                : 'Assured boot space, every time.',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // 3D Luggage Graphic
                    Expanded(
                      flex: 10,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/images/promo_luggage_boot.jpg',
                          height: 140,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 140,
                            color: const Color(0xFFF1F5F9),
                            child: const Center(
                              child: Icon(Icons.luggage_rounded, size: 48, color: Color(0xFF94A3B8)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Circular Next Arrow Button (Bottom Right)
              Positioned(
                right: 14,
                bottom: 14,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.08),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 17,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Card 2: Prime Plus Cinematic Interior Ride
  Widget _buildFestivePrimePlusCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 210,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.12),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () {
            HapticService.selection();
            onPrimePlusTap?.call();
          },
          child: Stack(
            children: [
              // High Quality Cinematic Background Image
              Positioned.fill(
                child: Image.asset(
                  'assets/images/promo_festive_prime.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF1E293B),
                    child: const Center(
                      child: Icon(Icons.celebration_rounded, size: 54, color: Color(0xFFF59E0B)),
                    ),
                  ),
                ),
              ),

              // Gradient scrim for optimal contrast
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.70),
                        Colors.black.withValues(alpha: 0.40),
                        Colors.black.withValues(alpha: 0.85),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge: District Prime+
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.workspace_premium_rounded, size: 13, color: Color(0xFFFBBF24)),
                              SizedBox(width: 4),
                              Text(
                                'DISTRICT PRIME+',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Headline
                    Text(
                      isHindi
                          ? 'त्योहारों का सफर,\nआराम और सुकून के साथ'
                          : 'More festive trips,\nless driving',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Subtitle
                    Text(
                      isHindi
                          ? 'शानदार गाड़ियाँ और तेज़ पिकअप Prime Plus के साथ'
                          : 'Enjoy spacious rides and speedy pickups with Prime Plus',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.90),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Circular White Action Button
              Positioned(
                right: 18,
                bottom: 18,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Card 3: Outstation Roadtrip Vacation Card
  Widget _buildOutstationToursCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 205,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.10),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () {
            HapticService.selection();
            context.push('/tours');
          },
          child: Stack(
            children: [
              // Scenic Outstation Hills Photo
              Positioned.fill(
                child: Image.asset(
                  'assets/images/promo_outstation_hills.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF1E293B),
                    child: const Center(
                      child: Icon(Icons.terrain_rounded, size: 54, color: Color(0xFFF59E0B)),
                    ),
                  ),
                ),
              ),

              // Gradient Scrim
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.55),
                        Colors.black.withValues(alpha: 0.25),
                        Colors.black.withValues(alpha: 0.85),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.80),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.explore_rounded, size: 12, color: Color(0xFFF59E0B)),
                          SizedBox(width: 4),
                          Text(
                            'DISTRICT OUTSTATION',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),

                    // Headline
                    Text(
                      isHindi ? 'छुट्टियों का सफर,\nबेहद रोमांचक!' : 'Vacations,\ntoy-ally exciting!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Subtitle
                    Text(
                      isHindi
                          ? 'झारखंड के दर्शनीय स्थलों के लिए किफायती आउटस्टेशन राइड'
                          : 'Book an affordable District Outstation ride',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.90),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Circular White Action Button
              Positioned(
                right: 18,
                bottom: 18,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Footer 4: #DistrictCarOnTheMove (Matching Ola screenshot 2)
  Widget _buildDistrictCarOnTheMoveFooter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '#DistrictCarOnTheMove',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Moving Jharkhand since 2024 🇮🇳',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          // Panoramic Mobility Illustration
          Container(
            height: 190,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(15, 23, 42, 0.04),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/images/promo_on_the_move_footer.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFF1F5F9),
                  child: const Center(
                    child: Icon(Icons.directions_car_rounded, size: 48, color: Color(0xFF94A3B8)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
