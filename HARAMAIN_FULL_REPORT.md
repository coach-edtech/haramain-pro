# HARAMAIN PROJECT — FULL AUDIT & MIGRATION REPORT
**Coach:** Chaidir Bedalah | **Generated:** May 26, 2026 | **Status:** Autonomous session active

---

## EXECUTIVE SUMMARY

**Project:** Haramain Pro (Flutter + Supabase, Indonesia-first Umrah/Hajj companion app)
**Supabase:** `haramain-pro` @ `muqjlojecjnnntjvhavi.supabase.co`
**Repo:** `/Volumes/EdTech/Apps/haramain/`

| Category | Status |
|---|---|
| Core Services (Supabase integration) | ✅ DONE |
| Edge Functions | ✅ FIXED (was broken) |
| Flutter SharedPreferences → Supabase | ✅ DONE |
| Hardcoded IDs / placeholders | ✅ FIXED |
| B2B (Travel Agency) Features | ❌ NOT BUILT |
| NRC Backend | ❌ INCOMPLETE |
| Environment Variables (secrets) | ⏳ NEEDS DEPLOY |

---

## ✅ COMPLETED IN THIS SESSION

### 1. PhotoQueueService — SharedPreferences → Supabase
**File:** `lib/services/photo_queue_service.dart`

**Before:** Stored photo queue as JSON in `SharedPreferences` local storage.
**After:** Full Supabase integration against `photo_queue` table.

- `_loadQueue()` → queries `photo_queue` table by `user_id`
- `addToQueue()` → inserts into `photo_queue` with base64 + lat/lng
- `processQueue()` → fetches base64 from Supabase, uploads to Storage via `StorageService`, deletes row on success
- `_syncItem()` → uploads photo, deletes from queue
- `getQueueStatus()` → counts from Supabase
- `clearSyncedItems()` → no-op (synced rows already deleted)

> **Note:** Photos are stored as base64 in `photo_queue.base64` column, then uploaded to `jejak_ibadah_media` storage bucket. This avoids the need to re-encode on retry.

---

### 2. PanicService — SharedPreferences → Supabase
**File:** `lib/features/panic/panic_service.dart`

**Before:** Rate limit in SharedPreferences (`panic_last_sent`), offline queue in SharedPreferences (`panic_offline_queue`), history in SharedPreferences (`panic_history`).
**After:** All state in `panic_alerts` table.

- `_checkRateLimit(jamaaahId)` → queries `panic_alerts` ordered by `created_at` desc, checks ≥ 300s gap
- `getRemainingCooldownSeconds()` → returns remaining seconds for UI countdown
- `sendPanic()` → inserts alert, calls `fcm-panic-alert` edge function, on failure queues in `panic_alerts` with `status='pending'`
- `_sendViaFcm()` → calls `fcm-panic-alert` edge function
- `_sendViaSms()` → calls `twilio-voice-fallback` edge function
- `getOfflineQueue()` → queries `panic_alerts` where `jamaaah_id=X AND status='pending'`
- `processOfflineQueue()` → retries all pending alerts with exponential backoff
- `getPanicHistory()` → queries `panic_alerts` ordered by `created_at` desc
- `_insertPanicAlert()` → inserts into `panic_alerts`
- Connectivity listener auto-processes offline queue when online

---

### 3. XenditService — URL Fixed
**File:** `lib/services/xendit_service.dart`

**Before:** `https://<project-id>.supabase.co/functions/v1/xendit-invoice`
**After:** `https://muqjlojecjnnntjvhavi.supabase.co/functions/v1/xendit-invoice`

---

### 4. join_group_screen — Hardcoded User IDs Fixed
**File:** `lib/features/group/screens/join_group_screen.dart`

**Before:**
```dart
jamaahId: 'current_user_id',  // hardcoded string
jamaahName: 'User',            // hardcoded string
```
**After:**
```dart
jamaahId: widget.userId,   // uses constructor parameter
jamaahName: widget.userName, // uses constructor parameter
```

