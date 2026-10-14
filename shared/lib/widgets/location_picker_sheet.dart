import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/location_search_service.dart';
import '../services/jharkhand_district_data.dart';

/// Ultra-Premium Mobility Location Picker Sheet
/// Styled to match the Sal Forest (#1E7B4F) + Marigold (#F4A62A) + Laterite Earth theme.
/// Fully responsive: centered modal with max-width on desktop/web, zero horizontal stretching.
/// Automatic typing mode: autofocus, keyboard popup, quick clear, search-as-you-type,
/// 24 Jharkhand district filter pills, landmark chips, and instant GPS fallback.
class LocationPickerSheet extends StatefulWidget {
  final String title;
  final String initialValue;
  final bool isPickup;

  const LocationPickerSheet({
    super.key,
    required this.title,
    this.initialValue = '',
    this.isPickup = false,
  });

  static Future<LocationModel?> show(
    BuildContext context, {
    required String title,
    String initialValue = '',
    bool isPickup = false,
  }) {
    return showModalBottomSheet<LocationModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (ctx) => LocationPickerSheet(
        title: title,
        initialValue: initialValue,
        isPickup: isPickup,
      ),
    );
  }

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  final _searchService = LocationSearchService();
  final _textController = TextEditingController();
  final _searchFocusNode = FocusNode();

  List<LocationSearchResult> _results = LocationSearchService.popularHubs;
  bool _isLoading = false;
  bool _isGpsLoading = false;
  Timer? _debounceTimer;

  // Selected Jharkhand District Filter (null means all / search mode)
  String? _selectedDistrictFilter;

  // Mobility quick chips for small towns and rural districts
  final List<String> _quickChips = [
    '🏥 Sadar Hospital',
    '🚌 Main Bus Stand',
    '🚉 Railway Station',
    '🏛️ Kutchery / Court',
    '🛒 Bazar Chowk',
    '🌾 Block Office',
  ];

  @override
  void initState() {
    super.initState();
    _textController.text = widget.initialValue;

    // Trigger immediate typing mode as soon as the sheet opens:
    // Focuses text field, opens mobile keyboard / web caret, and highlights initial text for 1-tap overwrite.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
        if (_textController.text.isNotEmpty) {
          _textController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _textController.text.length,
          );
        }
      }
    });

    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchFocusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () async {
      if (!mounted) return;
      final clean = query.trim();

      // If user clears search and a district is active, show that district's villages
      if (clean.isEmpty) {
        if (_selectedDistrictFilter != null) {
          setState(() {
            _results = JharkhandDistrictData.getLocationsForDistrict(_selectedDistrictFilter!);
            _isLoading = false;
          });
          return;
        } else {
          setState(() {
            _results = LocationSearchService.popularHubs;
            _isLoading = false;
          });
          return;
        }
      }

      setState(() => _isLoading = true);

      // Search local Jharkhand dataset first (instant response for villages)
      final localMatches = JharkhandDistrictData.searchInJharkhand(clean);

      // Concurrently query Google Places API for exact place predictions
      final googleResults = await _searchService.searchPlaces(clean);

      if (mounted) {
        // Merge without duplicates
        final Set<String> seen = {};
        final List<LocationSearchResult> merged = [];

        for (var item in localMatches) {
          final key = '${item.title}_${item.subtitle}'.toLowerCase();
          if (seen.add(key)) merged.add(item);
        }
        for (var item in googleResults) {
          final key = '${item.title}_${item.subtitle}'.toLowerCase();
          if (seen.add(key)) merged.add(item);
        }

        setState(() {
          _results = merged.isNotEmpty ? merged : googleResults;
          _isLoading = false;
        });
      }
    });
  }

  void _applyQuickChip(String chip) {
    final clean = chip.replaceAll(RegExp(r'[^\w\s]'), '').trim();
    _textController.text = clean;
    setState(() {});
    _onSearchChanged(clean);
  }

  void _selectDistrict(String districtName) {
    setState(() {
      if (_selectedDistrictFilter == districtName) {
        _selectedDistrictFilter = null;
        _results = LocationSearchService.popularHubs;
      } else {
        _selectedDistrictFilter = districtName;
        _results = JharkhandDistrictData.getLocationsForDistrict(districtName);
      }
    });
  }

  void _useCurrentGps() async {
    setState(() => _isGpsLoading = true);
    final loc = await _searchService.getCurrentDeviceLocation();
    if (mounted) {
      setState(() => _isGpsLoading = false);
      if (loc != null) {
        Navigator.pop(context, loc.toLocationModel());
      }
    }
  }

  void _onSelectResult(LocationSearchResult item) async {
    setState(() => _isLoading = true);
    final resolved = await _searchService.resolvePlaceDetails(item);
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context, resolved.toLocationModel());
    }
  }

  void _confirmManualTypedAddress() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isLoading = true);

    // Call Google Forward Geocoding to get exact pinpoint coordinates
    final geocoded = await _searchService.geocodeAddress(text);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (geocoded != null) {
      Navigator.pop(context, geocoded.toLocationModel());
      return;
    }

    // Fallback if geocoding returns null
    double lat = 23.3441;
    double lon = 85.3096;
    if (_results.isNotEmpty && _results.first.latitude != 0.0) {
      lat = _results.first.latitude;
      lon = _results.first.longitude;
    }

    Navigator.pop(
      context,
      LocationModel(
        latitude: lat,
        longitude: lon,
        address: text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardBottom = mediaQuery.viewInsets.bottom;
    final districts = JharkhandDistrictData.allDistricts;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Container(
          height: (mediaQuery.size.height * 0.90).clamp(520.0, 840.0),
          margin: EdgeInsets.only(bottom: keyboardBottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(28, 27, 24, 0.16),
                blurRadius: 28,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // 2. Header Row (Balanced Icon Badge + Title + Close Button)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
                child: Row(
                  children: [
                    // Status Badge (Emerald Sal Forest for Pickup, Terracotta Red for Drop)
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: widget.isPickup
                            ? const Color(0xFFE8F4EC)
                            : const Color(0xFFFBECE8),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.isPickup
                              ? AppColors.primary.withValues(alpha: 0.25)
                              : AppColors.error.withValues(alpha: 0.25),
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          widget.isPickup
                              ? Icons.trip_origin_rounded
                              : Icons.location_on_rounded,
                          color: widget.isPickup
                              ? AppColors.primary
                              : AppColors.error,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title & Context Subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isPickup
                                ? 'PICKUP POINT (कहाँ से)'
                                : 'DESTINATION (कहाँ जाना है)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: widget.isPickup
                                  ? AppColors.primary
                                  : AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Frosted Close Button
                    Material(
                      color: const Color(0xFFF1F5F9),
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Ultra-Premium Integrated Search Bar (Centered, with balanced padding & glow)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _searchFocusNode.hasFocus
                          ? AppColors.primary
                          : const Color(0xFFE2E8F0),
                      width: _searchFocusNode.hasFocus ? 1.6 : 1.0,
                    ),
                    boxShadow: _searchFocusNode.hasFocus
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      // Search Icon with comfortable padding (never stuck to the left)
                      Padding(
                        padding: const EdgeInsets.only(left: 14, right: 10),
                        child: Icon(
                          Icons.search_rounded,
                          size: 22,
                          color: _searchFocusNode.hasFocus
                              ? AppColors.primary
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                      // Text Input Field with auto-focus typing mode
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          focusNode: _searchFocusNode,
                          autofocus: true,
                          onChanged: (val) {
                            setState(() {});
                            _onSearchChanged(val);
                          },
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _confirmManualTypedAddress(),
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            hintText: widget.isPickup
                                ? 'Search village, chowk, hospital...'
                                : 'Where to? (Search village or district...)',
                            hintStyle: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF94A3B8),
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      // Quick Clear (X) Button when typing
                      if (_textController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(
                            Icons.cancel_rounded,
                            size: 19,
                            color: Color(0xFF94A3B8),
                          ),
                          tooltip: 'Clear search',
                          onPressed: () {
                            _textController.clear();
                            setState(() {});
                            _onSearchChanged('');
                            _searchFocusNode.requestFocus();
                          },
                        ),
                      // "Set / Go" Button inside search bar
                      if (_textController.text.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Material(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: _confirmManualTypedAddress,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Text(
                                      'Set',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 13,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // 4. Current Device GPS Location Tile (Prominent & Sal Forest styled)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                child: Material(
                  color: const Color(0xFFF0FDF4), // Sal Forest soft green tint
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _isGpsLoading ? null : _useCurrentGps,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: _isGpsLoading
                                ? const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.my_location_rounded,
                                    color: Colors.white,
                                    size: 17,
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Use Current GPS Location (वर्तमान स्थान)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  'Accurate doorstep pickup via device GPS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 13,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // 5. 24 Jharkhand Districts Horizontal Filter
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.map_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _selectedDistrictFilter != null
                                  ? 'District: $_selectedDistrictFilter'
                                  : 'Select District (झारखंड 24 जिले):',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        if (_selectedDistrictFilter != null)
                          InkWell(
                            onTap: () {
                              setState(() {
                                _selectedDistrictFilter = null;
                                _results = LocationSearchService.popularHubs;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Clear Filter',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: districts.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final district = districts[idx];
                        final isSelected = _selectedDistrictFilter == district;
                        return Material(
                          color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _selectDistrict(district),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSelected) ...[
                                    const Icon(Icons.check_rounded, color: Colors.white, size: 13),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    district,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      color: isSelected ? Colors.white : AppColors.textPrimary,
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
                ],
              ),

              const SizedBox(height: 6),

              // 6. Quick Landmark Chips (Hospital, Bus stand, etc.)
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _quickChips.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, idx) {
                    final chip = _quickChips[idx];
                    return Material(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _applyQuickChip(chip),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            chip,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Divider(height: 1, color: Color(0xFFE2E8F0)),
              ),

              // 7. Results Section Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      _selectedDistrictFilter != null
                          ? Icons.holiday_village_rounded
                          : Icons.near_me_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _selectedDistrictFilter != null
                          ? '$_selectedDistrictFilter Villages & Blocks (${_results.length})'
                          : (_textController.text.trim().isEmpty
                              ? 'Popular District Hubs & Stands'
                              : 'Search Results (${_results.length} found)'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // 8. Results List or Loading State
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2.5,
                        ),
                      )
                    : _results.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF1F5F9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.location_off_rounded,
                                      color: AppColors.textMuted,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No local match found for "${_textController.text.trim()}"',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'You can still set this custom address directly:',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  ElevatedButton.icon(
                                    onPressed: _confirmManualTypedAddress,
                                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                                    label: Text('Set "${_textController.text.trim()}"'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      elevation: 0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                            itemCount: _results.length,
                            separatorBuilder: (_, __) => const Divider(
                              height: 1,
                              indent: 52,
                              color: Color(0xFFF1F5F9),
                            ),
                            itemBuilder: (context, index) {
                              final item = _results[index];
                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.location_on_outlined,
                                      color: AppColors.primary,
                                      size: 19,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  item.subtitle.isNotEmpty ? item.subtitle : 'Jharkhand',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: const Icon(
                                  Icons.north_west_rounded,
                                  size: 15,
                                  color: Color(0xFF94A3B8),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onTap: () => _onSelectResult(item),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
