# Demo Video Script — Apple Critical Alert Entitlement
## Haramain Pro Panic Button

---

## Overview

**Purpose:** Show Apple reviewer that Haramain Pro Panic Button works even when iPhone is in Do Not Disturb / Silent mode — a life-safety feature for elderly Hajj pilgrims.

**Duration:** 60–90 detik (tidak perlu lebih dari 90 detik)

**Devices needed:** 2 iPhone fisik (bukan simulator)
- Device A: "Jamaah" — simulated lost pilgrim
- Device B: "Muthawif" — group leader receiving alert

**Video format:** Screen recording + optional voice-over. Tidak perlu editing mewah.

---

## Pre-Recording Checklist

### Device A — Jamaah (Sender)
- [ ] iPhone dengan app Haramain Pro ter-install (bisa debug build)
- [ ] Do Not Disturb NYATAKAN AKTIF (show control center)
- [ ] Silent Mode AKTIF
- [ ] Lokasi GPS hidup (izinkan location access)
- [ ] Screen recording mulai

### Device B — Muthawif (Receiver)
- [ ] iPhone dengan app Haramain Pro ter-install
- [ ] Dalam keadaan normal (DND bisa on atau off, tapi DND di Device A yang penting)
- [ ] Buka app, pastikan sudah login sebagai Muthawif
- [ ] Biarin di layar utama (nanti alert akan masuk)

### Environment
- [ ] Sinyal internet stabil (WiFi)
- [ ] Supabase Edge Function accessible (panic alert bisa kirim)
- [ ] Atau: gunakan Airplane Mode + local mockup kalau belum ada backend

---

## Scene Breakdown

### SCENE 1 — Title Card (5 detik)

**Visual:** Dark background, logo Haramain Pro, text overlay.

```
┌──────────────────────────────────────┐
│                                      │
│         HARAMAIN PRO                 │
│     Panic Button — Life Safety       │
│                                      │
│   Critical Alert Entitlement Demo    │
│                                      │
└──────────────────────────────────────┘
```

**Text overlay:**
> "Haramain Pro — Panic Button Demo"
> "Apple Critical Alert Entitlement Request"

**No audio needed** — bisa pakai ambient music lembut.

---

### SCENE 2 — Device A: Show DND Active (10 detik)

**Visual:** Close-up Device A screen. Tunjukkan DND aktif.

**Narration (optional, atau text overlay):**
> "Device A — Jamaah. Phone is in Do Not Disturb mode."

**Steps to show:**
1. Angkat iPhone, swipe down dari atas kanan → Control Center visible
2. Zoom ke Moon icon (🌙) — NYATAKAN WARNA PUTIH/PETERSBURG (artinya aktif)
3. Tunda 3 detik — biar reviewer bisa lihat
4. Swipe up/close Control Center

**Screenshot reference:**
```
┌─────────────────────────┐
│  🔘 Airplane Mode [OFF] │
│  📶 Cellular      [ON ] │
│  📤 AirDrop       [ON ] │
│  🔆 Brightness   [████]│
│  🌙 Do Not Disturb[ON]│  ← INI YANG PENTING
│  🔒 Lock Screen        │
└─────────────────────────┘
```

**Purpose:** Establishes that standard notifications would be silenced.

---

### SCENE 3 — Device A: Open App + Show Location (10 detik)

**Visual:** App opens, GPS coordinates visible in-app.

**Narration:**
> "Jamaah opens Haramain Pro. Location access enabled."

**Steps:**
1. Tap app icon → app opens
2. Navigasi ke Panic Button screen (atau tampilkan home screen dulu)
3. Show latitude/longitude di corner — ini proof lokasi real
4. Tunda 2 detik biar reviewer baca koordinat

**Screenshot reference:**
```
┌─────────────────────────────────┐
│  ┌───────────────────────────┐  │
│  │    🌍 Location: Active   │  │
│  │    📍 -21.7785, 39.8573  │  │  ← пример coordinates
│  └───────────────────────────┘  │
│                                 │
│     ┌─────────────────────┐     │
│     │                     │     │
│     │   🔴 PANIC BUTTON   │     │
│     │                     │     │
│     └─────────────────────┘     │
│                                 │
└─────────────────────────────────┘
```

