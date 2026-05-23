import 'package:flutter_map/flutter_map.dart';
import 'models/map_region_model.dart';
import 'services/offline_tile_service.dart';

/// Map tile source mode
enum TileSourceMode {
  online,
  offline,
}

/// Tile source configuration for flutter_map
class MapTileSources {
  /// Standard OSM online tile URL
  static const String osmOnlineUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Default OSM attribution
  static const String osmAttribution = '© OpenStreetMap contributors';

  /// Online tile layer for flutter_map
  static TileLayer get onlineTileLayer => TileLayer(
        urlTemplate: osmOnlineUrl,
        userAgentPackageName: 'com.haramain.pro',
      );

  /// Get offline tile layer for a region
  /// Falls back to online if region not downloaded
  static TileLayer getOfflineTileLayer(String regionCode) {
    final tilePath = OfflineTileService.instance.tileDirectoryPath;
    
    return TileLayer(
      urlTemplate: 'file://$tilePath/$regionCode/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.haramain.pro',
    );
  }

  /// Get tile layer that automatically switches between online/offline
  static TileLayer getTileLayer({
    required TileSourceMode mode,
    String? offlineRegionCode,
  }) {
    switch (mode) {
      case TileSourceMode.online:
        return onlineTileLayer;
      case TileSourceMode.offline:
        return getOfflineTileLayer(offlineRegionCode ?? 'makkah');
    }
  }

  /// Check if offline tiles are available for a region
  static Future<bool> hasOfflineTiles(String regionCode) async {
    return OfflineTileService.instance.isRegionDownloaded(
      MapRegions.getRegion(
        regionCode == 'makkah' ? MapRegionType.makkah : MapRegionType.madinah,
      ),
    );
  }
}
