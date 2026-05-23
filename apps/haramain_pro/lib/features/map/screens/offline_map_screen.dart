import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/map_region_model.dart';
import '../services/offline_tile_service.dart';
import '../services/map_search_service.dart';
import '../services/navigation_service.dart';
import '../tile_sources.dart';
import 'download_region_screen.dart';

/// Panic alert location data
class PanicAlertLocation {
  final String alertId;
  final double latitude;
  final double longitude;
  final String? jamaaahName;
  final DateTime timestamp;

  const PanicAlertLocation({
    required this.alertId,
    required this.latitude,
    required this.longitude,
    this.jamaaahName,
    required this.timestamp,
  });
}

/// Offline map screen with online/offline mode switch
class OfflineMapScreen extends StatefulWidget {
  final PanicAlertLocation? panicAlertLocation;

  const OfflineMapScreen({super.key, this.panicAlertLocation});

  @override
  State<OfflineMapScreen> createState() => _OfflineMapScreenState();
}

class _OfflineMapScreenState extends State<OfflineMapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isOnlineMode = true;
  String _currentRegion = 'makkah';
  LatLng? _currentLocation;
  bool _isLoadingLocation = false;
  bool _isSearching = false;
  List<PlaceSearchResult> _searchResults = [];
  
  // Route display
  RouteInfo? _currentRoute;
  LatLng? _routeFrom;
  LatLng? _routeTo;
  final List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
    _checkOfflineAvailability();
    _addPanicAlertMarker();
  }

  void _addPanicAlertMarker() {
    final panicLocation = widget.panicAlertLocation;
    if (panicLocation != null) {
      _markers.add(Marker(
        point: LatLng(panicLocation.latitude, panicLocation.longitude),
        width: 60,
        height: 60,
        child: GestureDetector(
          onTap: () => _showPanicAlertInfo(panicLocation),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red, width: 3),
            ),
            child: const Center(
              child: Icon(Icons.warning, color: Colors.red, size: 30),
            ),
          ),
        ),
      ));
    }
  }

  void _showPanicAlertInfo(PanicAlertLocation alert) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.red, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Panic Alert Location',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (alert.jamaaahName != null)
              Text('Jamaah: ${alert.jamaaahName}'),
            Text('Lat: ${alert.latitude.toStringAsFixed(6)}'),
            Text('Lng: ${alert.longitude.toStringAsFixed(6)}'),
            Text('Time: ${alert.timestamp.toString().split('.').first}'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _calculateRouteTo(LatLng(alert.latitude, alert.longitude));
                },
                icon: const Icon(Icons.directions),
                label: const Text('Navigate Here'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _currentLocation = LatLng(position.latitude, position.longitude);
      
      if (_isOnlineMode) {
        _mapController.move(_currentLocation!, 15);
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _checkOfflineAvailability() async {
    final isMakkahDownloaded = await OfflineTileService.instance.isRegionDownloaded(MapRegions.makkah);
    final isMadinahDownloaded = await OfflineTileService.instance.isRegionDownloaded(MapRegions.madinah);
    
    if (isMadinahDownloaded && !isMakkahDownloaded) {
      setState(() => _currentRegion = 'madinah');
    }
  }

  void _toggleMode() {
    setState(() {
      _isOnlineMode = !_isOnlineMode;
    });
  }

  void _switchRegion(String region) {
    setState(() {
      _currentRegion = region;
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final results = await MapSearchService.instance.searchPlaces(query);
    
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  void _onPlaceSelected(PlaceSearchResult place) {
    setState(() {
      _searchResults = [];
      _searchController.clear();
    });

    // Add marker for selected place
    _markers.add(Marker(
      point: place.latLng,
      width: 40,
      height: 40,
      child: const Icon(Icons.location_on, color: Colors.red, size: 40),
    ));

    _mapController.move(place.latLng, 16);
    setState(() {});
  }

  void _clearRoute() {
    setState(() {
      _currentRoute = null;
      _routeFrom = null;
      _routeTo = null;
    });
  }

  Future<void> _calculateRouteTo(LatLng destination) async {
    if (_currentLocation == null) {
      _showSnackBar('Lokasi saat ini tidak tersedia');
      return;
    }

    setState(() => _isSearching = true);

    final route = await NavigationService.instance.calculateWalkingRoute(
      from: _currentLocation!,
      to: destination,
    );

    if (mounted) {
      setState(() {
        _isSearching = false;
        _routeFrom = _currentLocation;
        _routeTo = destination;
        _currentRoute = route;
      });

      if (route != null) {
        _showRouteInfo(route);
      } else {
        _showSnackBar('Gagal menghitung rute');
      }
    }
  }

  void _showRouteInfo(RouteInfo route) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Rute',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.straighten, size: 20),
                const SizedBox(width: 8),
                Text('Jarak: ${route.formattedDistance}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 20),
                const SizedBox(width: 8),
                Text('Estimasi: ${route.formattedTime}'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.navigation),
                    label: const Text('Navigasi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      // Open in external maps app
                      _openInExternalMaps(_routeTo!);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _clearRoute();
                  },
                  child: const Text('Batal'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openInExternalMaps(LatLng destination) {
    // For now, show snackbar. In production, use url_launcher to open maps app
    _showSnackBar('Membuka aplikasi navigasi...');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  List<Polyline> get _routePolylines {
    if (_currentRoute == null) return [];
    return [
      Polyline(
        points: _currentRoute!.polyline,
        color: Colors.blue,
        strokeWidth: 5,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Offline'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          // Mode toggle button
          IconButton(
            icon: Icon(_isOnlineMode ? Icons.cloud_off : Icons.cloud),
            tooltip: _isOnlineMode ? 'Mode Offline' : 'Mode Online',
            onPressed: _toggleMode,
          ),
          // Download button
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Unduh Region',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DownloadRegionScreen(),
                ),
              ).then((_) => _checkOfflineAvailability());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(8),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari tempat (Bahasa Indonesia)...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _searchPlaces('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: _searchPlaces,
                  onSubmitted: _searchPlaces,
                ),
                // Search results
                if (_searchResults.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final place = _searchResults[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on, color: Colors.red),
                          title: Text(
                            place.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _onPlaceSelected(place),
                          trailing: IconButton(
                            icon: const Icon(Icons.directions),
                            onPressed: () => _calculateRouteTo(place.latLng),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          // Region selector (only show when offline)
          if (!_isOnlineMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  const Text('Region: '),
                  ChoiceChip(
                    label: const Text('Makkah'),
                    selected: _currentRegion == 'makkah',
                    onSelected: (_) => _switchRegion('makkah'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Madinah'),
                    selected: _currentRegion == 'madinah',
                    onSelected: (_) => _switchRegion('madinah'),
                  ),
                ],
              ),
            ),
          // Map
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLocation ?? const LatLng(21.4225, 39.8262),
                    initialZoom: 14,
                    minZoom: 10,
                    maxZoom: 18,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: _isOnlineMode
                          ? MapTileSources.osmOnlineUrl
                          : 'file://${OfflineTileService.instance.tileDirectoryPath}/$_currentRegion/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.haramain.pro',
                    ),
                    PolylineLayer(polylines: _routePolylines),
                    MarkerLayer(markers: _markers),
                  ],
                ),
                // Loading indicator for search
                if (_isSearching || _isLoadingLocation)
                  Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                // Mode indicator
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isOnlineMode ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isOnlineMode ? Icons.cloud : Icons.cloud_off,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isOnlineMode ? 'Online' : 'Offline',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                // Current location button
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Column(
                    children: [
                      // Route clear button
                      if (_currentRoute != null)
                        FloatingActionButton.small(
                          heroTag: 'clear_route',
                          backgroundColor: Colors.red,
                          onPressed: _clearRoute,
                          child: const Icon(Icons.close, color: Colors.white),
                        ),
                      const SizedBox(height: 8),
                      // My location button
                      FloatingActionButton(
                        heroTag: 'my_location',
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        onPressed: _loadCurrentLocation,
                        child: const Icon(Icons.my_location, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Debug print helper
void debugPrint(String message) {
  // ignore: avoid_print
  print('[OfflineMapScreen] $message');
}