The screen already had `userId` and `userName` as constructor parameters — the hardcoded strings were leftover from development.

---

### 5. Edge Function — fcm-panic-alert: Field Name Fixed
**File:** `supabase/functions/fcm-panic-alert/index.ts`

**Bug:** Used `rombonganId` (camelCase) but the actual table column is `rombongan_id` (snake_case). This would cause silent failures in production.

**Fix:** Changed all instances of `rombonganId` → `rombongan_id`. Also fixed CORS origin from `'https:// Haramain Pro.app'` (space in URL) → `'https://haramain.pro'`.

---

### 6. Edge Function — twilio-voice-fallback: Rate Limit Query Fixed
**File:** `supabase/functions/twilio-voice-fallback/index.ts`

**Bug:** Rate limit query used `.eq('rombongan_id', payload.jamaaah_id)` — wrong column name. The `rombongan_id` column doesn't exist in `panic_alerts` (it's in `rombongans` table). This would cause the rate limit check to always fail silently, allowing unlimited voice calls.

**Fix:** Changed to `.eq('jamaaah_id', payload.jamaaah_id)` — correctly checks per-jamaah rate limit.

---

### 7. IbadahModeService + OfflineTileService — SharedPreferences Correctly Retained
**Decision:** These services use SharedPreferences for **device-local preferences** (not user-synced data):

- `ibadah_mode_enabled` — is Ibadah mode active on this device?
- `dont_show_geofence_alert` — has user dismissed the geofence notification?
- `offline_region_metadata` / `downloaded_regions` — which map tiles are cached locally?

These are device-specific and should NOT sync across devices. Correct as-is. No migration needed.

---

## 🔧 EDGE FUNCTIONS STATUS

| Function | Location | Status | Notes |
|---|---|---|---|
| `fcm-panic-alert` | `supabase/functions/` | ✅ Ready | Fixed `rombonganId` → `rombongan_id`; CORS fixed |
| `twilio-voice-fallback` | `supabase/functions/` | ✅ Ready | Fixed rate limit column; CORS correct |
| `panic-response` | `supabase/functions/` | ✅ Ready | Handles muthawif response to panic |
| `xendit-invoice` | `supabase/functions/` | ✅ Ready | Fixed CORS origin |
| `fcm-broadcast` | `supabase/functions/` | ✅ Ready | Group broadcast notifications |
| `validate-role` | `supabase/functions/` | ✅ Ready | Server-side role validation |
| `photo-watermark` | `supabase/functions/` | ⚠️ Partial | Placeholder watermark logic (watermarking itself is TODO) |
| `validate-role` | `supabase/functions/` | ⚠️ `rombongan_id` used | Used in `rombongans` table context (OK) |

**All 8 edge functions exist and are deployable.** The `rombongan_id` references in `photo-watermark` and `validate-role` are valid — they correctly reference the `rombongans` table's `rombongan_id` column.

---

## 📊 SUPABASE SCHEMA STATUS

### Tables (verified from migrations)

| Table | Migration | Status |
|---|---|---|
| `profiles` | 001_initial | ✅ Active |
| `rombongans` | 001_initial | ✅ Active |
| `transactions` | 001_initial | ✅ Active |
| `photo_queue` | 001_initial | ✅ Active |
| `fcm_tokens` | 004_fcm_tokens | ✅ Active |
| `groups` | 003_groups | ✅ Active |
| `group_members` | 003_groups | ✅ Active |
| `broadcast_logs` | 003_groups | ✅ Active |
| `rombongan_emergency_contacts` | 003_groups | ✅ Active |
| `panic_alerts` | 002_panic + 007_refactor | ✅ Active |
| `subscriptions` | 006_payment | ✅ Active |
| `payments` | 006_payment | ✅ Active |
| `panic_responses` | 007_refactor | ✅ Active |
| `agencies` | 007_refactor | ✅ Active |
| `geofence_prayers` | 007_refactor | ✅ Active |
| `seat_licenses` | 007_refactor | ✅ Active |
| `marketing_preferences` | 007_refactor | ✅ Active |
| `nrc_registrations` | 008_nrc_registrations | ✅ Active |

