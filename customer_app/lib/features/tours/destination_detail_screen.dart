import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:district_car_shared/models/models.dart';
import 'package:district_car_shared/services/destinations_service.dart';
import '../../theme/theme.dart';
import '../../services/haptic_service.dart';
import 'tour_booking_screen.dart';

class DestinationDetailScreen extends StatefulWidget {
  final PopularDestinationModel? destination;
  final String? destinationId;

  const DestinationDetailScreen({
    super.key,
    this.destination,
    this.destinationId,
  });

  /// Universal entry point to open DestinationDetailScreen across any router or navigation context
  static Future<void> open(BuildContext context, PopularDestinationModel destination) async {
    HapticService.selectionClick();
    debugPrint('>>> [DESTINATION_DETAIL] Opening destination: ${destination.id} (${destination.name})');

    if (!context.mounted) return;

    try {
      await context.push('/destination-details?id=${destination.id}', extra: destination);
    } catch (e) {
      debugPrint('>>> [DESTINATION_DETAIL] context.push fallback: $e');
      if (context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DestinationDetailScreen(
              key: ValueKey(destination.id),
              destination: destination,
              destinationId: destination.id,
            ),
          ),
        );
      }
    }
  }

  /// Sanitize image URLs to prevent 404s or stale URLs
  static String sanitizeUrl(String url) {
    if (url.isEmpty || url == 'placeholder') {
      return 'https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?auto=format&fit=crop&w=1200&q=80';
    }
    if (url.contains('wikimedia.org') || url.contains('wikipedia.org')) {
      return 'https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?auto=format&fit=crop&w=1200&q=80';
    }
    return url;
  }

  @override
  State<DestinationDetailScreen> createState() => _DestinationDetailScreenState();
}

class _DestinationDetailScreenState extends State<DestinationDetailScreen> {
  bool _isDescriptionExpanded = false;
  bool _isFavorite = false;

  PopularDestinationModel get _dest {
    if (widget.destination != null) return widget.destination!;
    if (widget.destinationId != null && widget.destinationId!.isNotEmpty) {
      return DestinationsService.getById(widget.destinationId!) ??
          DestinationsService.defaultDestinations.firstWhere(
            (d) => d.id == widget.destinationId,
            orElse: () => DestinationsService.defaultDestinations.first,
          );
    }
    return DestinationsService.defaultDestinations.first;
  }

