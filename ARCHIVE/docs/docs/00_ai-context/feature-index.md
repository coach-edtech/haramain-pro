# Feature Index — Haramain Pro

> Owner: Onyx
> Status: Authoritative
> Note: This file is the master feature map for Haramain Pro. Use it to identify feature boundaries, dependencies, ownership direction, and reading order before opening detailed feature documents.

## Purpose
Dokumen ini adalah indeks fitur resmi untuk Haramain Pro.

Gunakan file ini untuk:
- melihat semua fitur utama dalam satu tempat
- memahami hubungan antar fitur
- menentukan fitur mana yang perlu dibaca lebih dulu
- membantu AI tools memilih konteks yang relevan
- membantu planning, implementation, review, dan UAT

Dokumen ini **bukan** pengganti detail feature docs.  
Untuk detail implementasi, selalu lanjut ke folder:
- `docs/05_features/{feature}/`

---

## How to Read This File
Gunakan urutan ini:

1. lihat **feature landscape** secara global
2. pilih fitur yang relevan
3. baca:
   - `summary.md`
   - `prd.md`
   - `trd.md`
   - `api.md`
   - `implementation.md`
4. cek keputusan terkait di `docs/06_decisions/`
5. cek protocol docs bila feature menyentuh logic lintas domain

---

## Feature Landscape

Haramain Pro dibagi ke dalam 12 fitur utama:

1. PDPL Consent
2. Marketing Consent
3. Offline Maps
4. Panic Alert
5. Virtual Muthawif
6. Subscription Paywall
7. B2B Volume Licensing
8. Rombongan Group Management
9. Jejak Ibadah
10. Agency Onboarding
11. Alumni Broadcast
12. Admin Tools
13. DX Tools

> Catatan: secara struktur repo saat ini `DX Tools` tetap dianggap feature operasional terpisah.

---

## Feature Catalog

| Feature | Purpose | Main Platforms | Priority | Depends On |
|---|---|---|---|---|
| `pdpl-consent` | Menangani onboarding consent, withdrawal, deletion, dan compliance access gating | Mobile, Backend | Critical | Auth, profiles, local purge, consent records |
| `marketing-consent` | Menangani opt-in/opt-out marketing per agency untuk broadcast alumni | Mobile, Web, Backend | High | Auth, consent records, alumni broadcast |
| `offline-maps` | Menyediakan peta offline Makkah/Madinah dengan batas storage 300MB | Mobile | Critical | Mapbox, local storage, trip context |
| `panic-alert` | Mengirim distress alert ke muthawif dengan fallback multi-layer | Mobile, Backend, Edge | Critical | FCM, Twilio, rombongan, device token |
| `virtual-muthawif` | Menampilkan doa kontekstual berdasarkan geofence/location | Mobile | High | GPS, geofence logic, doa cache, local storage |
| `subscription-paywall` | Mengatur trial, paywall, B2C lifetime access, dan unlock logic | Mobile, Backend, Edge | Critical | Midtrans, profiles, transaction state, access state machine |
| `b2b-volume-licensing` | Menangani pembelian seat licenses bulk oleh travel agency | Web, Backend, Edge | High | Midtrans, pricing formula, agency context |
| `rombongan-group-management` | Menangani pembuatan grup, join via PIN, trip lifecycle, dan bypass access | Mobile, Web, Backend | Critical | Auth, rombongan, subscription logic, trip model |
| `jejak-ibadah` | Menangani capture foto offline, queue, watermark sync, dan CRM media flow | Mobile, Backend, Edge, Web | High | Isar, media processing, storage, rombongan |
| `agency-onboarding` | Menangani registrasi agency, PPIU info, dan logo upload | Web, Backend | High | Auth, storage, agency records |
| `alumni-broadcast` | Menangani cohort selection dan pengiriman pesan promosi ke alumni | Web, Backend | High | Marketing consent, CRM cohorts, FCM |
| `admin-tools` | Menyediakan metrics, overrides, test toggles, dan internal controls | Web, Backend | Medium | Admin claims, metrics, sandbox controls |
| `dx-tools` | Menyediakan tools testing internal seperti GPS spoofer dan alert loopback | Mobile, Web Admin | Medium | Admin gating, non-production rules |

---

## Feature Summaries

## 1. `pdpl-consent`
### Goal
Memastikan user hanya dapat menggunakan fitur inti setelah memberikan consent yang diwajibkan.

### Includes
- onboarding consent
- consent state
- withdrawal
- deletion request
- local purge
- server-side deletion workflow

### Excludes
- passport storage
- biometric storage
- biometric processing di server

### Related Docs
- `docs/05_features/pdpl-consent/`
- `docs/03_technical/protocols/consent-matrix.md`
- `docs/06_decisions/013-remove-passport-biometric-from-mvp.md`

---

## 2. `marketing-consent`
### Goal
Memastikan promosi alumni hanya dikirim ke user yang memberi izin eksplisit.