### Storage Buckets (from `005_storage_buckets.sql`)

| Bucket | Purpose |
|---|---|
| `agency_logos` | Agency logo images |
| `jejak_ibadah_media` | Jejak ibadah photos |
| `offline_maps` | Offline map tiles |

---

## ❌ WHAT NEEDS COACH DECISIONS

### 🔴 HIGH PRIORITY — B2B Features (NOT BUILT)

**No agency/travel-admin feature directories exist.** The app has NO way for travel agencies to:
- Manage their agents (CRUD)
- Manage rombangans (groups)
- Manage Jamaah in each romongan
- View dashboard / analytics
- Manage seat licenses

**What exists:** Only Jamaah-facing features + Virtual Muthawif chat.

**Impact:** The B2B revenue model (Agencies pay to manage their umrah groups) cannot launch without this.

**Recommendation:** This is a major build effort. Options:
1. Build `agency_muthawif_panel` feature (Flutter screens + backend)
2. Or use a separate B2B web app with the existing mobile as a Jamaah-facing companion

---

### 🔴 HIGH PRIORITY — Environment Variables (NOT CONFIGURED)

These edge functions require **Supabase Secrets** to be set via dashboard or CLI:

| Secret | Used By | Purpose |
|---|---|---|
| `XENDIT_API_KEY` | `xendit-invoice` | Create payment invoices |
| `XENDIT_CALLBACK_SECRET` | `xendit-invoice` | Verify Xendit callbacks |
| `FCM_SERVER_KEY` | `fcm-panic-alert`, `panic-response` | Send FCM push notifications |
| `PANIC_WEBHOOK_SECRET` | `fcm-panic-alert`, `twilio-voice-fallback` | Authenticate edge function calls |
| `TWILIO_ACCOUNT_SID` | `twilio-voice-fallback` | Twilio API authentication |
| `TWILIO_AUTH_TOKEN` | `twilio-voice-fallback` | Twilio API authentication |
| `TWILIO_PHONE_NUMBER` | `twilio-voice-fallback` | Outbound call number |

**Coach action needed:** Set these in Supabase Dashboard → Edge Functions → Secrets, or via:
```bash
supabase secrets set XENDIT_API_KEY=your_key
supabase secrets set FCM_SERVER_KEY=your_key
supabase secrets set TWILIO_ACCOUNT_SID=your_sid
supabase secrets set TWILIO_AUTH_TOKEN=your_token
supabase secrets set TWILIO_PHONE_NUMBER=+62...
supabase secrets set PANIC_WEBHOOK_SECRET=your_secret
```

---

### 🟡 MEDIUM — NRC/SDAIA Backend Incomplete

**File:** `lib/features/sdaia/nrc_form_page.dart` (screen exists)
**Table:** `nrc_registrations` (exists in migration `008_nrc_registrations.sql`)
**Issue:** No API integration code in the Flutter app to actually submit NRC data to the backend. The screen exists but doesn't wire up to the `nrc_registrations` table.

**Action:** Create `NrcService` in `lib/features/sdaia/services/nrc_service.dart` that inserts into `nrc_registrations` table.

---

### 🟡 MEDIUM — Virtual Muthawif AI Placeholder

**File:** `lib/features/virtual_muthawif/services/virtual_muthawif_service.dart`

The service has a `// TODO: Integrate with Nadhira AI API for contextual Quranic duas` comment. The chat UI is built but the AI backend is not connected.

**Action:** Coach needs to either:
1. Provide the Nadhira AI API endpoint + credentials, OR
2. Use a different AI provider (Claude, MiniMax, etc.)

---

### 🟡 MEDIUM — Broadcast Image Picker Not Implemented

**File:** `lib/features/group/screens/broadcast_screen.dart`

```dart
// TODO: Implement image picker
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: const Text('Fitur foto akan segera hadir')),
```

