# 005 — Mapbox Offline Storage Limit: 300MB

> Owner: OpenClaw
> Status: Approved
> Note: Starter content — based on master doc direction.

## Decision
Limit offline map tile storage to **300MB per device** to balance functionality with device storage constraints.

## Rationale
- Mobile devices have limited storage
- 300MB provides meaningful coverage (Mecca + Medina core areas)
- Prevents app from being flagged as "large app" in stores
- Aligns with typical pilgrim device storage capacity

## Implementation

### Tile Caching Strategy
1. **Pre-download bundles** — Mecca region, Medina region
2. **On-demand tiles** — user can manually cache specific areas
3. **LRU eviction** — least-recently used tiles removed first

### Storage Allocation
| Region | Estimated Size |
|--------|---------------|
| Mecca (core Hajj areas) | ~150MB |
| Medina (core areas) | ~100MB |
| Remaining | ~50MB (flexible) |

### Circuit Breaker
- If device storage <500MB free: disable offline maps auto-download
- If user manually deletes: re-download requires WiFi only
- Total cache never exceeds 300MB enforced

## Mapbox Integration
- Style: `mapbox://styles/mapbox/satellite-streets-v11`
- Offline: Mapbox offline plugin with vector tiles
- Attribution required in app

## Related
- `docs/05_features/offline-maps/`
- `docs/03_technical/data-model/local-storage.md`
