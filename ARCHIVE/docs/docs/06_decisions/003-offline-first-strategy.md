# 003 — Offline-First Strategy

> Owner: OpenClaw
> Status: Approved
> Note: Starter content — based on master doc direction.

## Decision
Haramain Pro follows an **offline-first architecture** — the mobile app remains functional without network connectivity, with data syncing when connection is restored.

## Core Principles

### 1. Local-First Data
- All critical data stored in **Isar** (local mobile DB)
- App launches instantly from local cache
- User actions queued when offline

### 2. Sync-on-Reconnect
- Background sync when connectivity returns
- Conflict resolution: server-wins for shared data, merge for personal
- Sync status indicator visible to user

### 3. Offline-Capable Features (MVP)
| Feature | Offline Behavior |
|---------|-----------------|
| Panic Alert | Triggers local alarm + queues FCM/Twilio |
| Offline Maps | Pre-cached Mapbox tiles (max 300MB) |
| Virtual Muthawif | Local doa repository, GPS tracking queues |
| Jejak Ibadah | Queues photos + timestamps, sync later |
| Group View | Read-only cached group data |

### 4. Network-Dependent Features
| Feature | Requires Network |
|---------|----------------|
| Payment | Real-time Midtrans verification |
| Subscription Unlock | Realtime RLS update |
| New Group Join | API call required |

## Storage Circuit Breaker
If local storage exceeds thresholds:
1. Oldest synced Jejak ibadah entries deleted first
2. Least-recently-used offline map tiles evicted
3. User notified of cleanup

## Related
- `docs/03_technical/data-model/local-storage.md`
- `docs/05_features/offline-maps/`
- `016-local-storage-strategy-isar.md`
