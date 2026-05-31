# Location History

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
GPS/location tracking data model for pilgrims.

## Tables

#### `public.location_history`
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | PK |
| `user_id` | UUID | FK → profiles |
| `rombongan_id` | UUID | FK → rombongans |
| `lat` | FLOAT | Latitude |
| `lng` | FLOAT | Longitude |
| `accuracy` | FLOAT | GPS accuracy in meters |
| `altitude` | FLOAT | Meters above sea level |
| `recorded_at` | TIMESTAMPTZ | When GPS was captured |
| `created_at` | TIMESTAMPTZ | When stored |

## Local Queue (Isar)
| Column | Type | Description |
|--------|------|-------------|
| `lat` | double | |
| `lng` | double | |
| `accuracy` | double | |
| `recorded_at` | int64 | Unix timestamp |
| `synced` | bool | |

## Retention Policy
| Phase | Retention | Action |
|-------|-----------|--------|
| During trip | All points kept | Real-time sync |
| 0–7 days post-trip | All points kept | For recovery |
| 7–30 days post-trip | Aggregated (hourly) | Storage optimization |
| 30+ days post-trip | Deleted | Per PDPL requirements |

## Privacy
- Location only collected with active consent (consent_location=true)
- User can view their own location history
- Muthawif can view anggota location (rombongan members only)
- RLS enforced at all access points

## Related
- `docs/03_technical/data-model/rombongan.md`
- `docs/02_product/compliance/pdpl-requirements.md`
