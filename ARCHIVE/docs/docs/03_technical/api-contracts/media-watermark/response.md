# Media Watermark API — Response Contracts

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Response formats for media processing endpoints.

---

## POST /media/upload

### Success Response (201 Created)
```json
{
  "success": true,
  "photo_id": "uuid",
  "original_url": "https://storage.supabase.co/photos/uuid/original.jpg",
  "watermarked_url": "https://storage.supabase.co/photos/uuid/watermarked.jpg",
  "thumbnail_url": "https://storage.supabase.co/photos/uuid/thumb.jpg",
  "watermark_applied": true,
  "processing_time_ms": 1234
}
```

### Response Fields
| Field | Description |
|-------|-------------|
| `photo_id` | Unique ID for the photo record |
| `original_url` | Raw upload URL (supabase storage) |
| `watermarked_url` | **Processed output URL** — with watermark |
| `thumbnail_url` | Small preview version |
| `watermark_applied` | True if watermark was applied |
| `processing_time_ms` | Server-side processing time |

### Notes
- **processed output URL** is what client should use for display
- Watermark includes: app logo + timestamp + location name + group name

---

## POST /media/batch-upload

### Success Response (200)
```json
{
  "success": true,
  "processed": 5,
  "failed": 0,
  "results": [
    {
      "original_filename": "img_001.jpg",
      "photo_id": "uuid",
      "watermarked_url": "https://...",
      "status": "success"
    }
  ],
  "sync_token_used": "token-string"
}
```

## Related
- `docs/03_technical/api-contracts/media-watermark/request.md`
- `docs/03_technical/api-contracts/media-watermark/error.md`
