# External Services

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Integration overview for all external services.

## Service Inventory

### Supabase
| Aspect | Detail |
|--------|--------|
| Product | Backend-as-a-Service |
| Used For | Auth, Database, Realtime, Storage, Edge Functions |
| Region | Singapore (ap-southeast-1) |
| Pricing | Free tier → Pro (usage-based) |

### Mapbox
| Aspect | Detail |
|--------|--------|
| Product | Maps + Navigation |
| Used For | Offline maps, GPS tracking, geofencing |
| Offline Limit | 300MB per device |
| Pricing | Pay-per-tile + API calls |

### Midtrans
| Aspect | Detail |
|--------|--------|
| Product | Payment Gateway |
| Used For | B2C Safety Pass, B2B volume licenses |
| Methods | Credit card, GoPay, OVO, Dana, Bank Transfer |
| Integration | Snap (in-app checkout) |

### FCM (Firebase Cloud Messaging)
| Aspect | Detail |
|--------|--------|
| Product | Push Notifications |
| Used For | Panic alerts, group announcements, sync triggers |
| Pricing | Free (within quotas) |

### Twilio
| Aspect | Detail |
|--------|--------|
| Product | SMS + WhatsApp |
| Used For | Panic fallback (SMS/WhatsApp) |
| Coverage | Global (Saudi Arabia supported) |
| Pricing | Pay-per-SMS/WhatsApp message |

## Integration Architecture
```
Flutter App
  ├── Supabase SDK (Auth + DB)
  ├── Mapbox GL (Maps)
  ├── Firebase Messaging (FCM)
  └── HTTP Client (Midtrans Snap JS)
        │
        ▼
Supabase Backend
  ├── Edge Functions
  │     ├── Midtrans Webhook
  │     ├── Panic Escalation (Twilio)
  │     └── Sync Handlers
  │
  └── External APIs
        ├── Mapbox API
        ├── Twilio API
        └── FCM API
```

## Related
- `docs/03_technical/architecture/system-topology.md`
- `docs/05_features/panic-alert/`
- `docs/05_features/offline-maps/`
