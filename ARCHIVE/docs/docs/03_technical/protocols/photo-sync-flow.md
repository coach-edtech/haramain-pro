# Photo Sync Flow

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Offline photo capture → watermark → sync flow for Jejak Ibadah.

## Flow

```
User takes photo
    │
    ▼
Flutter: Compress photo
    → Quality: 80%
    → Max dimension: 2048px
    → Format: JPEG
    → Max file size: 2MB
    │
    ▼
Flutter: Apply watermark
    → Position: Bottom-right
    → Content: App logo + timestamp + location name
    → Style: Semi-transparent (50% opacity)
    │
    ▼
Flutter: Save to Isar queue
    → local_id (auto)
    → photo_local_path
    → metadata (type, location, timestamp)
    → synced = false
    │
    ▼
[If online] Flutter: Sync immediately
    → Upload to Supabase Storage
    → Create jejak_ibadah record
    → Mark synced=true
    │
    ▼
[If offline] SyncManager queues
    → Background sync on reconnect
    → Retry with exponential backoff
    → Max 3 retries
```

## Storage Path
```
supabase_storage/
  └── jejak_ibadah/
      └── {user_id}/
          └── {rombongan_id}/
              └── {jejak_id}/
                  └── photo.jpg
```

## Conflict Resolution
- Server record wins
- If local photo not synced within 7 days: delete local (user notified)

## Related
- `docs/05_features/jejak-ibadah/`
- `docs/03_technical/data-model/jejak-ibadah.md`
