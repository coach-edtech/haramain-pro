# Panic Alert API — Error Contracts

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Error codes and responses for panic alert endpoints.

## Error Codes

| Code | HTTP Status | Meaning | Handling |
|------|-------------|---------|----------|
| `PANIC_SUBSCRIPTION_REQUIRED` | 403 | No active Safety Pass | Purchase or assign subscription |
| `PANIC_NO_LOCATION` | 400 | Cannot get GPS location | Enable location services |
| `PANIC_NOT_IN_GROUP` | 400 | User not in any active group | Join group first |
| `PANIC_ALREADY_ACTIVE` | 409 | Existing unacknowledged alert | Wait or resolve existing |
| `PANIC_INVALID_ALERT_ID` | 404 | Alert ID not found | Check alert_id |
| `PANIC_NOT_AUTHORIZED` | 403 | Not authorized to acknowledge | Only muthawif/admin can ack |
| `PANIC_FALLBACK_TRIGGERED` | 200 | FCM failed, fallback used | Monitor, not actionable |
| `AUTH_REQUIRED` | 401 | Not authenticated | Authenticate first |

## Notes on Twilio Fallback
- Fallback is **automatic** — triggered server-side if FCM delivery fails
- Client receives `PANIC_FALLBACK_TRIGGERED` in notification payload
- SMS/WhatsApp costs borne by platform (Antigravity)
- Loopback (level 4) is **test/non-production only**

## Error Response Shape
```json
{
  "error": {
    "code": "PANIC_SUBSCRIPTION_REQUIRED",
    "message": "An active Safety Pass is required to trigger panic alerts",
    "action": "purchase_safety_pass"
  }
}
```

## Related
- `docs/03_technical/api-contracts/panic-alert/request.md`
- `docs/03_technical/api-contracts/panic-alert/response.md`
