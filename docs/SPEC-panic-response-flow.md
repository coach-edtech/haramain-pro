# SPEC: Panic Response Flow — Complete E2E

## Context

Panic alert sudah bisa dikirim dari Jamaah → Edge Function → FCM → Muthawif/Team-Support. Tapi begitu responder(Action) menekan tombol "Stay", "Saya di sini", atau "Telepon" — response TIDAK tersimpan ke Supabase. Masih hanya update SharedPreferences lokal.

## Goal

Responder action tersimpan ke Supabase + notifikasi ke Jamaah + audit trail.

---

## Architecture

```
Jamaah App              Edge Function             Supabase
    |                        |                       |
    |-- panic alert -------> |-- insert panic ------>|
    |                        |                       |
Muthawif/Support App     Edge Function             |
    |-- respond --------->|-- update response --->|
    |                        |                       |
    |<------ FCM push -------|                       |
    | (panic_responded)      |                       |
```

---

## What to Build

### 1. Edge Function: `panic-response`

**Endpoint:** `POST /functions/v1/panic-response`

**Request:**
```json
{
  "alert_id": "uuid",
  "responder_id": "uuid",
  "action": "stay_jemput | saya_di_sini | telepon",
  "status": "responded"
}
```

**Behavior:**
1. Validate alert_id exists and status is 'pending'
2. Validate responder_id is Muthawif or Admin (via profiles.role)
3. Update `panic_alerts` SET:
   - `responded_by = responder_id`
   - `responded_at = NOW()`
   - `status = 'responded'`
4. Fetch Jamaah FCM token from `fcm_tokens` WHERE `user_id = panic_alerts.jamaah_id`
5. Send FCM to Jamaah: "Muthawif [name] sedang menuju lokasi Anda" (with action info)
6. Return success/error

**Response:**
```json
{
  "status": "success",
  "alert_id": "uuid",
  "responded_at": "ISO8601"
}
```

### 2. Flutter: `PanicService.updatePanicStatus()` — wired to Supabase

**Change:** `updatePanicStatus()` currently only updates SharedPreferences.

**New behavior:**
1. Call Edge Function `panic-response`
2. If succeeds, update local SharedPreferences history
3. If fails, still update local (optimistic) but queue for retry

**Signature change:**
```dart
Future<bool> updatePanicStatus(
  String alertId,
  PanicStatus status, {
  String? responderId,
  String? responseType,
})
// Returns bool success
```

### 3. DB: Add missing columns to `panic_alerts`

Current `002_panic_alerts.sql` has `responded_by`, `responded_at`, `status`. Need to add:

```sql
-- Add response_type column if not exists
ALTER TABLE panic_alerts ADD COLUMN IF NOT EXISTS response_type TEXT;
```

### 4. RLS: Allow responders to update panic_alerts

Current RLS only allows Muthawif/Admin to UPDATE. This is correct.

---

## Files to Modify

| File | Change |
|------|--------|
| `supabase/functions/panic-response/index.ts` | **NEW** — response handler |
| `apps/haramain_pro/lib/features/panic/panic_service.dart` | Wire `updatePanicStatus` to Edge Function |
| `supabase/migrations/002_panic_alerts.sql` | Add `response_type` column |
| `supabase/functions/fcm-panic-alert/index.ts` | No change needed |

---

## Response Actions (enum in Flutter)

```dart
class PanicResponseAction {
  static const String stayJemput = 'stay_jemput';   // "Stay, saya jemput"
  static const String sayaDiSini = 'saya_di_sini'; // "Saya di sini"
  static const String telepon = 'telepon';          // "Telepon saya"
}
```

---

## Panic Alert Status Flow

```
pending → responded → resolved
             ↓
          (Muthawif resolves later, or auto-resolve after 30min)
```

---

## Verification

1. Flutter: Send panic alert, verify record in `panic_alerts` with `status = 'pending'`
2. Responder: Press response button, verify `panic_alerts.status = 'responded'` and `responded_by` populated
3. Jamaah: Receives FCM notification with responder name + action
4. Query: `SELECT * FROM panic_alerts ORDER BY created_at DESC LIMIT 5`

---

## Priority

1. Edge Function `panic-response` (backend contract)
2. Update `updatePanicStatus()` in Flutter
3. Migration for `response_type` column
4. End-to-end test
