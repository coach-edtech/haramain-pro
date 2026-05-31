# System Overview — Haramain Pro

> Owner: Onyx
> Status: Authoritative
> Note: This file defines the official high-level system architecture, major domains, platform boundaries, and cross-system interactions for Haramain Pro.

## Purpose
Dokumen ini menjelaskan gambaran arsitektur sistem Haramain Pro secara menyeluruh agar manusia dan AI dapat memahami:

- komponen utama sistem
- batas tanggung jawab tiap platform
- relasi antar domain
- alur data lintas mobile, web, backend, dan external services
- area yang paling kritis untuk implementation dan review

Dokumen ini adalah **high-level technical map**, bukan detail implementasi per feature.

---

## System Definition
Haramain Pro adalah sistem **offline-first B2B2C** yang terdiri dari:

1. **Mobile app** untuk jamaah dan muthawif
2. **Web dashboard** untuk travel agency dan sys admin
3. **Backend platform** untuk auth, persistence, storage, realtime, dan edge middleware
4. **External integrations** untuk maps, payments, notifications, dan fallback emergency delivery

---

## Architectural Principle
Sistem mengikuti prinsip:

### 1. Offline-first
Fitur lapangan yang kritis harus tetap bekerja meski konektivitas buruk atau tidak ada internet.

### 2. Thin backend for orchestration, not heavy monolith
Backend dipakai untuk:
- auth
- storage
- data sync
- payments verification
- media processing
- emergency orchestration

Bukan sebagai monolith besar dengan banyak business logic tersebar tanpa batas.

### 3. Sensitive operations live outside the client
Operasi sensitif tidak boleh ditaruh di client, terutama:
- payment verification
- backend pricing calculation
- signature validation
- watermark processing
- push orchestration
- privileged claims propagation

### 4. Clear domain ownership
Setiap area sistem harus jelas:
- mobile only
- web only
- shared backend
- admin only

### 5. Multi-tenant safety
Karena travel agencies adalah tenant yang berbeda, data isolation wajib dijaga secara ketat.

---

## High-Level Topology

```text
[ Mobile App (Flutter) ] ----\
 \
 > [ Supabase Platform ] <---- [ Web Dashboard (React) ]
 / |
[ DX / Debug Tools ] --------/ |
 |
 +---- [ Edge Functions ]
 |
 +---- [ Realtime / Storage / Auth / DB ]
 |
 +---- [ External Services ]
 - Mapbox
 - Firebase Cloud Messaging
 - Midtrans
 - Twilio
```

---

## Primary System Domains

Sistem Haramain Pro dapat dipahami melalui domain-domain berikut.

### 1. Compliance & Consent Domain
Mengatur:
- onboarding consent
- consent state
- consent withdrawal
- deletion request
- marketing consent separation
- retention lifecycle

Ini adalah domain yang menentukan apakah user boleh mengakses fitur tertentu atau tidak.

---

### 2. Access & Entitlement Domain
Mengatur:
- free trial
- B2C lifetime access
- B2B trip-based access
- trip expiry behavior
- premium bypass via rombongan
- post-trip downgrade behavior

Domain ini menentukan **akses final user** terhadap fitur premium.

---

### 3. Group / Rombongan Domain
Mengatur:
- pembuatan rombongan
- assignment muthawif
- group join via numeric PIN
- trip lifecycle
- meeting point / itinerary broadcast
- agency association

Rombongan adalah domain penghubung penting antara B2B dan B2C.

---

### 4. Safety & Emergency Domain
Mengatur:
- panic button
- distressed coordinates
- panic routing to muthawif
- critical/high-priority notification
- Twilio fallback
- safety event delivery reliability

Ini adalah salah satu domain paling kritikal secara operasional.

---

### 5. Offline Navigation & Context Domain
Mengatur:
- Mapbox offline tiles
- geofence detection
- local prayer library
- contextual doa surfacing
- local location state

Domain ini harus tetap berjalan walau internet buruk.

---

### 6. Media & Jejak Ibadah Domain
Mengatur:
- local camera capture
- offline photo queue
- pre-compression
- sync after reconnect
- watermarking
- CRM photo gallery

Domain ini menjembatani pengalaman lapangan dengan CRM pasca-trip.

