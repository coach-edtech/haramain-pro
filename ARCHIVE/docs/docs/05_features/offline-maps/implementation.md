# Offline Maps — Implementation

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Implementation Notes

### Flutter Setup
1. Add `mapbox_gl` to `pubspec.yaml`
2. Configure Mapbox token in environment
3. Enable offline capability in Mapbox account

### Region Definitions
```dart
class MapRegions {
  static const mecca = BoundingBox(
    name: 'Mecca',
    id: 'mecca',
    north: 21.45,
    south: 21.35,
    east: 39.85,
    west: 39.75,
    estimatedSize: 150 * 1024 * 1024, // 150MB
  );

  static const medina = BoundingBox(
    name: 'Medina',
    id: 'medina',
    north: 24.55,
    south: 24.45,
    east: 39.60,
    west: 39.50,
    estimatedSize: 100 * 1024 * 1024, // 100MB
  );
}
```

### Download UI
- Progress bar during download
- Cancel button
- Storage usage indicator
- "Downloaded" checkmark after completion

### Storage Management
- Show storage used / total limit
- Allow manual deletion
- Auto-cleanup on low storage (circuit breaker)

### Known Limitations
- Vector tiles only (no satellite offline)
- Zoom levels 12-18 available
- Max 300MB enforced

## Testing
- Airplane mode: map loads from cache
- Storage full: cleanup triggered
- Download interrupted: resume supported

## Related
- `docs/05_features/offline-maps/api.md`
- `docs/05_features/offline-maps/summary.md`
