# Consent API — Error Contracts

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Error codes and responses for consent management endpoints.

## Error Codes

| Code | HTTP Status | Meaning | Handling |
|------|-------------|---------|----------|
| `CONSENT_ALREADY_SUBMITTED` | 400 | Consent already recorded | No re-submission needed |
| `CONSENT_CATEGORY_INVALID` | 400 | Unknown consent category | Use valid category enum |
| `CONSENT_FIELD_MISSING` | 400 | Required consent field missing | Include all 4 categories |
| `CONSENT_WITHDRAW_INVALID` | 400 | Cannot withdraw non-granted consent | Check current state |
| `DELETION_ALREADY_PENDING` | 400 | Deletion request already in progress | Use existing request_id |
| `DELETION_CONFIRM_REQUIRED` | 400 | confirm field must be true | Re-submit with confirm: true |
| `AUTH_REQUIRED` | 401 | Not authenticated | Authenticate first |

## Error Response Shape
```json
{
  "error": {
    "code": "CONSENT_FIELD_MISSING",
    "message": "All consent categories must be provided",
    "missing_fields": ["location"]
  }
}
```

## Related
- `docs/03_technical/api-contracts/consent/request.md`
- `docs/03_technical/api-contracts/consent/response.md`
