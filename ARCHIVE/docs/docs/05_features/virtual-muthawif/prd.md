# Virtual Muthawif — PRD

> Owner: Openclaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Summary
Geofence-triggered contextual prayers and duas delivered based on pilgrim's GPS location.

## Goals
- Deliver spiritual guidance at the right moment and place
- Enhance pilgrimage experience with location-aware content
- Provide comfort and direction for pilgrims navigating unfamiliar sites

## Non-Goals
- Audio guidance (out of scope for MVP)
- AI-generated spiritual advice
- Video content

## User Stories
- As a pilgrim at Arafah, I want to receive the specific dua for Wuquf so I don't miss the most important moment
- As a pilgrim approaching the Ka'bah, I want a reminder of what to do during Tawaf

## Core Features
1. **Geofence Detection**: Detect when pilgrim enters holy site zones
2. **Content Delivery**: Push relevant prayers/duas based on location
3. **Local Repository**: Offline duas stored on device
4. **Background GPS**: Monitor location even when app is backgrounded

## Holy Sites Coverage
| Site | Prayer/Dua Content |
|------|-------------------|
| Masjidil Haram | Mecca prayer guidance |
| Ka'bah perimeter | Tawaf duas |
| Arafah | Wuquf duas |
| Mina | Jamarat prayers |
| Muzdalifah | Evening duas |
| Masjid Nabawi | Medina prayer guidance |

## Dependencies
- Background location permission
- Geofencing capability
- Local duas database

## Related
- `docs/05_features/virtual-muthawif/summary.md`
