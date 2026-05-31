# Auth API — Response Contracts

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Response formats for authentication endpoints.

---

## POST /auth/request-otp

### Success Response (200)
```json
{
  "success": true,
  "message": "OTP sent to +6281234567890",
  "expires_at": "2026-04-04T22:10:00Z"
}
```

---

## POST /auth/verify-otp

### Success Response (200)
```json
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "user": {
    "id": "uuid",
    "phone": "+6281234567890",
    "role": "jamaah",
    "agency_id": null,
    "profile_complete": false
  },
  "expires_in": 3600
}
```

### JWT Claims
| Claim | Description |
|-------|-------------|
| `sub` | User UUID |
| `role` | "jamaah" \| "muthawif" \| "travel_admin" \| "sys_admin" |
| `agency_id` | Tenant ID (null for individual Jamaah) |
| `exp` | Token expiry |

---

## POST /auth/assign-role

### Success Response (200)
```json
{
  "success": true,
  "user_id": "uuid",
  "role": "muthawif",
  "agency_id": "uuid"
}
```

## Related
- `docs/03_technical/api-contracts/auth/request.md`
- `docs/03_technical/api-contracts/auth/error.md`
