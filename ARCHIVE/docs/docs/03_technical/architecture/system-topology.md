# System Topology

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
High-level system architecture and component topology.

## Architecture Overview

```
┌─────────────────┐     ┌─────────────────┐
│   Flutter App   │────▶│    Supabase     │
│  (Mobile UI)    │◀────│   (Backend)    │
└────────┬────────┘     └────┬────────────┘
         │                    │
         │  ┌─────────────────┼─────────────────┐
         │  │                 │                 │
         ▼  ▼                 ▼                 ▼
    ┌─────────┐        ┌──────────┐    ┌──────────┐
    │  FCM    │        │ Midtrans │    │ Twilio   │
    │ (Push)  │        │ (Pay)    │    │ (SMS)    │
    └─────────┘        └──────────┘    └──────────┘
         │                                     │
         │  ┌─────────────────────────────────┘
         ▼
    ┌─────────┐
    │ Mapbox  │
    │ (Maps)  │
    └─────────┘
```

## Components

### Flutter Mobile App
- **Platform**: iOS + Android
- **Local DB**: Isar (primary offline store)
- **State**: BLoC/Riverpod
- **HTTP**: Dio or http package
- **Maps**: mapbox_gl

### Supabase Backend
- **Auth**: Phone OTP (Supabase Auth)
- **Database**: PostgreSQL + RLS
- **Realtime**: Subscription channels
- **Edge Functions**: Webhook handlers
- **Storage**: Media uploads (watermarked photos)

### Notification Layer
- **FCM**: Primary push (free, fast)
- **Twilio SMS**: Fallback for panic
- **Twilio WhatsApp**: Tertiary fallback

### Payment
- **Midtrans Snap**: B2C payments
- **Midtrans Invoice**: B2B volume purchases

### Maps
- **Mapbox**: Offline tile storage
- **Tile Limit**: 300MB per device

## Data Flow

### Typical Request
```
User Action → Flutter App → Supabase API → RLS Check → PostgreSQL
                ▲                                      │
                └──────── Realtime Update ◀─────────────┘
```

### Offline Request
```
User Action → Isar (local) → Queue → Sync on Reconnect → Supabase
```

## Related
- `docs/03_technical/architecture/client-tier.md`
- `docs/03_technical/architecture/persistence-tier.md`
- `docs/03_technical/architecture/edge-functions.md`
