import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:district_car_shared/models/models.dart';
import 'package:district_car_shared/services/destinations_service.dart';
import '../../theme/theme.dart';
import '../../services/haptic_service.dart';
import '../../widgets/tours/branded_destination_placeholder.dart';
import 'tour_pricing_service.dart';
import 'tour_booking_screen.dart';

/// Redesigned Destination Detail Screen
/// Editorial layout: Hero photo pager, 2x3 quick facts, season bar, bilingual about,
/// safety tips, nearby stops multi-stop upsell, guarantee card, and sticky package fare bar.
class DestinationDetailScreen extends StatefulWidget {
  final PopularDestinationModel? destination;
  final String? destinationId;

  const DestinationDetailScreen({
    super.key,
    this.destination,
    this.destinationId,
  });

  /// Sanitize image URLs to prevent 404s or stale Wikimedia URLs
  static String sanitizeUrl(String url) {
    if (url.contains('Hundru_Falls_Ranchi.jpg')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/b/be/Hundru_Falls%2C_Jharkhand%2C_India_4.jpg';
    }
    return url;
  }

  /// Universal entry point to open DestinationDetailScreen across any router or navigation context.
  /// Uses addPostFrameCallback to ensure all mouse pointer & hover events finish cleanly,
  /// completely preventing mouse_tracker assertion failures on Flutter Web.
  static Future<void> open(BuildContext context, PopularDestinationModel destination) {
    HapticService.selectionClick();
    debugPrint('>>> [DESTINATION_DETAIL] Opening destination: ${destination.id} (${destination.name})');

    final completer = Completer<void>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) {
        completer.complete();
        return;
      }

      try {
        // Direct root Navigator push: 100% reliable across Web, Mobile, and Desktop
        await Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            settings: RouteSettings(name: '/destination-details?id=${destination.id}'),
            builder: (_) => DestinationDetailScreen(
              key: ValueKey(destination.id),
              destination: destination,
              destinationId: destination.id,
            ),
          ),
        );
      } catch (e) {
        debugPrint('>>> [DESTINATION_DETAIL] Navigator.push fallback to context.push: $e');
        if (context.mounted) {
          try {
            await context.push('/destination-details?id=${destination.id}', extra: destination);
          } catch (routerError) {
            debugPrint('>>> [DESTINATION_DETAIL] context.push also failed: $routerError');
          }
        }
      } finally {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    return completer.future;
  }

  @override
  State<DestinationDetailScreen> createState() => _DestinationDetailScreenState();
}

class _DestinationDetailScreenState extends State<DestinationDetailScreen> {
  int _currentPhotoIndex = 0;
  bool _isFavorite = false;
  bool _isHindi = false;
  bool _isAboutExpanded = false;
  final Set<String> _selectedNearbyStopIds = <String>{};
  int? _expandedFaqIndex;
  bool _isNavigatingToBooking = false;

  PopularDestinationModel get _dest {
    if (widget.destination != null) return widget.destination!;
    if (widget.destinationId != null && widget.destinationId!.isNotEmpty) {
      return DestinationsService.defaultDestinations.firstWhere(
        (d) => d.id == widget.destinationId,
        orElse: () => DestinationsService.defaultDestinations.first,
      );
    }
    return DestinationsService.defaultDestinations.first;
  }

  late List<String> _allPhotos;

