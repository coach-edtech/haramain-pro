# Jejak Ibadah

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Spiritual activity logging (jejak ibadah) data model.

## Tables

#### `public.jejak_ibadah`
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | PK |
| `user_id` | UUID | FK → profiles |
| `rombongan_id` | UUID | FK → rombongans (nullable) |
| `type` | ENUM | 'prayer', 'dua', 'tawaf', 'sa'i', 'wuquf', 'visiting' |
| `location_lat` | FLOAT | Latitude |
| `location_lng` | FLOAT | Longitude |
| `location_name` | TEXT | Place name (optional) |
| `photo_url` | TEXT | Supabase storage URL |
| `photo_watermarked` | BOOLEAN | Watermark applied |
| `performed_at` | TIMESTAMPTZ | When the activity occurred |
| `notes` | TEXT | Optional user notes |
| `created_at` | TIMESTAMPTZ | Record creation |
| `synced_at` | TIMESTAMPTZ | When synced to server |

## Offline Queue (Isar)
| Column | Type | Description |
|--------|------|-------------|
| `local_id` | Auto | Isar auto-increment |
| `type` | ENUM | Same as above |
| `location_lat` | FLOAT | |
| `location_lng` | FLOAT | |
| `photo_local_path` | TEXT | Local file path |
| `performed_at` | INT64 | Unix timestamp |
| `synced` | BOOLEAN | |
| `synced_at` | INT64 | Nullable |

## Sync Flow
1. User logs jejak ibadah → saved to Isar queue
2. Photo compressed (80% quality, max 2MB)
3. Watermark applied locally
4. On reconnect: upload photo → create record
5. Mark synced=true, update synced_at

## Related
- `docs/05_features/jejak-ibadah/`
- `docs/03_technical/data-model/local-storage.md`
