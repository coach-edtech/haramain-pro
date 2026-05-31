# Offline Maps — Summary

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Feature Summary

| Aspect | Detail |
|--------|--------|
| Feature | Offline Maps |
| Owner | OpenClaw (starter), Onyx (refinement) |
| Priority | P1 |
| Status | Implementation pending |

## What It Does
Provides pre-downloaded Mapbox maps for Mecca and Medina, allowing pilgrims to navigate offline without data connectivity.

## Key Specs
- **Storage**: Max 300MB per device
- **Regions**: Mecca (~150MB) + Medina (~100MB)
- **Load Time**: <2s offline
- **Format**: Vector tiles (Mapbox MVT)

## Implementation Path
1. Mapbox account + token
2. `mapbox_gl` Flutter package
3. OfflineRegionManager for downloads
4. Storage circuit breaker
5. Download UI with progress

## Open Questions
- Exact bounding box coordinates for Hajj sites?
- Auto-download on WiFi when trip starts?
- Update frequency for tiles?

## Dependencies
- Mapbox account
- 300MB device storage

## Related
- `docs/03_technical/data-model/local-storage.md`
- `docs/06_decisions/005-mapbox-offline-storage-limit.md`
