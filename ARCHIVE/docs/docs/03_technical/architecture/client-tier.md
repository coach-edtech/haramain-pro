# Client Tier

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Mobile client architecture for Flutter app.

## Architecture

### State Management
- **BLoC Pattern** or **Riverpod**
- Separation: UI Events → BLoC → Repository → Data Source

### Layers
```
UI Layer (Widgets)
    │
    ▼
BLoC/State Layer (Business Logic)
    │
    ▼
Repository Layer (Data Abstraction)
    │
    ├── Remote Data Source (Supabase)
    └── Local Data Source (Isar)
```

### Key Packages
| Package | Purpose |
|---------|---------|
| `supabase_flutter` | Backend connectivity |
| `isar` + `isar_flutter_libs` | Local database |
| `mapbox_gl` | Maps and location |
| `firebase_messaging` | FCM push |
| `dio` | HTTP client |
| `flutter_bloc` | State management |
| `geolocator` | GPS location |
| `workmanager` | Background tasks |

### Offline Strategy
1. All writes go to Isar first
2. SyncManager queues pending writes
3. On reconnect: batch sync to Supabase
4. Conflict resolution: server-wins for shared, merge for personal

### Platform Channels
- None currently required (all packages have Flutter bindings)

## Related
- `docs/03_technical/architecture/system-topology.md`
- `docs/03_technical/data-model/local-storage.md`
