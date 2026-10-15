import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:district_car_shared/models/models.dart';
import 'package:district_car_shared/services/destinations_service.dart';
import '../../theme/theme.dart';
import '../../services/haptic_service.dart';
import '../../widgets/floating_bottom_dock.dart';
import '../../widgets/tours/branded_destination_placeholder.dart';
import '../../widgets/tours/tour_assets.dart';
import 'tour_pricing_service.dart';
import 'destination_detail_screen.dart';
import '../auth/auth_service.dart';

/// Redesigned Explore Screen (Tours & Travels Jharkhand)
/// Concept: Sal forest + marigold + laterite earth, blue-free.
class PopularDestinationsScreen extends ConsumerStatefulWidget {
  const PopularDestinationsScreen({super.key});

  @override
  ConsumerState<PopularDestinationsScreen> createState() => _PopularDestinationsScreenState();
}

class _PopularDestinationsScreenState extends ConsumerState<PopularDestinationsScreen> {
  String _selectedCategory = 'all';
  String _searchQuery = '';
  String _sortBy = 'popular'; // 'popular', 'nearest', 'price'
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final Set<String> _savedPlaceIds = <String>{};

  final List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'label': 'All Places', 'icon': Icons.auto_awesome_rounded},
    {'id': 'trending', 'label': 'Trending', 'icon': Icons.local_fire_department_rounded},
    {'id': 'waterfall', 'label': 'Waterfalls', 'icon': Icons.water_rounded},
    {'id': 'temple', 'label': 'Temples & Spiritual', 'icon': Icons.temple_hindu_rounded},
    {'id': 'hill_station', 'label': 'Hills & Valleys', 'icon': Icons.terrain_rounded},
    {'id': 'wildlife', 'label': 'Wildlife & Nature', 'icon': Icons.pets_rounded},
    {'id': 'heritage', 'label': 'Heritage', 'icon': Icons.account_balance_rounded},
  ];

  final List<String> _recentSearches = ['Hundru Falls', 'Netarhat Sunset', 'Patratu Valley', 'Baidyanath Dham'];

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
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
      // Already on Explore / Tours
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

  void _openDestinationDetail(BuildContext context, PopularDestinationModel dest) {
    DestinationDetailScreen.open(context, dest);
  }

  void _toggleSave(String id) {
    setState(() {
      if (_savedPlaceIds.contains(id)) {
        _savedPlaceIds.remove(id);
        HapticService.lightImpact();
      } else {
        _savedPlaceIds.add(id);
        HapticService.success();
      }
    });
  }

  void _showSortSheet() {
    HapticService.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppTokens.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusSheets)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppTokens.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sort Destinations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTokens.ink),
            ),
            const SizedBox(height: 12),
            _buildSortOption('popular', 'Most Popular / Top Rated', Icons.star_rounded),
            _buildSortOption('nearest', 'Nearest to Me (GPS Distance)', Icons.near_me_rounded),
            _buildSortOption('price', 'Starting Price: Low to High', Icons.currency_rupee_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String id, String label, IconData icon) {
    final isSelected = _sortBy == id;
    return ListTile(
      onTap: () {
        setState(() => _sortBy = id);
        Navigator.pop(context);
        HapticService.selectionClick();
      },
      leading: Icon(icon, color: isSelected ? AppTokens.primary : AppTokens.secondaryText),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected ? AppTokens.primaryDark : AppTokens.ink,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppTokens.primary) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      tileColor: isSelected ? AppTokens.primaryTint : Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom + FloatingBottomDock.dockHeight + 24;

    return Scaffold(
      backgroundColor: AppTokens.background,
      body: Stack(
        children: [
          StreamBuilder<List<PopularDestinationModel>>(
            stream: DestinationsService.streamDestinations(),
            builder: (context, snapshot) {
              final allDestinations = snapshot.data ?? DestinationsService.defaultDestinations;

              // Filter by category and search query
              var filtered = allDestinations.where((d) {
                final matchesCat = _selectedCategory == 'all' ||
                    (_selectedCategory == 'trending' && d.isTrending) ||
                    d.category == _selectedCategory;

                final query = _searchQuery.toLowerCase().trim();
                final matchesQuery = query.isEmpty ||
                    d.name.toLowerCase().contains(query) ||
                    d.hindiName.toLowerCase().contains(query) ||
                    d.district.toLowerCase().contains(query) ||
                    d.category.toLowerCase().contains(query);

                return matchesCat && matchesQuery;
              }).toList();

              // Sort
              if (_sortBy == 'popular') {
                filtered.sort((a, b) => b.rating.compareTo(a.rating));
              } else if (_sortBy == 'nearest') {
                filtered.sort((a, b) => a.approxDistanceKm.compareTo(b.approxDistanceKm));
              } else if (_sortBy == 'price') {
                filtered.sort((a, b) => a.startingFare.compareTo(b.startingFare));
              }

              final featuredList = allDestinations.where((d) => d.isTrending).take(3).toList();

              return CustomScrollView(
                slivers: [
                  // 1. Collapsing Editorial App Bar
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 110,
                    elevation: 0,
                    backgroundColor: AppTokens.background.withValues(alpha: 0.94),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTokens.ink),
                      onPressed: () => context.go('/'),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTokens.primaryTint,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTokens.primary.withValues(alpha: 0.2)),
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
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(left: 56, bottom: 12),
                      title: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Tours & Travels',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppTokens.ink,
                              letterSpacing: -0.4,
                            ),
                          ),
                          Text(
                            'Explore Jharkhand • Day Tours & Getaways',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppTokens.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Search & Filter Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTokens.border),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchCtrl,
                                focusNode: _searchFocus,
                                onChanged: (val) => setState(() => _searchQuery = val),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTokens.ink),
                                decoration: InputDecoration(
                                  hintText: 'Waterfall, mandir, Netarhat…',
                                  hintStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppTokens.hint,
                                  ),
                                  prefixIcon: const Icon(Icons.search_rounded, color: AppTokens.secondaryText, size: 22),
                                  suffixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_searchQuery.isNotEmpty)
                                        IconButton(
                                          icon: const Icon(Icons.close_rounded, size: 18, color: AppTokens.secondaryText),
                                          onPressed: () {
                                            _searchCtrl.clear();
                                            setState(() => _searchQuery = '');
                                          },
                                        ),
                                      IconButton(
                                        icon: const Icon(Icons.mic_rounded, color: AppTokens.primary, size: 20),
                                        onPressed: () {
                                          HapticService.selectionClick();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Listening in Hindi / English…')),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Sort Button
                          InkWell(
                            onTap: _showSortSheet,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              height: 52,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTokens.border),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.sort_rounded, size: 20, color: AppTokens.ink),
                                  SizedBox(width: 4),
                                  Text(
                                    'Sort',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTokens.ink),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Recent searches suggestions when search focused and empty
                  if (_searchFocus.hasFocus && _searchQuery.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Trending Searches in Jharkhand',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTokens.secondaryText),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _recentSearches.map((term) {
                                return ActionChip(
                                  onPressed: () {
                                    _searchCtrl.text = term;
                                    setState(() => _searchQuery = term);
                                    _searchFocus.unfocus();
                                  },
                                  backgroundColor: AppTokens.surface2,
                                  side: BorderSide.none,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  avatar: const Icon(Icons.history_rounded, size: 14, color: AppTokens.secondaryText),
                                  label: Text(
                                    term,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTokens.ink),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 3. Category Filter Chips Row (Horizontally scrollable with smooth 200ms transition)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final cat = _categories[idx];
                          final isSelected = _selectedCategory == cat['id'];

                          return Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(AppTokens.radiusChips),
                            child: InkWell(
                              onTap: () {
                                HapticService.selectionClick();
                                setState(() => _selectedCategory = cat['id'] as String);
                              },
                              borderRadius: BorderRadius.circular(AppTokens.radiusChips),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: isSelected ? AppTokens.primaryGradient : null,
                                  color: isSelected ? null : Colors.white,
                                  borderRadius: BorderRadius.circular(AppTokens.radiusChips),
                                  border: Border.all(
                                    color: isSelected ? Colors.transparent : AppTokens.border,
                                  ),
                                  boxShadow: isSelected ? AppTokens.elevationGlow : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      cat['icon'] as IconData,
                                      size: 16,
                                      color: isSelected ? Colors.white : AppTokens.secondaryText,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      cat['label'] as String,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        color: isSelected ? Colors.white : AppTokens.ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // 4. Featured Snap Carousel (Max 3 cards, when viewing 'all' and no search)
                  if (_selectedCategory == 'all' && _searchQuery.isEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'Featured Experiences',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                                color: AppTokens.ink,
                              ),
                            ),
                            Text(
                              'Top Rated',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTokens.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 220,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: featuredList.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 14),
                          itemBuilder: (context, idx) {
                            final dest = featuredList[idx];
                            return _buildFeaturedCard(context, dest);
                          },
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  ],

                  // 5. Seasonal Monsoon Banner
                  if (_searchQuery.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              final hundru = allDestinations.firstWhere(
                                (d) => d.id == 'hundru_falls',
                                orElse: () => allDestinations.first,
                              );
                              _openDestinationDetail(context, hundru);
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              height: 110,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: AppTokens.softCardShadow,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.memory(
                                      kMonsoonBannerBytes,
                                      fit: BoxFit.cover,
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppTokens.darkSurface.withValues(alpha: 0.85),
                                            Colors.transparent,
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppTokens.marigold,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'SEASON SPECIAL',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                                color: AppTokens.ink,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Monsoon Waterfalls at Full Glory',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const Text(
                                            'Book a weekend village tour with verified local drivers',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // 6. Curated Tour Packages Row (Bundles)
                  if (_searchQuery.isEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'Popular Tour Packages',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppTokens.ink,
                              ),
                            ),
                            Text(
                              'Curated Circuits',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTokens.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 100,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            _buildPackageBundleCard(
                              title: 'Ranchi Waterfall Circuit',
                              subtitle: 'Hundru + Dassam + Jonha · 1 Day',
                              fare: 'From ₹1,899',
                              tag: 'Most Popular',
                              onTap: () {
                                final hundru = allDestinations.firstWhere(
                                  (d) => d.id == 'hundru_falls',
                                  orElse: () => DestinationsService.defaultDestinations.firstWhere((d) => d.id == 'hundru_falls'),
                                );
                                _openDestinationDetail(context, hundru);
                              },
                            ),
                            const SizedBox(width: 12),
                            _buildPackageBundleCard(
                              title: 'Plateau & Sunset Escape',
                              subtitle: 'Patratu Valley + Dam Cruise · Half Day',
                              fare: 'From ₹1,299',
                              tag: 'Best Value',
                              onTap: () {
                                final patratu = allDestinations.firstWhere(
                                  (d) => d.id == 'patratu_valley',
                                  orElse: () => DestinationsService.defaultDestinations.firstWhere((d) => d.id == 'patratu_valley'),
                                );
                                _openDestinationDetail(context, patratu);
                              },
                            ),
                            const SizedBox(width: 12),
                            _buildPackageBundleCard(
                              title: 'Spiritual Jyotirlinga Dham',
                              subtitle: 'Baba Baidyanath Deoghar Darshan',
                              fare: 'From ₹3,999',
                              tag: 'Pilgrimage',
                              onTap: () {
                                final baidyanath = allDestinations.firstWhere(
                                  (d) => d.id == 'baidyanath_dham',
                                  orElse: () => DestinationsService.defaultDestinations.firstWhere((d) => d.id == 'baidyanath_dham'),
                                );
                                _openDestinationDetail(context, baidyanath);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],

                  // 7. Grid Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedCategory == 'all'
                                ? 'All Jharkhand Destinations (${filtered.length})'
                                : '${filtered.length} Places Found',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: AppTokens.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // 8. 2-Column Grid (4:5 Aspect Ratio Cards with Serif Titles & Tabular Fares)
                  if (filtered.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'No destinations match your search.\nTry searching for "Waterfall" or "Temple"',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTokens.secondaryText, fontSize: 14),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.72,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final dest = filtered[index];
                            final isSaved = _savedPlaceIds.contains(dest.id);
                            return _buildDestinationGridCard(context, dest, isSaved);
                          },
                          childCount: filtered.length,
                        ),
                      ),
                    ),

                  // Bottom padding for floating dock (Rule 0e: bottom nav must never overlap content)
                  SliverToBoxAdapter(
                    child: SizedBox(height: bottomInset),
                  ),
                ],
              );
            },
          ),

          // Floating Bottom Navigation Dock (All 4 tabs showing labels)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingBottomDock(
              currentIndex: 1, // Explore tab
              onTabSelected: _onDockTabSelected,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafeImage(String rawUrl, {BoxFit fit = BoxFit.cover}) {
    final url = DestinationDetailScreen.sanitizeUrl(rawUrl);
    if (url.isEmpty || !url.startsWith('http')) {
      return const BrandedDestinationPlaceholder();
    }
    return Image.network(
      url,
      fit: fit,
      errorBuilder: (_, __, ___) => const BrandedDestinationPlaceholder(),
    );
  }

  /// 4:5 Destination Grid Card with Serif title and no redundant "Explore Place" button
  Widget _buildDestinationGridCard(
    BuildContext context,
    PopularDestinationModel dest,
    bool isSaved,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTokens.radiusCards),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDestinationDetail(context, dest),
        borderRadius: BorderRadius.circular(AppTokens.radiusCards),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radiusCards),
            border: Border.all(color: AppTokens.border),
            boxShadow: AppTokens.softCardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Top Image Container with Badges
            Expanded(
              flex: 11,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTokens.radiusCards)),
                    child: _buildSafeImage(dest.imageUrl, fit: BoxFit.cover),
                  ),
                  // Top Scrim
                  Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusCards)),
                      gradient: LinearGradient(
                        colors: [Colors.black38, Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                      ),
                    ),
                  ),
                  // Rating Badge (Bottom Left, Marigold with Ink text)
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTokens.marigold,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 13, color: AppTokens.ink),
                          const SizedBox(width: 3),
                          Text(
                            dest.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: AppTokens.ink, // Contrast ink on marigold
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Heart Favorite Button (Top Right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _toggleSave(dest.id),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Icon(
                          isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 16,
                          color: isSaved ? AppTokens.terracotta : AppTokens.secondaryText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Card Bottom Details
            Expanded(
              flex: 8,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppTokens.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${dest.district} • ${dest.approxDistanceKm.round()} km',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppTokens.secondaryText,
                          ),
                        ),
                      ],
                    ),

                    // Distance & Fare Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Round Trip from',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTokens.hint,
                              ),
                            ),
                            Text(
                              '₹${dest.startingFare.round()}',
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                color: AppTokens.primary,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'View',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(Icons.arrow_forward_rounded, size: 11, color: Color(0xFF0F172A)),
                            ],
                          ),
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
    ),
  );
}

  /// Featured Snap Carousel Card
  Widget _buildFeaturedCard(BuildContext context, PopularDestinationModel dest) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTokens.radiusCards),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDestinationDetail(context, dest),
        borderRadius: BorderRadius.circular(AppTokens.radiusCards),
        child: Container(
          width: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radiusCards),
            boxShadow: AppTokens.softCardShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radiusCards),
            child: Stack(
              fit: StackFit.expand,
              children: [
              _buildSafeImage(dest.imageUrl, fit: BoxFit.cover),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Color.fromRGBO(16, 26, 20, 0.85)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTokens.darkSurface.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    dest.district,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                bottom: 14,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dest.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${dest.approxDistanceKm.round()} km from you',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTokens.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'From ₹${dest.startingFare.round()}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
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
    ),
  );
}

  /// Package Bundle Card
  Widget _buildPackageBundleCard({
    required String title,
    required String subtitle,
    required String fare,
    required String tag,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticService.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTokens.border),
            boxShadow: AppTokens.softCardShadow,
          ),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTokens.ink),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTokens.marigoldTint,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTokens.ink),
                  ),
                ),
              ],
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTokens.secondaryText),
            ),
            Text(
              fare,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTokens.primary),
            ),
          ],
        ),
      ),
    ),
  );
}
}
