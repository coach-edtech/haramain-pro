# Auth API — Error Contracts

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Error codes and responses for authentication endpoints.

## Error Codes

| Code | HTTP Status | Meaning | Handling |
|------|-------------|---------|----------|
| `AUTH_OTP_EXPIRED` | 400 | OTP code has expired | Request new OTP |
| `AUTH_OTP_INVALID` | 400 | Incorrect OTP | Retry with correct code |
| `AUTH_PHONE_INVALID` | 400 | Phone format invalid | Validate E.164 format |
| `AUTH_SESSION_EXPIRED` | 401 | JWT expired | Re-authenticate |
| `AUTH_UNAUTHORIZED` | 403 | Not permitted to assign role | Check admin rights |
| `AUTH_ROLE_INVALID` | 400 | Unknown role | Use valid role enum |
| `AUTH_AGENCY_REQUIRED` | 400 | agency_id required for role | Include agency_id |

## Error Response Shape
```json
{
  "error": {
    "code": "AUTH_OTP_INVALID",
    "message": "The OTP code provided is incorrect",
    "details": {}
  }
}
```

## Related
- `docs/03_technical/api-contracts/auth/request.md`
- `docs/03_technical/api-contracts/auth/response.md`