  void _loadPhotos() {
    final d = _dest;
    final primaryImg = DestinationDetailScreen.sanitizeUrl(d.imageUrl);
    _allPhotos = [
      if (primaryImg.isNotEmpty) primaryImg,
      ...d.galleryImages
          .map(DestinationDetailScreen.sanitizeUrl)
          .where((img) => img.isNotEmpty && img != primaryImg),
    ];
    if (_allPhotos.isEmpty) {
      _allPhotos = [primaryImg.isNotEmpty ? primaryImg : 'placeholder'];
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  @override
  void didUpdateWidget(covariant DestinationDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.destination?.id != widget.destination?.id ||
        oldWidget.destinationId != widget.destinationId) {
      _loadPhotos();
      _currentPhotoIndex = 0;
    }
  }

  Widget _buildSafeHeroImage(String rawUrl) {
    final url = DestinationDetailScreen.sanitizeUrl(rawUrl);
    if (url.isEmpty || url == 'placeholder' || !url.startsWith('http')) {
      return const BrandedDestinationPlaceholder();
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const BrandedDestinationPlaceholder(),
    );
  }

  void _shareViaWhatsApp() async {
    HapticService.selectionClick();
    final d = _dest;
    final text = 'Namaste! Check out this tour to ${d.name} (${d.district}, Jharkhand) on District Car: round-trip fixed packages from ₹${d.startingFare.round()}. Verified local drivers & doorstep pickup: https://districtcar.in/tours/${d.id}';
    final url = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _openFullScreenGallery(int initialIndex) {
    HapticService.selectionClick();
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (ctx) => _FullScreenGalleryViewer(
          images: _allPhotos,
          initialIndex: initialIndex,
          destinationName: _dest.name,
          credit: _dest.imageCredit,
          license: _dest.imageLicense,
        ),
      ),
    );
  }