### Includes
- opt-in marketing
- opt-out preferences
- agency-scoped preference
- retention awareness

### Key Rule
Marketing consent terpisah dari operational consent.

### Related Docs
- `docs/05_features/marketing-consent/`
- `docs/05_features/alumni-broadcast/`
- `docs/06_decisions/017-marketing-consent-for-b2b-broadcast.md`

---

## 3. `offline-maps`
### Goal
Menyediakan peta offline yang tetap usable saat koneksi lemah atau tidak ada.

### Includes
- offline Mapbox tiles
- local map storage
- download management
- storage circuit breaker

### Key Rule
Storage map harus dibatasi maksimal 300MB.

### Related Docs
- `docs/05_features/offline-maps/`
- `docs/06_decisions/005-mapbox-offline-storage-limit.md`
- `docs/06_decisions/016-local-storage-strategy-isar.md`

---

## 4. `panic-alert`
### Goal
Menyediakan emergency trigger yang dapat mengirim lokasi jamaah ke muthawif dengan reliability tinggi.

### Includes
- panic trigger
- countdown/cancel window
- coordinates capture
- push notification
- Twilio fallback
- safety delivery logic

### Key Rule
Panic alert adalah safety-critical feature dan harus memiliki fallback berlapis.

### Related Docs
- `docs/05_features/panic-alert/`
- `docs/03_technical/protocols/panic-flow.md`
- `docs/06_decisions/015-panic-alert-fallback-with-twilio.md`

---

## 5. `virtual-muthawif`
### Goal
Menyediakan doa yang relevan dengan lokasi user secara otomatis.

### Includes
- geofence detection
- contextual prayer surfacing
- local doa repository
- offline prayer availability

### Key Risk
Battery efficiency dan akurasi geofence.

### Related Docs
- `docs/05_features/virtual-muthawif/`
- `docs/08_child-specifications/mobile-offline-sync.md`

---

## 6. `subscription-paywall`
### Goal
Mengatur monetization B2C melalui free trial dan lifetime pass.

### Includes
- 7-day trial
- trial countdown
- paywall
- Midtrans checkout
- settlement-based unlock
- access state evaluation

### Key Rule
Access harus mengikuti state machine resmi B2B/B2C/trial.

### Related Docs
- `docs/05_features/subscription-paywall/`
- `docs/03_technical/protocols/subscription-access-state-machine.md`
- `docs/06_decisions/012-subscription-access-state-machine.md`

---

## 7. `b2b-volume-licensing`
### Goal
Mengatur monetization B2B melalui pembelian seat licenses oleh agency.

### Includes
- pax input
- volume discount display
- backend-calculated checkout
- seat provisioning

### Key Rule
Harga final harus dihitung di backend, bukan client.

### Related Docs
- `docs/05_features/b2b-volume-licensing/`
- `docs/02_product/monetization/b2b-volume-licensing.md`
- `docs/06_decisions/004-payment-gateway-midtrans.md`

---

## 8. `rombongan-group-management`
### Goal
Menghubungkan jamaah, muthawif, agency, dan trip lifecycle dalam satu struktur group.

### Includes
- group creation
- muthawif assignment
- 6-digit numeric PIN join
- trip dates
- B2B access bypass
- itinerary and meeting coordination

### Key Rules
- join via **6-digit numeric PIN**
- trip lifecycle harus punya `trip_start_at` dan `trip_end_at`

### Related Docs
- `docs/05_features/rombongan-group-management/`
- `docs/03_technical/protocols/trip-lifecycle.md`
- `docs/06_decisions/011-group-invite-format-numeric-pin.md`
- `docs/06_decisions/014-trip-lifecycle-and-gps-ttl.md`

---

## 9. `jejak-ibadah`
### Goal
Merekam pengalaman perjalanan melalui foto offline yang kemudian diproses menjadi aset CRM.

### Includes
- offline camera
- local queue
- pre-compression
- watermarking
- upload sync
- CRM photo availability

### Key Risk
Memory limits, queue conflicts, expired group handling.

### Related Docs
- `docs/05_features/jejak-ibadah/`
- `docs/08_child-specifications/edge-media-processing.md`
- `docs/08_child-specifications/mobile-offline-sync.md`

---

## 10. `agency-onboarding`
### Goal
Memungkinkan travel agency masuk ke sistem dengan identitas bisnis yang valid.

### Includes
- registration form
- PPIU license input
- logo upload
- agency profile bootstrap

### Related Docs
- `docs/05_features/agency-onboarding/`
- `docs/03_technical/api-contracts/auth/`
- `docs/03_technical/api-contracts/b2b-checkout/`

---

## 11. `alumni-broadcast`
### Goal
Memungkinkan agency mengirim promosi atau update ke cohort alumni yang relevan.

### Includes
- cohort selection
- message composition
- send trigger
- consent filtering

