# Broadcast API — Error Contracts

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Error codes and responses for alumni broadcast endpoints.

## Error Codes

| Code | HTTP Status | Meaning | Handling |
|------|-------------|---------|----------|
| `BROADCAST_TITLE_TOO_LONG` | 400 | Title exceeds 50 characters | Shorten title |
| `BROADCAST_BODY_TOO_LONG` | 400 | Body exceeds 200 characters | Shorten body |
| `BROADCAST_EMPTY_AUDIENCE` | 400 | No matching pilgrims in audience | Adjust filters |
| `BROADCAST_NO_CONSENT` | 400 | No users with marketing consent | Cannot send without consent |
| `BROADCAST_NOT_AGENCY` | 403 | Only agency admin can send broadcasts | Check user role |
| `BROADCAST_NOT_OWN_AGENCY` | 403 | Cannot broadcast to other agency's pilgrims | Restrict to own alumni |
| `BROADCAST_RATE_LIMIT` | 429 | Too many broadcasts (max 3/day) | Wait before next send |
| `AUTH_REQUIRED` | 401 | Not authenticated | Authenticate first |

## Notes on Marketing Consent
- Broadcast only sent to users with `consent_marketing = true`
- `without_consent` users are always filtered out — no workaround
- Consent check is at broadcast time (not send time — so users who withdraw mid-campaign don't receive)

## Error Response Shape
```json
{
  "error": {
    "code": "BROADCAST_NO_CONSENT",
    "message": "No users in the selected audience have granted marketing consent",
    "details": {
      "total_matching": 342,
      "with_consent": 0
    }
  }
}
```

## Related
- `docs/03_technical/api-contracts/broadcast/request.md`
- `docs/03_technical/api-contracts/broadcast/response.md`
