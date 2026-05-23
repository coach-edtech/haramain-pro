import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../design/design.dart';

class MapScreenPremium extends StatefulWidget {
  const MapScreenPremium({super.key});

  @override
  State<MapScreenPremium> createState() => _MapScreenPremiumState();
}

class _MapScreenPremiumState extends State<MapScreenPremium> {
  final MapController _mapController = MapController();
  LatLng _currentPosition = const LatLng(21.4225, 39.8262);
  bool _isLoading = true;
  bool _showDownloadDialog = false;

  final List<MapRegion> _regions = [
    MapRegion(
      name: 'Masjidil Haram',
      center: const LatLng(21.4225, 39.8262),
      zoom: 16.0,
      description: 'Mekkah, Arab Saudi',
      downloadSize: '45 MB',
    ),
    MapRegion(
      name: 'Masjid Nabawi',
      center: const LatLng(24.4672, 39.6111),
      zoom: 16.0,
      description: 'Madinah, Arab Saudi',
      downloadSize: '38 MB',
    ),
    MapRegion(
      name: 'Arafah',
      center: const LatLng(21.3563, 39.9833),
      zoom: 14.0,
      description: 'Padang Arafah',
      downloadSize: '25 MB',
    ),
    MapRegion(
      name: 'Mina',
      center: const LatLng(21.3833, 39.8833),
      zoom: 14.0,
      description: 'Tenda Mina',
      downloadSize: '30 MB',
    ),
    MapRegion(
      name: 'Muzdalifah',
      center: const LatLng(21.3833, 39.9667),
      zoom: 14.0,
      description: 'Padang Muzdalifah',
      downloadSize: '22 MB',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _goToLocation(LatLng location, double zoom) {
    _mapController.move(location, zoom);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 14.0,
              minZoom: 3.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.haramain.pro',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: const LatLng(21.4225, 39.8262),
                    width: 50,
                    height: 50,
                    child: _buildMarker(
                      icon: Icons.mosque,
                      color: AppColors.gold,
                      isDark: isDark,
                    ),
                  ),
                  Marker(
                    point: const LatLng(24.4672, 39.6111),
                    width: 50,
                    height: 50,
                    child: _buildMarker(
                      icon: Icons.mosque,
                      color: AppColors.gold,
                      isDark: isDark,
                    ),
                  ),
                  if (!_isLoading)
                    Marker(
                      point: _currentPosition,
                      width: 50,
                      height: 50,
                      child: _buildMarker(
                        icon: Icons.my_location,
                        color: AppColors.error,
                        isDark: isDark,
                      ),
                    ),
                ],
              ),
            ],
          ),
          _buildTopBar(isDark),
          _buildQuickActions(isDark),
          if (_showDownloadDialog) _buildDownloadDialog(isDark),
          if (_isLoading) _buildLoadingOverlay(isDark),
        ],
      ),
      floatingActionButton: _buildFAB(isDark),
    );
  }

  Widget _buildMarker({required IconData icon, required Color color, required bool isDark}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: color, width: 2),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildTopBar(bool isDark) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.surfaceDark : AppColors.backgroundLight)
              .withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.map,
              color: AppColors.gold,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Peta Offline',
              style: AppTypography.titleMedium.copyWith(
                color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Online',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    return Positioned(
      right: AppSpacing.md,
      top: 100,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.surfaceDark : AppColors.backgroundLight)
              .withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: [
            _buildQuickActionButton(
              icon: Icons.my_location,
              onTap: () {
                if (!_isLoading) {
                  _goToLocation(_currentPosition, 16.0);
                }
              },
              isDark: isDark,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildQuickActionButton(
              icon: Icons.download,
              onTap: () => setState(() => _showDownloadDialog = true),
              isDark: isDark,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildQuickActionButton(
              icon: Icons.layers,
              onTap: () {},
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
        ),
        child: Icon(
          icon,
          color: AppColors.gold,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildDownloadDialog(bool isDark) {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.lg),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.download, color: AppColors.gold),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Download Region',
                    style: AppTypography.titleLarge.copyWith(
                      color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Pilih region untuk didownload:',
                style: AppTypography.bodyMedium.copyWith(
                  color: (isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight)
                      .withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ..._regions.map((region) => _buildRegionItem(region, isDark)),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => setState(() => _showDownloadDialog = false),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegionItem(MapRegion region, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(
              Icons.location_on,
              color: AppColors.gold,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  region.name,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  region.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: (isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight)
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              region.downloadSize,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.gold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay(bool isDark) {
    return Container(
      color: (isDark ? AppColors.backgroundDark : AppColors.backgroundLight)
          .withValues(alpha: 0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Loading map...',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(bool isDark) {
    return FloatingActionButton(
      onPressed: () => _showRegionSelector(),
      backgroundColor: AppColors.gold,
      child: Icon(
        Icons.place,
        color: AppColors.primaryDark,
      ),
    );
  }

  void _showRegionSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: AppColors.dividerLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pergi ke Lokasi',
                    style: AppTypography.titleLarge.copyWith(
                      color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ..._regions.map((region) => ListTile(
                        leading: Icon(Icons.location_on, color: AppColors.gold),
                        title: Text(region.name),
                        subtitle: Text(region.description),
                        onTap: () {
                          Navigator.pop(context);
                          _goToLocation(region.center, region.zoom);
                        },
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MapRegion {
  final String name;
  final LatLng center;
  final double zoom;
  final String description;
  final String downloadSize;

  MapRegion({
    required this.name,
    required this.center,
    required this.zoom,
    required this.description,
    required this.downloadSize,
  });
}
