# Group API — Request Contracts

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Request formats for group (rombongan) management endpoints.

---

## POST /group/create

Create a new group (agency admin only).

### Request
```json
{
  "name": "Umrah April 2026 Batch 2",
  "trip_start_at": "2026-04-15T00:00:00+03:00",
  "trip_end_at": "2026-04-25T00:00:00+03:00"
}
```

### Fields
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Group display name |
| `trip_start_at` | ISO8601 | Yes | Trip start (Saudi time +03:00) |
| `trip_end_at` | ISO8601 | Yes | Trip end (Saudi time +03:00) |

### Notes
- **6-digit numeric PIN** auto-generated server-side
- **Active trip validation**: join only allowed before trip_start_at + 1 day grace period
- Agency context taken from JWT — no separate agency_id needed

---

## POST /group/join

Join a group using PIN (Jamaah).

### Request
```json
{
  "pin": "482193"
}
```

### Fields
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `pin` | string | Yes | 6-digit numeric PIN |

### Notes
- **B2B bypass logic**: agency can provision Jamaah directly without PIN (separate endpoint)
- PIN matching: exact 6-digit numeric string
- After trip starts: join blocked (grace period only)

---

## GET /group/{id}/members

Get members of a group (muthawif or agency admin).

### Path Parameters
| Param | Type | Description |
|-------|------|-------------|
| `id` | uuid | Rombongan ID |

---

## POST /group/b2b/invite

Direct invite without PIN (agency admin).

### Request
```json
{
  "user_id": "uuid-of-jamaah",
  "rombongan_id": "uuid"
}
```

### Notes
- **B2B bypass**: agency admin assigns Jamaah directly
- User must exist in platform
- No PIN exchange needed

## Related
- `docs/03_technical/api-contracts/group/response.md`
- `docs/03_technical/api-contracts/group/error.md`