**Purpose:** Shows the app knows user's location before panic — critical for rescue.

---

### SCENE 4 — Device A: Press Panic Button (5 detik)

**Visual:** Finger presses red Panic Button, animation plays.

**Narration:**
> "Jamaah presses the Panic Button."

**Steps:**
1. Finger enters frame
2. Tap/drag ke button besar merah
3. Button animates (scale up + pulse)
4. Screen shows "Sending alert..." state
5. Shows checkmark: "Emergency alert sent"

**Screenshot reference:**
```
┌─────────────────────────────────┐
│                                 │
│     ┌─────────────────────┐     │
│     │   ⚠️ SENDING...     │     │
│     │   [-      ]         │     │
│     └─────────────────────┘     │
│                                 │
│  ┌───────────────────────────┐  │
│  │ ✓ Emergency alert sent   │  │
│  │   to: Muthawif Ahmad     │  │
│  │   📍 -21.7785, 39.8573   │  │
│  │   ⏰ 10:45:32 AM         │  │
│  └───────────────────────────┘  │
│                                 │
└─────────────────────────────────┘
```

**Purpose:** Shows explicit user action + confirmation.

---

### SCENE 5 — Device B: Alert Arrives (15 detik)

**Visual:** Device B screen — notification banner appears at TOP despite DND.

**CRITICAL MOMENT** — This is the whole point of Critical Alert.

**Steps:**
1. Cut to Device B — screen initially normal/locked
2. Wait 1-2 seconds
3. NOTIFICATION BANNER SLAMS IN from top (critical alert style — bold, cannot be missed)
4. Banner stays visible — shows:
   - App icon + "Haramain Pro"
   - "PANIC ALERT!"
   - "Jamaah [Nama] — Emergency"
   - Location coordinates
5. Bold sound plays (default critical alert tone)
6. Haptic feedback fires

**Screenshot reference:**
```
┌─────────────────────────────────┐
│  ┌─ NOTIFICATION BANNER ─────┐ │
│  │ 🔴 HARAMAIN PRO            │ │
│  │ ⚠️  PANIC ALERT!           │ │
│  │ Jamaah Sari - Emergency    │ │
│  │ 📍 -21.7785, 39.8573      │ │
│  │                            │ │
│  │ [View] [Dismiss]           │ │
│  └────────────────────────────┘ │
│                                 │
│         ← iPhone Home Screen    │
└─────────────────────────────────┘
```

**Narration:**
> "Alert arrives on Muthawif's device — despite DND mode active on the pilgrim's phone."

**Purpose:** This is THE shot. Must show notification penetrating DND.

---

### SCENE 6 — Device B: Open Alert → View Map (15 detik)

**Visual:** Tap notification → app opens to map with pilgrim location.

**Steps:**
1. Tap notification or "View" button
2. App opens to Map screen
3. RED MARKER shows pilgrim's exact location
4. Muthawif name + Jamaah name visible
5. Distance/ETA if available
6. "Navigate to location" button visible