---

### 7. B2B Licensing & CRM Domain
Mengatur:
- agency registration
- logo upload
- bulk seat licensing
- volume discounts
- alumni segmentation
- marketing broadcast

Ini adalah domain utama untuk monetisasi B2B.

---

### 8. Admin & Operational Control Domain
Mengatur:
- global metrics
- trial overrides
- global test mode
- watermark preview
- debugging support
- operational verification tools

Beberapa tool di domain ini hanya tersedia untuk admin dan non-production contexts.

---

## Platform Boundaries

## Mobile App (Flutter)
### Responsibilities
Mobile app bertanggung jawab atas:
- consent onboarding UI
- route gating di sisi client
- offline maps
- geofence/contextual prayer
- panic trigger UI
- group join flow
- trial/paywall UI
- offline photo queue
- sync orchestration di sisi client
- local persistence

### Mobile-specific constraints
- harus usable saat internet buruk
- harus hemat storage
- harus hemat battery
- tidak boleh menyimpan secrets sensitif
- tidak boleh menjadi sumber kebenaran untuk operasi privileged

---

## Web Dashboard (React)
### Responsibilities
Web dashboard bertanggung jawab atas:
- agency onboarding
- PPIU/license capture
- bulk seat purchase UX
- volume pricing visualization
- CRM gallery browsing
- alumni segmentation
- promotional broadcast composition
- admin portal

### Web-specific constraints
- tidak mengelola field operations secara langsung
- tidak boleh bypass tenant isolation
- semua access admin harus strict-guarded

---

## Supabase Platform
### Responsibilities
Supabase bertindak sebagai core backend platform untuk:
- authentication
- JWT / claims basis
- PostgreSQL persistence
- RLS isolation
- realtime subscription updates
- storage buckets
- edge function execution

### Why Supabase matters
Supabase menjadi pusat:
- source of truth data
- authorization enforcement
- multi-tenant boundary
- async updates to clients

---

## Edge Functions
### Responsibilities
Edge Functions digunakan untuk operasi yang:
- sensitif
- privileged
- asynchronous
- integration-heavy

### Core edge functions
- `fcm-panic-alert`
- `photo-watermark`
- `midtrans-webhook`
- claim refresh / auth-related function bila dibutuhkan

### Why edge functions exist
Karena client tidak boleh dipercaya untuk:
- memverifikasi payment
- menghitung settlement final
- memproses watermark
- menjalankan service-role access
- mengorkestrasikan fallback emergency delivery secara aman

---

## External Services

### Mapbox
Dipakai untuk:
- offline tile download
- map rendering
- location-based visual context

### Firebase Cloud Messaging
Dipakai untuk:
- push notification
- high-priority alert delivery
- targeted broadcasts

### Midtrans
Dipakai untuk:
- B2C Safety Pass checkout
- B2B volume licensing checkout
- async settlement webhook

### Twilio
Dipakai untuk:
- fallback voice call
- potential SMS escalation
- bagian dari safety fallback stack

---

## Core Data Flows

## 1. Consent and Access Flow
```
User opens app
→ consent onboarding required
→ consent stored in backend + local state
→ free trial starts (if applicable)
→ access state computed from trial/B2C/B2B status
```

---

## 2. Panic Flow
```
User presses panic button
→ device captures coordinates
→ request sent to edge function
→ edge resolves muthawif target
→ FCM push sent
→ if push unreliable/fails, fallback path may trigger
```

---

## 3. Group Join Flow
```
User enters 6-digit numeric PIN
→ backend validates active rombongan
→ user bound to trip/group context
→ B2B access bypass applied while trip active
```

---

## 4. Payment Unlock Flow
```
User initiates Midtrans checkout
→ payment pending
→ Midtrans sends settlement webhook
→ edge validates signature
→ backend updates transaction + access state
→ client receives updated entitlement
```

---

## 5. Jejak Ibadah Sync Flow
```
Muthawif captures photo offline
→ photo pre-compressed locally
→ stored in local queue
→ connectivity returns
→ edge processes watermark
→ storage URL returned
→ local queue item marked synced
```

---

## Cross-Cutting System Concerns

