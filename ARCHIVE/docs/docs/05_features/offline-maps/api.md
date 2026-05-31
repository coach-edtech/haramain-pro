# Offline Maps — API

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Flutter API

### OfflineRegionManager
```dart
class OfflineRegionManager {
  /// Download map tiles for a region
  Future<void> downloadRegion({
    required String regionId,
    required double north,
    required double south,
    required double east,
    required double west,
    int maxTiles = 10000,
  });

  /// Get download progress
  Stream<DownloadProgress> get progressStream;

  /// Delete downloaded region
  Future<void> deleteRegion(String regionId);

  /// Get list of downloaded regions
  Future<List<OfflineRegion>> get downloadedRegions;

  /// Get total storage used
  Future<int> get totalStorageUsed;

  /// Check if region is available offline
  Future<bool> isRegionAvailable(String regionId);
}
```

### Usage
```dart
// Download Mecca region
await OfflineRegionManager().downloadRegion(
  regionId: 'mecca',
  north: 21.45,
  south: 21.35,
  east: 39.85,
  west: 39.75,
);

// Listen to progress
manager.progressStream.listen((progress) {
  print('Downloaded: ${progress.percentage}%');
});
```

## Storage Circuit Breaker
```dart
Future<void> checkAndCleanup() async {
  final used = await manager.totalStorageUsed;
  final limit = 300 * 1024 * 1024; // 300MB

  if (used > limit * 0.9) {
    // Delete least recently used region
    final regions = await manager.downloadedRegions;
    await manager.deleteRegion(regions.first.id);
  }
}
```

## Related
- `docs/05_features/offline-maps/implementation.md`
- `docs/03_technical/data-model/local-storage.md`
