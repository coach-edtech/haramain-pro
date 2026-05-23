# HARAMAIN PRO — Codebase Review Report

**Date:** 2026-05-22
**Reviewer:** Hermes Fox (mr. Fox)
**Scope:** Flutter app (haramain_pro), full stack
**Files Reviewed:** main.dart, constants.dart, panic_service.dart, location_service.dart, supabase_client.dart, paywall_screen.dart, design system, pubspec.yaml

---

## EXECUTIVE SUMMARY

Haramain Pro codebase is functional with solid foundations in panic alerting, offline maps, and Supabase integration. However, there are **critical security issues** (exposed credentials), **architectural debt** (missing wiring for offline features), and **spec drift** (paywall code out of sync with TIER23 spec) that need to be addressed before production release.

**Overall Grade: C+**

---

## STACK OVERVIEW

| Component | Technology |
|-----------|------------|
| Platform | Flutter (Android) |
| Backend | Supabase (Auth, DB, Storage, Edge Functions) |
| Push Notifications | Firebase Core + Firebase Messaging |
| Maps | OSM tiles via flutter_map + flutter_map_tile_caching |
| Prayer Times | Adhan package |
| State Management | Riverpod (partial adoption) |
| Payments | Midtrans (to be replaced with Xendit) |

---

## 1. SECURITY — Grade: C-

### Critical Issues

#### 1.1 Credentials Hardcoded in Source

**File:** `lib/config/constants.dart`

```
Lines 16-32 (FirebaseConstants):
  - apiKey = 'your-firebase-api-key'           ← FAKE but visible
  - messagingSenderId = '000000000000'          ← FAKE but visible
  - iosBundleId = 'com.haramain.pro'            ← potentially real

Lines 74-88 (SmsApiConstants):
  - twilioAccountSid = 'YOUR_TWILIO_ACCOUNT_SID'  ← FAKE but visible
  - twilioAuthToken = 'YOUR_TWILIO_AUTH_TOKEN'   ← REAL credential format
  - nexmoApiKey = 'YOUR_NEXMO_API_KEY'           ← FAKE but visible
  - emergencyContacts = '+123****7890'            ← FAKE but visible
```

**Risk:** If this code is committed to a public repo or shared with anyone, real credential values could be accidentally pasted here in the future. The pattern of `YOUR_*` suggests developers know these should be replaced — but the file structure encourages pasting real values.

**Fix Required:**
- Move ALL secrets to `.env` file
- Use `const String.fromEnvironment('KEY', defaultValue: '')` for all secrets
- Add validation on app start: if key is empty, show clear error message
- Never ship a file where real credentials could be accidentally committed

#### 1.2 Supabase Keys Use Empty Default

**File:** `lib/config/constants.dart` lines 5-6

```dart
static String get supabaseUrl => const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
static String get supabaseKey => const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
```

**Risk:** If env vars are missing, the app will silently fail at runtime with cryptic Supabase errors. No early warning.

**Fix Required:** Add app-level initialization check that crashes fast with a clear message if required env vars are missing.

#### 1.3 API Base URL Points to Nonexistent Domain

**File:** `lib/config/constants.dart` line 52

```dart
static const String baseUrl = 'https://api.haramain.pro/v1';
```

**Risk:** This domain does not exist. If any code paths use `ApiEndpoints.baseUrl` directly, they will fail. Currently `ApiEndpoints` appears unused, but if it gets wired up later, this will be a production issue.

**Fix:** Either remove dead code or make it configurable via environment.

---

## 2. ARCHITECTURE — Grade: C+

### What's Good

- **Singleton pattern** consistently used for services (LocationService, PanicService, IbadahModeService)
- **Clean folder structure:** features/, services/, models/, design/, config/
- **Supabase wrapper class** provides type-safe access
- **Edge function calls** centralized in service layer
- **Separation of concerns** between UI and business logic

### Issues

#### 2.1 No Repository Pattern

Services directly call `Supabase.instance.client` throughout. This couples business logic to Supabase. For an app this size, it's acceptable — but it means swapping Supabase for another backend would require changes in every service.

**Recommendation:** For v1.1, acceptable. If scale grows, introduce repository interfaces.

#### 2.2 No Dependency Injection

All services instantiated via `ClassName._internal()` singleton pattern. This works but:
- Hard to mock for testing
- Couples concrete implementations throughout the app

