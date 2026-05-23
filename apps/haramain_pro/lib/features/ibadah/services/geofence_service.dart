import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../../services/location_service.dart';

/// Mosque location data
class MosqueLocation {
  final String id;
  final String name;
  final String nameArabic;
  final double latitude;
  final double longitude;
  final double radiusInMeters;
  final MosqueType type;

  const MosqueLocation({
    required this.id,
    required this.name,
    required this.nameArabic,
    required this.latitude,
    required this.longitude,
    required this.radiusInMeters,
    required this.type,
  });
}

enum MosqueType { harammakkah, nabawi }

/// Geofence event types
enum GeofenceEvent { enter, exit }

/// Geofence event data
class GeofenceEventData {
  final MosqueLocation mosque;
  final GeofenceEvent event;
  final DateTime timestamp;

  const GeofenceEventData({
    required this.mosque,
    required this.event,
    required this.timestamp,
  });
}

/// Geofence service for monitoring mosque areas
class GeofenceService {
  static final GeofenceService _instance = GeofenceService._internal();
  static GeofenceService get instance => _instance;

  GeofenceService._internal();

  final LocationService _locationService = LocationService.instance;

  // Stream controller for geofence events
  final StreamController<GeofenceEventData> _eventController =
      StreamController<GeofenceEventData>.broadcast();

  // Current location stream subscription
  StreamSubscription<Position>? _locationSubscription;

  // Track current state
  final Map<String, bool> _insideMosque = {};

  // Predefined mosque geofences
  static final List<MosqueLocation> mosques = [
    const MosqueLocation(
      id: 'haram_makkah',
      name: 'Masjidil Haram',
      nameArabic: 'المسجد الحرام',
      latitude: 21.4225,
      longitude: 39.8262,
      radiusInMeters: 1000, // 1km radius for entry detection
      type: MosqueType.harammakkah,
    ),
    const MosqueLocation(
      id: 'nabawi_madinah',
      name: 'Masjid Nabawi',
      nameArabic: 'المسجد النبوي',
      latitude: 24.4672,
      longitude: 39.6072,
      radiusInMeters: 1000, // 1km radius for entry detection
      type: MosqueType.nabawi,
    ),
  ];

  /// Stream of geofence events (enter/exit)
  Stream<GeofenceEventData> get onGeofenceEvent => _eventController.stream;

  /// Check if user is currently inside any monitored mosque
  bool get isInsideMosque => _insideMosque.values.any((inside) => inside);

  /// Get which mosque user is currently inside (if any)
  MosqueLocation? get currentMosque {
    for (final entry in _insideMosque.entries) {
      if (entry.value) {
        return mosques.firstWhere(
          (m) => m.id == entry.key,
          orElse: () => mosques.first,
        );
      }
    }
    return null;
  }

  /// Start monitoring geofences
  Future<void> startMonitoring() async {
    // Check location permission
    final hasPermission = await _checkLocationPermission();
    if (!hasPermission) {
      debugPrint('Location permission not granted for geofencing');
      return;
    }

    // Initialize all mosques as "outside"
    for (final mosque in mosques) {
      _insideMosque[mosque.id] = false;
    }

    // Start listening to location updates
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen(_onLocationUpdate);
  }

  /// Stop monitoring geofences
  void stopMonitoring() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  /// Handle location updates and check geofences
  void _onLocationUpdate(Position position) {
    for (final mosque in mosques) {
      final wasInside = _insideMosque[mosque.id] ?? false;
      final isInside = _locationService.isWithinRadius(
        position.latitude,
        position.longitude,
        mosque.latitude,
        mosque.longitude,
        mosque.radiusInMeters,
      );

      if (isInside != wasInside) {
        _insideMosque[mosque.id] = isInside;

        final event = GeofenceEventData(
          mosque: mosque,
          event: isInside ? GeofenceEvent.enter : GeofenceEvent.exit,
          timestamp: DateTime.now(),
        );

        debugPrint(
          'Geofence ${event.event == GeofenceEvent.enter ? "ENTER" : "EXIT"}: ${mosque.name}',
        );

        _eventController.add(event);
      }
    }
  }

  /// Manually check current location and trigger events if needed
  Future<void> checkCurrentLocation() async {
    final location = await _locationService.getCurrentLocation();
    if (location == null) return;

    for (final mosque in mosques) {
      final isInside = _locationService.isWithinRadius(
        location.latitude,
        location.longitude,
        mosque.latitude,
        mosque.longitude,
        mosque.radiusInMeters,
      );

      final wasInside = _insideMosque[mosque.id] ?? false;

      if (isInside != wasInside) {
        _insideMosque[mosque.id] = isInside;

        final event = GeofenceEventData(
          mosque: mosque,
          event: isInside ? GeofenceEvent.enter : GeofenceEvent.exit,
          timestamp: DateTime.now(),
        );

        debugPrint(
          'Manual check ${event.event == GeofenceEvent.enter ? "ENTER" : "EXIT"}: ${mosque.name}',
        );

        _eventController.add(event);
      }
    }
  }

  /// Check if a specific location is inside a specific mosque
  bool isInsideMosqueById(String mosqueId, double lat, double lng) {
    final mosque = mosques.firstWhere(
      (m) => m.id == mosqueId,
      orElse: () => mosques.first,
    );

    return _locationService.isWithinRadius(
      lat,
      lng,
      mosque.latitude,
      mosque.longitude,
      mosque.radiusInMeters,
    );
  }

  /// Get distance to a specific mosque
  double distanceToMosque(String mosqueId, double lat, double lng) {
    final mosque = mosques.firstWhere(
      (m) => m.id == mosqueId,
      orElse: () => mosques.first,
    );

    return _locationService.calculateDistance(
      lat,
      lng,
      mosque.latitude,
      mosque.longitude,
    );
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    _eventController.close();
  }

  /// Check location permission (similar to LocationService but public)
  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled');
      return false;
    }

    var status = await Geolocator.checkPermission();
    if (status == LocationPermission.denied) {
      status = await Geolocator.requestPermission();
    }

    if (status == LocationPermission.deniedForever) {
      debugPrint('Location permission permanently denied');
      return false;
    }

    return status == LocationPermission.always ||
        status == LocationPermission.whileInUse;
  }
}

// Debug print helper
void debugPrint(String message) {
  // ignore: avoid_print
  print('[GeofenceService] $message');
}
