# Tech Spec: F02 — Panic Button

_Source: PRD v1.10-FINAL Section 3.1.2_
_Status: UPDATED — Dual Responder + Team-Support_

---

## Overview

Panic Button allows Jamaah to send emergency alert with one tap. GPS location auto-attaches. Alert goes to BOTH Muthawif AND Team-Support. Both can respond.

---

## Flow

```
Jamaah presses Panic Button (any screen, works in silent mode)
       ↓
GPS location captured
       ↓
Panic Alert created: { lat, lng, timestamp, jamaa_id, trip_id }
       ↓
FCM push sent to:
  - Muthawif of this trip (travel_id scoped)
  - Team-Support (all support accounts)
       ↓
Alert shown on Muthawif app + Support dashboard
       ↓
Responder selects:
  A) "Stay, saya jemput" (no location shared)
  B) "Saya di sini" (sends responder location to Jamaah)
       ↓
Jamaah receives response
       ↓
Alert auto-deactivates H+1 after return date
       ↓
Re-activates via: new trip OR Safety Pass renewal
```

---

## Database Schema

### `panic_alerts`

```sql
CREATE TABLE panic_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  trip_id UUID REFERENCES trips(id),
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  status VARCHAR(20) DEFAULT 'pending',
  -- 'pending' | 'responded' | 'resolved' | 'expired'
  response_type VARCHAR(20),
  -- 'stay' | 'here'
  responder_id UUID REFERENCES users(id),
  responder_location_lat DECIMAL(10, 8),
  responder_location_lng DECIMAL(11, 8),
  responded_at TIMESTAMPTZ,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### `panic_responses` (log)

```sql
CREATE TABLE panic_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alert_id UUID REFERENCES panic_alerts(id),
  responder_id UUID REFERENCES users(id),
  response_type VARCHAR(20) NOT NULL,
  location_lat DECIMAL(10, 8),
  location_lng DECIMAL(11, 8),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## API Endpoints

### POST /panic/alerts
Create panic alert.

```json
// Request
{
  "latitude": -6.2088,
  "longitude": 46.9033,
  "trip_id": "uuid"
}

// Response
{
  "id": "uuid",
  "status": "pending",
  "created_at": "ISO8601"
}
```

### POST /panic/alerts/{id}/respond
Responder accepts alert.

```json
// Request
{
  "response_type": "stay" | "here",
  "location_lat": -6.2088,  // only if response_type = "here"
  "location_lng": 46.9033
}
```

### GET /panic/alerts
List alerts for responder (Muthawif/Support).

---

## FCM Payload

```json
{
  "notification": {
    "title": "🚨 Panic Alert!",
    "body": "Jamaah [name] butuh bantuan di [location name]"
  },
  "data": {
    "alert_id": "uuid",
    "latitude": "-6.2088",
    "longitude": "46.9033",
    "type": "panic"
  }
}
```

**FCM Topics:**
- `travel_{travel_id}` — for Muthawif
- `support` — for Team-Support

---

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| Works in silent mode | Critical for mosque scenarios |
| GPS always attached | No manual location entry |
| Dual responder (Muthawif + Team-Support) | Muthawif phone die/low battery → Team-Support as backup |
| Option B sends responder location | Jamaah knows where help is coming from |
| Auto-deactivate H+1 | Anti-abuse: only active around trip dates |
| Team-Support receives ALL alerts | Not scoped to travel_id |

---

## Panic Button Lifecycle (Mandatory Input)

**Jamaah Mandiri** (not in travel group):
- Must input departure date + duration during onboarding
- Panic Button activates H-3 before departure
- Auto-deactivates H+1 after return date
- Re-activates via new trip input OR Safety Pass renewal

---

## Edge Cases

| Case | Handling |
|------|----------|
| Muthawif offline | Team-Support still receives alert |
| Team-Support offline | Muthawif receives alert (primary) |
| GPS unavailable | Show error, prevent panic send |
| Multiple panic taps | Dedupe by user_id + 5-min window |
| Jamaah no active trip | Panic disabled — must start/join trip |

---

## Dependencies

- Supabase (auth, db, storage)
- FCM (push notifications)
- GPS/Location services (device)
- Google Maps API (reverse geocoding for location name)
- Critical Alert entitlement (iOS) + SMS fallback

---

## Related Modules

- [F06](F06-b2b-group-system.md): Rombongan members, trip_id assignment
- [DB](DB-schema.md): panic_alerts, panic_responses tables
- [00-overview](../00-overview.md): OSM not Mapbox (map context)

---

_Maintained by: Hermes (CTO)_
_Last Updated: 2026-05-02 (v1.10-FINAL)_
