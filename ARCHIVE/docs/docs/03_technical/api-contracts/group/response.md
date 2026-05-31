# Group API — Response Contracts

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Response formats for group management endpoints.

---

## POST /group/create

### Success Response (201 Created)
```json
{
  "success": true,
  "rombongan": {
    "id": "uuid",
    "name": "Umrah April 2026 Batch 2",
    "pin_code": "482193",
    "trip_start_at": "2026-04-15T00:00:00+03:00",
    "trip_end_at": "2026-04-25T00:00:00+03:00",
    "status": "planning",
    "created_at": "2026-04-04T22:10:00Z"
  },
  "share_url": "https://app.haramain.pro/join/482193"
}
```

---

## POST /group/join

### Success Response (200)
```json
{
  "success": true,
  "rombongan": {
    "id": "uuid",
    "name": "Umrah April 2026 Batch 2",
    "trip_start_at": "2026-04-15T00:00:00+03:00",
    "trip_end_at": "2026-04-25T00:00:00+03:00",
    "status": "planning",
    "my_role": "jamaah"
  },
  "member_since": "2026-04-04T22:12:00Z"
}
```

### Member Roles in Response
| Role | Description |
|------|-------------|
| `jamaah` | Regular pilgrim member |
| `muthawif` | Assigned guide |
| `lead` | Group lead |

---

## GET /group/{id}/members

### Success Response (200)
```json
{
  "rombongan_id": "uuid",
  "rombongan_name": "Umrah April 2026 Batch 2",
  "members": [
    {
      "user_id": "uuid",
      "name": "Ahmad Fauzi",
      "role": "muthawif",
      "joined_at": "2026-04-01T10:00:00Z"
    },
    {
      "user_id": "uuid",
      "name": "Fatimah Zahra",
      "role": "jamaah",
      "joined_at": "2026-04-04T22:12:00Z"
    }
  ]
}
```

---

## POST /group/b2b/invite

### Success Response (200)
```json
{
  "success": true,
  "user_id": "uuid",
  "rombongan_id": "uuid",
  "role": "jamaah",
  "invited_at": "2026-04-04T22:15:00Z"
}
```

## Related
- `docs/03_technical/api-contracts/group/request.md`
- `docs/03_technical/api-contracts/group/error.md`
