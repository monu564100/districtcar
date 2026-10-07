import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/models.dart';

class LocationSearchResult {
  final String title;
  final String subtitle;
  final double latitude;
  final double longitude;
  final String? placeId;

  const LocationSearchResult({
    required this.title,
    required this.subtitle,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.placeId,
  });

  LocationModel toLocationModel() {
    return LocationModel(
      latitude: latitude,
      longitude: longitude,
      address: subtitle.isEmpty ? title : '$title, $subtitle',
    );
  }

  LocationSearchResult copyWith({
    String? title,
    String? subtitle,
    double? latitude,
    double? longitude,
    String? placeId,
  }) {
    return LocationSearchResult(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      placeId: placeId ?? this.placeId,
    );
  }
}

class LocationSearchService {
  // Official Google Maps API Key provided by user
  static const String googleApiKey = 'AIzaSyC4J6x9hq3DeuivIndeTfnwr_A3aJlT-ec';

  // Popular Jharkhand district & rural mobility hubs
  static const List<LocationSearchResult> popularHubs = [
    LocationSearchResult(
      title: 'Albert Ekka Chowk (Main Road)',
      subtitle: 'Ranchi, Jharkhand',
      latitude: 23.3700,
      longitude: 85.3250,
    ),
    LocationSearchResult(
      title: 'Ranchi Railway Station (RNC)',
      subtitle: 'Gosaintola, Chutia, Ranchi, Jharkhand',
      latitude: 23.3512,
      longitude: 85.3406,
    ),
    LocationSearchResult(
      title: 'Khadgarha Inter-State Bus Stand',
      subtitle: 'Kantatoli, Ranchi, Jharkhand',
      latitude: 23.3689,
      longitude: 85.3528,
    ),
    LocationSearchResult(
      title: 'Birsa Munda Airport',
      subtitle: 'Hinoo, Ranchi, Jharkhand',
      latitude: 23.3143,
      longitude: 85.3217,
    ),
    LocationSearchResult(
      title: 'RIMS Hospital & Medical College',
      subtitle: 'Bariatu, Ranchi, Jharkhand',
      latitude: 23.3853,
      longitude: 85.3582,
    ),
    LocationSearchResult(
      title: 'Tatanagar Junction Railway Station',
      subtitle: 'Jamshedpur, East Singhbhum, Jharkhand',
      latitude: 22.7667,
      longitude: 86.2008,
    ),
    LocationSearchResult(
      title: 'Sakchi Bus Stand & Market',
      subtitle: 'Jamshedpur, Jharkhand',
      latitude: 22.8056,
      longitude: 86.2030,
    ),
    LocationSearchResult(
      title: 'Dhanbad Railway Station & City Centre',
      subtitle: 'Dhanbad, Jharkhand',
      latitude: 23.7957,
      longitude: 86.4304,
    ),
    LocationSearchResult(
      title: 'Bokaro Steel City Sector 4 / Naya More',
      subtitle: 'Bokaro, Jharkhand',
      latitude: 23.6693,
      longitude: 86.1511,
    ),
    LocationSearchResult(
      title: 'Hazaribagh Old Bus Stand',
      subtitle: 'Hazaribagh, Jharkhand',
      latitude: 23.9960,
      longitude: 85.3622,
    ),
    LocationSearchResult(
      title: 'Baba Baidyanath Mandir / Tower Chowk',
      subtitle: 'Deoghar, Jharkhand',
      latitude: 24.4925,
      longitude: 86.7000,
    ),
    LocationSearchResult(
      title: 'Giridih Bus Stand',
      subtitle: 'Giridih, Jharkhand',
      latitude: 24.1860,
      longitude: 86.3070,
    ),
    LocationSearchResult(
      title: 'Ramgarh Cantt Chowk',
      subtitle: 'Ramgarh, Jharkhand',
      latitude: 23.6288,
      longitude: 85.5173,
    ),
    LocationSearchResult(
      title: 'Khunti District Bus Stand',
      subtitle: 'Khunti Village District, Jharkhand',
      latitude: 23.0740,
      longitude: 85.2780,
    ),
    LocationSearchResult(
      title: 'Gumla District Chowk',
      subtitle: 'Gumla, Jharkhand',
      latitude: 23.0435,
      longitude: 84.5414,
    ),
    LocationSearchResult(
      title: 'Simdega Town Bus Stand',
      subtitle: 'Simdega, Jharkhand',
      latitude: 22.6167,
      longitude: 84.5167,
    ),
    LocationSearchResult(
      title: 'Dumka Bus Terminal',
      subtitle: 'Santhal Pargana, Dumka, Jharkhand',
      latitude: 24.2678,
      longitude: 87.2486,
    ),
    LocationSearchResult(
      title: 'Chaibasa Bus Stand',
      subtitle: 'West Singhbhum, Jharkhand',
      latitude: 22.5510,
      longitude: 85.8118,
    ),
    LocationSearchResult(
      title: 'Medininagar / Daltonganj Bus Stand',
      subtitle: 'Palamu, Jharkhand',
      latitude: 24.0384,
      longitude: 84.0722,
    ),
  ];

