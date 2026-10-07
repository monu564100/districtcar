import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/location_search_service.dart';

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
  List<LocationSearchResult> _results = LocationSearchService.popularHubs;
  bool _isLoading = false;
  bool _isGpsLoading = false;
  Timer? _debounceTimer;

  // Ola/Uber mobility quick chips for small towns and rural districts
  final List<String> _quickChips = [
    '🚉 Railway Station',
    '🚌 Bus Stand',
    '🏥 Sadar Hospital',
    '🏛️ Kutchery / Court',
    '🛒 Main Chowk / Bazar',
    '✈️ Airport',
  ];

  @override
  void initState() {
    super.initState();
    _textController.text = widget.initialValue;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      setState(() => _isLoading = true);
      final results = await _searchService.searchPlaces(query);
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    });
  }

  void _applyQuickChip(String chip) {
    // Strip emoji and search
    final clean = chip.replaceAll(RegExp(r'[^\w\s]'), '').trim();
    _textController.text = clean;
    _onSearchChanged(clean);
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
    // If place details needed, resolve exact coordinates via Google Place Details
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
    final keyboardBottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      margin: EdgeInsets.only(bottom: keyboardBottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 6),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.isPickup ? Icons.trip_origin : Icons.location_on,
                      color: widget.isPickup ? const Color(0xFF10B981) : AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search input field + Set button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    autofocus: true,
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _confirmManualTypedAddress(),
                    decoration: InputDecoration(
                      hintText: widget.isPickup
                          ? 'Search pickup chowk, village or landmark...'
                          : 'Search drop village, station or district...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                      suffixIcon: _textController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _textController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.surfaceSecondary,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: _confirmManualTypedAddress,
                  child: const Text('Set', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // Ola/Uber Quick Suggestion Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: _quickChips.map((chip) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(chip, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    backgroundColor: const Color(0xFFF1F5F9),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onPressed: () => _applyQuickChip(chip),
                  ),
                );
              }).toList(),
            ),
          ),

          // Current GPS Location Tile (Always 1-Tap Ready)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _isGpsLoading ? null : _useCurrentGps,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: _isGpsLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Use Current GPS Location',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                          ),
                          Text(
                            'Exact pinpoint via Google Maps Geocoding',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 13, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ),

          const Divider(height: 16),

          // Section Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Icon(
                  _textController.text.trim().isEmpty ? Icons.star_border : Icons.search,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  _textController.text.trim().isEmpty
                      ? 'Jharkhand District & Rural Hubs'
                      : 'Google Places Predictions',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          // Results List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
                    itemBuilder: (context, index) {
                      final item = _results[index];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                        ),
                        title: Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                        ),
                        subtitle: Text(
                          item.subtitle.isNotEmpty ? item.subtitle : 'Jharkhand',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.north_west, size: 14, color: AppColors.textMuted),
                        onTap: () => _onSelectResult(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
