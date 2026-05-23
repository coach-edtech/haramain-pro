import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';

/// Place search result model
class PlaceSearchResult {
  final String name;
  final String displayName;
  final double latitude;
  final double longitude;
  final String type;
  final String? importance;
  final String? country;
  final String? city;

  const PlaceSearchResult({
    required this.name,
    required this.displayName,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.importance,
    this.country,
    this.city,
  });

  LatLng get latLng => LatLng(latitude, longitude);

  factory PlaceSearchResult.fromNominatim(Map<String, dynamic> json) {
    return PlaceSearchResult(
      name: json['display_name'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      latitude: double.parse(json['lat'].toString()),
      longitude: double.parse(json['lon'].toString()),
      type: json['type'] as String? ?? 'place',
      importance: json['importance']?.toString(),
      country: json['address']?['country'] as String?,
      city: json['address']?['city'] as String? ?? json['address']?['town'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'displayName': displayName,
      'latitude': latitude,
      'longitude': longitude,
      'type': type,
      'importance': importance,
      'country': country,
      'city': city,
    };
  }

  @override
  String toString() {
    return 'PlaceSearchResult(name: $name, lat: $latitude, lng: $longitude, type: $type)';
  }
}

/// Service for searching places using Nominatim geocoding
/// Supports Bahasa Indonesia queries
class MapSearchService {
  static final MapSearchService _instance = MapSearchService._internal();
  static MapSearchService get instance => _instance;

  MapSearchService._internal();

  static const String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  static const String _recentSearchesKey = 'recent_place_searches';
  static const int _maxRecentSearches = 10;

  SharedPreferences? _prefs;

  /// Initialize the service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Search for places using Nominatim
  /// Returns list of matching places
  Future<List<PlaceSearchResult>> searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      // Use Bahasa Indonesia locale for better results with Indonesian queries
      final uri = Uri.parse('$_nominatimBaseUrl/search').replace(
        queryParameters: {
          'q': query,
          'format': 'json',
          'addressdetails': '1',
          'limit': '10',
          'accept-language': 'id', // Bahasa Indonesia
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'HaramainPro/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        final results = data
            .map((item) => PlaceSearchResult.fromNominatim(item as Map<String, dynamic>))
            .toList();

        // Save to recent searches
        if (results.isNotEmpty) {
          await _saveToRecentSearches(results.first);
        }

        return results;
      } else {
        debugPrint('Nominatim search failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error searching places: $e');
      return [];
    }
  }

  /// Search for places near a location (reverse geocoding)
  Future<List<PlaceSearchResult>> searchNearLocation(
    double lat,
    double lng, {
    double radiusDegrees = 0.1,
  }) async {
    try {
      final uri = Uri.parse('$_nominatimBaseUrl/search').replace(
        queryParameters: {
          'q': 'point:$lat,$lng',
          'format': 'json',
          'addressdetails': '1',
          'limit': '5',
          'accept-language': 'id',
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'HaramainPro/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((item) => PlaceSearchResult.fromNominatim(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error in reverse geocoding: $e');
      return [];
    }
  }

  /// Get recent searches
  Future<List<PlaceSearchResult>> getRecentSearches() async {
    final searches = _prefs?.getStringList(_recentSearchesKey) ?? [];
    return searches.map((s) {
      final json = jsonDecode(s) as Map<String, dynamic>;
      return PlaceSearchResult.fromNominatim(json);
    }).toList();
  }

  /// Save search result to recent searches
  Future<void> _saveToRecentSearches(PlaceSearchResult result) async {
    final searches = _prefs?.getStringList(_recentSearchesKey) ?? [];
    
    // Remove if already exists
    searches.removeWhere((s) {
      final json = jsonDecode(s) as Map<String, dynamic>;
      return json['display_name'] == result.displayName;
    });

    // Add to beginning
    searches.insert(0, jsonEncode(result.toJson()));

    // Keep only recent searches
    if (searches.length > _maxRecentSearches) {
      searches.removeRange(_maxRecentSearches, searches.length);
    }

    await _prefs?.setStringList(_recentSearchesKey, searches);
  }

  /// Clear recent searches
  Future<void> clearRecentSearches() async {
    await _prefs?.remove(_recentSearchesKey);
  }

  /// Search for holy places in Makkah and Madinah
  Future<List<PlaceSearchResult>> searchHolySites(String query) async {
    // Prepend location context for better results
    final holySiteQuery = '$query Makkah Madinah Saudi Arabia';
    return searchPlaces(holySiteQuery);
  }

  /// Common holy sites in Bahasa Indonesia
  static const List<Map<String, dynamic>> commonHolySites = [
    {
      'name': 'Masjidil Haram',
      'displayName': 'Masjidil Haram, Makkah',
      'lat': 21.4225,
      'lng': 39.8262,
      'type': 'religious',
    },
    {
      'name': 'Masjid Nabawi',
      'displayName': 'Masjid Nabawi, Madinah',
      'lat': 24.4672,
      'lng': 39.6078,
      'type': 'religious',
    },
    {
      'name': 'Mina (Arafat)',
      'displayName': 'Arafat, Mina, Makkah',
      'lat': 21.3547,
      'lng': 39.9722,
      'type': 'religious',
    },
    {
      'name': 'Muzdalifah',
      'displayName': 'Muzdalifah, Makkah',
      'lat': 21.3833,
      'lng': 39.9500,
      'type': 'religious',
    },
    {
      'name': 'Jamarat',
      'displayName': 'Jamarat, Mina, Makkah',
      'lat': 21.3667,
      'lng': 39.9833,
      'type': 'religious',
    },
    {
      'name': 'Gua Hira',
      'displayName': 'Gua Hira, Makkah',
      'lat': 21.4475,
      'lng': 39.8578,
      'type': 'religious',
    },
    {
      'name': 'Gunung Nur',
      'displayName': 'Gunung Nur, Makkah',
      'lat': 21.4500,
      'lng': 39.8550,
      'type': 'religious',
    },
  ];
}

/// Debug print helper
void debugPrint(String message) {
  // ignore: avoid_print
  print('[MapSearchService] $message');
}