**Recommendation:** Consider Riverpod's `Provider` pattern for dependency injection. Riverpod is already in pubspec.yaml but not visibly used for DI.

#### 2.3 No Role Enum

`RolePermissions` uses string literals:
```dart
'admin', 'coordinator', 'leader', 'member', 'jamaah', 'muthawif', 'team_support'
```

**Risk:** Typos will compile fine but cause runtime bugs.

**Fix:** Create a `UserRole` enum. Already partially done with `UserProfile` model, but `RolePermissions` still uses strings.

---

## 3. PANIC SERVICE — Grade: B

### What's Good

- **Retry with exponential backoff:** 1s, 2s, 4s delays
- **Rate limiting:** 5-minute cooldown between panic alerts per user
- **Offline queue:** Panic alerts stored in SharedPreferences if network fails
- **SMS fallback:** If FCM fails, falls back to Twilio/Voice edge function
- **Well-structured model:** `PanicAlert` with proper JSON serialization

### Issues

#### 3.1 Offline Queue Not Wired

Methods exist but not called:
- `processOfflineQueue()` — defined but never invoked
- `getOfflineQueue()` — defined but never invoked

**Risk:** If user loses connectivity, alerts queue up but never retry when connectivity returns.

**Fix:** Call `processOfflineQueue()` when connectivity is restored (listen to `connectivity_plus` stream).

#### 3.2 Panic History Not Wired

```dart
savePanicHistory()    ← defined, not called from any screen
getPanicHistory()     ← defined, not called from any screen
```

**Fix:** Wire to panic history screen.

#### 3.3 Stub Method

```dart
int getRemainingCooldownSeconds(String jamaaahId) {
  return 0;  // This is a sync helper - actual check is async
}
```

**Issue:** Always returns 0, providing no actual cooldown feedback to the UI.

**Fix:** Either implement it properly or remove it.

#### 3.4 Rate Limit Error Message Hardcoded

```dart
error: 'Please wait 5 minutes before sending another panic alert.'
```

Should reference `_rateLimitSeconds` constant instead of hardcoding "5 minutes".

---

## 4. PAYWALL / PAYMENT — Grade: C

### Spec Drift

**TIER23 Task Spec says:**
- Simplify paywall to show ONLY "Safety Pass" (Rp 120K/lifetime)
- Replace PaymentService with XenditService
- New flow: tap → Xendit checkout → poll → auto-Premium

**Current Code:**
- Shows 4 tiers (Safety Pass, Independent, Small, Medium)
- Uses `PaymentService` with Midtrans (per WEEK03 result)
- No `xendit_service.dart` exists

### Issues

1. **No Xendit service** — `xendit_service.dart` not in codebase
2. **Paywall shows wrong tiers** — TIER23 spec not implemented
3. **PaymentService** references Midtrans but WEEK04 result says it was implemented

### Files Involved

| File | Action |
|------|--------|
| `services/xendit_service.dart` | CREATE (new) |
| `services/payment_service.dart` | KEEP for B2B, UPDATE for Mandiri |
| `features/paywall/paywall_screen.dart` | UPDATE to single-tier |
| `supabase/functions/mandiri-subscription/` | CREATE (new edge function) |

---

## 5. CONSTANTS / CONFIG — Grade: C

### Issues

| Issue | Location | Fix |
|-------|----------|-----|
| Firebase placeholders | constants.dart:16-32 | Move to env vars |
| SMS credentials exposed | constants.dart:74-88 | Move to env vars |
| Empty defaults for Supabase | constants.dart:5-6 | Add validation |
| Dead code `ApiEndpoints` | constants.dart:48-68 | Remove or use |
| `isDebug = true` hardcoded | constants.dart:44 | Make env-aware |
| No env switching | N/A | Add dev/staging/prod |

### Initialization Gap

`main.dart` calls:
```dart
await app.SupabaseClientWrapper.instance.initialize(
  supabaseUrl: SupabaseConstants.supabaseUrl,
  supabaseKey: SupabaseConstants.supabaseKey,
);
```

If `supabaseUrl` is empty string, this silently proceeds and fails later with cryptic errors.

**Fix:** Add validation:
```dart
if (SupabaseConstants.supabaseUrl.isEmpty) {
  throw Exception('SUPABASE_URL environment variable is required');
}
```

---

## 6. DESIGN SYSTEM — Grade: B

### What's Good

- Clean separation: `tokens/` (colors, typography, spacing) + `theme/` + barrel `design.dart`
- Gold accent appropriate for app theme
- Consistent use of design tokens throughout

