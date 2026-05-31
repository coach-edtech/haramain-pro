# Local Storage

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Mobile local storage architecture — Isar database and file system.

## Isar (Primary Local DB)

### Collections
| Collection | Schema | Purpose |
|-----------|--------|---------|
| `UserProfile` | Mirrors profiles table | Cached user data |
| `Subscription` | Mirrors subscriptions | Local subscription state |
| `Rombongan` | Mirrors rombongans | Cached groups |
| `JejakIbadahEntry` | Lightweight schema | Offline jejak queue |
| `LocationPoint` | Lat, lng, timestamp | GPS queue |
| `SyncQueueItem` | Type, payload, retry | Generic sync queue |

### Schema Example: JejakIbadahEntry
```dart
@collection
class JejakIbadahEntry {
  Id id = Isar.autoIncrement;
  late String type; // prayer, dua, tawaf, etc.
  late double lat;
  late double lng;
  late DateTime performedAt;
  String? photoLocalPath;
  late bool synced;
  DateTime? syncedAt;
}
```

## File System

### Directories
| Path | Purpose | Size Limit |
|------|---------|------------|
| `app_documents/photos/` | Jejak ibadah photos | 100MB (compressed) |
| `app_documents/tiles/` | Mapbox offline tiles | 300MB |
| `app_cache/` | Temporary files | Auto-clean by OS |

### Photo Handling
1. User takes photo
2. Compress to 80% quality (max 2MB)
3. Apply watermark (app logo + timestamp)
4. Save to `app_documents/photos/`
5. Queue for sync
6. On sync success: delete local (or keep if storage allows)

## Storage Circuit Breaker
If storage exceeds 90% of limit:
1. Oldest synced Jejak entries flagged
2. User prompted to delete or sync
3. Auto-cleanup of oldest synced photos
4. Graceful degradation: disable offline maps

## Related
- `016-local-storage-strategy-isar.md`
- `docs/05_features/jejak-ibadah/`
- `docs/05_features/offline-maps/`
