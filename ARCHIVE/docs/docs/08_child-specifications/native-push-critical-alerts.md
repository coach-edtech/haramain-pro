# Native Push Critical Alerts

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Detailed specification for native push notification handling, focusing on critical/emergency alerts.

## Push Architecture

```
Panic Alert Triggered (Server)
        │
        ▼
┌───────────────────┐
│  Supabase Edge    │
│  Function         │
│  (panic-fallback) │
└────────┬──────────┘
         │
         ▼
┌───────────────────┐
│  FCM / Twilio     │
│  (Push Provider)  │
└────────┬──────────┘
         │
         ▼
┌───────────────────┐
│  Device           │
│  (Flutter App)    │
└───────────────────┘
```

## FCM Configuration

### Message Priority
| Alert Type | FCM Priority | Reasoning |
|-----------|---------------|-----------|
| Panic Alert | `high` | Critical — must deliver immediately |
| Group Announcement | `normal` | Non-critical |
| Sync Trigger | `normal` | Background only |

### iOS Caveats
- **APNs priority**: use `content-available: 1` for background
- **Critical alerts**: requires special entitlement from Apple (not available for MVP)
- **Notification permissions**: must prompt user

### Android Caveats
- **FCM default priority** is `normal`
- Set `priority: "high"` in FCM payload for panic alerts
- **Doze mode**: high-priority messages wake device

## Critical Alert Fallback: Twilio Relationship

### Fallback Cascade
```
FCM Push (priority: high)
    │
    ├─ If delivered → Alert shown
    │
    └─ If timeout (5s) or fail
           │
           ▼
        Twilio SMS
            │
            ├─ If delivered → Done
            │
            └─ If fail
                   │
                   ▼
              Twilio WhatsApp
```

### Why Both SMS and WhatsApp?
- SMS: works on any phone, no app required
- WhatsApp: higher delivery rate in some regions, supports location sharing

## Loopback Test Restriction

### What is Loopback?
- Panic alert that triggers full flow but sends only to self
- Used for testing without disturbing actual group members
- **Non-production only**: loopback disabled in production builds

### Implementation
```dart
if (kDebugMode) {
  // Loopback available in debug
} else {
  // Loopback blocked in production
}
```

### Test Tools (DX)
- `dx-tools` feature provides loopback trigger
- Requires authenticated test account
- Visible "TEST MODE" banner in UI

## Notification Content

### Panic Alert Payload
```json
{
  "notification": {
    "title": "🚨 Panic Alert",
    "body": "[Name] needs help at [Location]"
  },
  "data": {
    "type": "panic_alert",
    "alert_id": "uuid",
    "lat": "21.4225",
    "lng": "39.8262"
  },
  "android": {
    "priority": "high",
    "channel_id": "panic_alerts"
  },
  "apns": {
    "priority": "10",
    "headers": {
      "apns-priority": "10"
    }
  }
}
```

## Channel Configuration

### Android (NotificationChannel)
```dart
NotificationChannel(
  id: 'panic_alerts',
  name: 'Panic Alerts',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
)
```

### iOS
- Uses default notification center
- Requires notification permission
- Critical alert entitlement (future phase)

## Related
- `docs/05_features/panic-alert/`
- `docs/03_technical/protocols/panic-flow.md`
