# Panic Alert

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Emergency alert data model.

## Tables

#### `public.panic_alerts`
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | PK |
| `triggered_by` | UUID | FK → profiles (user who triggered) |
| `rombongan_id` | UUID | FK → rombongans |
| `status` | ENUM | 'triggered', 'acknowledged', 'resolved', 'false_alarm' |
| `location_lat` | FLOAT | GPS at trigger time |
| `location_lng` | FLOAT | |
| `location_accuracy` | FLOAT | GPS accuracy |
| `triggered_at` | TIMESTAMPTZ | |
| `acknowledged_at` | TIMESTAMPTZ | Nullable |
| `acknowledged_by` | UUID | FK → profiles (muthawif/admin) |
| `resolved_at` | TIMESTAMPTZ | Nullable |
| `escalation_level` | INT | 1=FCM, 2=SMS, 3=WhatsApp, 4=loopback |
| `notes` | TEXT | Resolution notes |

#### `public.panic_notifications`
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | PK |
| `alert_id` | UUID | FK → panic_alerts |
| `recipient_user_id` | UUID | FK → profiles |
| `channel` | ENUM | 'fcm', 'sms', 'whatsapp' |
| `status` | ENUM | 'sent', 'delivered', 'failed' |
| `sent_at` | TIMESTAMPTZ | |
| `delivered_at` | TIMESTAMPTZ | Nullable |

## Fallback Flow
```
Level 1 (FCM Push)
  → If delivery fails within 5s
  Level 2 (Twilio SMS)
  → If delivery fails
  Level 3 (Twilio WhatsApp)
  → If all fail
  Level 4 (Local loopback — test only)
```

## Related
- `docs/05_features/panic-alert/`
- `docs/03_technical/protocols/panic-flow.md`
