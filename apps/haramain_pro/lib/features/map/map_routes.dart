import 'package:flutter/material.dart';
import 'screens/offline_map_screen.dart';
import 'screens/download_region_screen.dart';

/// Route names for map feature
class MapRoutes {
  static const String map = '/map';
  static const String download = '/map/download';
  static const String search = '/map/search';

  /// Get all map routes
  static Map<String, WidgetBuilder> get routes => {
        map: (context) => const OfflineMapScreen(),
        download: (context) => const DownloadRegionScreen(),
      };

  /// Generate route for map feature
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '');

    // /map
    if (uri.pathSegments.length == 1 && uri.pathSegments[0] == 'map') {
      return MaterialPageRoute(
        builder: (context) => const OfflineMapScreen(),
      );
    }

    // /map/download
    if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'map') {
      if (uri.pathSegments[1] == 'download') {
        return MaterialPageRoute(
          builder: (context) => const DownloadRegionScreen(),
        );
      }
    }

    return null;
  }
}
