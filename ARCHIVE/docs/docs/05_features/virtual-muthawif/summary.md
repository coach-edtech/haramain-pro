# Virtual Muthawif — Summary

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Feature Summary

| Aspect | Detail |
|--------|--------|
| Feature | Virtual Muthawif |
| Owner | OpenClaw (starter), Onyx (refinement) |
| Priority | P1 |
| Status | Implementation pending |

## What It Does
Delivers geofence-triggered prayers and duas when pilgrims enter designated holy sites in Mecca and Medina.

## Key Specs
- **Trigger**: GPS geofence entry (50-200m radius)
- **Content**: Local repository of Arabic + Indonesian duas
- **Mode**: Background GPS aware
- **Offline**: Yes, works without internet

## Implementation Path
1. Define geofence boundaries for holy sites
2. Background location service
3. Geofence event detection
4. Local duas database (JSON)
5. Notification + in-app display

## Geofence Zones
- Masjidil Haram (Mecca)
- Ka'bah perimeter
- Arafah
- Mina (Jamarat)
- Muzdalifah
- Masjid Nabawi (Medina)

## Content Requirements
- ~50 duas covering major pilgrimage moments
- Arabic text + Indonesian translation
- Audio optional (future)

## Related
- `docs/02_product/journeys/b2c-pilgrim-journey.md`
- `docs/06_decisions/003-offline-first-strategy.md`