**Screenshot reference:**
```
┌─────────────────────────────────┐
│  HARAMAIN PRO           [Back]  │
│  ┌───────────────────────────┐  │
│  │     ┌─────────────────┐  │  │
│  │     │   MAP VIEW      │  │  │
│  │     │                 │  │  │
│  │     │      📍 ← RED   │  │  │
│  │     │    PILGRIM      │  │  │
│  │     │                 │  │  │
│  │     └─────────────────┘  │  │
│  │                           │  │
│  │  👤 Jamaah Sari          │  │
│  │  📍 -21.7785, 39.8573   │  │
│  │  📏 1.2 km away         │  │
│  │                           │  │
│  │  [🧭 Navigate]           │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

**Narration:**
> "Muthawif sees exact location. Can navigate immediately to assist."

---

### SCENE 7 — Text Summary (10 detik)

**Visual:** White background, key points in bullet format.

```
┌──────────────────────────────────────┐
│                                      │
│  WHY CRITICAL ALERT?                 │
│                                      │
│  ✓ Works in Silent / DND mode        │
│  ✓ Life-safety for elderly pilgrims  │
│  ✓ < 5 second response time          │
│  ✓ Location-aware emergency alerts   │
│                                      │
│  Only used for genuine emergencies   │
│                                      │
└──────────────────────────────────────┘
```

---

### SCENE 8 — Closing Card (5 detik)

```
┌──────────────────────────────────────┐
│                                      │
│         HARAMAIN PRO                 │
│                                      │
│   Requesting Critical Alert          │
│   Entitlement for iOS                │
│                                      │
│   Bundle ID: com.haramain.pro        │
│   Contact: coach@haramain.pro        │
│                                      │
└──────────────────────────────────────┘
```

---

## Voice-Over Script (Optional)

If you want to add narration, here's the full script:

> "Haramain Pro serves Indonesian Hajj and Umrah pilgrims — many elderly, traveling in one of the world's most crowded environments.
>
> Our Panic Button is a life-safety feature. When a pilgrim is lost or in distress, pressing the button sends their GPS location to their Muthawif — even if their phone is in Silent or Do Not Disturb mode.
>
> [Scene 5] Watch as the alert penetrates Do Not Disturb on the Muthawif's device — arriving in under 5 seconds.
>
> [Scene 6] The Muthawif sees the exact location on a map and can navigate immediately to assist.
>
> Critical Alert is the only way to guarantee this alert is heard. Standard notifications would be silenced by DND — and in an emergency inside Masjidil Haram or in the desert, those seconds matter.
>
> We request Apple's Critical Alert entitlement for this life-safety application."

---

## Recording Tips for Pak Aji

### Equipment
- 2 iPhone fisik (paling penting)
- Tripod atau phone stand untuk stabil shot
- Good lighting (biar screen capture jelas)
- Bisa record both screens sequentially atau simultaneous dg 2 operator

### Screen Recording
- iPhone: Settings → Control Center → Screen Recording
- Atau pakai QuickTime di Mac + lightning cable

### Tips Biar Hasil Professional
1. **Hide notch/time** — record di landscape kalau bisa
2. **Clean status bar** — hide battery %, signal bars kalau mengganggu
3. **Steady hands** — gunakan tripod, jangan handheld
4. **Good contrast** — pastikan Panic Button merah terlihat jelas
5. **Test dulu** — test 2-3x sebelum final record
6. **Audio** — kalau pakai voice-over, pakai external mic (AirPods cukup)

### Kalau Backend Belum Ready
Kalau Edge Function belum jalan, bisa mockup:
1. Record Scene 1-4 seperti biasa
2. Untuk Scene 5, buat mockup video terpisah:
   - Pre-record normal notification (yang ter-delay/deleted)
   - Lalu overlay "With Critical Alert:" text
   - Tunjukkan mockup alert banner di Device B

---

## Post-Recording

1. Trim start/end
2. Add title cards (Scene 1, 7, 8)
3. Export as MP4, 1080p, 30fps
4. Upload ke:
   - YouTube (unlisted/private)
   - atau Google Drive
5. Paste link di Feedback Assistant form

---

## File Output

After recording, save:
- **Primary:** `/Volumes/StartUp/Haramain-Pro/apple-critical-alert-demo.mp4`
- **Backup:** iCloud HermesSync folder

---

## Next Steps After Video Ready

1. Coach fills in email + phone di application letter
2. Coach gets Apple Developer Team ID
3. Coach submits via https://feedbackassistant.apple.com
4. Attach:
   - Application letter (markdown atau PDF)
   - Demo video link
   - Screenshot bukti Bundle ID + Team ID
5. Hermes update tracker

---

**Last Updated:** May 4, 2026
**Author:** Hermes (CTO Review)
