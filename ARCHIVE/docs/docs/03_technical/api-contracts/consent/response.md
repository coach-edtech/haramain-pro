# Consent API — Response Contracts

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Response formats for consent management endpoints.

---

## POST /consent/submit

### Success Response (200)
```json
{
  "success": true,
  "consents": {
    "location": true,
    "media": true,
    "notification": true,
    "marketing": false
  },
  "consented_at": "2026-04-04T22:10:00Z",
  "trial_started": true,
  "trial_expires_at": "2026-04-11T22:10:00Z"
}
```

### Response Fields
| Field | Description |
|-------|-------------|
| `consents` | Current consent state |
| `consented_at` | Server timestamp |
| `trial_started` | True if this is first consent submission |
| `trial_expires_at` | 7 days from consent submission |

---

## POST /consent/withdraw

### Success Response (200)
```json
{
  "success": true,
  "category": "marketing",
  "withdrawn_at": "2026-04-04T22:15:00Z",
  "effects": [
    "Alumni broadcast opt-out applied"
  ]
}
```

### Effects by Category
| Category | Effect |
|----------|--------|
| `location` | GPS tracking disabled, latest location anonymized |
| `media` | Future photos not collected |
| `notification` | Push disabled, FCM token removed |
| `marketing` | Immediately excluded from broadcasts |

---

## POST /deletion-request

### Success Response (202 Accepted)
```json
{
  "success": true,
  "request_id": "uuid",
  "status": "pending",
  "estimated_completion": "2026-04-05T22:10:00Z",
  "message": "Deletion request received. You will be notified upon completion."
}
```

## Related
- `docs/03_technical/api-contracts/consent/request.md`
- `docs/03_technical/api-contracts/consent/error.md`
