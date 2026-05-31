# Offline Maps — TRD

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Technical Requirements

### Storage
| Aspect | Value |
|--------|-------|
| Max total size | 300MB |
| Tile format | Vector (MVT) |
| Region | Mecca (~150MB) + Medina (~100MB) |
| Circuit breaker | Auto-cleanup at 90% threshold |

### Mapbox Integration
- Style: `mapbox://styles/mapbox/satellite-streets-v11`
- Package: `mapbox_gl`
- Offline plugin: `mapbox_gl_flutter` (offline support)
- Tile regions: Pre-defined bounding boxes for Mecca/Medina

### Implementation
```
Flutter:
  - mapbox_gl package
  - OfflineManager.downloadRegion()
  - Geofence: optional boundary
```

### Offline Behavior
- Map loads from local cache
- No live traffic
- No offline search (requires API)
- GPS tracking continues

## Acceptance Criteria
- [ ] Map loads in <2s offline
- [ ] Storage never exceeds 300MB
- [ ] Tiles visible in airplane mode
- [ ] Circuit breaker cleans old tiles when storage low

## Related
- `docs/05_features/offline-maps/api.md`
- `docs/05_features/offline-maps/implementation.md`
