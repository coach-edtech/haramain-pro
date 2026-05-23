/// Offline tile model representing a downloaded map tile
class OfflineTileModel {
  final int x;
  final int y;
  final int z;
  final String region;
  final String path;
  final bool downloaded;
  final DateTime? downloadedAt;

  const OfflineTileModel({
    required this.x,
    required this.y,
    required this.z,
    required this.region,
    required this.path,
    this.downloaded = false,
    this.downloadedAt,
  });

  /// Unique tile key for storage
  String get tileKey => '$region/$z/$x/$y';

  /// Create a copy with updated values
  OfflineTileModel copyWith({
    int? x,
    int? y,
    int? z,
    String? region,
    String? path,
    bool? downloaded,
    DateTime? downloadedAt,
  }) {
    return OfflineTileModel(
      x: x ?? this.x,
      y: y ?? this.y,
      z: z ?? this.z,
      region: region ?? this.region,
      path: path ?? this.path,
      downloaded: downloaded ?? this.downloaded,
      downloadedAt: downloadedAt ?? this.downloadedAt,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'z': z,
      'region': region,
      'path': path,
      'downloaded': downloaded,
      'downloadedAt': downloadedAt?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory OfflineTileModel.fromJson(Map<String, dynamic> json) {
    return OfflineTileModel(
      x: json['x'] as int,
      y: json['y'] as int,
      z: json['z'] as int,
      region: json['region'] as String,
      path: json['path'] as String,
      downloaded: json['downloaded'] as bool? ?? false,
      downloadedAt: json['downloadedAt'] != null
          ? DateTime.parse(json['downloadedAt'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'OfflineTileModel(x: $x, y: $y, z: $z, region: $region, path: $path)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OfflineTileModel &&
        other.x == x &&
        other.y == y &&
        other.z == z &&
        other.region == region;
  }

  @override
  int get hashCode => Object.hash(x, y, z, region);
}
