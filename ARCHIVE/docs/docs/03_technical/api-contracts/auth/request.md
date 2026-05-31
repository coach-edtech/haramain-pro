# Auth API — Request Contracts

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Request formats for authentication and role management endpoints.

---

## POST /auth/request-otp

Request OTP for phone number authentication.

### Request
```json
{
  "phone": "+6281234567890",
  "purpose": "login"
}
```

### Fields
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `phone` | string | Yes | E.164 format (+62xxx) |
| `purpose` | string | Yes | "login" or "register" |

---

## POST /auth/verify-otp

Verify OTP and establish session.

### Request
```json
{
  "phone": "+6281234567890",
  "code": "123456"
}
```

### Fields
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `phone` | string | Yes | E.164 format |
| `code` | string | Yes | 6-digit OTP |

---

## POST /auth/assign-role

Assign role to user (admin only).

### Request
```json
{
  "user_id": "uuid-of-user",
  "role": "muthawif",
  "agency_id": "uuid-of-agency"
}
```

### Fields
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `user_id` | uuid | Yes | Target user |
| `role` | enum | Yes | "jamaah", "muthawif", "travel_admin", "sys_admin" |
| `agency_id` | uuid | Conditional | Required for travel_admin, muthawif |

### Notes
- **Role assignment** determines RLS access scope
- **Agency binding** links user to tenant context
- Claim propagation via Supabase JWT — role included in token

## Related
- `docs/03_technical/api-contracts/auth/response.md`
- `docs/03_technical/protocols/auth-role-model.md`
