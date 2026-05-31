# Media Watermark API — Error Contracts

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Error codes and responses for media processing endpoints.

## Error Codes

| Code | HTTP Status | Meaning | Handling |
|------|-------------|---------|----------|
| `MEDIA_FILE_TOO_LARGE` | 413 | File exceeds 10MB pre-compression limit | Compress before upload |
| `MEDIA_INVALID_FORMAT` | 400 | Not a valid JPEG | Convert to JPEG |
| `MEDIA_PROCESSING_FAILED` | 500 | Watermark processing failed | Retry, report if persistent |
| `MEDIA_GROUP_EXPIRED` | 200 | Group past trip_end_at | Warn user, apply archive watermark |
| `MEDIA_STORAGE_FULL` | 507 | Supabase storage quota exceeded | Contact support |
| `MEDIA_BATCH_TOO_MANY` | 400 | Exceeds max 10 files per batch | Split into smaller batches |
| `AUTH_REQUIRED` | 401 | Not authenticated | Authenticate first |

## Notes on Group Expired Handling
When `rombongan_id` is past `trip_end_at`:
- Watermark still applied (user's memory is valid)
- "Archived Trip" suffix added to watermark text
- No access to non-expired group data

## Error Response Shape
```json
{
  "error": {
    "code": "MEDIA_FILE_TOO_LARGE",
    "message": "Image exceeds maximum size of 10MB",
    "details": {
      "actual_size_mb": 12.3,
      "max_size_mb": 10
    }
  }
}
```

## Related
- `docs/03_technical/api-contracts/media-watermark/request.md`
- `docs/03_technical/api-contracts/media-watermark/response.md`
