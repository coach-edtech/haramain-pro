# Offline Maps — PRD

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Summary
Pre-downloaded Mapbox tiles enabling navigation without internet in Mecca and Medina.

## Goals
- Enable pilgrims to navigate sacred sites without data connection
- Reduce anxiety about getting lost
- Provide seamless experience in low-connectivity areas

## Non-Goals
- Full GPS navigation turn-by-turn (out of scope)
- Offline search (requires internet)
- Traffic or live data

## User Stories
- As a pilgrim, I want to view maps offline so I can navigate without burning data
- As a pilgrim, I want pre-downloaded Mecca/Medina maps so I'm prepared before my trip

## Core Features
1. **Region Download**: Download map tiles for Mecca and Medina regions
2. **Storage Management**: Display download size, allow deletion
3. **Auto-Update**: Refresh tiles when online (monthly)
4. **Storage Circuit Breaker**: Auto-cleanup if device storage low

## Key Metrics
- Offline map load time: <2 seconds
- Storage limit: 300MB per device
- Supported regions: Mecca, Medina

## Dependencies
- Mapbox account + access token
- Sufficient device storage

## Related
- `docs/05_features/offline-maps/summary.md`
