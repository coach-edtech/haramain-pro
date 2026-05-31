# Mobile Offline Sync

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Detailed specification for mobile offline synchronization architecture.

## Architecture Overview

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Flutter UI    │────▶│   Isar (Local) │────▶│  SyncManager   │
│  (Presentation) │◀────│  (Source of    │◀────│  (Background)  │
└─────────────────┘     │   Truth)        │     └────────┬────────┘
                        └─────────────────┘              │
                                                         ▼
                                              ┌─────────────────┐
                                              │   Supabase      │
                                              │  (Remote API)   │
                                              └─────────────────┘
```

## State Management: Riverpod Coordination

### Providers
```dart
// Offline state
final offlineQueueProvider = StateNotifierProvider<OfflineQueueNotifier, QueueState>

// Sync status
final syncStatusProvider = StreamProvider<SyncStatus>

// Pending writes count
final pendingWritesProvider = Provider<int>
```

### SyncManager
- Runs in background isolate
- Monitors connectivity state
- Processes Isar queue FIFO
- Handles retry with exponential backoff

## Isar Local Persistence

### Primary Collections
| Collection | Purpose |
|-----------|---------|
| `UserProfile` | Cached user data |
| `Subscription` | Local subscription state |
| `Rombongan` | Cached group data |
| `JejakIbadahEntry` | Offline spiritual activity queue |
| `LocationPoint` | GPS coordinate queue |
| `SyncQueueItem` | Generic sync queue |

### Sync Protocol
1. User action → write to Isar (immediate, local)
2. SyncManager detects online state
3. Batch pending items (max 50 per batch)
4. POST to Supabase API
5. Mark synced=true on success
6. On failure: increment retry count, reschedule

## Photo Queue

### Sync Flow
```
Photo taken
  → Compress (80% quality, max 2MB)
  → Save to Isar queue
  → SyncManager picks up
  → Upload to Supabase Storage (pre-authenticated URL)
  → Create jejak_ibadah record
  → Mark synced
```

### Retry Logic
- Max 3 retries per photo
- Exponential backoff: 5s, 15s, 45s
- After 3 failures: mark as failed, surface error to user

## Conflict Resolution: Last-Write-Wins

### Strategy
- **Personal data (jejak ibadah)**: last-write-wins by `performed_at` timestamp
- **Shared data (group membership)**: server-wins (RLS prevents conflicts)
- **Location history**: server aggregates, client is append-only

### Why Last-Write-Wins?
- Offline-first: user actions are always valid
- Spiritual activities are personal memories — no business conflict
- Server timestamp (`performed_at`) used, not local device time

## Offline Indicators

### UI States
| State | Indicator |
|-------|-----------|
| Online | Green dot, "Synced" |
| Offline | Orange dot, "Offline" |
| Syncing | Blue spinner, "Syncing (3)" |
| Sync failed | Red dot, "Sync failed" |

## Related
- `docs/03_technical/data-model/local-storage.md`
- `docs/05_features/jejak-ibadah/`
