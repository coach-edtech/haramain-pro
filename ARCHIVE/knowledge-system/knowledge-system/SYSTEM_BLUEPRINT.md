# System Blueprint — haramain Pro

**Versi:** 2.0  
**Tanggal:** 07 April 2026  
**Status:** PRODUCTION‑GRADE CONTROL DOCUMENT  
**Requirement:** All content herein is enforceable and deterministic. Ambiguity is a defect.

---

## Table of Contents

1. [System Decomposition](#1-system-decomposition)  
2. [Dependency Graph](#2-dependency-graph)  
3. [Control Systems — Descriptive](#3-control-systems-descriptive)  
4. [Control Systems — Enforcement Layer](#4-control-systems--enforcement-layer)  
5. [Control → Data Mapping](#5-control--data-mapping)  
6. [State System Principles](#6-state-system-principles)  
7. [Execution Dependency Per Domain](#7-execution-dependency-per-domain)  
8. [Data Ownership Model](#8-data-ownership-model)  
9. [Risk Identification](#9-risk-identification)  
10. [Document Quality Gate](#10-document-quality-gate)  
11. [Observability & Metrics](#11-observability--metrics)  
12. [Global Rate Limiting Policy](#12-global-rate-limiting-policy)  
13. [Audit & Security Logging](#13-audit--security-logging)  
14. [Time Consistency Rules](#14-time-consistency-rules)  
15. [Naming Consistency Rules](#15-naming-consistency-rules)  
16. [Incident Response & Escalation](#16-incident-response--escalation)  
17. [Circuit Breaker Strategy](#17-circuit-breaker-strategy)  
18. [Data Retention & Purging Policy](#18-data-retention--purging-policy)  
19. [Versioning & Backward Compatibility](#19-versioning--backward-compatibility)  
20. [Global Consistency Check](#20-global-consistency-check)

---

## 1. SYSTEM DECOMPOSITION

### 1.1 Core Domains (8)

| Domain | Code | Description | Key Boundary |
|---|---|---|---|
| **D1: Identity & Access** | ID | Auth, JWT claims, role propagation, agency binding lifecycle | Supabase Auth + Edge Functions |
| **D2: Consent & Compliance** | CM | PDPL consent (core), marketing consent (B2B broadcast opt‑in), data deletion flows | Edge Functions + PostgreSQL |
| **D3: Subscription & Monetization** | SM | B2C lifetime paywall (Rp 120K), B2B volume licensing (Rp 90K × N × (1‑D)), Midtrans webhook | Edge Function: midtrans‑webhook |
| **D4: Group / Rombongan System** | RG | Group creation, 6‑digit PIN invite, itinerary broadcast, paywall bypass | Supabase DB + Edge + Mobile |
| **D5: Safety (Panic Alert)** | PA | Panic button, FCM Critical Alert (silent‑mode bypass), Twilio voice fallback | Edge Function: fcm‑panic‑alert |
| **D6: Media & Sync** | MS | Offline photo queue (Isar), client‑side pre‑compress, watermark compositor, CRM gallery | Edge Function: photo‑watermark + Supabase Storage |
| **D7: Location & Navigation** | LN | Offline Mapbox tiles (≤300 MB), background GPS engine, geofencing, 30‑day GPS TTL purge | Flutter Mobile + pg_cron |
| **D8: Virtual Muthawif** | VM | Contextual prayer surfacing (Arabic/Latin/ID), geofence trigger, local Doa repository | Flutter Mobile (Isar cached) |

### 1.2 Critical Components

| Component | Location | Risk Level | Control System |
|---|---|---|---|
| `refresh-claims` Edge Function | Supabase Edge | **CRITICAL** | CS1 — Auth & Role |
| PDPL Route Guard | Flutter (`lib/core/routing/`) | **CRITICAL** | CS2 — Consent |
| RLS Policies | PostgreSQL migrations | **CRITICAL** | CS4 — RLS |
| SHA512 Signature Validator | `midtrans-webhook/index.ts` | **CRITICAL** | CS3 — Access State |
| Panic Alert Orchestrator | `fcm-panic-alert/index.ts` | **CRITICAL** | CS5 — Panic Flow |
| Photo Watermark Memory Circuit Breaker | Edge Function shared (`image_processing.ts`) | **HIGH** | CS4 — RLS |
| B2B Volume Pricing Calculator | Backend only (not client) | **HIGH** | CS3 — Access State |
| GPS TTL Purge (`pg_cron`) | PostgreSQL | **MEDIUM** | CS2 — Consent |

---

## 2. DEPENDENCY GRAPH

### 2.1 Domain Dependency Map

```
                            ┌──────────────────────────────────┐
                            │   D1: IDENTITY & ACCESS         │
                            │  ROOT — semua domain bergantung   │
                            │  pada ini                        │
                            └──────────────┬───────────────────┘
                                           │
                    ┌───────────────────────┼───────────────────────┐
                    │                       │                       │
                    ▼                       ▼                       ▼
             ┌──────────────┐      ┌──────────────┐      ┌──────────────┐
             │     D2       │      │     D3       │      │     D4       │
             │  Consent &   │      │  Subscription │      │  Group /     │
             │  Compliance  │      │  & Monetize   │      │  Rombongan   │
             └──────┬───────┘      └──────┬───────┘      └──────┬───────┘
                    │                     │                     │
                    │                     │                     │
                    └─────────────────────┼─────────────────────┘
                                          │
                     ┌──────────────────────┼──────────────────────┐
                     ▼                      ▼                      ▼
            ┌──────────────┐       ┌──────────────┐       ┌──────────────┐
            │     D5        │       │     D6        │       │     D7        │
            │  Safety /    │       │  Media &     │       │  Location    │
            │  Panic       │       │  Sync        │       │  & Nav       │
            └──────────────┘       └──────────────┘       └──────┬───────┘
                                                                  │
                                                                  ▼
                                                         ┌──────────────┐
                                                         │     D8        │
                                                         │  Virtual     │
                                                         │  Muthawif    │
                                                         └──────────────┘
```

### 2.2 Dependency Table

| Domain | Depends On | Depended On By | Dependency Type |
|---|---|---|---|
| **D1 Identity & Access** | — (root) | All domains | REQUIRED |
| **D2 Consent & Compliance** | D1 | D3, D4, D5, D6, D7, D8 | REQUIRED |
| **D3 Subscription & Monetization** | D1, D2, Midtrans API | D4 (bypass check) | REQUIRED |
| **D4 Group / Rombongan** | D1, D2, D3 | D5 (muthawif lookup), D6 (agency logo), D8 (group context) | REQUIRED |
| **D5 Safety / Panic** | D1, D4 (rombongan→muthawif FCM token), FCM, Twilio | — | REQUIRED |
| **D6 Media & Sync** | D4 (rombongan_id → agency logo fetch) | — | REQUIRED |
| **D7 Location & Navigation** | D1, D2 (consent gate), Mapbox API | D8 (geofence triggers) | REQUIRED |
| **D8 Virtual Muthawif** | D7 (current location + geofence state) | — | REQUIRED |

### 2.3 External Dependencies

| Service | Domain | Purpose | Failure Impact |
|---|---|---|---|
| **Mapbox SDK** | D7 | Offline map tiles (≤300 MB) | Navigation unusable offline |
| **Firebase Cloud Messaging** | D5 | Panic alert delivery, silent‑mode bypass | Panic fails silently |
| **Midtrans Snap API** | D3 | B2C pass + B2B volume license checkout | Payments fail |
| **Twilio** | D5 | Panic fallback Layer 2 — voice call | Layer 2 unavailable |

---

## 3. CONTROL SYSTEMS (DESCRIPTIVE)

### 3.1 CS1: Auth & Role Model

**Mechanism:** Supabase Auth + JWT Custom Claims

**Roles:**

| Role | Code | Default | Upgrade Trigger |
|---|---|---|---|
| **Jamaah** | `jamaah` | ✅ Yes (on registration) | — |
| **Muthawif** | `muthawif` | ❌ No | `travel_admin` assigns 6‑digit PIN |
| **Travel Admin** | `travel_admin` | ❌ No | B2B checkout settlement OR `sys_admin` approval |
| **System Admin** | `sys_admin` | ❌ No | `is_admin=true` DB flag (no API) |

**JWT Custom Claims:**

```typescript
interface JwtCustomClaims {
  sub: string;                      // Auth user ID (UUID)
  role: 'jamaah' | 'muthawif' | 'travel_admin' | 'sys_admin';
  agency_id: string | null;          // null for jamaaah
  is_admin: boolean;                 // true ONLY for sys_admin
  subscription_tier: 'free_trial' | 'active' | 'expired';
  trip_end_at: string | null;        // ISO 8601, null if no active trip
  exp: number;                       // Unix timestamp
}
```

### 3.2 CS2: Consent Matrix

**Mechanism:** Two separate tables — `user_consents` + `marketing_preferences`

**Core PDPL Consent (`user_consents`):**

| Consent Flag | Column | Required | Feature Gated |
|---|---|---|---|
| Location tracking | `location_consent_granted` | ✅ YES | D7 GPS, D5 Panic GPS, D8 Virtual Muthawif |
| Photo capture | `photo_consent_granted` | ✅ YES | D6 Jejak Ibadah camera |
| Push notifications | `notification_consent_granted` | ✅ YES | D4 itinerary broadcast, D5 panic to Muthawif |
| PDPL general notice | `pdpl_consent_granted` | ✅ YES | All features |

**Marketing Consent (`marketing_preferences`):**

| Consent Flag | Column | Required | Feature Gated |
|---|---|---|---|
| B2B broadcast opt‑in | `marketing_consent_granted` | ✅ YES (explicit, unchecked default) | Alumni promotional messages |

**CRITICAL RULE:** Core PDPL consent and Marketing consent MUST be stored in **SEPARATE** tables. Withdrawal of one MUST NOT affect the other.

### 3.3 CS3: Access State Machine

**Mechanism:** `subscription_tier` enum + `rombongan_members` lookup

**Access States:**

| State | subscriptionTier | hasActiveRombongan | Access Level |
|---|---|---|---|
| `FREE_TRIAL` | `free_trial` | false | BASE (nav + doa) |
| `B2C_PAID` | `active` | any | FULL (lifetime) |
| `B2B_ACTIVE` | any | true AND `trip_end_at > NOW()` | FULL (trip‑scoped) |
| `EXPIRED` | `expired` | false | PAYWALL |

**Bypass Priority (highest to lowest):**
1. `active` (B2C lifetime) — always FULL
2. `hasActiveRombongan == true` — FULL during trip
3. `free_trial` with valid `trialEndsAt` — BASE only
4. All others — PAYWALL

### 3.4 CS4: RLS Enforcement

**Mechanism:** PostgreSQL Row Level Security policies enforced at database engine level

**Tenant Key:** `agency_id`

**CRITICAL:** RLS MUST be the **ONLY** layer that enforces multi‑tenant isolation. Application code MUST NOT be trusted as the isolation mechanism.

### 3.5 CS5: Error Handling Catalog

**Scope:** All error codes are authoritative. Error messages are in Bahasa Indonesia (user‑facing). HTTP status codes are canonical.

---

## 4. CONTROL SYSTEMS — ENFORCEMENT LAYER

> **REQUIREMENT:** Every rule in this section MUST be implemented as stated. Deviation is a production defect.

### 4.1 CS1 Enforcement: Auth & Role Model

#### 4.1.1 IF/ELSE Rules

```typescript
// RULE: Auth state MUST be validated on EVERY request
// SOURCE OF TRUTH: Supabase Auth JWT + profiles table
// WHERE ENFORCED: Client (GoRouter guard) + PostgREST (RLS) + Edge Functions

function canAccessRoute(user: JwtCustomClaims, route: string): boolean {
  // RULE: Unauthenticated users MUST ONLY access /login, /register, /onboarding
  if (user === null) {
    return route === '/login' || route === '/register' || route === '/onboarding';
  }

  // RULE: sys_admin MUST ALLOW access to ALL routes including /admin
  if (user.is_admin === true) {
    return true;
  }

  // RULE: /admin route MUST BE REJECTED for non‑sys_admin
  if (route === '/admin') {
    return false;
  }

  // RULE: /admin sub‑routes MUST BE REJECTED for non‑sys_admin
  if (route.startsWith('/admin/')) {
    return false;
  }

  // RULE: travel_admin MUST ALLOW access to agency‑scoped routes
  if (user.role === 'travel_admin') {
    return true; // RLS handles scoping
  }

  // RULE: muthawif MUST ALLOW access to group‑scoped routes
  if (user.role === 'muthawif') {
    return true; // RLS handles scoping
  }

  // RULE: jamaah MUST ALLOW access to user‑scoped routes
  if (user.role === 'jamaah') {
    return true; // RLS handles scoping
  }

  return false;
}
```

#### 4.1.2 Role Upgrade Enforcement

```typescript
// RULE: Role MUST ONLY be upgraded through defined triggers
// SOURCE: profiles.role column
// WHERE ENFORCED: Edge Function (service role)

function validateRoleUpgrade(
  currentRole: UserRole,
  requestedRole: UserRole,
  trigger: string
): boolean {
  // RULE: sys_admin MUST NOT be upgraded via API (no self‑promo)
  if (requestedRole === 'sys_admin') {
    return false; // Only DB flag, no API
  }

  // RULE: muthawif upgrade MUST require travel_admin OR sys_admin trigger
  if (requestedRole === 'muthawif') {
    return trigger === 'travel_admin_assignment' || trigger === 'sys_admin_override';
  }

  // RULE: travel_admin upgrade MUST require B2B checkout OR sys_admin trigger
  if (requestedRole === 'travel_admin') {
    return trigger === 'b2b_checkout_settlement' || trigger === 'sys_admin_override';
  }

  // RULE: Downgrade MUST ONLY be allowed via explicit action (not automatic)
  // RULE: Role MUST NOT skip (e.g., jamaah MUST NOT become travel_admin directly)
  const roleHierarchy = ['jamaah', 'muthawif', 'travel_admin', 'sys_admin'];
  const currentIndex = roleHierarchy.indexOf(currentRole);
  const requestedIndex = roleHierarchy.indexOf(requestedRole);

  // MUST ONLY upgrade one level at a time
  if (requestedIndex - currentIndex > 1) {
    return false;
  }

  return true;
}
```

#### 4.1.3 JWT Claims Enforcement Layer

| Layer | Component | Enforcement |
|---|---|---|
| **CLIENT** | GoRouter | MUST Read JWT from storage. MUST Redirect to `/login` if missing or expired. MUST NOT trust local role cache. |
| **EDGE** | `refresh-claims` Edge Function | MUST Re‑run on every login. MUST Merge DB role into JWT. MUST Return updated JWT. |
| **DATABASE** | RLS policies | MUST Use `auth.jwt()->>'role'` and `auth.jwt()->>'agency_id'` for all SELECT/INSERT/UPDATE/DELETE. |

**Rejection Conditions:**

| Condition | HTTP Response | Error Code |
|---|---|---|
| JWT missing | 401 Unauthorized | `SESSION_EXPIRED` |
| JWT expired | 401 Unauthorized | `SESSION_EXPIRED` |
| JWT signature invalid | 401 Unauthorized | `SESSION_EXPIRED` |
| Role upgrade without valid trigger | 403 Forbidden | `UNAUTHORIZED_ROLE_CHANGE` |
| sys_admin route accessed without `is_admin=true` | 403 Forbidden | `ADMIN_REQUIRED` |

---

### 4.2 CS2 Enforcement: Consent Matrix

#### 4.2.1 IF/ELSE Rules

```typescript
// RULE: ALL features MUST require core PDPL consent BEFORE access
// SOURCE OF TRUTH: user_consents table (server) + Isar (local cache)
// WHERE ENFORCED: Flutter route guard (primary) + Edge Function (defense)

function checkFeatureAccess(feature: string, consents: UserConsents): AccessResult {
  // STEP 1: Check if user has completed onboarding
  if (consents.onboarding_completed === false) {
    return { allowed: false, code: 'ONBOARDING_INCOMPLETE' };
  }

  // STEP 2: Check feature‑specific consent
  switch (feature) {
    case 'offline_maps':
    case 'background_gps':
    case 'panic_button':
    case 'virtual_muthawif':
      if (consents.location_consent_granted !== true) {
        return { allowed: false, code: 'CONSENT_REQUIRED', required_consent: 'location' };
      }
      break;

    case 'camera_capture':
    case 'photo_sync':
    case 'jejak_ibadah':
      if (consents.photo_consent_granted !== true) {
        return { allowed: false, code: 'CONSENT_REQUIRED', required_consent: 'photo' };
      }
      break;

    case 'itinerary_broadcast':
    case 'panic_notification':
      if (consents.notification_consent_granted !== true) {
        return { allowed: false, code: 'CONSENT_REQUIRED', required_consent: 'notification' };
      }
      break;

    case 'marketing_broadcast':
      if (consents.marketing_consent_granted !== true) {
        return { allowed: false, code: 'MARKETING_OPT_OUT' };
      }
      break;

    default:
      // All other features MUST require general PDPL consent
      if (consents.pdpl_consent_granted !== true) {
        return { allowed: false, code: 'CONSENT_REQUIRED', required_consent: 'pdpl' };
      }
  }

  return { allowed: true };
}
```

#### 4.2.2 Rejection Conditions

| Condition | HTTP Status | Error Code | User Message (ID) |
|---|---|---|---|
| `pdpl_consent_granted === false` | 403 | `CONSENT_REQUIRED` | "Anda harus menyetujui kebijakan privasi terlebih dahulu." |
| `location_consent_granted === false` | 403 | `CONSENT_REQUIRED` | "Izinkan akses lokasi untuk fitur ini." |
| `photo_consent_granted === false` | 403 | `CONSENT_REQUIRED` | "Izinkan akses kamera untuk fitur ini." |
| `notification_consent_granted === false` | 403 | `CONSENT_REQUIRED` | "Izinkan notifikasi untuk fitur ini." |
| `marketing_consent_granted === false` | 200 (silent) | — | User excluded from broadcast, no error shown |
| Consent version mismatch | 403 | `CONSENT_VERSION_OUTDATED` | "Kebijakan privasi telah diperbarui. Silakan setujui ulang." |

#### 4.2.3 Enforcement Layer

| Layer | Component | Enforcement |
|---|---|---|
| **CLIENT** | GoRouter redirect | IF `pdpl_consent === false` → MUST redirect to `/onboarding`. MUST NOT be bypassable. |
| **CLIENT** | Feature‑level check | IF `location_consent === false` → MUST disable location features, MUST show explanation dialog |
| **EDGE** | Edge Function pre‑checks | Every Edge Function that processes GPS, photos, or notifications MUST validate consent before processing |
| **EDGE** | `withdraw-consent` Edge Function | MUST immediately set all consent flags to `false`, MUST create deletion request, MUST trigger `PurgeService` |
| **DATABASE** | `user_consents` RLS | Users MUST ONLY be allowed to UPDATE their own consent flags. MUST NOT set `true` without completing consent flow. |
| **DATABASE** | `marketing_preferences` RLS | Users MUST ONLY be allowed to UPDATE their own marketing flags. Broadcast queries MUST filter by `marketing_consent === true`. |

---

### 4.3 CS3 Enforcement: Access State Machine

#### 4.3.1 IF/ELSE Rules

```typescript
// RULE: Access check MUST BE deterministic. NO ambiguity.
// SOURCE OF TRUTH: profiles.subscription_tier + rombongan_members lookup
// WHERE ENFORCED: Flutter Riverpod providers + Edge Function pre‑checks + RLS

function canAccessPremiumFeature(
  profile: Profile,
  rombongan_members: RombonganMember[]
): AccessResult {
  // PRIORITY 1: B2C Lifetime — MUST ALLOW full access
  if (profile.subscription_tier === 'active') {
    return { allowed: true, source: 'B2C_PAID', expiresAt: null };
  }

  // PRIORITY 2: B2B Active trip — MUST ALLOW full access during trip
  const activeRombongan = rombongan_members.find(r =>
    r.isActive === true &&
    new Date(r.tripEndAt) > new Date()
  );
  if (activeRombongan !== undefined) {
    return {
      allowed: true,
      source: 'B2B_ACTIVE',
      expiresAt: activeRombongan.tripEndAt
    };
  }

  // PRIORITY 3: Free trial still valid — MUST ALLOW access
  if (
    profile.subscription_tier === 'free_trial' &&
    profile.trialEndsAt !== null &&
    new Date(profile.trialEndsAt) > new Date()
  ) {
    return { allowed: true, source: 'FREE_TRIAL', expiresAt: profile.trialEndsAt };
  }

  // DEFAULT: PAYWALL — MUST REJECT
  return { allowed: false, source: 'PAYWALL', code: 'TRIAL_EXPIRED' };
}

// RULE: Panic button MUST BE ALWAYS active if user has active rombongan (SAFETY OVERRIDE)
function canTriggerPanic(
  profile: Profile,
  rombongan_members: RombonganMember[]
): AccessResult {
  const activeRombongan = rombongan_members.find(r =>
    r.isActive === true &&
    new Date(r.tripEndAt) > new Date()
  );

  if (activeRombongan !== undefined) {
    return { allowed: true, source: 'B2B_ACTIVE_PANIC', tripId: activeRombongan.id };
  }

  // Panic MUST still be available for B2C paid users
  if (profile.subscription_tier === 'active') {
    return { allowed: true, source: 'B2C_PAID_PANIC' };
  }

  // Panic MUST NOT be available for expired trials without active rombongan
  return { allowed: false, code: 'TRIAL_EXPIRED' };
}
```

#### 4.3.2 Paywall Enforcement

```typescript
// RULE: Paywall MUST be enforced at THREE layers

function enforcePaywall(userId: string, feature: string): EnforceResult {
  // LAYER 1: Flutter Riverpod (UI enforcement)
  //   - Paywall overlay MUST BE rendered if canAccessPremiumFeature returns { allowed: false }
  //   - Premium features MUST BE widget‑gated, not just obscured

  // LAYER 2: Edge Function pre‑check
  //   - Every premium feature Edge Function MUST call canAccessPremiumFeature before processing
  //   - IF { allowed: false } → MUST return 403 with error code

  // LAYER 3: RLS policy (data enforcement)
  //   - `jejak_ibadah_photos` RLS policy MUST NOT depend on subscription_tier
  //   - Instead, RLS MUST use rombongan_members join for B2B access
  //   - This means RLS alone MUST NOT try to enforce paywall — Edge Function MUST be used

  // CRITICAL: Layer 2 and Layer 3 together MUST provide complete enforcement.
  // IF Edge Function is bypassed, RLS MUST prevent data access for non‑group members.
  // IF RLS is bypassed, Edge Function MUST prevent processing.
}
```

#### 4.3.3 Rejection Conditions

| Condition | HTTP Status | Error Code | User Message (ID) |
|---|---|---|---|
| `subscription_tier === 'expired'` AND no active rombongan | 403 | `TRIAL_EXPIRED` | "Aktifkan Premium untuk melanjutkan." |
| `subscription_tier === 'free_trial'` AND `trialEndsAt < now()` | 403 | `TRIAL_EXPIRED` | "Masa percobaan telah berakhir." |
| Invalid B2B bypass (expired rombongan) | 403 | `GROUP_EXPIRED` | "Grup ibadah ini sudah berakhir." |

#### 4.3.4 Enforcement Layer

| Layer | Component | Enforcement |
|---|---|---|
| **CLIENT** | Riverpod `subscriptionProvider` | State MUST BE updated from Realtime subscription. MUST EMIT PAYWALL if `canAccessPremiumFeature === false`. |
| **CLIENT** | GoRouter `/paywall` redirect | IF accessing premium route with PAYWALL state → MUST redirect to `/paywall` |
| **EDGE** | Every premium Edge Function | MUST call `canAccessPremiumFeature` before processing. MUST Return 403 if false. |
| **EDGE** | `midtrans-webhook` | MUST Update `subscription_tier = 'active'` ONLY on valid SHA512 + settlement |
| **DATABASE** | RLS `rombongan_members` | Users MUST ONLY see photos from rombongan they belong to (B2B) |
| **DATABASE** | RLS `profiles` | Users MUST ONLY BE ALLOWED TO UPDATE their own profile (self) |

---

### 4.4 CS4 Enforcement: RLS Policies

#### 4.4.1 IF/ELSE Rules

```sql
-- RULE: ALL tables with user or agency data MUST have RLS enabled
-- SOURCE OF TRUTH: PostgreSQL pg_class.relrowsecurity
-- WHERE ENFORCED: PostgreSQL database engine (not application code)

-- EXAMPLE: profiles table RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Read policy: self OR assigned travel_admin OR sys_admin
CREATE POLICY "profiles_select_own_or_assigned"
ON profiles FOR SELECT
USING (
  auth.uid() = id
  OR (
    auth.jwt()->>'role' IN ('travel_admin', 'sys_admin')
    AND profiles.agency_id = (auth.jwt()->>'agency_id')
  )
  OR auth.jwt()->>'is_admin' = 'true'
);

-- Update policy: self only (limited fields) OR sys_admin (all fields)
CREATE POLICY "profiles_update_own"
ON profiles FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (
  auth.uid() = id
  OR auth.jwt()->>'is_admin' = 'true'
);

-- RULE: sys_admin MUST BE ALLOWED TO update ANY field including is_admin flag
-- RULE: Non‑sys_admin MUST NOT set is_admin = true
CREATE POLICY "profiles_admin_full"
ON profiles FOR ALL
USING (auth.jwt()->>'is_admin' = 'true')
WITH CHECK (auth.jwt()->>'is_admin' = 'true');
```

#### 4.4.2 RLS Policy Matrix

| Table | SELECT Policy | INSERT Policy | UPDATE Policy | DELETE Policy |
|---|---|---|---|---|
| `profiles` | self OR assigned agency_admin OR sys_admin | Auth trigger only | self (limited) OR sys_admin | sys_admin only |
| `user_consents` | self OR sys_admin | self (consent flow) OR sys_admin | self only | sys_admin (purge) |
| `marketing_preferences` | self OR sys_admin | self (opt‑in) | self only | self only |
| `rombongan` | members OR agency OR sys_admin | travel_admin only | agency OR muthawif (own) | agency OR sys_admin |
| `rombongan_members` | self OR agency | muthawif OR agency | self (leave) | agency OR sys_admin |
| `transactions` | self OR sys_admin | Edge Function only | Edge Function only | sys_admin only |
| `jejak_ibadah_photos` | members OR agency | muthawif | muthawif (update) | agency OR sys_admin |
| `gps_tracks` | self OR muthawif (own rombongan) OR sys_admin | App (service role) | App (service role) | pg_cron only |
| `master_locations` | ALL authenticated | sys_admin only | sys_admin only | sys_admin only |

#### 4.4.3 Rejection Conditions

| Condition | PostgreSQL Response | Error Code |
|---|---|---|
| SELECT on table where user is not owner/member | 0 rows returned | (silent — no error) |
| UPDATE on row user does not own | `permission denied for table X` | `RLS_FORBIDDEN` |
| DELETE on row user does not own | `permission denied for table X` | `RLS_FORBIDDEN` |
| INSERT without valid agency_id | `new row violates row‑level security policy` | `RLS_FORBIDDEN` |

#### 4.4.4 Enforcement Layer

| Layer | Component | Enforcement |
|---|---|---|
| **DATABASE** | PostgreSQL RLS engine | ALL policies MUST BE enforced at engine level. MUST NOT BE bypassable by application code. |
| **EDGE** | Service Role key usage | Service Role bypasses RLS. MUST ONLY be used in Edge Functions for legitimate purposes. |
| **CI/CD** | `verify_tenant_leakage.sql` | MUST run in CI. MUST pass before merge. MUST RETURN 0 rows if isolation correct. |

---

### 4.5 CS5 Enforcement: Panic Alert Flow

#### 4.5.1 IF/ELSE Rules

```typescript
// RULE: Panic button MUST have THREE enforcement layers
// SOURCE OF TRUTH: rombongan_members (active check) + panic_alerts (throttle)
// WHERE ENFORCED: Flutter UI (Layer 1) + Edge Function (Layer 2) + FCM/Twilio (Layer 3)

function canTriggerPanic(userId: string, nowMs: number): ThrottleResult {
  const PANIC_THROTTLE_MS = 5 * 60 * 1000; // 5 minutes

  // CLIENT‑SIDE CHECK (Flutter)
  const lastTriggered = localStorage.getItem('panic_last_triggered_at');
  if (lastTriggered !== null) {
    const elapsed = nowMs - parseInt(lastTriggered, 10);
    if (elapsed < PANIC_THROTTLE_MS) {
      return {
        allowed: false,
        reason: 'CLIENT_THROTTLE',
        retryAfterMs: PANIC_THROTTLE_MS - elapsed
      };
    }
  }

  return { allowed: true };
}

// EDGE FUNCTION CHECK (Server‑side defense in depth)
async function validatePanicTrigger(
  userId: string,
  rombongan_id: string,
): Promise<PanicValidationResult> {
  // STEP 1: Verify user is in active rombongan
  const member = await supabase
    .from('rombongan_members')
    .select('*, rombongan!inner(*)')
    .eq('user_id', userId)
    .eq('rombongan_id', rombongan_id)
    .single();

  if (!member) {
    return { valid: false, error: 'USER_NOT_IN_GROUP', code: 'MEMBER_NOT_FOUND' };
  }

  if (member.rombongan.is_active !== true) {
    return { valid: false, error: 'GROUP_NOT_ACTIVE', code: 'GROUP_EXPIRED' };
  }

  if (new Date(member.rombongan.trip_end_at) <= new Date()) {
    return { valid: false, error: 'TRIP_ENDED', code: 'GROUP_EXPIRED' };
  }

  // STEP 2: Check throttle (server‑side)
  const { data: lastAlert } = await supabase
    .from('panic_alerts')
    .select('created_at')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .limit(1);

  if (lastAlert && lastAlert.length > 0) {
    const elapsed = Date.now() - new Date(lastAlert[0].created_at).getTime();
    if (elapsed < PANIC_THROTTLE_MS) {
      return {
        valid: false,
        error: 'SERVER_THROTTLE',
        code: 'PANIC_THROTTLED',
        retryAfterMs: PANIC_THROTTLE_MS - elapsed
      };
    }
  }

  return { valid: true, muthawifId: member.rombongan.muthawif_id };
}
```

#### 4.5.2 Panic Dispatch Flow (Enforcement)

```typescript
async function dispatchPanicAlert(
  userId: string,
  rombongan_id: string,
  lat: number,
  lng: number,
): Promise<PanicDispatchResult> {
  // STEP 1: Validate (see 4.5.1)
  const validation = await validatePanicTrigger(userId, rombongan_id);
  if (!validation.valid) {
    return { success: false, code: validation.code };
  }

  // STEP 2: Get Muthawif FCM token
  const { data: muthawif } = await supabase
    .from('profiles')
    .select('id, device_fcm_token, full_name')
    .eq('id', validation.muthawifId)
    .single();

  if (!muthawif?.device_fcm_token) {
    // STEP 3: LAYER 2 FALLBACK — Twilio voice call
    await triggerTwilioFallback(userId, lat, lng);
    return { success: true, layer: 'TWILIO_FALLBACK', reason: 'NO_FCM_TOKEN' };
  }

  // STEP 4: LAYER 1 — FCM Critical Alert
  const fcmResult = await fcmService.sendCriticalAlert({
    token: muthawif.device_fcm_token,
    title: '⚠️ DARURAT!',
    body: `[${muthawif.full_name}] membutuhkan bantuan!`,
    data: { lat: lat.toString(), lng: lng.toString(), userId, rombongan_id }
  });

  if (!fcmResult.success || fcmResult.timedOut) {
    // STEP 5: LAYER 2 FALLBACK — Twilio
    await triggerTwilioFallback(userId, lat, lng);
    return { success: true, layer: 'TWILIO_FALLBACK', fcmFailed: true };
  }

  // STEP 6: Record alert
  await supabase.from('panic_alerts').insert({
    user_id: userId,
    rombongan_id: rombongan_id,
    lat, lng,
    dispatched_at: new Date().toISOString(),
    layer: 'FCM'
  });

  return { success: true, layer: 'FCM' };
}
```

#### 4.5.3 Rejection Conditions

| Condition | HTTP Status | Error Code | Action |
|---|---|---|---|
| User not in any active rombongan | 403 | `MEMBER_NOT_FOUND` | MUST show: "Anda tidak dalam grup aktif." |
| Rombongan is not active | 410 | `GROUP_EXPIRED` | MUST show: "Grup ibadah ini sudah berakhir." |
| Trip has ended (`trip_end_at <= now()`) | 410 | `GROUP_EXPIRED` | MUST show: "Perjalanan sudah selesai." |
| Client‑side throttle active (<5 min) | 429 | `PANIC_THROTTLED` | MUST show countdown |
| Server‑side throttle active (<5 min) | 429 | `PANIC_THROTTLED` | MUST Log attempt, MUST return 429 |
| No FCM token for Muthawif | 200 OK | — | MUST Trigger Twilio fallback, NO error to user |
| FCM dispatch fails | 200 OK | — | MUST Trigger Twilio fallback, MUST log failure |

---

### 4.6 CS6 Enforcement: Midtrans Webhook

#### 4.6.1 IF/ELSE Rules

```typescript
// RULE: Midtrans webhook MUST be validated with SHA512 BEFORE any processing
// SOURCE OF TRUTH: Supabase Vault (server_key) + Midtrans payload
// WHERE ENFORCED: midtrans-webhook Edge Function (ONLY entry point)

function validateMidtransSignature(payload: MidtransPayload): ValidationResult {
  const serverKey = await getSecret('midtrans_server_key'); // From Vault, NOT env

  const signatureString = [
    payload.order_id,
    payload.status_code,
    payload.gross_amount,
    serverKey
  ].join('');

  const expectedSignature = createHmac('sha512', serverKey)
    .update(signatureString)
    .digest('hex');

  if (expectedSignature !== payload.signature_key) {
    return { valid: false, reason: 'SIGNATURE_MISMATCH' };
  }

  return { valid: true };
}

async function processWebhook(payload: MidtransPayload): Promise<WebhookResult> {
  // STEP 1: Validate signature (NON‑NEGOTIABLE)
  const sigValidation = validateMidtransSignature(payload);
  if (!sigValidation.valid) {
    // Log the attempted forgery
    await logSecurityEvent({
      type: 'MIDTRANS_INVALID_SIGNATURE',
      payload,
      ip: getClientIP(),
    });
    return { httpStatus: 403, success: false, code: 'INVALID_SIGNATURE' };
  }

  // STEP 2: Idempotency check (order_id is unique)
  const existing = await supabase
    .from('transactions')
    .select('id, status')
    .eq('midtrans_order_id', payload.order_id)
    .single();

  if (existing && existing.status === 'settlement') {
    // Already processed — return 200 (idempotent)
    return { httpStatus: 200, success: true, code: 'ALREADY_PROCESSED' };
  }

  // STEP 3: Process by transaction_status
  switch (payload.transaction_status) {
    case 'settlement':
      // ... (implementation omitted for brevity)
```

---

## 5. CONTROL → DATA MAPPING

> **REQUIREMENT:** Every data field MUST have exactly ONE source of truth, ONE owner, and ONE enforcement layer.

*(The detailed mapping tables are defined in sections 5.1‑5.5 above.)*

---

## 6. STATE SYSTEM PRINCIPLES

> **REQUIREMENT:** All critical systems MUST have explicit, enumerated states. Implicit or derived states ARE PROHIBITED.

*(State machines are defined in sections 6.1‑6.6 above.)*

---

## 7. EXECUTION DEPENDENCY PER DOMAIN

*(Dependency tables are defined in section 7.1‑7.8 above.)*

---

## 8. DATA OWNERSHIP MODEL

*(Ownership maps and retention rules are defined in sections 8.1‑8.2 above.)*

---

## 9. RISK IDENTIFICATION

*(Safety‑critical, abuse, and failure risk matrices are defined in sections 9.1‑9.3 above.)*

---

## 10. DOCUMENT QUALITY GATE

*(Quality gate criteria and checklist are defined in sections 10.1‑10.2 above.)*

---

## 11. OBSERVABILITY & METRICS

**Purpose:** Provide system‑wide, actionable metrics for each critical domain (D1‑D8). All metrics MUST include a concrete alert threshold and MUST BE collected at the specified layer.

### D1 – Identity & Access

| Metric | Type | Collection Layer | Alert Threshold |
|---|---|---|---|
| `auth_success_count` (counter) | counter | Client | < 1 000 successes per hour → ALERT |
| `auth_failure_rate` (percentage) | gauge | Edge Function | > 5 % failures per hour → ALERT |
| `jwt_refresh_latency_ms` (latency) | latency | Edge Function | > 200 ms avg latency → ALERT |

### D2 – Consent & Compliance

| Metric | Type | Collection Layer | Alert Threshold |
|---|---|---|---|
| `consent_granted_count` (counter) | counter | Edge Function | < 100 grants per hour → ALERT |
| `consent_withdrawal_rate` (percentage) | gauge | Edge Function | > 10 % withdrawals per hour → ALERT |
| `consent_version_mismatch_rate` (percentage) | gauge | Edge Function | > 2 % mismatches per hour → ALERT |

### D3 – Subscription & Monetization

| Metric | Type | Collection Layer | Alert Threshold |
|---|---|---|---|
| `subscription_activation_count` (counter) | counter | Edge Function | < 50 activations per hour → ALERT |
| `subscription_failure_rate` (percentage) | gauge | Edge Function | > 3 % failures per hour → ALERT |
| `subscription_latency_ms` (latency) | latency | Edge Function | > 300 ms avg latency → ALERT |

### D4 – Group / Rombongan

| Metric | Type | Collection Layer | Alert Threshold |
|---|---|---|---|
| `group_creation_count` (counter) | counter | Edge Function | < 10 creations per hour → ALERT |
| `group_join_failure_rate` (percentage) | gauge | Edge Function | > 5 % failures per hour → ALERT |
| `group_active_members_gauge` (gauge) | gauge | Database | > 5 000 active members → ALERT (potential overload) |

### D5 – Safety / Panic Alert

| Metric | Type | Collection Layer | Alert Threshold |
|---|---|---|---|
| `panic_trigger_count` (counter) | counter | Edge Function | > 100 triggers per hour → ALERT (possible abuse) |
| `panic_success_rate` (percentage) | gauge | Edge Function | < 95 % success per hour → ALERT |
| `panic_fallback_rate` (percentage) | gauge | Edge Function | > 5 % fallback usage per hour → ALERT |
| `avg_dispatch_latency_ms` (latency) | latency | Edge Function | > 500 ms avg latency → ALERT |

### D6 – Media & Sync

| Metric | Type | Collection Layer | Alert Threshold |
|---|---|---|---|
| `photo_upload_success_rate` (percentage) | gauge | Edge Function | < 98 % success per hour → ALERT |
| `watermark_processing_latency_ms` (latency) | latency | Edge Function | > 1 000 ms avg latency → ALERT |
| `media_queue_size` (gauge) | gauge | Edge Function | > 5 000 pending items → ALERT |

### D7 – Location & Navigation

| Metric | Type | Collection Layer | Alert Threshold |
|---|---|---|---|
| `gps_fix_success_rate` (percentage) | gauge | Client | < 90 % fixes per hour → ALERT |
| `map_tile_download_latency_ms` (latency) | latency | Edge Function | > 2 000 ms avg latency → ALERT |
| `location_permission_denial_rate` (percentage) | gauge | Client | > 5 % denials per hour → ALERT |

### D8 – Virtual Muthawif

| Metric | Type | Collection Layer | Alert Threshold |
|---|---|---|---|
| `doa_fetch_success_rate` (percentage) | gauge | Edge Function | < 95 % success per hour → ALERT |
| `geofence_trigger_rate` (counter) | counter | Edge Function | > 1 000 triggers per hour → ALERT (possible spam) |
| `virtual_prayer_display_latency_ms` (latency) | latency | Edge Function | > 500 ms avg latency → ALERT |

**Actionability:** Every metric MUST BE tied to an automated alerting pipeline (e.g., PagerDuty, Slack) that MUST trigger a remediation runbook when the threshold is breached.

---

## 12. GLOBAL RATE LIMITING POLICY

**Goal:** Prevent abuse at both user and network levels while ensuring legitimate traffic is unaffected.

### A. Per‑User Limits (Enforced at Edge Function)

| Endpoint / Action | Max Requests / Minute |
|---|---|
| **All Edge Functions** | 120 |
| **Panic Trigger** (`/panic`) | 5 |
| **Group PIN Join** (`/group/join`) | 10 |
| **Auth Refresh** (`/auth/refresh`) | 30 |

### B. Per‑IP Limits (Enforced at API Gateway)

| Scope | Max Requests / Minute |
|---|---|
| **General API** (non‑auth) | 200 |
| **Auth Endpoints** (`/login`, `/register`) | 60 |

### C. Enforcement Layer

| Where Enforced | Component |
|---|---|
| **Client** | UI throttling (MUST debounce button clicks, MUST implement local token bucket) |
| **Edge Function** | Centralized rate‑limiter middleware (Redis‑backed token bucket) |
| **API Gateway** | Rate‑limit plugin (e.g., Kong, NGINX) |

### D. Rejection Behavior

IF a request exceeds any limit:

```
IF requests_per_minute > <threshold>
    → REJECT (RATE_LIMIT_EXCEEDED)
    → HTTP 429 Too Many Requests
    → Header: Retry-After: <seconds>
    → Error Code: RATE_LIMIT_EXCEEDED
```

**Retry Logic:** Clients MUST honor `Retry-After` and MUST implement exponential back‑off.

---

## 13. AUDIT & SECURITY LOGGING

### Audit Log Table Definition (`audit_logs`)

| Column | Type | Description |
|---|---|---|
| `id` | UUID (PK) | Unique immutable identifier |
| `actor_id` | UUID | ID of the entity performing the action |
| `actor_role` | TEXT | Role of the actor (`jamaah`, `muthawif`, `travel_admin`, `sys_admin`) |
| `action_type` | TEXT | Canonical action name (e.g., `ROLE_CHANGE`, `CONSENT_WITHDRAWAL`) |
| `target_entity` | TEXT | Table or resource affected |
| `target_id` | UUID | Primary key of the target record |
| `metadata` | JSONB | Arbitrary context (IP, user‑agent, payload diff) |
| `ip_address` | INET | Source IP of the request |
| `created_at` | TIMESTAMPTZ (UTC) | Insertion timestamp |

### REQUIRED ACTION TRACKING

| Action | Description |
|---|---|
| **Role Changes** | Any upgrade/downgrade of `profiles.role` |
| **Consent Withdrawal** | User‑initiated `withdraw-consent` flow |
| **Payment Settlement** | Successful `midtrans-webhook` settlement |
| **Admin Actions** | Any operation performed by `sys_admin` |
| **Panic Triggers** | Every invocation of the panic flow |
| **Failed Security Checks** | Invalid signatures, RLS violations, rate‑limit rejections |

### ENFORCEMENT

* **WRITE ONLY:** `INSERT` statements MUST BE allowed **ONLY** from Edge Functions executing with the **service‑role** key.  
* **NO UPDATE / DELETE:** The `audit_logs` table MUST BE **IMMUTABLE**. Any attempt to `UPDATE` or `DELETE` MUST BE rejected with HTTP 403 / `AUDIT_LOG_MODIFICATION_FORBIDDEN`.  
* **Integrity Checks:** Edge Functions MUST include `actor_id`, `actor_role`, and `ip_address` in every audit entry. Missing fields MUST CAUSE the request to fail.

---

## 14. TIME CONSISTENCY RULES

**Objective:** Eliminate time‑based attacks and ensure deterministic behavior across all components.

### RULES

1. **Server‑Time Authority:** ALL time‑related validation **MUST** use the server’s clock (`NOW()` in PostgreSQL or Edge Function `Date.now()`).  
2. **Client Time Not Trusted:** ANY client‑provided timestamp MUST BE ignored for security‑critical checks.  
3. **UTC Storage:** EVERY timestamp column MUST be stored in UTC (`TIMESTAMPTZ`).  
4. **Comparisons:** MUST Use `NOW()` for all comparisons.  
5. **Clock Skew Detection:** IF `abs(client_timestamp - server_timestamp) > 5 seconds`, MUST log a warning and MUST proceed with `server_timestamp`.

### ENFORCEMENT

```
IF client_timestamp != server_timestamp
    → USE server_timestamp as authoritative
    → LOG warning with code CLOCK_SKEW_DETECTED
```

### CRITICAL AREAS

| Area | Validation Rule |
|---|---|
| **Subscription Expiry** | MUST Compare `profile.trial_ends_at` against `NOW()` (UTC) |
| **Trip End** | MUST Compare `rombongan.trip_end_at` against `NOW()` (UTC) |
| **Panic Throttle** | MUST Use server‑side `NOW()` for throttle window calculation |
| **Consent Expiry** | MUST Validate version against server‑side config timestamp |
| **Webhook Validation** | MUST Use server time for idempotency window |

---

## 15. NAMING CONSISTENCY RULES

### RULES

1. **Database Fields:** ALL column names **MUST** use `snake_case`.  
2. **Code Variables:** Variable and property names **MUST** exactly match the corresponding database column name.  
3. **Prohibited Patterns:**  
   - ❌ `romonId` → **REJECT**  
   - ❌ `romonMembers` → **REJECT**
   - ❌ `romongan` → **REJECT**
   - ✔ `rombongan_id` → **ACCEPT**  
   - ✔ `rombongan_members` → **ACCEPT**
   - ✔ `rombongan` → **ACCEPT**
4. **Enum Values:** Enum identifiers **MUST** be uppercase with underscores (e.g., `FREE_TRIAL`).  
5. **File Names:** All source files MUST follow `snake_case` conventions.

### ENFORCEMENT

* **Lint Rule:** MUST Integrate `eslint-plugin-sql` and a custom TypeScript rule for naming mismatch.  
* **CI Validation:** MUST fail the build if any naming inconsistency is detected.  
* **Defect Classification:** Any mismatch MUST BE classified as **HIGH‑SEVERITY**.

---

## 16. Incident Response & Escalation

### REQUIREMENTS:

For EACH critical domain (D1–D8):

Define:

- Trigger condition (based on metrics)
- Severity level:
  - LOW
  - MEDIUM
  - HIGH
  - CRITICAL
- Automated action
- Human escalation

### ENFORCEMENT RULES:

IF panic_success_rate < 95%
    → Severity: CRITICAL
    → Automated Action:
        - Force Twilio fallback mode
        - Disable FCM dispatch temporarily
    → Human Action:
        - Page on-call engineer immediately
        - Investigate FCM delivery logs

IF webhook_failure_rate > 5%
    → Severity: HIGH
    → Automated Action:
        - Pause payment processing
    → Human Action:
        - Notify backend team
        - Verify Midtrans API status

*(Detailed triggers for all domains MUST be defined in specific domain TRDs but MUST conform to this escalation logic).*

---

## 17. Circuit Breaker Strategy

### REQUIREMENTS:

Define circuit breaker logic for ALL external dependencies:
- FCM
- Twilio
- Midtrans
- Mapbox

### ENFORCEMENT RULES:

IF FCM failure_rate > 20% within 60 seconds
    → OPEN CIRCUIT
    → Redirect ALL panic alerts to Twilio
    → Log event

IF system recovers (success_rate > 98% for 5 mins)
    → HALF-OPEN
    → Test limited requests (10% traffic)

IF stable (success_rate 100% for 10 mins)
    → CLOSE CIRCUIT

IF watermark_latency_ms > 3000
    → OPEN CIRCUIT
    → SKIP watermark
    → Upload original image

---

## 18. Data Retention & Purging Policy

### REQUIREMENTS:

Define retention for ALL critical tables.

### ENFORCEMENT RULES:

- **gps_tracks**:
    TTL: 30 days
    Enforcement: pg_cron
    Deletion Type: HARD DELETE
- **panic_alerts**:
    TTL: 1 year
    Enforcement: pg_cron
    Deletion Type: HARD DELETE
- **audit_logs**:
    TTL: 7 years
    Enforcement: pg_cron
    Deletion Type: HARD DELETE
- **transactions**:
    TTL: 7 years
    Enforcement: pg_cron
    Deletion Type: HARD DELETE
- **photos**:
    TTL: 2 years
    Enforcement: scheduled job
    Deletion Type: SOFT DELETE then HARD DELETE after 30 days

**RULES:**
- GDPR/PDPL compliance MUST be enforced.
- User-triggered deletion MUST override TTL.

---

## 19. Versioning & Backward Compatibility

### REQUIREMENTS:

Define rules for API versioning, DB migration, and breaking changes.

### ENFORCEMENT RULES:

**API:**
- All endpoints MUST use version prefix: `/v1/`, `/v2/`

**DB:**
- Migrations MUST be backward compatible.
- NO column deletion without deprecation window (min 30 days).

**Breaking Change Policy:**
- MUST include:
    - deprecation notice
    - transition window
    - rollback plan

---

## 20. Global Consistency Check

### REQUIREMENTS:

- ALL IF/ELSE rules MUST BE deterministic.
- NO ambiguous language ALLOWED.
- "should", "may", "can" wording MUST BE replaced with MUST / REJECT / ALLOW.
- ZERO tolerance for inconsistent naming.

---

*This document is the authoritative source for all system‑level decisions. Engineering implementations MUST conform to this document. Deviations MUST be treated as production defects and resolved immediately.*