## Offline Behavior
Offline is not an edge case.
Offline adalah kondisi utama untuk:
- maps
- prayer content
- photo queue
- field safety usability

---

## Multi-Tenant Security
Travel agency data harus benar-benar terisolasi.
Mekanisme utamanya:
- Supabase RLS
- role-aware access
- scoped claims
- agency binding logic

---

## Access Computation
Akses user tidak boleh dihitung sembarangan di banyak tempat.
Harus ada logical source yang konsisten untuk:
- trial state
- lifetime access
- trip-based bypass
- expiry behavior

---

## Compliance Lifecycle
Consent, withdrawal, deletion, retention, and marketing preferences bukan sekadar UI concern.
Ini adalah domain rules yang memengaruhi:
- route access
- data retention
- CRM behavior
- broadcast eligibility

---

## Production Gating
Fitur tertentu harus benar-benar dibatasi:
- GPS spoofer
- alert loopback
- sandbox toggles
- watermark preview test tools

Beberapa boleh ada di production hanya untuk admin.
Sebagian lain harus compile-time or runtime disabled.

---

## Domain-to-Platform Mapping

| Domain | Mobile | Web | Backend | Edge | External |
|---|---|---|---|---|---|
| Compliance & Consent | Yes | Limited | Yes | Optional | No |
| Access & Entitlement | Yes | Limited | Yes | Yes | Midtrans |
| Rombongan Management | Yes | Yes | Yes | Optional | No |
| Panic & Emergency | Yes | No | Yes | Yes | FCM, Twilio |
| Offline Navigation | Yes | No | Limited | No | Mapbox |
| Virtual Muthawif | Yes | No | Limited | No | Mapbox |
| Jejak Ibadah | Yes | Yes | Yes | Yes | Storage |
| B2B Licensing | Limited | Yes | Yes | Yes | Midtrans |
| Alumni Broadcast | Receive only | Yes | Yes | Optional | FCM |
| Admin Tools | Limited | Yes | Yes | Yes | Multiple |

---

## Current Technical Truths
Beberapa kebenaran sistem yang harus dianggap final saat ini:

- Mobile app menggunakan **Flutter**
- Web dashboard menggunakan **React**
- Backend utama menggunakan **Supabase**
- Local DB resmi untuk MVP adalah **Isar**
- Group join menggunakan **6-digit numeric PIN**
- Panic delivery menggunakan **layered fallback**
- MVP **tidak menyimpan passport/biometric data**
- Marketing consent **terpisah** dari operational consent
- B2B bypass access berlaku hanya saat trip aktif
- GPS history harus dipurge berdasarkan `trip_end_at`

---

## Main Risks by Architecture Layer

### Client layer risks
- local/server state mismatch
- battery drain
- storage exhaustion
- offline queue inconsistency

### Backend layer risks
- RLS mistakes
- stale claims
- pricing miscalculation
- retention jobs not running correctly

### Edge layer risks
- webhook verification failures
- watermark memory issues
- emergency fallback branching complexity

### Integration layer risks
- Midtrans settlement delays
- FCM delivery inconsistency
- Twilio costs / fallback reliability
- Mapbox offline package constraints

---

## What AI Should Do With This File
Gunakan file ini untuk:
- memahami gambaran Sistem
- mengenali domain boundaries
- menentukan platform mana yang harus disentuh
- memahami relasi high-level antar fitur

Jangan gunakan file ini sebagai pengganti:
- feature-specific PRD/TRD
- API contracts detail
- protocol-specific rules
- decision files

Untuk pekerjaan detail, lanjutkan ke:
- `feature-index.md`
- feature docs terkait
- protocol docs terkait
- decision docs terkait

---

## Related Documents
- `docs/00_ai-context/global-summary.md`
- `docs/00_ai-context/feature-index.md`
- `docs/00_ai-context/system-rules.md`
- `docs/00_ai-context/feature-ownership-matrix.md`
- `docs/03_technical/protocols/subscription-access-state-machine.md`
- `docs/03_technical/protocols/trip-lifecycle.md`
- `docs/03_technical/protocols/auth-role-model.md`
- `docs/03_technical/protocols/consent-matrix.md`
- `docs/03_technical/non-functional-requirements.md`
