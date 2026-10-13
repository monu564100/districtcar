import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:district_car_shared/models/models.dart';
import 'package:district_car_shared/services/destinations_service.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import '../../widgets/floating_bottom_dock.dart';
import '../../widgets/premium_empty_state.dart';

class PopularDestinationsScreen extends ConsumerStatefulWidget {
  const PopularDestinationsScreen({super.key});

  @override
  ConsumerState<PopularDestinationsScreen> createState() => _PopularDestinationsScreenState();
}

class _PopularDestinationsScreenState extends ConsumerState<PopularDestinationsScreen> {
  String _selectedCategory = 'all'; // 'all', 'trending', 'waterfall', 'temple', 'hill_station', 'nature'
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'label': 'All Places', 'icon': Icons.stars_rounded},
    {'id': 'trending', 'label': 'Trending', 'icon': Icons.local_fire_department_rounded},
    {'id': 'waterfall', 'label': 'Waterfalls', 'icon': Icons.water_rounded},
    {'id': 'temple', 'label': 'Temples', 'icon': Icons.account_balance_rounded},
    {'id': 'hill_station', 'label': 'Hill Stations', 'icon': Icons.terrain_rounded},
    {'id': 'nature', 'label': 'Nature & Forest', 'icon': Icons.forest_rounded},
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onDockTabSelected(int index) {
    if (index == 0) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        context.go('/');
      }
    } else if (index == 1) {
      // already on tours
    } else if (index == 2) {
      context.push('/trips');
    } else if (index == 3) {
      context.push('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          SafeArea(
            child: StreamBuilder<List<PopularDestinationModel>>(
              stream: DestinationsService.streamDestinations(),
              builder: (context, snapshot) {
                final allDestinations = snapshot.data ?? DestinationsService.defaultDestinations;

                // Filter destinations
                final filtered = allDestinations.where((d) {
                  final matchesCat = _selectedCategory == 'all' ||
                      (_selectedCategory == 'trending' && d.isTrending) ||
                      d.category == _selectedCategory;

                  final query = _searchQuery.toLowerCase().trim();
                  final matchesQuery = query.isEmpty ||
                      d.name.toLowerCase().contains(query) ||
                      d.district.toLowerCase().contains(query) ||
                      d.locationAddress.toLowerCase().contains(query) ||
                      d.category.toLowerCase().contains(query);

                  return matchesCat && matchesQuery;
                }).toList();

                final trendingList = allDestinations.where((d) => d.isTrending).toList();

                return CustomScrollView(
                  slivers: [
                    // 1. App Bar & Search Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => context.go('/'),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          'Tours & Travels',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF0F172A),
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        Text(
                                          'झारखंड दर्शन एवं तीर्थ यात्रा',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF059669),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.verified, size: 14, color: Color(0xFF16A34A)),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${allDestinations.length} Places',
                                        style: const TextStyle(
                                          color: Color(0xFF15803D),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Search Field
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: (val) => setState(() => _searchQuery = val),
                                decoration: InputDecoration(
                                  hintText: 'Search waterfalls, temples, Netarhat...',
                                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 18),
                                          onPressed: () {
                                            _searchCtrl.clear();
                                            setState(() => _searchQuery = '');
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 2. Category Filter Chips
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 44,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            final cat = _categories[idx];
                            final isSel = _selectedCategory == cat['id'];
                            final icon = cat['icon'] as IconData;
                            return ChoiceChip(
                              avatar: Icon(
                                icon,
                                size: 16,
                                color: isSel ? Colors.white : AppColors.primary,
                              ),
                              label: Text(
                                cat['label']! as String,
                                style: TextStyle(
                                  color: isSel ? Colors.white : const Color(0xFF334155),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              selected: isSel,
                              selectedColor: AppColors.primary,
                              backgroundColor: Colors.white,
                              elevation: isSel ? 2 : 0,
                              pressElevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSel ? AppColors.primary : Colors.grey.shade200,
                                ),
                              ),
                              onSelected: (_) => setState(() => _selectedCategory = cat['id']! as String),
                            );
                          },
                        ),
                      ),
                    ),

                    // 3. Trending Locations Section (When "All" is active)
                    if (_selectedCategory == 'all' && _searchQuery.isEmpty && trendingList.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.local_fire_department_rounded, color: Color(0xFFEA580C), size: 20),
                                  SizedBox(width: 6),
                                  Text(
                                    'Trending Locations',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Top Visited',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () => setState(() => _selectedCategory = 'trending'),
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                                child: const Text(
                                  'See All',
                                  style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 190,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            scrollDirection: Axis.horizontal,
                            itemCount: trendingList.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 14),
                            itemBuilder: (context, index) {
                              final dest = trendingList[index];
                              return _buildTrendingBannerCard(dest);
                            },
                          ),
                        ),
                      ),
                    ],

                    // 4. Section Title for Grid: "Popular Places (1 Row 2 Cards)"
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                        child: Row(
                          children: [
                            Icon(
                              _selectedCategory == 'waterfall'
                                  ? Icons.water_rounded
                                  : _selectedCategory == 'temple'
                                      ? Icons.account_balance_rounded
                                      : _selectedCategory == 'hill_station'
                                          ? Icons.terrain_rounded
                                          : _selectedCategory == 'nature'
                                              ? Icons.forest_rounded
                                              : Icons.location_on_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _selectedCategory == 'waterfall'
                                  ? 'Waterfalls of Jharkhand'
                                  : _selectedCategory == 'temple'
                                      ? 'Holy Temples & Pilgrimages'
                                      : _selectedCategory == 'hill_station'
                                          ? 'Hill Stations & Viewpoints'
                                          : _selectedCategory == 'nature'
                                              ? 'Wildlife & Nature Sanctuaries'
                                              : 'All Popular Destinations (${filtered.length})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 5. 2-COLUMN SQUARE GRID (1 row 2 square images as requested)
                    if (filtered.isEmpty)
                      SliverToBoxAdapter(
                        child: PremiumEmptyState(
                          title: 'No Destinations Found',
                          subtitle: 'We couldn\'t find any destinations matching "$_searchQuery". Try searching for Ranchi, Netarhat, or waterfalls.',
                          imageAsset: 'assets/images/empty_search_pulse.jpg',
                          fallbackIcon: Icons.travel_explore_rounded,
                          glowColor: const Color(0xFF0F766E),
                          actionLabel: 'Reset All Filters',
                          onAction: () {
                            _searchCtrl.clear();
                            setState(() {
                              _searchQuery = '';
                              _selectedCategory = 'all';
                            });
                          },
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, // 2 items per row
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.72, // Snug, responsive ratio without white gap or overflow
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = filtered[index];
                              return _buildSquareDestinationCard(item);
                            },
                            childCount: filtered.length,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // Floating Bottom Navigation Dock
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingBottomDock(
              currentIndex: 1, // Tours active
              onTabSelected: _onDockTabSelected,
            ),
          ),
        ],
      ),
    );
  }

  /// Trending Top Banner Card
  Widget _buildTrendingBannerCard(PopularDestinationModel dest) {
    return GestureDetector(
      onTap: () => context.push('/destination-details', extra: dest),
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                dest.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF1E293B),
                  child: const Center(child: Icon(Icons.image, color: Colors.white54)),
                ),
              ),
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.85),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // District Badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        dest.district,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              // Rating Badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, size: 12, color: Colors.white),
                      const SizedBox(width: 3),
                      Text(
                        dest.rating.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom Details
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dest.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${dest.approxDistanceKm.toInt()} km away',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: const [
                              Text(
                                'Explore',
                                style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 3),
                              Icon(Icons.arrow_forward_rounded, size: 10, color: Colors.white),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 1 Row 2 Square Cards Grid Item
  Widget _buildSquareDestinationCard(PopularDestinationModel dest) {
    return GestureDetector(
      onTap: () => context.push('/destination-details', extra: dest),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exact Square Image with Rounded Top Corners & Badges
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: AspectRatio(
                aspectRatio: 1.15, // Responsive square photo ratio
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      dest.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF1E293B),
                        child: const Center(
                          child: Icon(Icons.image_not_supported, color: Colors.white54),
                        ),
                      ),
                    ),
                    // Subtle Top Shadow
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    // Category Chip
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          dest.category.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    // Rating Star
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.white, size: 10),
                            const SizedBox(width: 2),
                            Text(
                              dest.rating.toStringAsFixed(1),
                              style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Card Body Information
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dest.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                            color: Color(0xFF0F172A),
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.place_outlined, size: 12, color: Color(0xFF64748B)),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                '${dest.district} · ~${dest.approxDistanceKm.toInt()} km',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Explore Place',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Color(0xFF059669),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
