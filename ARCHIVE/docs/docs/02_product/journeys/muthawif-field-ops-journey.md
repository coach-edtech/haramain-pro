# Muthawif Field Ops Journey

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Journey for muthawif using the app during active pilgrimage trips.

## Journey Stages

### 1. Setup & Assignment
**Start**: Assigned to rombongan by agency
**End**: App configured, assigned to group

Steps:
1. Receive invitation notification
2. Install app (if not already)
3. Join as Muthawif role
4. View assignedrombongan members
5. Review group details (trip dates, passenger list)

### 2. Pre-Trip Preparation
**Start**: Days before trip
**End**: Ready for field operations

Steps:
1. View passenger list and contact info
2. Download offline maps (optional)
3. Test panic alert loopback (DX tools)
4. Receive trip briefing from agency

### 3. Active Trip Field Operations
**Start**: Arrival at Saudi Arabia / trip_start_at
**End**: Daily operations until departure

#### Morning Checklist
1. Check group status dashboard
2. View any overnight alerts
3. Send morning announcement

#### During Pilgrimage Activities
1. GPS tracking active for assigned group
2. Receive automatic prayer notifications
3. View nearby holy sites on map
4. Receive panic alerts instantly

#### Geofence-Triggered Content
When entering designated zones:
| Zone | Trigger |
|------|---------|
| Masjidil Haram | Mecca prayers |
| Ka'bah perimeter | Tawaf duas |
| Arafah | Wuquf duas |
| Mina | Jamarat prayers |
| Muzdalifah | Evening duas |
| Masjid Nabawi | Medina prayers |

### 4. Emergency Response
**Start**: Panic alert received
**End**: Situation resolved

Steps:
1. Push notification with pilgrim name + location
2. Tap to view pilgrim location on map
3. Call pilgrim directly (one tap)
4. Coordinate with agency
5. Mark alert resolved

### 5. Post-Trip Handover
**Start**: trip_end_at
**End**: Group archived

Steps:
1. Final group status check
2. Submit field report (optional)
3. View trip summary
4. Group moves to archive

## Related
- `docs/02_product/personas/muthawif.md`
- `docs/05_features/panic-alert/`
- `docs/05_features/virtual-muthawif/`
