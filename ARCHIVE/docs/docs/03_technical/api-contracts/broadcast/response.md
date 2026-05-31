# Broadcast API — Response Contracts

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Response formats for alumni broadcast endpoints.

---

## POST /broadcast/send

### Success Response (202 Accepted)
```json
{
  "success": true,
  "broadcast_id": "uuid",
  "status": "queued",
  "audience": {
    "total": 298,
    "push_enabled": 276,
    "without_consent": 22
  },
  "sent": 0,
  "scheduled_at": null,
  "created_at": "2026-04-04T22:10:00Z"
}
```

### Processing Notes
- Broadcast is queued and processed asynchronously
- Only users with `consent_marketing = true` receive the notification
- `without_consent` count shown but这些人不会收到

---

## GET /broadcast/{id}/status

Get broadcast delivery status.

### Success Response (200)
```json
{
  "broadcast_id": "uuid",
  "status": "completed",
  "audience": {
    "queued": 298,
    "sent": 276,
    "delivered": 268,
    "failed": 8,
    "no_consent_filtered": 22
  },
  "completed_at": "2026-04-04T22:11:00Z"
}
```

### Delivery Stats
| Metric | Description |
|--------|-------------|
| `queued` | Total targeted (with consent) |
| `sent` | FCM send attempted |
| `delivered` | Confirmed by FCM |
| `failed` | FCM delivery failed |

---

## GET /broadcast/audience/preview

### Success Response (200)
```json
{
  "total_matching": 342,
  "with_consent": 298,
  "without_consent": 44,
  "push_enabled": 276
}
```

## Related
- `docs/03_technical/api-contracts/broadcast/request.md`
- `docs/03_technical/api-contracts/broadcast/error.md`
