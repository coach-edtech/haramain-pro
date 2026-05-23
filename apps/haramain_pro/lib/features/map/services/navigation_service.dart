import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Route information model
class RouteInfo {
  final List<LatLng> polyline;
  final double distanceKm;
  final Duration estimatedTime;
  final String? summary;

  const RouteInfo({
    required this.polyline,
    required this.distanceKm,
    required this.estimatedTime,
    this.summary,
  });

  /// Get formatted distance string
  String get formattedDistance {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  /// Get formatted time string
  String get formattedTime {
    if (estimatedTime.inHours > 0) {
      return '${estimatedTime.inHours} j ${estimatedTime.inMinutes % 60} m';
    }
    return '${estimatedTime.inMinutes} mnt';
  }
}

/// Service for calculating routes using OSRM
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  static NavigationService get instance => _instance;

  NavigationService._internal();

  static const String _osrmBaseUrl = 'https://router.project-osrm.org';

  /// Calculate route between two points
  /// Uses OSRM public API
  Future<RouteInfo?> calculateRoute({
    required LatLng from,
    required LatLng to,
    String profile = 'driving', // driving, foot, bicycle
  }) async {
    try {
      final uri = Uri.parse('$_osrmBaseUrl/route/v1/$profile/${from.longitude},${from.latitude};${to.longitude},${to.latitude}').replace(
        queryParameters: {
          'overview': 'full',
          'geometries': 'polyline',
          'steps': 'false',
          'annotations': 'false',
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'HaramainPro/1.0',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        if (data['code'] == 'Ok' && data['routes'] != null) {
          final routes = data['routes'] as List;
          if (routes.isNotEmpty) {
            final route = routes.first as Map<String, dynamic>;
            return _parseRoute(route);
          }
        }
      }
      debugPrint('OSRM route calculation failed: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Error calculating route: $e');
      return null;
    }
  }

  /// Parse OSRM route response
  RouteInfo _parseRoute(Map<String, dynamic> route) {
    // Decode polyline
    final geometry = route['geometry'] as String;
    final polyline = _decodePolyline(geometry);

    // Get distance in meters and convert to km
    final distanceMeters = (route['distance'] as num).toDouble();
    final distanceKm = distanceMeters / 1000;

    // Get duration in seconds and convert to Duration
    final durationSeconds = (route['duration'] as num).toDouble();
    final estimatedTime = Duration(seconds: durationSeconds.round());

    // Get route summary if available
    final legs = route['legs'] as List?;
    String? summary;
    if (legs != null && legs.isNotEmpty) {
      summary = legs.first['summary'] as String?;
    }

    return RouteInfo(
      polyline: polyline,
      distanceKm: distanceKm,
      estimatedTime: estimatedTime,
      summary: summary,
    );
  }

  /// Decode polyline string to list of LatLng
  /// Uses OSRM's polyline encoding (precision 5)
  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> polyline = [];
    int index = 0;
    double lat = 0;
    double lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int byte;

      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);

      final dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);

      final dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      polyline.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return polyline;
  }

  /// Calculate walking route
  Future<RouteInfo?> calculateWalkingRoute({
    required LatLng from,
    required LatLng to,
  }) {
    return calculateRoute(from: from, to: to, profile: 'foot');
  }

  /// Calculate driving route
  Future<RouteInfo?> calculateDrivingRoute({
    required LatLng from,
    required LatLng to,
  }) {
    return calculateRoute(from: from, to: to, profile: 'driving');
  }

  /// Get bearing between two points
  double calculateBearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * 3.141592653589793 / 180;
    final lat2 = to.latitude * 3.141592653589793 / 180;
    final dLng = (to.longitude - from.longitude) * 3.141592653589793 / 180;

    final y = dLng > 0 
        ? _sin(dLng) * _cos(lat2)
        : -_sin(-dLng) * _cos(lat2);
    final x = _cos(lat1) * _sin(lat2) - 
        _sin(lat1) * _cos(lat2) * _cos(dLng);

    var bearing = _atan2(y, x) * 180 / 3.141592653589793;
    bearing = (bearing + 360) % 360;

    return bearing;
  }

  double _sin(double x) {
    return _taylorSin(x - 2 * 3.141592653589793 * ((x + 3.141592653589793) / (2 * 3.141592653589793)).floor());
  }

  double _cos(double x) {
    return _sin(x + 3.141592653589793 / 2);
  }

  double _atan2(double y, double x) {
    if (x > 0) {
      return _atan(y / x);
    } else if (x < 0 && y >= 0) {
      return _atan(y / x) + 3.141592653589793;
    } else if (x < 0 && y < 0) {
      return _atan(y / x) - 3.141592653589793;
    } else if (x == 0 && y > 0) {
      return 3.141592653589793 / 2;
    } else if (x == 0 && y < 0) {
      return -3.141592653589793 / 2;
    }
    return 0;
  }

  double _atan(double x) {
    // Taylor series approximation for atan
    if (x.abs() <= 1) {
      double result = 0;
      double term = x;
      for (int n = 0; n < 20; n++) {
        result += term / (2 * n + 1) * (n % 2 == 0 ? 1 : -1);
        term *= x * x;
      }
      return result;
    } else {
      return (3.141592653589793 / 2) - _atan(1 / x);
    }
  }

  double _taylorSin(double x) {
    // Normalize x to [-pi, pi]
    while (x > 3.141592653589793) {
      x -= 2 * 3.141592653589793;
    }
    while (x < -3.141592653589793) {
      x += 2 * 3.141592653589793;
    }
    
    double result = 0;
    double term = x;
    for (int n = 0; n < 10; n++) {
      result += term;
      term *= -x * x / ((2 * n + 2) * (2 * n + 3));
    }
    return result;
  }
}

/// Debug print helper
void debugPrint(String message) {
  // ignore: avoid_print
  print('[NavigationService] $message');
}
