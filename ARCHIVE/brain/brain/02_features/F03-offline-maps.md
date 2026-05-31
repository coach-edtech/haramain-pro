# Feature Brief: Offline Maps

_Feature ID: F-03_
_Status: Draft_
_Date: 2026-04-04_
_Author: OpenClaw (extracted from PRD)_

---

## 1. Problem Statement

Pilgrims navigate in areas with unreliable or nonexistent internet connectivity (Metro tunnels, dense crowds, interior of mosques). Without offline maps, GPS tracking and navigation become useless exactly when needed most.

---

## 2. Goal

- Cache Mapbox offline map tiles covering Makkah and Madinah city limits
- Limit storage footprint to maximum 300MB
- Enable GPS tracking and location display even without connectivity
- Support display of panic alert locations from Muthawif perspective

---

## 3. User Flow

```
First launch (or manual trigger)
       ↓
Check: Are offline maps downloaded?
       ↓
If NO:
  Prompt user: "Download offline maps for Makkah & Madinah (300MB)"
       ↓
User confirms → Download starts (background)
       ↓
Progress indicator shown
       ↓
Maps ready for offline use
       ↓
GPS location tracked and displayed on offline map
```

---

## 4. Scope

### In Scope
- Mapbox SDK integration for offline tile caching
- Makkah + Madinah city boundary coverage
- Maximum 300MB storage constraint
- Download progress UI
- Offline GPS location display
- Automatic tile cache management (purge old tiles)
- Developer menu coordinate injection (GPS spoofing for testing)

### Out of Scope
- Turn-by-turn navigation (display only, no routing)
- Other cities / regions
- Manual map region selection
- Offline search (text search requires connectivity)

---

## 5. Acceptance Criteria

- [ ] Total offline map size does NOT exceed 300MB
- [ ] Maps render correctly without internet connection
- [ ] User location (blue dot) displays on offline map
- [ ] Download can proceed in background
- [ ] Progress indicator shows download status
- [ ] Graceful handling if storage insufficient
- [ ] GPS coordinates captured even when offline (for panic button)
- [ ] Developer menu allows coordinate injection (DEV/TEST ONLY — PRD-85)

---

## 6. Map Regions

| Region | Coverage | Estimated Size |
|--------|----------|----------------|
| Makkah (Masjid Al-Haram + surrounding) | ~15km radius | ~180MB |
| Madinah (Masjid An-Nabawi + surrounding) | ~10km radius | ~120MB |
| **Total** | | **~300MB max** |

---

## 7. Technical Notes

**Mapbox SDK:**
- Use `Mapbox离线包` / offline tile API
- Pre-generate offline tile packs for Makkah + Madinah
- Store in app's document directory (not external SD card dependency)
- Use `mapbox_gl` or `flutter_map` with offline plugin

**Storage Management:**
- Monitor tile cache size
- Auto-purge tiles older than 6 months
- User can manually delete offline maps from Settings

**GPS:**
- Use `geolocator` package
- Cache last known location (max 30 days per PDPL)
- Works offline using last cached satellite/A-GPS data

---

## 8. Dependencies

- Mapbox SDK account + API token
- Mapbox offline tile packs for Makkah/Madinah
- Geolocator plugin (Flutter)
- Local storage management (path_provider)

---

## 9. Related PRD References

- PRD-11: Must cache Mapbox offline tiles for Makkah/Madinah
- PRD-12: Storage footprint max 300MB
- PRD-59-63: GPS Spoofing Simulator (DX test feature)
- PRD-85: GPS Spoofing Simulator must be stripped from production

---

## 10. Production Safety

⚠️ **GPS Spoofing Simulator (coordinate injection) must be HARD-DISABLED in production.** Per PRD-85, this feature is restricted to local and pre-production builds only.

---

## 11. Questions Open

1. Should tiles be pre-bundled in the app binary (reduces first-launch download) or downloaded on demand?
2. Should there be a "update maps" check when connectivity is available?
3. What is the tile expiration policy? (How old can tiles be before requiring refresh?)
4. Should map language default to Arabic, Latin transliteration, or Indonesian?

