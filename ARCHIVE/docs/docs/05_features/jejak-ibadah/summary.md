# Jejak Ibadah — Summary

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Feature Summary

| Aspect | Detail |
|--------|--------|
| Feature | Jejak Ibadah (Spiritual Activity Trail) |
| Owner | OpenClaw (starter), Onyx (refinement) |
| Priority | P1 |
| Status | Implementation pending |

## What It Does
Records and timestamps spiritual activities (prayers, duas, visits) with photo evidence and watermarks, creating a personal pilgrimage journal.

## Activity Types
- Prayer (fard, sunnah, tawaf, etc.)
- Dua (supplication)
- Tawaf (circumambulation of Ka'bah)
- Sa'i (walking between Safa and Marwa)
- Wuquf (standing at Arafah)
- Visiting (ziyarat to holy sites)

## Key Specs
- **Photo**: Compressed to 80%, watermarked, max 2MB
- **Location**: GPS coordinates captured automatically
- **Offline**: Queued in Isar, sync on reconnect
- **Storage**: Local first, with circuit breaker

## Sync Flow
1. User taps "Log Activity"
2. Select type + optional photo
3. GPS + timestamp auto-captured
4. Watermark applied to photo
5. Saved to Isar queue
6. Sync to Supabase when online

## Related
- `docs/02_product/personas/pilgrim.md`
- `docs/03_technical/data-model/jejak-ibadah.md`
- `docs/03_technical/protocols/photo-sync-flow.md`
