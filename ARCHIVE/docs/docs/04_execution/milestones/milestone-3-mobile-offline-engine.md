# Milestone 3 — Mobile Offline Engine

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Objective
Offline-first mobile architecture: Isar local DB, Mapbox offline maps, sync manager.

## Scope
- Isar database integration
- Offline queue for writes
- Sync manager with conflict resolution
- Mapbox offline tile download (300MB limit)
- Photo capture + compression + watermark
- Background GPS tracking

## Deliverables
- [ ] Isar schemas for all offline entities
- [ ] SyncManager with retry logic
- [ ] Offline map download UI + storage management
- [ ] Photo capture pipeline (compress → watermark → queue)
- [ ] Background location tracking
- [ ] Storage circuit breaker

## Dependencies
- Milestone 2 (Edge Functions for sync)
- Flutter project with all packages

## Success Criteria
- App launches from local cache when offline
- User can log jejak ibadah without internet
- Photos watermarked and queued for sync
- Offline maps load within 2s
- Storage never exceeds 300MB for tiles

## Related
- `docs/03_technical/data-model/local-storage.md`
- `docs/05_features/offline-maps/`
- `docs/05_features/jejak-ibadah/`
- `docs/04_execution/milestones/milestone-4-user-journeys.md`