  void _handleBack() {
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

  void _openImageLightbox(BuildContext context, String initialUrl, List<String> allImages) {
    showDialog(
      context: context,
      builder: (ctx) {
        String current = initialUrl;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: InteractiveViewer(
                    maxScale: 4.0,
                    child: Image.network(
                      DestinationDetailScreen.sanitizeUrl(current),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        height: 250,
                        color: Colors.black87,
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
                if (allImages.length > 1)
                  Positioned(
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: allImages.map((u) {
                          final isSel = u == current;
                          return GestureDetector(
                            onTap: () => setDialogState(() => current = u),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: isSel ? 24 : 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: isSel ? AppTokens.primary : Colors.white54,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dest = _dest;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: AppTokens.background,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Stack(
              children: [
                CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // 1. Hero Image App Bar
                    SliverAppBar(
                      expandedHeight: 320,
                      pinned: true,
                      backgroundColor: AppTokens.darkSurface,
                      leading: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                          onPressed: _handleBack,
                        ),
                      ),
                      actions: [
                        Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: _isFavorite ? AppTokens.terracotta : Colors.white,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() => _isFavorite = !_isFavorite);
                              HapticService.selectionClick();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_isFavorite ? 'Saved to Favorites ❤️' : 'Removed from Favorites'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              DestinationDetailScreen.sanitizeUrl(dest.imageUrl),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppTokens.darkSurface,
                                child: const Center(child: Icon(Icons.image, size: 48, color: Colors.white54)),
                              ),
                            ),
                            // Gradient Overlay
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black54,
                                    Colors.transparent,
                                    Color.fromRGBO(16, 26, 20, 0.90),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  stops: [0.0, 0.4, 1.0],
                                ),
                              ),
                            ),
                            // Title & Badges
                            Positioned(
                              left: 20,
                              bottom: 20,
                              right: 20,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: dest.isCombo ? AppTokens.marigold : AppTokens.primary,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          dest.isCombo ? 'COMBO TOUR' : dest.category.toUpperCase(),
                                          style: TextStyle(
                                            color: dest.isCombo ? AppTokens.ink : Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 10.5,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.25),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.location_on, size: 12, color: AppTokens.marigold),
                                            const SizedBox(width: 3),
                                            Text(
                                              dest.district,
                                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    dest.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 22,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 2. Main Content Body
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Location & Rating Header Card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppTokens.border),
                                boxShadow: AppTokens.softCardShadow,
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.place_rounded, color: AppTokens.primary, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          dest.locationAddress.isNotEmpty ? dest.locationAddress : '${dest.name}, ${dest.district}',
                                          style: const TextStyle(
                                            color: AppTokens.ink,
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 22, color: AppTokens.border),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.star_rounded, color: AppTokens.marigoldDark, size: 18),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${dest.rating} (${dest.reviewsCount}+ reviews)',
                                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTokens.ink),
                                          ),
                                        ],
                                      ),
                                      Container(height: 16, width: 1, color: AppTokens.border),
                                      Row(
                                        children: [
                                          const Icon(Icons.verified_user_rounded, color: AppTokens.primary, size: 17),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'Verified Destination',
                                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTokens.primaryDark),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Quick Facts (Entry Fee, Best Time, Timings, Time Needed)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppTokens.border),
                                boxShadow: AppTokens.softCardShadow,
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      _buildFactItem(Icons.confirmation_number_outlined, 'Entry Fee', dest.entryFee),
                                      _buildFactItem(Icons.schedule_rounded, 'Time Needed', dest.timeNeeded),
                                    ],
                                  ),
                                  const Divider(height: 20, color: AppTokens.border),
                                  Row(
                                    children: [
                                      _buildFactItem(Icons.calendar_month_rounded, 'Best Season', dest.bestTimeToVisit),
                                      _buildFactItem(Icons.local_parking_rounded, 'Access', dest.stepsOrParking),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // About Description
                            const Text(
                              'About this Place',
                              style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: AppTokens.ink),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppTokens.border),
                                boxShadow: AppTokens.softCardShadow,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dest.description,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      color: AppTokens.secondaryText,
                                      height: 1.6,
                                    ),
                                    maxLines: _isDescriptionExpanded ? null : 4,
                                    overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () {
                                      HapticService.selectionClick();
                                      setState(() => _isDescriptionExpanded = !_isDescriptionExpanded);
                                    },
                                    child: Text(
                                      _isDescriptionExpanded ? 'Read Less ▲' : 'Read More ▼',
                                      style: const TextStyle(
                                        color: AppTokens.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Photo Gallery
                            () {
                              final allImages = {
                                dest.imageUrl,
                                ...dest.galleryImages,
                              }.where((url) => url.isNotEmpty).toList();

                              if (allImages.length <= 1) return const SizedBox.shrink();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Photo Gallery',
                                        style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: AppTokens.ink),
                                      ),
                                      Text(
                                        '${allImages.length} Photos',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTokens.primary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    height: 110,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: allImages.length,
                                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                                      itemBuilder: (context, idx) {
                                        final img = allImages[idx];
                                        return GestureDetector(
                                          onTap: () => _openImageLightbox(context, img, allImages),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(14),
                                            child: Stack(
                                              children: [
                                                Image.network(
                                                  DestinationDetailScreen.sanitizeUrl(img),
                                                  width: 140,
                                                  height: 110,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => Container(
                                                    width: 140,
                                                    height: 110,
                                                    color: AppTokens.surface2,
                                                    child: const Icon(Icons.broken_image, color: AppTokens.hint),
                                                  ),
                                                ),
                                                Positioned(
                                                  bottom: 6,
                                                  right: 6,
                                                  child: Container(
                                                    padding: const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black.withOpacity(0.55),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(Icons.fullscreen, color: Colors.white, size: 16),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              );
                            }(),

                            // Highlights
                            if (dest.highlights.isNotEmpty) ...[
                              const Text(
                                'Tour Highlights',
                                style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: AppTokens.ink),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: AppTokens.border),
                                  boxShadow: AppTokens.softCardShadow,
                                ),
                                child: Column(
                                  children: dest.highlights.map((h) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.check_circle_rounded, color: AppTokens.primary, size: 18),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              h,
                                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppTokens.ink),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Safety & Local Tips
                            if (dest.safetyTips.isNotEmpty) ...[
                              const Text(
                                'Travel Safety & Local Tips',
                                style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: AppTokens.ink),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: AppTokens.border),
                                  boxShadow: AppTokens.softCardShadow,
                                ),
                                child: Column(
                                  children: dest.safetyTips.map((tip) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.info_outline_rounded, color: AppTokens.terracotta, size: 17),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              tip,
                                              style: const TextStyle(fontSize: 13, color: AppTokens.secondaryText, height: 1.4),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // 3. Sticky Bottom Booking Bar
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      14,
                      20,
                      MediaQuery.of(context).padding.bottom + 14,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromRGBO(28, 27, 24, 0.1),
                          blurRadius: 16,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'From ₹${dest.startingFare.toInt()}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppTokens.ink,
                              ),
                            ),
                            Text(
                              dest.isCombo ? 'Combo Package Price' : 'Round-trip from hub',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppTokens.primary,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {
                            HapticService.buttonPress();
                            TourBookingScreen.open(context, dest);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTokens.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Plan this trip',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward_rounded, size: 17),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFactItem(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppTokens.primaryTint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTokens.primary, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AppTokens.hint, fontWeight: FontWeight.w500),
                ),
                Text(
                  value.isNotEmpty ? value : 'N/A',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppTokens.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