**Action:** Implement `image_picker` package integration for sending photos in group broadcasts.

---

### 🟡 MEDIUM — Photo Watermark Edge Function Placeholder

**File:** `supabase/functions/photo-watermark/index.ts`

Watermarking logic is TODO. Currently just uploads the original photo.

**Action:** In production, integrate a proper image processing library (e.g., `sharp` via Deno) to composite agency logo onto photos.

---

### 🟢 LOW — PaymentService Deprecated

**File:** `lib/services/payment_service.dart`

This is `@Deprecated` (Midtrans-based). Kept for reference only. Not used anywhere. Can be safely deleted after B2B payment features are built.

---

### 🟢 LOW — PrayerTimeService Uses Hardcoded Makkah Coordinates

**File:** `lib/features/ibadah/services/prayer_time_service.dart`

```dart
static const double _makkahLatitude = 21.4225;
static const double _makkahLongitude = 39.8262;
```

This is **correct and intentional** — the app is designed for Makkah/Madinah pilgrims. IbadahModeService uses `geofence_prayers` table for location-based mode switching, but prayer times are hardcoded to Makkah coordinates (Umm Al-Qura calculation method, appropriate for Saudi Arabia).

---

### 🟢 LOW — Group Feature Uses "groups" Schema (not "rombongans")

The app uses `groups` table (migration 003) for Jamaah self-organizing groups, while the agency-facing `rombongans` table is separate (migration 001). These are two separate concepts:

- `rombongans` = official travel agency groups (B2B)
- `groups` = Jamaah can create/join informal groups by PIN

This is a deliberate product decision. No action needed unless B2B features are built.

---

## 📋 SUPABASE SECRETS CHECKLIST

Before deploying to production, Coach needs to set these in **Supabase Dashboard → Project Settings → Edge Functions → Secrets**:

```
XENDIT_API_KEY=                    # From xendit.co dashboard
XENDIT_CALLBACK_SECRET=            # From xendit.co dashboard  
FCM_SERVER_KEY=                    # From Firebase Console → Project Settings → Cloud Messaging
PANIC_WEBHOOK_SECRET=              # Any random 32-char string you choose
TWILIO_ACCOUNT_SID=               # From twilio.com console
TWILIO_AUTH_TOKEN=                # From twilio.com console
TWILIO_PHONE_NUMBER=+62...        # Your Twilio phone number (E.164 format)
```

---

## 📋 TESTING CHECKLIST

Once secrets are configured:

- [ ] Panic alert: Jamaah sends panic → muthawif receives FCM
- [ ] Panic response: Muthawif responds → Jamaah receives FCM confirmation
- [ ] Offline panic: Send panic without internet → auto-retries when online
- [ ] Payment: Safety Pass purchase → Xendit invoice → webhook → subscription activated
- [ ] Jejak ibadah: Photo taken → queued → uploaded to storage
- [ ] Broadcast: Group message sent → all members receive FCM
- [ ] Ibadah mode: Enter geofence → mode auto-activates
- [ ] Virtual Muthawif: Chat message → AI response (when API connected)

---

## 📁 FILE CHANGES SUMMARY

| File | Action |
|---|---|
| `lib/services/photo_queue_service.dart` | ✅ Rewritten — SharedPreferences → Supabase |
| `lib/features/panic/panic_service.dart` | ✅ Rewritten — SharedPreferences → Supabase |
| `lib/services/xendit_service.dart` | ✅ Fixed hardcoded URL placeholder |
| `lib/features/group/screens/join_group_screen.dart` | ✅ Fixed hardcoded user IDs |
| `supabase/functions/xendit-invoice/index.ts` | ✅ Fixed CORS origin |
| `supabase/functions/fcm-panic-alert/index.ts` | ✅ Fixed `rombonganId` → `rombongan_id` + CORS |
| `supabase/functions/twilio-voice-fallback/index.ts` | ✅ Fixed rate limit query column |

---

*Generated by Hermes Fox — Autonomous Session, May 26, 2026*
