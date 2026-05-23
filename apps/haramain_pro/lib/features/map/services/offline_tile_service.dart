import 'dart:io';
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/map_region_model.dart';

/// Service for managing offline map tile downloads
/// Uses flutter_map_tile_caching pattern for tile management
class OfflineTileService {
  static final OfflineTileService _instance = OfflineTileService._internal();
  static OfflineTileService get instance => _instance;

  OfflineTileService._internal();

  static const String _tileStoreDir = 'offline_tiles';
  static const String _regionMetadataKey = 'offline_region_metadata';
  static const String _downloadedRegionsKey = 'downloaded_regions';

  /// SharedPreferences instance
  SharedPreferences? _prefs;

  /// Tile download directory
  Directory? _tileDirectory;

  /// Initialize the service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    final appDir = await getApplicationDocumentsDirectory();
    _tileDirectory = Directory('${appDir.path}/$_tileStoreDir');
    if (!await _tileDirectory!.exists()) {
      await _tileDirectory!.create(recursive: true);
    }
  }

  /// Get tile directory path
  String get tileDirectoryPath => _tileDirectory?.path ?? '';

  /// Calculate all tile coordinates for a region at zoom levels 10-17
  /// Returns list of tile coordinates (x, y, z)
  List<TileCoordinate> _calculateTilesForRegion(MapRegionModel region) {
    final tiles = <TileCoordinate>[];
    const minZoom = 10;
    const maxZoom = 17;

    for (int z = minZoom; z <= maxZoom; z++) {
      final minTile = _latLngToTile(region.bounds.southWest, z);
      final maxTile = _latLngToTile(region.bounds.northEast, z);

      for (int x = minTile.x; x <= maxTile.x; x++) {
        for (int y = minTile.y; y <= maxTile.y; y++) {
          tiles.add(TileCoordinate(x: x, y: y, z: z));
        }
      }
    }

    return tiles;
  }

  /// Convert LatLng to tile coordinates at given zoom level
  TileCoordinate _latLngToTile(LatLng point, int zoom) {
    final lat = point.latitude;
    final lng = point.longitude;

    final x = ((lng + 180.0) / 360.0 * (1 << zoom)).floor();
    final y = ((1.0 -
                (math.log(math.tan(lat / 90.0 * math.pi))) /
                    math.pi) /
            2.0 *
            (1 << zoom))
        .floor();

    return TileCoordinate(x: x, y: y, z: zoom);
  }

  /// Calculate estimated region size in bytes
  /// Based on average tile size (~15KB) and tile count
  Future<int> calculateRegionSize(MapRegionModel region) async {
    final tiles = _calculateTilesForRegion(region);
    // Average tile size is approximately 15KB
    const avgTileSizeBytes = 15 * 1024;
    return tiles.length * avgTileSizeBytes;
  }

  /// Calculate region size in MB (for display)
  Future<double> calculateRegionSizeMb(MapRegionModel region) async {
    final bytes = await calculateRegionSize(region);
    return bytes / (1024 * 1024);
  }

  /// Check if region is already downloaded
  Future<bool> isRegionDownloaded(MapRegionModel region) async {
    final downloadedRegions = _getDownloadedRegions();
    return downloadedRegions.contains(region.code);
  }

  /// Get list of downloaded region codes
  Set<String> _getDownloadedRegions() {
    final regions = _prefs?.getStringList(_downloadedRegionsKey) ?? [];
    return regions.toSet();
  }

  /// Get downloaded regions list with metadata
  Future<List<MapRegionModel>> getDownloadedRegions() async {
    final regions = _getDownloadedRegions();
    final allRegions = MapRegions.all;
    
    return allRegions.where((r) => regions.contains(r.code)).map((r) {
      // Load saved metadata
      final metadata = _prefs?.getString('${_regionMetadataKey}_${r.code}');
      if (metadata != null) {
        // Parse and return with saved data
        return _updateRegionFromMetadata(r, metadata);
      }
      return r;
    }).toList();
  }

  /// Update region with saved metadata
  MapRegionModel _updateRegionFromMetadata(MapRegionModel region, String metadata) {
    try {
      final parts = metadata.split('|');
      if (parts.length >= 3) {
        return region.copyWith(
          downloadedAt: DateTime.tryParse(parts[0]),
          sizeBytes: int.tryParse(parts[1]) ?? 0,
        );
      }
    } catch (e) {
      debugPrint('Error parsing region metadata: $e');
    }
    return region;
  }

  /// Save region metadata
  Future<void> _saveRegionMetadata(MapRegionModel region) async {
    final metadata = '${region.downloadedAt?.toIso8601String() ?? ''}|${region.sizeBytes}|${region.code}';
    await _prefs?.setString('${_regionMetadataKey}_${region.code}', metadata);
  }

  /// Download all tiles for a region
  /// Returns stream of download progress (0.0 - 1.0)
  Stream<double> downloadRegion(MapRegionModel region) async* {
    final tiles = _calculateTilesForRegion(region);
    final totalTiles = tiles.length;
    var downloadedTiles = 0;

    debugPrint('Starting download for ${region.displayName}: $totalTiles tiles');

    for (final tile in tiles) {
      try {
        await _downloadTile(tile, region);
        downloadedTiles++;
        yield downloadedTiles / totalTiles;
      } catch (e) {
        debugPrint('Error downloading tile ${tile.x},${tile.y},${tile.z}: $e');
        // Continue with next tile even if one fails
        downloadedTiles++;
        yield downloadedTiles / totalTiles;
      }
    }

    // Mark region as downloaded
    final downloadedRegions = _getDownloadedRegions();
    downloadedRegions.add(region.code);
    await _prefs?.setStringList(_downloadedRegionsKey, downloadedRegions.toList());

    // Save metadata
    final sizeBytes = await calculateRegionSize(region);
    final updatedRegion = region.copyWith(
      downloadedAt: DateTime.now(),
      sizeBytes: sizeBytes,
    );
    await _saveRegionMetadata(updatedRegion);

    debugPrint('Download complete for ${region.displayName}');
  }

  /// Download a single tile
  Future<void> _downloadTile(TileCoordinate tile, MapRegionModel region) async {
    final tilePath = getTilePath(tile.x, tile.y, tile.z, region.code);
    final tileFile = File(tilePath);

    // Skip if already downloaded
    if (await tileFile.exists()) {
      return;
    }

    // Ensure directory exists
    final dir = tileFile.parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // Download tile from first available source
    for (final baseUrl in region.tileUrls) {
      try {
        final url = baseUrl
            .replaceAll('{z}', tile.z.toString())
            .replaceAll('{x}', tile.x.toString())
            .replaceAll('{y}', tile.y.toString());

        final response = await http.get(Uri.parse(url)).timeout(
          const Duration(seconds: 10),
        );

        if (response.statusCode == 200) {
          await tileFile.writeAsBytes(response.bodyBytes);
          return;
        }
      } catch (e) {
        debugPrint('Failed to download from $baseUrl: $e');
      }
    }

    throw Exception('Failed to download tile from all sources');
  }

  /// Get the local file path for a tile
  String getTilePath(int x, int y, int z, String regionCode) {
    return '$tileDirectoryPath/$regionCode/$z/$x/$y.png';
  }

  /// Delete downloaded region tiles
  Future<void> deleteRegion(MapRegionModel region) async {
    final regionDir = Directory('$tileDirectoryPath/${region.code}');
    
    if (await regionDir.exists()) {
      await regionDir.delete(recursive: true);
      debugPrint('Deleted region: ${region.displayName}');
    }

    // Remove from downloaded regions
    final downloadedRegions = _getDownloadedRegions();
    downloadedRegions.remove(region.code);
    await _prefs?.setStringList(_downloadedRegionsKey, downloadedRegions.toList());

    // Remove metadata
    await _prefs?.remove('${_regionMetadataKey}_${region.code}');
  }

  /// Get total downloaded size in bytes
  Future<int> getTotalDownloadedSize() async {
    int totalSize = 0;
    
    for (final region in MapRegions.all) {
      if (await isRegionDownloaded(region)) {
        final regionDir = Directory('$tileDirectoryPath/${region.code}');
        if (await regionDir.exists()) {
          await for (final entity in regionDir.list(recursive: true)) {
            if (entity is File) {
              totalSize += await entity.length();
            }
          }
        }
      }
    }
    
    return totalSize;
  }

  /// Get total downloaded size in MB
  Future<double> getTotalDownloadedSizeMb() async {
    final bytes = await getTotalDownloadedSize();
    return bytes / (1024 * 1024);
  }

  /// Check if WiFi is available (placeholder - actual implementation would use connectivity_plus)
  Future<bool> isWifiAvailable() async {
    // Placeholder: In production, use connectivity_plus to check
    // For now, return true to allow downloads
    return true;
  }

  /// Get number of tiles for a region
  int getTileCountForRegion(MapRegionModel region) {
    return _calculateTilesForRegion(region).length;
  }

  /// Get list of tile URLs for a region (for FMTC compatibility)
  List<String> getTileUrlsForRegion(MapRegionModel region) {
    return region.tileUrls;
  }
}

/// Tile coordinate helper
class TileCoordinate {
  final int x;
  final int y;
  final int z;

  const TileCoordinate({
    required this.x,
    required this.y,
    required this.z,
  });

  @override
  String toString() => 'TileCoordinate($x, $y, $z)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TileCoordinate && other.x == x && other.y == y && other.z == z;
  }

  @override
  int get hashCode => Object.hash(x, y, z);
}

/// Debug print helper
void debugPrint(String message) {
  // ignore: avoid_print
  print('[OfflineTileService] $message');
}
