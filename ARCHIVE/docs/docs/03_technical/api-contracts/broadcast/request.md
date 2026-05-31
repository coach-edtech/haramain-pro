# Broadcast API — Request Contracts

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Request formats for alumni broadcast endpoints.

---

## POST /broadcast/send

Send a broadcast notification to alumni (agency admin).

### Request
```json
{
  "title": "Umrah Season 2027 - Early Bird Offer!",
  "body": "Special discounts for returning pilgrims...",
  "audience": {
    "trip_date_from": "2025-01-01",
    "trip_date_to": "2025-12-31",
    "exclude_converted": true
  },
  "scheduled_at": null
}
```

### Fields
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | string | Yes | Notification title (max 50 chars) |
| `body` | string | Yes | Notification body (max 200 chars) |
| `audience.trip_date_from` | date | No | Filter: trips from date |
| `audience.trip_date_to` | date | No | Filter: trips to date |
| `audience.exclude_converted` | boolean | No | Exclude already-converted pilgrims |
| `scheduled_at` | ISO8601 | No | Send immediately if null |

### Notes
- **audience selection**: pilgrims filtered by agency + trip date range
- **marketing consent requirement**: only pilgrims with `consent_marketing = true` receive broadcast
- **send request concept**: FCM batch send to matching device tokens

---

## GET /broadcast/audience/preview

Preview audience size before sending.

### Request Query Params
```
?trip_date_from=2025-01-01&trip_date_to=2025-12-31
```

### Response
```json
{
  "total_matching": 342,
  "with_consent": 298,
  "without_consent": 44,
  "push_enabled": 276
}
```

## Related
- `docs/03_technical/api-contracts/broadcast/response.md`
- `docs/03_technical/api-contracts/broadcast/error.md`
