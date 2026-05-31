# Feature Brief: Panic Button (Emergency Alert)

_Feature ID: F-02_
_Status: Draft_
_Date: 2026-04-04_
_Author: OpenClaw (extracted from PRD)_

---

## 1. Problem Statement

Pilgrims risk getting lost in massive crowds in Makkah and Madinah. Cellular networks are congested and devices are often in silent/DND mode. When a pilgrim is in distress, there is no reliable way to alert their group leader (Muthawif) immediately.

---

## 2. Goal

Provide a one-tap Panic Button that:
- Captures the user's offline GPS coordinates
- Dispatches a high-priority FCM payload to the assigned Muthawif
- Bypasses iOS/Android silent mode and Do Not Disturb on the receiving device
- Works even without internet connectivity (uses cached location)

---

## 3. User Flow

```
Jamaah presses PANIC BUTTON
       ↓
App captures current GPS coordinates (offline cache if needed)
       ↓
POST /panic-alert to edge function
       ↓
Edge queries Rombongan → gets Muthawif FCM token
       ↓
FCM dispatches HIGH PRIORITY alert to Muthawif
       ↓
Muthawif device: plays LOUD sound + vibration
       ↓
Muthawif app: shows distressed pilgrim's location on offline map
       ↓
Jamaah: confirmation "Alert sent to Muthawif"
```

---

## 4. Scope

### In Scope
- Prominent, always-visible Panic Button (floating or fixed position)
- Offline GPS coordinate capture
- FCM high-priority dispatch to Muthawif
- Silent/DND bypass (iOS Critical Alert, Android high-priority)
- Muthawif receives coordinates and displays on offline map
- Confirmation feedback to user
- "Simulate Panic Delivery" debug button (dev/test only)

### Out of Scope
- SMS fallback (if FCM fails)
- Auto-escalation to authorities
- Panic without assigned Muthawif (graceful error)
- Group-wide broadcast (single Muthawif only)

---

## 5. Acceptance Criteria

- [ ] Panic Button is visible on ALL screens (floating action or persistent header)
- [ ] GPS coordinates captured within 3 seconds of button press
- [ ] Alert delivered to Muthawif within 5 seconds (when online)
- [ ] Muthawif device plays loud sound even if in silent/DND mode
- [ ] Muthawif sees distressed pilgrim's location on offline map
- [ ] Works when Jamal's phone is offline (queued and sent when connectivity restored)
- [ ] Cannot accidentally trigger (requires confirmation dialog or long-press)
- [ ] Debug "Simulate Panic" button available in dev builds ONLY

---

## 6. Edge Cases

| Case | Handling |
|------|----------|
| No internet when panic triggered | Queue alert locally, send when connectivity restored |
| User not assigned to any Rombongan | Show error: "No group assigned. Contact your travel agency." |
| Muthawif phone offline | FCM retries; if Muthawif offline >X min, alert expires |
| Panic triggered multiple times | Debounce: 1 panic per 5 minutes per user |
| GPS unavailable (indoor/canyon) | Use last cached location with timestamp warning |

---

## 7. Technical Notes

**PanicAlertRequest:**
```typescript
{
  jamaahId: string,
  rombonganId: string,
  muthawifId: string,
  distressedLat: number,
  distressedLng: number,
  timestamp: string
}
```

**FCM Payload Requirements:**
- iOS: `content_available: true`, critical sound payload
- Android: `priority: "high"`, notification channel with high priority

**Edge Function:** `fcm-panic-alert`
- Verifies JWT
- Queries Rombongan for Muthawif device token
- Dispatches FCM with high-priority config

---

## 8. Dependencies

- Mapbox (offline map display on Muthawif side)
- FCM (Firebase Cloud Messaging)
- Supabase Edge Function: `fcm-panic-alert`
- GPS / Geolocator plugin (offline-capable)
- Local queue for offline-triggered panics

---

## 9. Related PRD References

- PRD-13: Panic Button captures offline GPS + dispatches to Muthawif
- PRD-14: FCM must bypass silent/DND modes
- PRD-43: Muthawif displays coordinates on offline map
- PRD-70-75: Critical Alert Loopback (Verify DX feature)
- PRD-86: Critical Alert Loopback must be stripped from production

---

## 10. Production Safety

⚠️ **CRITICAL: The "Simulate Panic Delivery" debug feature must be HARD-DISABLED or STRIPPED in production builds.** This is explicitly stated in PRD-86 to prevent false positives in live emergency scenarios.

---

## 11. Questions Open

1. Should the panic also notify the B2B travel agency dashboard?
2. What is the exact debounce window? (suggested: 5 min)
3. Should there be a "false alarm" cancel option within X seconds?
4. Is there a maximum retry count if FCM delivery fails?