### Issues

| Issue | Fix |
|-------|-----|
| Only 4 spacing values | Grow token set as needed |
| No shadow/shape tokens | Add border radius, shadow tokens |
| `radiusMd` hardcoded value | Extract to design token |

---

## 7. STATE MANAGEMENT — Grade: B (Incomplete)

Riverpod is in `pubspec.yaml` (`flutter_riverpod: ^2.6.1`) but:
- No visible provider definitions
- Screens use `ConsumerStatefulWidget` but without visible `ref.watch()`
- Most state appears to be local `setState()`

**Note:** Full Riverpod adoption may exist but not visible in the files reviewed.

---

## 8. OFFLINE CAPABILITY — Grade: B

**Good:**
- `flutter_map_tile_caching` for offline map tiles
- `connectivity_plus` for network state
- `offline queue` concept in PanicService

**Missing:**
- Offline queue processing not wired to connectivity events
- No visible sync logic for other data (profiles, etc.)

---

## 9. FIREBASE CONFIGURATION — Grade: C-

All Firebase constants in `constants.dart` are TODOs with placeholder values:

```dart
static const String projectId = 'haramain-pro';  // May be real
static const String messagingSenderId = '000000000000';  // FAKE
static const String apiKey = 'your-firebase-api-key';  // FAKE
```

**If Firebase is not configured:**
- FCM push notifications will not work
- Firebase Auth callbacks will fail
- App may crash on notification permission requests

**Fix:** Configure Firebase via `google-services.json` (Android) and `GoogleService-Info.plist` (iOS), loaded at build time — not hardcoded in Dart.

---

## PRIORITY MATRIX

| Priority | Issue | Impact | Effort |
|----------|-------|--------|--------|
| P0-CRITICAL | Credentials in source code | Security breach | Low |
| P0-CRITICAL | Empty Supabase defaults | Silent production failure | Low |
| P1-HIGH | Offline queue not wired | Panic alerts lost | Medium |
| P1-HIGH | TIER23 not implemented | Revenue blocked | High |
| P2-MEDIUM | Panic history not wired | Feature broken | Medium |
| P2-MEDIUM | Rate limit stub method | UI confusion | Low |
| P3-LOW | No role enum | Potential bugs | Low |
| P3-LOW | Dead code (ApiEndpoints) | Maintenance burden | Low |

---

## RECOMMENDED ACTION PLAN

### Immediate (Before Any Release)

1. **Move all secrets to environment variables**
   - Create `.env.example` with all required keys
   - Update `constants.dart` to use `fromEnvironment()` with validation
   - Add startup crash with clear error if required env vars missing

2. **Add env validation in main.dart**
   ```dart
   if (SupabaseConstants.supabaseUrl.isEmpty) {
     throw Exception('FATAL: SUPABASE_URL not configured');
   }
   ```

3. **Add .gitignore entry for `.env`**

### Short Term (v1.1)

4. Wire offline queue processing to connectivity events
5. Wire panic history to UI
6. Implement TIER23 (Xendit payment)
7. Create `UserRole` enum

### Medium Term (v1.2)

8. Full Riverpod adoption for DI
9. Repository pattern for Supabase access
10. Add Firebase configuration files (not in Dart constants)
11. Add dev/staging/prod environment switching

---

## FILES SUMMARY

| File | Status | Action |
|------|--------|--------|
| `lib/main.dart` | OK | Add env validation |
| `lib/config/constants.dart` | ISSUES | Move secrets to env |
| `lib/supabase/supabase_client.dart` | OK | — |
| `lib/services/panic_service.dart` | OK + GAPS | Wire offline queue |
| `lib/services/location_service.dart` | OK | — |
| `lib/services/payment_service.dart` | STALE | TIER23 update needed |
| `lib/features/paywall/paywall_screen.dart` | STALE | Simplify per TIER23 |
| `lib/design/design.dart` | OK | — |
| `pubspec.yaml` | OK | Riverpod included |

---

## CONCLUSION

Haramain Pro has a solid technical foundation — panic alerting logic is well-thought-out with retry, fallback, and offline support. The main risks are **security (exposed credentials)** and **incomplete wiring of features that exist but aren't connected**. The codebase is production-ready once the P0 issues are addressed and TIER23 is implemented.

**Recommendation:** Fix P0 issues before next beta release. The app should not go to external testers with credentials in source code.