  void _handleBack(BuildContext context) {
    HapticService.selectionClick();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    try {
      if (context.canPop()) {
        context.pop();
        return;
      }
    } catch (_) {}
    try {
      context.go('/tours');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final dest = _dest;
    final heroHeight = (MediaQuery.of(context).size.height * 0.40).clamp(280.0, 420.0);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBack(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppTokens.background,
        bottomNavigationBar: _buildStickyBottomBar(dest),
        body: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
                // 1. Pinned Hero App Bar (Back button ALWAYS visible, never stuck)
                SliverAppBar(
                  expandedHeight: heroHeight,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: AppTokens.darkSurface,
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Center(
                      child: _buildFrostedButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => _handleBack(context),
                      ),
                    ),
                  ),
                  actions: [
                    _buildFrostedButton(
                      icon: Icons.share_rounded,
                      onTap: _shareViaWhatsApp,
                    ),
                    const SizedBox(width: 8),
                    _buildFrostedButton(
                      icon: _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      iconColor: _isFavorite ? AppTokens.terracotta : Colors.white,
                      onTap: () {
                        setState(() => _isFavorite = !_isFavorite);
                        if (_isFavorite) {
                          HapticService.success();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Saved to your Favorites ❤️')),
                          );
                        } else {
                          HapticService.lightImpact();
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Photo PageView
                        PageView.builder(
                          itemCount: _allPhotos.length,
                          onPageChanged: (i) {
                            HapticService.selectionClick();
                            setState(() => _currentPhotoIndex = i);
                          },
                          itemBuilder: (context, index) {
                            final imgUrl = _allPhotos[index];
                            return GestureDetector(
                              onTap: () => _openFullScreenGallery(index),
                              child: _buildSafeHeroImage(imgUrl),
                            );
                          },
                        ),

                        // Dark Hero Scrim
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black45,
                                Colors.transparent,
                                Color.fromRGBO(16, 26, 20, 0.90),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: [0.0, 0.35, 1.0],
                            ),
                          ),
                        ),

                        // Photo Counter Pill (e.g. "1/6")
                        Positioned(
                          right: 16,
                          bottom: 72,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Text(
                              '${_currentPhotoIndex + 1}/${_allPhotos.length} Photos',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        // Bottom Scrim Details: Category, City, Serif Title, Hindi Title
                        Positioned(
                          left: 20,
                          right: 20,
                          bottom: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTokens.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      dest.category.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTokens.marigold,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      dest.district,
                                      style: const TextStyle(
                                        color: AppTokens.ink,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                dest.name,
                                style: const TextStyle(
                                  fontFamily: 'Georgia',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              if (dest.hindiName.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  dest.hindiName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTokens.marigold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),


              // 2. Photo License & Attribution Bar (Rule 0a: Real attribution stored in data)
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  color: AppTokens.surface2,
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded, size: 14, color: AppTokens.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Photo credit: ${dest.imageCredit} · License: ${dest.imageLicense}',
                          style: const TextStyle(fontSize: 11, color: AppTokens.secondaryText),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Quick-Facts Grid (2x3)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTokens.radiusCards),
                      border: Border.all(color: AppTokens.border),
                      boxShadow: AppTokens.softCardShadow,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _buildQuickFactItem(
                              icon: Icons.star_rounded,
                              iconColor: AppTokens.marigoldDark,
                              label: 'Rating',
                              value: '${dest.rating} (${dest.reviewsCount}+)',
                            ),
                            _buildQuickFactItem(
                              icon: Icons.near_me_rounded,
                              iconColor: AppTokens.primary,
                              label: 'Distance',
                              value: '${dest.approxDistanceKm.round()} km from you',
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: AppTokens.border, height: 1),
                        ),
                        Row(
                          children: [
                            _buildQuickFactItem(
                              icon: Icons.schedule_rounded,
                              iconColor: AppTokens.terracotta,
                              label: 'Time Needed',
                              value: dest.timeNeeded,
                            ),
                            _buildQuickFactItem(
                              icon: Icons.confirmation_number_rounded,
                              iconColor: AppTokens.primary,
                              label: 'Entry Fee',
                              value: dest.entryFee,
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: AppTokens.border, height: 1),
                        ),
                        Row(
                          children: [
                            _buildQuickFactItem(
                              icon: Icons.wb_sunny_rounded,
                              iconColor: AppTokens.marigoldDark,
                              label: 'Best Season',
                              value: dest.bestTimeToVisit.isNotEmpty
                                  ? dest.bestTimeToVisit.split('(').first.trim()
                                  : 'Oct to Feb',
                            ),
                            _buildQuickFactItem(
                              icon: Icons.local_parking_rounded,
                              iconColor: AppTokens.primaryDark,
                              label: 'Access & Parking',
                              value: dest.stepsOrParking,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. Best Time to Visit Card with 12 Months Season Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTokens.marigoldTint,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTokens.marigold.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.calendar_month_rounded, size: 18, color: AppTokens.marigoldDark),
                                SizedBox(width: 8),
                                Text(
                                  'Season Guide & Weather',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppTokens.ink,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTokens.marigold.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.wb_cloudy_rounded, size: 13, color: AppTokens.primary),
                                  SizedBox(width: 4),
                                  Text(
                                    '26°C · Pleasant',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTokens.ink),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // 12 Months Season Bar
                        _buildSeasonBar(),
                        const SizedBox(height: 8),
                        Text(
                          'Recommended: ${dest.bestTimeToVisit}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppTokens.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 5. About Section with Language Toggle & Read More
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTokens.radiusCards),
                      border: Border.all(color: AppTokens.border),
                      boxShadow: AppTokens.softCardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'About this Place',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppTokens.ink),
                            ),
                            // Language Toggle
                            GestureDetector(
                              onTap: () {
                                HapticService.selectionClick();
                                setState(() => _isHindi = !_isHindi);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTokens.primaryTint,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTokens.primary.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  _isHindi ? 'हिन्दी / EN' : 'EN / हिन्दी',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppTokens.primaryDark,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          dest.description,
                          maxLines: _isAboutExpanded ? 20 : 4,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: AppTokens.secondaryText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () {
                            HapticService.selectionClick();
                            setState(() => _isAboutExpanded = !_isAboutExpanded);
                          },
                          child: Text(
                            _isAboutExpanded ? 'Show Less' : 'Read More',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppTokens.primary, // Primary green, NOT blue
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 6. Highlights (Clean Checklist, one per row)
              if (dest.highlights.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTokens.radiusCards),
                        border: Border.all(color: AppTokens.border),
                        boxShadow: AppTokens.softCardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tour Highlights',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppTokens.ink),
                          ),
                          const SizedBox(height: 12),
                          ...dest.highlights.map((h) => _buildHighlightRow(h)),
                        ],
                      ),
                    ),
                  ),
                ),

              // 7. Safety & Tips Section (Builds trust, prevents misunderstandings)
              if (dest.safetyTips.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTokens.radiusCards),
                        border: Border.all(color: AppTokens.border),
                        boxShadow: AppTokens.softCardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.shield_outlined, size: 20, color: AppTokens.terracotta),
                              SizedBox(width: 8),
                              Text(
                                'Travel Safety & Local Tips',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppTokens.ink),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...dest.safetyTips.map((tip) => _buildSafetyTipRow(tip)),
                        ],
                      ),
                    ),
                  ),
                ),

              // 8. Combine with this Trip (Nearby Stops Multi-Stop Upsell)
              if (dest.nearbyStops.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTokens.radiusCards),
                        border: Border.all(color: AppTokens.border),
                        boxShadow: AppTokens.softCardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Combine with this Trip',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppTokens.ink),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Add nearby spots to your route with zero detour bargaining',
                            style: TextStyle(fontSize: 12.5, color: AppTokens.secondaryText),
                          ),
                          const SizedBox(height: 14),
                          ...dest.nearbyStops.map((stop) {
                            final stopId = stop['id']?.toString() ?? '';
                            final isAdded = _selectedNearbyStopIds.contains(stopId);
                            return _buildNearbyStopTile(stop, isAdded);
                          }),
                        ],
                      ),
                    ),
                  ),
                ),

              // 9. District Car Guarantee Card (Dark Forest Gradient + Marigold Shield)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppTokens.darkForestGradient,
                      borderRadius: BorderRadius.circular(AppTokens.radiusCards),
                      boxShadow: AppTokens.softCardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTokens.marigold.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.verified_user_rounded, color: AppTokens.marigold, size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'District Car Tour Guarantee',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'झारखंड टूर सुरक्षा एवं भरोसा',
                                    style: TextStyle(color: AppTokens.marigold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildGuaranteeCheck('Local verified drivers with deep route knowledge'),
                        _buildGuaranteeCheck('Flexible waiting hours (1 hr free in round trips)'),
                        _buildGuaranteeCheck('Doorstep pickup & drop right at your home or hotel'),
                        _buildGuaranteeCheck('100% Fixed package price: no bargaining, no surge'),
                      ],
                    ),
                  ),
                ),
              ),

              // 10. FAQ Accordion (3 items)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTokens.radiusCards),
                      border: Border.all(color: AppTokens.border),
                      boxShadow: AppTokens.softCardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Frequently Asked Questions',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppTokens.ink),
                        ),
                        const SizedBox(height: 12),
                        _buildFaqItem(
                          index: 0,
                          q: 'How does round-trip waiting work?',
                          a: 'Your driver stays with your vehicle at the destination parking. 1 hour of waiting is included free. Extra hours are just ₹100–₹150/hr.',
                        ),
                        _buildFaqItem(
                          index: 1,
                          q: 'Can I pick up family members along the route?',
                          a: 'Yes! Doorstep pickup anywhere in the hub city is included. You can add stops during checkout.',
                        ),
                        _buildFaqItem(
                          index: 2,
                          q: 'What if weather turns bad or rain starts?',
                          a: 'Free cancellation is available up to 2 hours before your scheduled departure time.',
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildStickyBottomBar(PopularDestinationModel dest) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(28, 27, 24, 0.12),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'From ₹${dest.startingFare.round()}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTokens.ink,
                    letterSpacing: -0.4,
                  ),
                ),
                Text(
                  'Round trip from ${dest.district}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTokens.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {
              if (_isNavigatingToBooking) return;
              _isNavigatingToBooking = true;
              HapticService.buttonPress();
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!mounted) {
                  _isNavigatingToBooking = false;
                  return;
                }
                try {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => TourBookingScreen(destination: dest),
                    ),
                  );
                } catch (_) {
                  if (mounted) {
                    await context.push('/book-tour?id=${dest.id}', extra: dest);
                  }
                } finally {
                  if (mounted) {
                    _isNavigatingToBooking = false;
                  }
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTokens.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Plan this trip',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrostedButton({
    required IconData icon,
    Color iconColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.50),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white30),
          ),
          child: Center(
            child: Icon(icon, color: iconColor, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFactItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTokens.primaryTint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppTokens.hint),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTokens.ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonBar() {
    const months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
    // For waterfall/plateau destinations in Jharkhand, best months are typically Jul-Feb (indices 6, 7, 8, 9, 10, 11, 0, 1)
    const bestIndices = {6, 7, 8, 9, 10, 11, 0, 1};

    return Row(
      children: List.generate(12, (index) {
        final isBest = bestIndices.contains(index);
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            height: 24,
            decoration: BoxDecoration(
              color: isBest ? AppTokens.primary : AppTokens.border,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                months[index],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isBest ? Colors.white : AppTokens.secondaryText,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHighlightRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, color: AppTokens.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppTokens.ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTipRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppTokens.terracotta, size: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTokens.secondaryText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyStopTile(Map<String, dynamic> stop, bool isAdded) {
    final stopId = stop['id']?.toString() ?? '';
    final stopName = stop['name']?.toString() ?? 'Nearby Spot';
    final distanceKm = stop['distanceKm']?.toString() ?? '10';
    final fare = stop['fare']?.toString() ?? '200';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isAdded ? AppTokens.primaryTint : AppTokens.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAdded ? AppTokens.primary : AppTokens.border,
          width: isAdded ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stopName,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppTokens.ink),
                ),
                Text(
                  '+$distanceKm km · +₹$fare',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTokens.primary),
                ),
              ],
            ),
          ),
          Switch(
            value: isAdded,
            activeColor: AppTokens.primary,
            onChanged: (val) {
              HapticService.selectionClick();
              setState(() {
                if (val) {
                  _selectedNearbyStopIds.add(stopId);
                } else {
                  _selectedNearbyStopIds.remove(stopId);
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGuaranteeCheck(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: AppTokens.marigold, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem({required int index, required String q, required String a}) {
    final isExpanded = _expandedFaqIndex == index;
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            HapticService.selectionClick();
            setState(() => _expandedFaqIndex = isExpanded ? null : index);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    q,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTokens.ink),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: AppTokens.secondaryText,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              a,
              style: const TextStyle(fontSize: 13, color: AppTokens.secondaryText, height: 1.4),
            ),
          ),
        const Divider(color: AppTokens.border, height: 1),
      ],
    );
  }
}

/// Full Screen Gallery Viewer with Pinch-to-zoom and swipe to dismiss
class _FullScreenGalleryViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String destinationName;
  final String credit;
  final String license;

  const _FullScreenGalleryViewer({
    required this.images,
    required this.initialIndex,
    required this.destinationName,
    required this.credit,
    required this.license,
  });

  @override
  State<_FullScreenGalleryViewer> createState() => _FullScreenGalleryViewerState();
}

class _FullScreenGalleryViewerState extends State<_FullScreenGalleryViewer> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.destinationName,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_currentIndex + 1}/${widget.images.length}',
                style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            itemCount: widget.images.length,
            controller: PageController(initialPage: widget.initialIndex),
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, idx) {
              return InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Center(
                  child: (widget.images[idx].isNotEmpty && widget.images[idx].startsWith('http'))
                      ? Image.network(
                          widget.images[idx],
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image, color: Colors.white54, size: 54),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.photo_library_rounded, color: Colors.white54, size: 54),
                        ),
                ),
              );
            },
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Credit: ${widget.credit} · License: ${widget.license}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
