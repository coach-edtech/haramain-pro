# Panic Alert API — Response Contracts

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Response formats for panic alert endpoints.

---

## POST /panic/trigger

### Success Response (202 Accepted)
```json
{
  "success": true,
  "alert_id": "uuid",
  "status": "triggered",
  "escalation_level": 1,
  "notification_targets": [
    {
      "user_id": "uuid",
      "name": "Ahmad Muthawif",
      "role": "muthawif",
      "channel": "fcm",
      "status": "sent"
    },
    {
      "user_id": "uuid",
      "name": "Fatima Jamaah",
      "role": "jamaah",
      "channel": "fcm",
      "status": "sent"
    }
  ],
  "triggered_at": "2026-04-04T22:10:00Z"
}
```

### Escalation Levels
| Level | Channel | Trigger |
|-------|---------|---------|
| 1 | FCM Push | Primary — automatic |
| 2 | Twilio SMS | If FCM fails within 5s |
| 3 | Twilio WhatsApp | If SMS fails |
| 4 | Local Loopback | Non-production test only |

---

## POST /panic/acknowledge

### Success Response (200)
```json
{
  "success": true,
  "alert_id": "uuid",
  "status": "acknowledged",
  "acknowledged_by": "uuid-of-muthawif",
  "acknowledged_at": "2026-04-04T22:11:00Z"
}
```

---

## POST /panic/resolve

### Success Response (200)
```json
{
  "success": true,
  "alert_id": "uuid",
  "status": "resolved",
  "resolution": "false_alarm",
  "resolved_at": "2026-04-04T22:15:00Z"
}
```

## Related
- `docs/03_technical/api-contracts/panic-alert/request.md`
- `docs/03_technical/api-contracts/panic-alert/error.md`
