import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:district_car_shared/models/models.dart';
import 'package:district_car_shared/services/destinations_service.dart';
import '../../theme/theme.dart';
import '../../services/haptic_service.dart';
import '../../widgets/floating_bottom_dock.dart';
import '../auth/auth_service.dart';
import 'destination_detail_screen.dart';

class PopularDestinationsScreen extends ConsumerStatefulWidget {
  const PopularDestinationsScreen({super.key});

  @override
  ConsumerState<PopularDestinationsScreen> createState() => _PopularDestinationsScreenState();
}

class _PopularDestinationsScreenState extends ConsumerState<PopularDestinationsScreen> {
  String _selectedCategory = 'all';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'label': 'All Places', 'icon': Icons.auto_awesome_rounded},
    {'id': 'combo', 'label': 'Combo Tours', 'icon': Icons.card_giftcard_rounded},
    {'id': 'trending', 'label': 'Trending', 'icon': Icons.local_fire_department_rounded},
    {'id': 'waterfall', 'label': 'Waterfalls', 'icon': Icons.water_rounded},
    {'id': 'temple', 'label': 'Temples', 'icon': Icons.temple_hindu_rounded},
    {'id': 'hill_station', 'label': 'Hills & Valleys', 'icon': Icons.terrain_rounded},
    {'id': 'nature', 'label': 'Nature & Forest', 'icon': Icons.forest_rounded},
    {'id': 'heritage', 'label': 'Heritage', 'icon': Icons.account_balance_rounded},
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
      // Already on tours
    } else if (index == 2) {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) {
        context.push('/login', extra: '/trips');
      } else {
        context.push('/trips');
      }
    } else if (index == 3) {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) {
        context.push('/login', extra: '/profile');
      } else {
        context.push('/profile');
      }
    }
  }

  void _openDetail(PopularDestinationModel dest) {
    HapticService.selectionClick();
    DestinationDetailScreen.open(context, dest);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth > 1100 ? 4 : (screenWidth > 680 ? 3 : 2);
    final bottomInset = MediaQuery.of(context).padding.bottom + FloatingBottomDock.dockHeight + 20;

    return Scaffold(
      backgroundColor: AppTokens.background,
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
                      (_selectedCategory == 'combo' && (d.isCombo || d.category == 'combo')) ||
                      d.category == _selectedCategory;

                  final query = _searchQuery.toLowerCase().trim();
                  final matchesQuery = query.isEmpty ||
                      d.name.toLowerCase().contains(query) ||
                      d.district.toLowerCase().contains(query) ||
                      d.packageType.toLowerCase().contains(query) ||
                      d.locationAddress.toLowerCase().contains(query) ||
                      d.category.toLowerCase().contains(query);

                  return matchesCat && matchesQuery;
                }).toList();

                final trendingList = allDestinations.where((d) => d.isTrending).toList();
                final comboList = allDestinations.where((d) => d.isCombo || d.category == 'combo').toList();

                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // 1. App Bar Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTokens.ink),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        if (Navigator.canPop(context)) {
                                          Navigator.pop(context);
                                        } else {
                                          context.go('/');
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 14),
                                    const Text(
                                      'Tours & Travels',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: AppTokens.ink,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppTokens.primaryTint,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTokens.primary.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.pin_drop_rounded, size: 13, color: AppTokens.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${allDestinations.length} places',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: AppTokens.primaryDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Search Field
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTokens.border),
                                boxShadow: AppTokens.softCardShadow,
                              ),
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: (val) => setState(() => _searchQuery = val),
                                decoration: InputDecoration(
                                  hintText: 'Search waterfalls, temples, Netarhat, combos...',
                                  hintStyle: const TextStyle(fontSize: 13.5, color: AppTokens.hint),
                                  prefixIcon: const Icon(Icons.search_rounded, color: AppTokens.primary, size: 20),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear_rounded, size: 18, color: AppTokens.secondaryText),
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
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 8),
                        child: SizedBox(
                          height: 42,
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
                                  size: 15,
                                  color: isSel ? Colors.white : AppTokens.primary,
                                ),
                                label: Text(
                                  cat['label']! as String,
                                  style: TextStyle(
                                    color: isSel ? Colors.white : AppTokens.ink,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                                selected: isSel,
                                selectedColor: AppTokens.primary,
                                backgroundColor: Colors.white,
                                elevation: isSel ? 1 : 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: isSel ? AppTokens.primary : AppTokens.border,
                                  ),
                                ),
                                onSelected: (_) {
                                  HapticService.selectionClick();
                                  setState(() => _selectedCategory = cat['id']! as String);
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    // 3. Featured / Trending Horizontal Carousel (When "All" is selected)
                    if (_selectedCategory == 'all' && _searchQuery.isEmpty && trendingList.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.local_fire_department_rounded, color: AppTokens.marigoldDark, size: 20),
                                  SizedBox(width: 6),
                                  Text(
                                    'Trending Destinations',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppTokens.ink,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () => setState(() => _selectedCategory = 'trending'),
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                                child: const Text(
                                  'See All',
                                  style: TextStyle(color: AppTokens.primary, fontSize: 12.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 185,
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

                    // 4. Curated Combo Packages Row (When "All" is selected & combos exist)
                    if (_selectedCategory == 'all' && _searchQuery.isEmpty && comboList.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.card_giftcard_rounded, color: AppTokens.primary, size: 20),
                                  SizedBox(width: 6),
                                  Text(
                                    'Curated Combo Packages',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppTokens.ink,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () => setState(() => _selectedCategory = 'combo'),
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                                child: const Text(
                                  'View Combos',
                                  style: TextStyle(color: AppTokens.primary, fontSize: 12.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 105,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            scrollDirection: Axis.horizontal,
                            itemCount: comboList.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final combo = comboList[index];
                              return _buildComboPackageCard(combo);
                            },
                          ),
                        ),
                      ),
                    ],

                    // 5. Grid Section Title
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                        child: Text(
                          _selectedCategory == 'combo'
                              ? 'All Combo Tour Packages'
                              : (_selectedCategory == 'trending'
                                  ? 'Trending Top Visited'
                                  : 'Popular Places'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTokens.ink,
                          ),
                        ),
                      ),
                    ),

                    // 6. Responsive Destinations Grid
                    if (filtered.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.travel_explore_rounded, size: 54, color: AppTokens.hint),
                                const SizedBox(height: 12),
                                Text(
                                  'No tours found matching "$_searchQuery"',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTokens.secondaryText),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset),
                        sliver: SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.82,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final dest = filtered[index];
                              return _buildDestinationCard(dest);
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
              currentIndex: 1,
              onTabSelected: _onDockTabSelected,
            ),
          ),
        ],
      ),
    );
  }

  /// Trending Horizontal Card
  Widget _buildTrendingBannerCard(PopularDestinationModel dest) {
    return InkWell(
      onTap: () => _openDetail(dest),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 270,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppTokens.softCardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                DestinationDetailScreen.sanitizeUrl(dest.imageUrl),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppTokens.surface2,
                  child: const Center(child: Icon(Icons.image, color: AppTokens.hint)),
                ),
              ),
              // Gradient Overlay
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Color.fromRGBO(16, 26, 20, 0.3),
                      Color.fromRGBO(16, 26, 20, 0.88),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Top District Badge
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
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
              ),
              // Rating Badge
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTokens.marigold,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 12, color: AppTokens.ink),
                      const SizedBox(width: 2),
                      Text(
                        dest.rating.toStringAsFixed(1),
                        style: const TextStyle(color: AppTokens.ink, fontSize: 11, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom Details
              Positioned(
                left: 14,
                right: 14,
                bottom: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        dest.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTokens.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'View',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
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

  /// Curated Combo Card
  Widget _buildComboPackageCard(PopularDestinationModel combo) {
    return InkWell(
      onTap: () => _openDetail(combo),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 230,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTokens.marigold.withOpacity(0.5)),
          boxShadow: AppTokens.softCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTokens.marigoldTint,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTokens.marigoldDark.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'COMBO',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTokens.ink),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    combo.packageType.isNotEmpty ? combo.packageType : '${combo.district} Circuit',
                    style: const TextStyle(fontSize: 11, color: AppTokens.secondaryText, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              combo.name,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppTokens.ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${combo.district}, Jharkhand',
                    style: const TextStyle(fontSize: 11, color: AppTokens.primary, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 14, color: AppTokens.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Grid Destination Card
  Widget _buildDestinationCard(PopularDestinationModel dest) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _openDetail(dest),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTokens.border),
            boxShadow: AppTokens.softCardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Image
              Expanded(
                flex: 10,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(
                        DestinationDetailScreen.sanitizeUrl(dest.imageUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppTokens.surface2,
                          child: const Center(child: Icon(Icons.image, color: AppTokens.hint)),
                        ),
                      ),
                    ),
                    // Rating Badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTokens.marigold,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 11, color: AppTokens.ink),
                            const SizedBox(width: 2),
                            Text(
                              dest.rating.toStringAsFixed(1),
                              style: const TextStyle(color: AppTokens.ink, fontSize: 10, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Category Badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: dest.isCombo ? AppTokens.marigold : Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          dest.isCombo ? 'COMBO' : dest.category.toUpperCase(),
                          style: TextStyle(
                            color: dest.isCombo ? AppTokens.ink : Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Card Info
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dest.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: AppTokens.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            dest.district,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTokens.secondaryText,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: AppTokens.primaryTint,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'View',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppTokens.primary,
                            ),
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
}