  /// High-accuracy Google Places Autocomplete API with local bias
  Future<List<LocationSearchResult>> searchPlaces(
    String query, {
    double? biasLat,
    double? biasLng,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return popularHubs;
    }

    try {
      String url =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(cleanQuery)}&components=country:in&key=$googleApiKey';

      // Apply local radial biasing (Ola/Uber best practice)
      if (biasLat != null && biasLng != null) {
        url += '&location=$biasLat,$biasLng&radius=50000';
      } else {
        // Bias around Jharkhand state center (Ranchi 23.3441, 85.3096)
        url += '&location=23.3441,85.3096&radius=120000';
      }

      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status'] as String? ?? '';
        final predictions = data['predictions'] as List? ?? [];

        if (status == 'OK' && predictions.isNotEmpty) {
          return predictions.map((item) {
            final structured = item['structured_formatting'] as Map<String, dynamic>?;
            final mainText = structured?['main_text'] as String? ?? item['description'] ?? '';
            final secondaryText = structured?['secondary_text'] as String? ?? '';
            final placeId = item['place_id'] as String?;

            return LocationSearchResult(
              title: mainText,
              subtitle: secondaryText,
              placeId: placeId,
            );
          }).toList();
        }
      }
    } catch (_) {}

    // Fallback filter over popular hubs
    final matched = popularHubs.where((hub) =>
        hub.title.toLowerCase().contains(cleanQuery.toLowerCase()) ||
        hub.subtitle.toLowerCase().contains(cleanQuery.toLowerCase())).toList();

    return matched.isNotEmpty ? matched : popularHubs;
  }

  /// Resolve exact coordinates for a selected Google Place prediction
  Future<LocationSearchResult> resolvePlaceDetails(LocationSearchResult result) async {
    if (result.placeId == null || (result.latitude != 0.0 && result.longitude != 0.0)) {
      return result;
    }

    try {
      final url =
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=${result.placeId}&fields=geometry,formatted_address,name&key=$googleApiKey';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['result'] != null) {
          final res = data['result'];
          final location = res['geometry']?['location'];
          final lat = (location?['lat'] as num?)?.toDouble() ?? 0.0;
          final lng = (location?['lng'] as num?)?.toDouble() ?? 0.0;
          final formatted = res['formatted_address'] as String? ?? '';
          final name = res['name'] as String? ?? result.title;

          return LocationSearchResult(
            title: name.isNotEmpty ? name : result.title,
            subtitle: formatted.isNotEmpty ? formatted : result.subtitle,
            latitude: lat,
            longitude: lng,
            placeId: result.placeId,
          );
        }
      }
    } catch (_) {}

    return result;
  }

  /// Forward Geocode a typed manual address using Google Geocoding API
  Future<LocationSearchResult?> geocodeAddress(String query, {double? biasLat, double? biasLng}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return null;

    try {
      final url =
          'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(cleanQuery)}&components=country:in&key=$googleApiKey';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
          final first = data['results'][0];
          final loc = first['geometry']?['location'];
          final lat = (loc?['lat'] as num?)?.toDouble() ?? 23.3441;
          final lng = (loc?['lng'] as num?)?.toDouble() ?? 85.3096;
          final formatted = first['formatted_address'] as String? ?? cleanQuery;

          // Extract human-friendly short name
          final parts = formatted.split(',');
          final title = parts.isNotEmpty ? parts.first.trim() : cleanQuery;
          final subtitle = parts.length > 1 ? parts.sublist(1).join(',').trim() : '';

          return LocationSearchResult(
            title: title,
            subtitle: subtitle.isNotEmpty ? subtitle : formatted,
            latitude: lat,
            longitude: lng,
            placeId: first['place_id'],
          );
        }
      }
    } catch (_) {}

    return null;
  }

  /// Exact GPS auto-detection with Google Reverse Geocoding API
  Future<LocationSearchResult?> getCurrentDeviceLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return popularHubs.first;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return popularHubs.first;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return popularHubs.first;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      // Google Reverse Geocoding for accurate landmark, mohalla, chowk, village
      try {
        final url =
            'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$googleApiKey';
        final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 6));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
            final results = data['results'] as List;
            // Best result (usually the first pinpoint or street level)
            final best = results.first;
            final formatted = best['formatted_address'] as String? ?? '';

            // Extract best readable components
            String title = '';
            String subtitle = '';

            final components = best['address_components'] as List? ?? [];
            for (var c in components) {
              final types = (c['types'] as List?)?.cast<String>() ?? [];
              if (types.contains('sublocality_level_1') ||
                  types.contains('neighborhood') ||
                  types.contains('point_of_interest') ||
                  types.contains('premise')) {
                title = c['long_name'] ?? '';
                break;
              }
            }

            if (title.isEmpty && formatted.isNotEmpty) {
              final parts = formatted.split(',');
              title = parts.first.trim();
              subtitle = parts.length > 1 ? parts.sublist(1, parts.length.clamp(1, 4)).join(',').trim() : '';
            } else if (formatted.isNotEmpty) {
              subtitle = formatted;
            }

            return LocationSearchResult(
              title: title.isNotEmpty ? title : 'Current Location',
              subtitle: subtitle.isNotEmpty ? subtitle : 'Near ${position.latitude.toStringAsFixed(3)}, ${position.longitude.toStringAsFixed(3)}',
              latitude: position.latitude,
              longitude: position.longitude,
            );
          }
        }
      } catch (_) {}

      return LocationSearchResult(
        title: 'Current Location',
        subtitle: 'GPS (${position.latitude.toStringAsFixed(3)}, ${position.longitude.toStringAsFixed(3)})',
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      return popularHubs.first;
    }
  }
}
