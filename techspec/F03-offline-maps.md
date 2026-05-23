# Tech Spec: F03 — Offline Maps (OSM)

_Source: PRD v1.10-FINAL Section 3.3.3_
_Status: PENDING — OSM Self-Hosted Tiles_

---

## Overview

Offline maps allow Jamaah to navigate without internet in Saudi Arabia. Uses **OpenStreetMap (OSM) self-hosted tiles** — NOT Mapbox.

**Cost Elimination:** OSM is open source. Self-hosted tile server costs ~Rp 500rb-1jt/month for bandwidth + storage. No per-tile licensing fees.

---

## Architecture

```
┌─────────────────────────────────────────────┐
│  Flutter App                                │
│  ┌─────────────┐    ┌──────────────────┐   │
│  │ MapView     │    │ Tile Cache       │   │
│  │ (flutter_map)   │ │ (flutter_map)    │   │
│  └──────┬──────┘    └────────┬─────────┘   │
│         │                     │              │
│         │  tile URLs          │ fallback     │
│         ▼                     ▼              │
│  ┌─────────────────────────────────────┐    │
│  │     OSM Tile Server (Self-Hosted)   │    │
│  │     https://tiles.haramain.pro/     │    │
│  └─────────────────────────────────────┘    │
└─────────────────────────────────────────────┘
```

---

## Technology Stack

| Component | Choice |
|-----------|--------|
| Map Widget | `flutter_map` (Flutter) + `flutter_map_Tile_caching` |
| Tile Source | OSM tiles via self-hosted tile server |
| Tile Server | Nominatim + custom tile rendering |
| Tile Caching | flutter_map_Tile_caching plugin |

---

## User Flow

### Download Map Region
```
Jamaah opens app → Offline Maps section
       ↓
Select region: Makkah / Madinah / All
       ↓
Shows estimated size (e.g., "45 MB")
       ↓
[Download] → background download
       ↓
Progress shown
       ↓
Stored in app cache
```

### Use Offline Map
```
Jamaah offline (no signal)
       ↓
Opens map → loads from cache automatically
       ↓
Shows: GPS location, nearby POIs, duas
       ↓
Works in airplane mode
```

---

## POI Categories

| Category | Data Source | Cached |
|----------|-------------|--------|
| Masjidil Haram | OSM + manual | Yes |
| Masjid Nabawi | OSM + manual | Yes |
| Hotels | OSM + travel input | Yes |
| Restaurants | OSM | Yes |
| Hospitals | OSM | Yes |
| Transportation hubs | OSM | Yes |

---

## Tile Server Infrastructure

**Self-hosted OSM tile server:**
- Domain: `tiles.haramain.pro` (example)
- Software: OSM tile server (mod_tile + renderd)
- Mapnik rendering
- Pre-render popular zoom levels (z10-z16)

**Cost Estimate:**
- Server: ~Rp 500rb-1jt/month (self-hosted or VPS)
- Bandwidth: ~Rp 200rb-500rb/month
- Total: ~Rp 700rb-1.5jt/month

vs Mapbox: ~$0.005/tile = ~Rp 80/tile × 1jt tiles = Rp 80jt/month

---

## Database Schema

### `offline_map_regions`

```sql
CREATE TABLE offline_map_regions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  city VARCHAR(50) NOT NULL,
  -- 'makkah' | 'madinah' | 'all'
  bbox_lat_min DECIMAL(10, 8),
  bbox_lng_min DECIMAL(11, 8),
  bbox_lat_max DECIMAL(10, 8),
  bbox_lng_max DECIMAL(11, 8),
  tile_count INTEGER,
  size_mb INTEGER,
  is_preloaded BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### `offline_map_downloads` (user tracking)

```sql
CREATE TABLE offline_map_downloads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  region_id UUID REFERENCES offline_map_regions(id),
  downloaded_at TIMESTAMPTZ DEFAULT NOW(),
  size_mb INTEGER
);
```

---

## API Endpoints

### GET /maps/regions
List available offline regions.

```json
// Response
{
  "regions": [
    {
      "id": "uuid",
      "name": "Makkah",
      "city": "makkah",
      "size_mb": 45,
      "tile_count": 12500,
      "is_preloaded": true
    }
  ]
}
```

### GET /maps/tiles/{z}/{x}/{y}.png
Tile server endpoint (internal only).

---

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| **OSM NOT Mapbox** | Cost elimination — no per-tile licensing |
| Self-hosted tiles | Full control, no third-party dependency |
| Pre-render common zoom levels | Fast load, less server compute |
| POI overlay from OSM | Free, editable, community maintained |

---

## Edge Cases

| Case | Handling |
|------|----------|
| Download interrupted | Resume support — track downloaded tiles |
| Storage full | Warn user, suggest deleting old regions |
| GPS unavailable | Show cached location, don't block map |
| Server down | Fall back to cached tiles only |

---

## Dependencies

- Flutter map + tile caching plugin
- OSM tile server infrastructure
- Storage space on device (warn if < 500MB)
- GPS for location tracking

---

## Related Modules

- [F02](F02-panic-button.md): Panic uses map for location display
- [DB](DB-schema.md): offline_map_regions, offline_map_downloads
- [00-overview](../00-overview.md): Architecture context

---

_Maintained by: Hermes (CTO)_
_Last Updated: 2026-05-02 (v1.10-FINAL)_
