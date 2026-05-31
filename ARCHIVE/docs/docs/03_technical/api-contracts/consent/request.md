# Consent API — Request Contracts

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Request formats for consent management endpoints.

---

## POST /consent/submit

Submit initial consents during onboarding.

### Request
```json
{
  "consents": {
    "location": true,
    "media": true,
    "notification": true,
    "marketing": false
  }
}
```

### Fields
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `consents.location` | boolean | Yes | GPS tracking consent |
| `consents.media` | boolean | Yes | Photo/media collection consent |
| `consents.notification` | boolean | Yes | Push notification consent |
| `consents.marketing` | boolean | Yes | Alumni broadcast consent (separate) |

### Notes
- All fields required — no partial submissions
- Marketing consent is independent of core service
- Timestamp recorded server-side (client time ignored)

---

## POST /consent/withdraw

Withdraw previously granted consent.

### Request
```json
{
  "category": "marketing"
}
```

### Fields
| Field | Type | Description |
|-------|------|-------------|
| `category` | enum | "location" \| "media" \| "notification" \| "marketing" |

### Notes
- Withdrawal processed within 24 hours (PDPL SLA)
- Core consents (location, media, notification) affect feature availability
- Marketing withdrawal is immediate — opt-out honored instantly

---

## POST /deletion-request

Request full account and data deletion.

### Request
```json
{
  "reason": "no longer traveling",
  "confirm": true
}
```

### Fields
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `reason` | string | No | Optional reason for deletion |
| `confirm` | boolean | Yes | Must be true to process |

### Notes
- Deletion SLA: within 24 hours
- Removes all personal data from active tables
- Backup purging per retention policy

## Related
- `docs/03_technical/api-contracts/consent/response.md`
- `docs/03_technical/api-contracts/consent/error.md`
