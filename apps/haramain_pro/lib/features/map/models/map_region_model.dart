import 'package:latlong2/latlong.dart';

/// Region enum for offline map coverage areas
enum MapRegionType {
  makkah,
  madinah,
}

/// Map region model for offline tile downloads
class MapRegionModel {
  final MapRegionType region;
  final LatLngBounds bounds;
  final List<String> tileUrls;
  final DateTime? downloadedAt;
  final int sizeBytes;

  const MapRegionModel({
    required this.region,
    required this.bounds,
    required this.tileUrls,
    this.downloadedAt,
    this.sizeBytes = 0,
  });

  /// Region display name (Bahasa Indonesia)
  String get displayName {
    switch (region) {
      case MapRegionType.makkah:
        return 'Makkah';
      case MapRegionType.madinah:
        return 'Madinah';
    }
  }

  /// Region code for storage
  String get code {
    switch (region) {
      case MapRegionType.makkah:
        return 'makkah';
      case MapRegionType.madinah:
        return 'madinah';
    }
  }

  /// Estimated size in MB
  double get sizeMb => sizeBytes / (1024 * 1024);

  /// Check if region is downloaded
  bool get isDownloaded => downloadedAt != null;

  /// Create a copy with updated values
  MapRegionModel copyWith({
    MapRegionType? region,
    LatLngBounds? bounds,
    List<String>? tileUrls,
    DateTime? downloadedAt,
    int? sizeBytes,
  }) {
    return MapRegionModel(
      region: region ?? this.region,
      bounds: bounds ?? this.bounds,
      tileUrls: tileUrls ?? this.tileUrls,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      sizeBytes: sizeBytes ?? this.sizeBytes,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'region': region.index,
      'bounds': {
        'north': bounds.north,
        'south': bounds.south,
        'east': bounds.east,
        'west': bounds.west,
      },
      'tileUrls': tileUrls,
      'downloadedAt': downloadedAt?.toIso8601String(),
      'sizeBytes': sizeBytes,
    };
  }

  /// Create from JSON
  factory MapRegionModel.fromJson(Map<String, dynamic> json) {
    final boundsMap = json['bounds'] as Map<String, dynamic>;
    return MapRegionModel(
      region: MapRegionType.values[json['region'] as int],
      bounds: LatLngBounds(
        LatLng(boundsMap['north'] as double, boundsMap['east'] as double),
        LatLng(boundsMap['south'] as double, boundsMap['west'] as double),
      ),
      tileUrls: List<String>.from(json['tileUrls'] as List),
      downloadedAt: json['downloadedAt'] != null
          ? DateTime.parse(json['downloadedAt'] as String)
          : null,
      sizeBytes: json['sizeBytes'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    return 'MapRegionModel(region: $displayName, downloaded: $isDownloaded, size: ${sizeMb.toStringAsFixed(2)} MB)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MapRegionModel && other.region == region;
  }

  @override
  int get hashCode => region.hashCode;
}

/// LatLngBounds helper class
class LatLngBounds {
  final LatLng northEast;
  final LatLng southWest;

  const LatLngBounds(this.northEast, this.southWest);

  double get north => northEast.latitude;
  double get south => southWest.latitude;
  double get east => northEast.longitude;
  double get west => southWest.longitude;

  /// Check if a point is within bounds
  bool contains(LatLng point) {
    return point.latitude >= south &&
        point.latitude <= north &&
        point.longitude >= west &&
        point.longitude <= east;
  }
}

/// Pre-defined regions
class MapRegions {
  /// Makkah region bounds (covers Grand Mosque area and surrounding)
  static final MapRegionModel makkah = MapRegionModel(
    region: MapRegionType.makkah,
    bounds: LatLngBounds(
      const LatLng(21.4500, 39.8500), // North East
      const LatLng(21.3500, 39.6500), // South West
    ),
    tileUrls: [
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    ],
  );

  /// Madinah region bounds (covers Prophet's Mosque area and surrounding)
  static final MapRegionModel madinah = MapRegionModel(
    region: MapRegionType.madinah,
    bounds: LatLngBounds(
      const LatLng(24.5500, 39.7200), // North East
      const LatLng(24.4000, 39.5500), // South West
    ),
    tileUrls: [
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    ],
  );

  /// Get all available regions
  static List<MapRegionModel> get all => [makkah, madinah];

  /// Get region by type
  static MapRegionModel getRegion(MapRegionType type) {
    switch (type) {
      case MapRegionType.makkah:
        return makkah;
      case MapRegionType.madinah:
        return madinah;
    }
  }
}
