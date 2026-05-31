# Edge Media Processing

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Detailed specification for server-side media processing (compression, watermarking).

## Edge Function: `/media/watermark`

Runs in Supabase Edge Functions (Deno runtime).

## Processing Pipeline

```
Client Upload (multipart)
        │
        ▼
┌───────────────────┐
│  Validate File    │ ← Type (JPEG only), size (<10MB)
└────────┬──────────┘
         │
         ▼
┌───────────────────┐
│  Decompress to   │ ← Temporarily load into memory
│  Memory          │
└────────┬──────────┘
         │
         ▼
┌───────────────────┐
│  Apply Watermark │ ← Composite logo + text overlay
└────────┬──────────┘
         │
         ▼
┌───────────────────┐
│  Compress Output │ ← Re-encode as JPEG (quality: 85%)
└────────┬──────────┘
         │
         ▼
┌───────────────────┐
│  Upload to        │ ← Supabase Storage (authenticated URL)
│  Supabase Storage │
└────────┬──────────┘
         │
         ▼
Return processed URL
```

## Compression

### Input
- Format: JPEG only
- Max size: 10MB (pre-compression)
- Client pre-compresses to ~80% quality, max 2048px

### Output
- Format: JPEG
- Quality: 85%
- Max dimension: 2048px (preserve aspect ratio)

## Watermark Compositing

### Watermark Elements
| Element | Position | Style |
|---------|-----------|--------|
| App Logo | Bottom-right corner | 80x80px, 60% opacity |
| Timestamp | Above logo | "Apr 4, 2026 · 10:30 AM" |
| Location Name | Above timestamp | "Masjidil Haram, Mecca" |

### Logo Constraints
- App logo: `public/watermark-logo.png` (bundled with edge function)
- Size: 80x80px max
- Background: transparent

### Memory Limits
- Deno Edge Function memory limit: 512MB
- Max image dimension: 4096px
- If exceeded: reject with `MEDIA_PROCESSING_FAILED`

### Storage Upload Flow
```
1. Edge function generates pre-authenticated upload URL
2. Client uploads directly to Supabase Storage (not through function)
3. Edge function returns processed URL
```

### Group Expired Handling
If `rombongan_id` is past `trip_end_at`:
- Watermark still applied
- "Archived Trip" suffix added to location text
- Processed normally (no special error)

## Error Handling

| Error | Cause | Response |
|-------|-------|----------|
| `MEDIA_INVALID_FORMAT` | Not JPEG | 400 + error code |
| `MEDIA_FILE_TOO_LARGE` | >10MB | 413 + error code |
| `MEDIA_PROCESSING_FAILED` | Memory/timeout | 500 + retry hint |
| `MEDIA_STORAGE_FULL` | Quota exceeded | 507 + contact support |

## Performance

### Benchmarks (typical)
| Image Size | Processing Time |
|-----------|-----------------|
| 1MB JPEG | ~300ms |
| 5MB JPEG | ~800ms |
| 9MB JPEG | ~1500ms |

### Timeout
- Edge function timeout: 30 seconds
- If exceeded: return error, client can retry

## Related
- `docs/03_technical/api-contracts/media-watermark/`
- `docs/03_technical/architecture/edge-functions.md`
