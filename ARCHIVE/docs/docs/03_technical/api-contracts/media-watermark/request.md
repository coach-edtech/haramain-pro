# Media Watermark API — Request Contracts

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Request formats for media processing (watermark) endpoints.

---

## POST /media/upload

Upload and watermark a photo (typically for Jejak Ibadah).

### Request
```
Content-Type: multipart/form-data

file: [binary JPEG, max 10MB pre-compression]
rombongan_id: uuid (optional — required for watermark context)
lat: float (optional)
lng: float (optional)
activity_type: enum (optional) — prayer|dua|tawaf|visiting
performed_at: ISO8601 string (optional)
```

### Fields
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `file` | binary | Yes | JPEG image, max 10MB pre-compression |
| `rombongan_id` | uuid | No | Group context — affects watermark text |
| `lat` | float | No | GPS latitude |
| `lng` | float | No | GPS longitude |
| `activity_type` | enum | No | Type of spiritual activity |
| `performed_at` | string | No | When activity occurred |

### Notes
- **base64 image input** via multipart upload (not JSON body)
- **rombonganId** used for watermark — includes group name if available
- **group expired handling**: if romboangan_id is past trip_end_at, watermark still applied but "archive" suffix added
- Client should pre-compress to ~80% quality, max 2048px before upload

---

## POST /media/batch-upload

Batch upload multiple photos (queued sync).

### Request
```
Content-Type: multipart/form-data

files: [binary array, max 10 files]
rombongan_id: uuid
sync_token: string (from Isar queue)
```

## Related
- `docs/03_technical/api-contracts/media-watermark/response.md`
- `docs/03_technical/api-contracts/media-watermark/error.md`