### Key Rule
Broadcast hanya boleh ke user dengan marketing consent valid.

### Related Docs
- `docs/05_features/alumni-broadcast/`
- `docs/05_features/marketing-consent/`
- `docs/03_technical/api-contracts/broadcast/`

---

## 12. `admin-tools`
### Goal
Menyediakan alat kontrol operasional untuk internal/admin.

### Includes
- metrics viewer
- trial override
- global test mode
- watermark preview
- administrative controls

### Key Rule
Admin tools harus dilindungi oleh admin claim yang valid.

### Related Docs
- `docs/05_features/admin-tools/`
- `docs/03_technical/protocols/auth-role-model.md`

---

## 13. `dx-tools`
### Goal
Menyediakan alat bantu testing dan verification untuk tim development dan reviewer.

### Includes
- GPS spoofer
- alert loopback
- consent reset
- test-only operational tools

### Key Rule
DX tools tidak boleh tersedia untuk regular production users.

### Related Docs
- `docs/05_features/dx-tools/`
- `docs/03_technical/verification/production-gates.md`

---

## Feature Dependency Highlights

### Critical dependency chains
1. `pdpl-consent` → memengaruhi semua protected features
2. `subscription-paywall` ↔ `rombongan-group-management`
3. `marketing-consent` → `alumni-broadcast`
4. `offline-maps` + `virtual-muthawif` → membutuhkan local storage + location behavior
5. `panic-alert` → membutuhkan rombongan + muthawif target + push/fallback path
6. `jejak-ibadah` → membutuhkan rombongan + storage + watermark edge function

---

## Feature Clusters

### Cluster A — Compliance & Access
- `pdpl-consent`
- `marketing-consent`
- `subscription-paywall`

### Cluster B — Field Operations
- `offline-maps`
- `panic-alert`
- `virtual-muthawif`
- `rombongan-group-management`

### Cluster C — Media & Retention
- `jejak-ibadah`
- `alumni-broadcast`

### Cluster D — B2B Commercial
- `agency-onboarding`
- `b2b-volume-licensing`

### Cluster E — Operations & Internal Control
- `admin-tools`
- `dx-tools`

---

## Recommended Reading Order by Use Case

## If the task is about compliance
Read:
1. `pdpl-consent`
2. `marketing-consent`
3. `consent-matrix.md`
4. `pdpl-requirements.md`

## If the task is about monetization
Read:
1. `subscription-paywall`
2. `b2b-volume-licensing`
3. `subscription-access-state-machine.md`

## If the task is about field safety
Read:
1. `panic-alert`
2. `rombongan-group-management`
3. `trip-lifecycle.md`
4. `offline-maps`

## If the task is about offline behavior
Read:
1. `offline-maps`
2. `virtual-muthawif`
3. `jejak-ibadah`
4. `mobile-offline-sync.md`

## If the task is about B2B CRM
Read:
1. `agency-onboarding`
2. `b2b-volume-licensing`
3. `jejak-ibadah`
4. `alumni-broadcast`
5. `marketing-consent`

## If the task is about admin/debugging
Read:
1. `admin-tools`
2. `dx-tools`
3. `production-gates.md`

---

## Feature Status Guidance
Secara dokumentasi, anggap status feature saat ini sebagai:

| Feature | Documentation Status |
|---|---|
| pdpl-consent | Onyx authoritative content pending completion |
| marketing-consent | Onyx authoritative content pending completion |
| offline-maps | starter docs available |
| panic-alert | Onyx authoritative content pending completion |
| virtual-muthawif | starter docs available |
| subscription-paywall | Onyx authoritative content pending completion |
| b2b-volume-licensing | starter docs available |
| rombongan-group-management | Onyx authoritative content pending completion |
| jejak-ibadah | starter docs available |
| agency-onboarding | starter docs available |
| alumni-broadcast | starter docs available |
| admin-tools | starter docs available |
| dx-tools | starter docs available |

---

## Rules for AI Tools
Jika Anda adalah AI tool yang membaca repo ini:

1. mulai dari `global-summary.md`
2. lanjut ke `system-overview.md`
3. gunakan file ini untuk memilih feature target
4. baca `summary.md` feature sebelum masuk ke dokumen lain
5. cek keputusan formal sebelum membuat asumsi
6. jangan infer behavior penting tanpa membaca:
   - decision files
   - protocol files
   - system rules

---

## Related Documents
- `docs/00_ai-context/global-summary.md`
- `docs/00_ai-context/system-overview.md`
- `docs/00_ai-context/system-rules.md`
- `docs/00_ai-context/feature-ownership-matrix.md`
- `docs/03_technical/protocols/subscription-access-state-machine.md`
- `docs/03_technical/protocols/trip-lifecycle.md`
- `docs/03_technical/protocols/auth-role-model.md`
- `docs/03_technical/protocols/consent-matrix.md`