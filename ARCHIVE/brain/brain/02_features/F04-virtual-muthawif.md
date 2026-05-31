# Feature Brief: Virtual Muthawif (Location-Contextual Prayer Surfacing)

_Feature ID: F-04_
_Status: Draft_
_Date: 2026-04-04_
_Author: OpenClaw (extracted from PRD)_

---

## 1. Problem Statement

Pilgrims often don't know which prayers to read, what dua to make, or what they're supposed to do at specific locations (e.g., near Ka'bah, Sa'i, Raudhah). Having a physical Muthawif is ideal, but pilgrims may be alone or separated from their group.

---

## 2. Goal

When a pilgrim's device detects proximity to predefined sacred geographic boundaries:
- Automatically surface the relevant contextual prayer text
- Display in Arabic, Latin transliteration, AND local translation (Indonesian)
- Trigger audio recitation optionally
- Work offline (prayer content pre-cached)

---

## 3. User Flow

```
Pilgrim walks with GPS active
       ↓
Device detects proximity to geofenced location
       ↓
Auto-trigger: "You're approaching [Location Name]"
       ↓
Surface prayer / dua content for that location
       ↓
Show in 3 languages: Arabic + Latin + Indonesian
       ↓
Optional: Play audio recitation
       ↓
Content auto-dismisses when leaving geofence OR user dismisses
```

---

## 4. Scope

### In Scope
- Geofence detection for key sacred locations
- Prayer/dua content display (Arabic + Latin + ID translation)
- Auto-surfacing on proximity
- Offline content caching (no network required to display)
- Audio recitation option (offline-cached)
- Manual location-based content lookup (search list of locations)

### Out of Scope
- Turn-by-turn navigation to location
- Historical/educational content beyond prayers
- AI-generated prayers (static curated content)
- Auto-play audio without user interaction

---

## 5. Geofenced Locations (Phase 1 MVP)

| Location | Arabic Name | Trigger Radius |
|----------|-------------|----------------|
| Ka'bah (Masjid Al-Haram) | الكعبة | 500m |
| Safa & Marwa (Sa'i) | الصفا والمروة | 200m |
| Raudhah (Rawdah) | الروضة | 100m (restricted access) |
| Mina (Jamarat) | منى | 300m |
| Arafat | عرفة | 500m |
| Muzdalifah | مزدلفة | 300m |

---

## 6. Content Structure

Each location has:
```
Location: {
  name: string (EN/ID)
  arabicName: string
  coordinates: { lat, lng }
  triggerRadius: number (meters)
  prayers: [
    {
      title: string,
      arabic: string,
      latin: string,
      translation: string (ID),
      audioFile?: string (local path)
    }
  ],
  notes?: string (contextual info)
}
```

---

## 7. Acceptance Criteria

- [ ] When device enters geofence radius, prayer content auto-surfaces within 3 seconds
- [ ] Content displays in Arabic, Latin, and Indonesian simultaneously
- [ ] Works completely offline (content pre-cached)
- [ ] Audio recitation plays if user taps (not auto-play)
- [ ] Geofence triggers work in background (app minimized)
- [ ] User can manually browse all locations and their prayers
- [ ] Notification shown when approaching location (even if app closed)

---

## 8. Edge Cases

| Case | Handling |
|------|----------|
| Multiple geofences overlap | Show content for most "sacred" priority (Ka'bah > others) |
| User in Raudhah (restricted access) | Special note: "Raudhah access requires permit" |
| GPS inaccurate (canyon effect) | Use last reliable location with "approximate" indicator |
| Audio file missing | Hide audio button, show text only |
| Conflicting notifications | Queue, don't stack |

---

## 9. Technical Notes

**Geofencing:**
- Use `geofence_flutter` or native geofencing
- Background location updates required (battery optimization exception needed)
- Use ` Geofence.initialize()` with radius and callbacks

**Offline Content:**
- Bundle prayer content as JSON in app assets
- Audio files stored locally (MP3/OGG, compressed)
- ~50-100MB estimated for full audio library (optional download)

**Content Update:**
- When online, check for content updates
- Download new prayers/locations as JSON patch

---

## 10. Dependencies

- Geolocator plugin (background location)
- Geofence plugin (Flutter)
- Local asset bundle (prayers JSON)
- Optional: Audio player plugin (audioplayers)
- Notification permission (for background alerts)

---

## 11. Related PRD References

- PRD-15: Virtual Muthawif detects proximity → surfaces contextual prayer
- PRD-63: Success signal — prayer library surfaces correctly

---

## 12. Questions Open

1. Should audio auto-download or be bundled in initial install? (App size impact)
2. How often should content be updated? (Monthly, per-holy-season?)
3. Should there be a "Muthawif chat" fallback (AI chatbot) for questions beyond prayers?
4. Priority of overlapping geofences — is there a canonical ranking?
5. Should the app show notification when approaching even if app is killed (background service)?

