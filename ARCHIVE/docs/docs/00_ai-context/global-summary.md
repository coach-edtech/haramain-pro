# Global Summary — Haramain Pro

> Owner: Onyx
> Status: Authoritative
> Note: This file is the primary AI entry point for understanding the Haramain Pro system at a high level.

## Purpose
Dokumen ini adalah ringkasan global resmi untuk membantu manusia dan AI memahami Haramain Pro dengan cepat tanpa harus membaca seluruh dokumen proyek.

Gunakan file ini sebagai:
- entry point utama untuk AI tools
- ringkasan sistem sebelum membaca feature docs
- konteks global untuk planning, implementation, dan review

---

## What Haramain Pro Is
Haramain Pro adalah **native mobile app (Flutter iOS/Android)** dan **companion B2B web dashboard (React)** yang dirancang sebagai **Smart Companion** untuk jamaah Umrah dan Haji.

Produk ini menyelesaikan dua masalah utama:

1. **Masalah safety di lapangan**
 - jamaah bisa tersesat di keramaian besar
 - jaringan seluler sering padat atau tidak stabil
 - perangkat sering dalam silent mode / DND
 - user tetap membutuhkan navigasi, panic alert, dan panduan kontekstual secara offline

2. **Masalah diferensiasi dan retention travel agency**
 - travel agency perlu menawarkan nilai tambah yang nyata
 - agency ingin mempertahankan hubungan dengan alumni pasca perjalanan
 - album "Jejak Ibadah" dan alumni CRM menjadi mesin retensi jangka panjang

---

## Product Model
Haramain Pro menggunakan model **B2B2C flywheel**:

- **B2B side:** travel agency membeli seat licenses, membuat rombongan, menunjuk muthawif, dan menggunakan web dashboard untuk CRM/alumni broadcast
- **B2C side:** jamaah menggunakan mobile app untuk safety, offline navigation, contextual prayer, dan personal trip experience
- **Retention loop:** foto dan jejak perjalanan menjadi aset CRM pasca-trip

---

## Core Platforms
### Mobile App
- Flutter native
- iOS + Android
- offline-first
- fokus pada safety, navigation, doa kontekstual, group coordination, photo queue, dan paywall

### Web Dashboard
- React web dashboard
- untuk travel agency dan admin
- fokus pada licensing, rombongan management, CRM gallery, broadcast, dan admin tools

### Backend
- Supabase
 - Auth
 - PostgreSQL
 - Storage
 - Realtime
 - Edge Functions

---

## Core Users and Roles

### Jamaah
User default aplikasi.
Membutuhkan:
- onboarding consent
- offline maps
- panic safety
- contextual prayer
- join group via PIN
- premium/trial/paywall access

### Muthawif
Pendamping lapangan.
Membutuhkan:
- koordinasi rombongan
- menerima panic alert
- itinerary broadcast
- offline camera
- media sync

### Travel Admin
Admin pihak travel agency.
Membutuhkan:
- agency onboarding
- seat licensing
- package / rombongan setup
- muthawif assignment
- CRM gallery
- alumni broadcast

### Sys Admin
Admin internal Haramain.
Membutuhkan:
- metrics
- trial override
- global test mode
- watermark preview
- operational observability

---

## Main Product Capabilities

### 1. PDPL Consent & Data Lifecycle
- onboarding consent wajib sebelum akses fitur inti
- MVP hanya meminta consent untuk:
 - location / GPS
 - photo / media
 - push notifications
 - marketing consent terpisah
- **MVP tidak menyimpan passport atau biometric data**
- user dapat withdraw consent dan request data deletion
- consent withdrawal harus tersedia di production

### 2. Offline Maps & Navigation
- Mapbox offline tile download
- cakupan Makkah dan Madinah
- batas footprint local map storage maksimal 300MB
- storage circuit breaker wajib

### 3. Panic Alert & Emergency Delivery
- user dapat mengirim panic alert dengan koordinat
- target utama adalah muthawif rombongan
- delivery strategy berlapis:
 1. FCM push / critical alert
 2. Twilio voice fallback
 3. SMS / WhatsApp fallback
 4. local loopback hanya untuk non-production test
- fitur ini safety-critical dan tidak boleh bergantung pada satu channel saja

### 4. Virtual Muthawif / Contextual Prayer
- mendeteksi lokasi penting seperti Ka'bah, Sa'i, Raudhah
- menampilkan doa kontekstual
- data doa tersedia secara lokal/offline
- membutuhkan geofence logic dan battery-aware background behavior

### 5. Subscription, Trial, and Paywall
- user baru mendapatkan **7-day free trial**
- premium B2C dijual sebagai:
 - **Haramain Safety Pass**
 - **Rp 120.000**
 - **lifetime access**
- unlock premium terjadi setelah settlement Midtrans webhook
- access state dipengaruhi oleh:
 - free trial
 - B2C paid lifetime
 - B2B trip-based bypass

### 6. B2B Group / Rombongan System
- muthawif/travel membuat rombongan
- jamaah join menggunakan **6-digit numeric PIN only**
- format valid: `^\d{6}$`
- PIN unik per rombongan aktif
- B2B trip membership dapat membypass paywall selama trip aktif

### 7. Jejak Ibadah
- muthawif dapat memotret secara offline
- foto disimpan di local queue
- saat koneksi kembali:
 - foto di-pre-compress
 - dikirim ke edge function
 - diberi watermark logo travel
 - disimpan ke storage
 - muncul di CRM gallery

### 8. CRM & Alumni Broadcast
- agency dapat melihat gallery alumni
- agency dapat memilih cohort alumni
- agency dapat mengirim broadcast promosi via push
- **broadcast hanya boleh ke user dengan marketing consent yang valid**

---

## Core Business Rules

### Group Invite Rule
- group join memakai **6-digit numeric PIN**
- bukan alphanumeric
- leading zero diperbolehkan
- brute-force protection wajib di backend

### Subscription Access Rule
Priority access:
1. B2B trip-active access
2. B2C paid lifetime
3. Free trial
4. Free/basic state

Behavior:
- B2B trip access bypass paywall hanya selama trip aktif
- setelah `trip_end_at`, akses B2B berakhir
- jika user punya B2C lifetime, full access tetap lanjut setelah trip
- jika tidak, user kembali ke trial/free sesuai kondisi

### Consent Rule
- no consent → no protected access
- no passport/biometric in MVP
- marketing consent terpisah dari operational consent
- withdrawal path wajib tersedia di production

### Storage Rule
- **Isar adalah primary local DB untuk MVP**
- file system digunakan untuk map/media storage
- SQLite bukan local storage resmi untuk MVP

### Retention Rule
- GPS/location history:
 - `purge_at = trip_end_at + 30 days`
- alumni marketing retention:
 - default 365 hari setelah `trip_end_at`
 - subject to consent rules
- archived photo/media behavior mengikuti consent dan retention policies yang lebih spesifik

---

## Core Technical Architecture
Sistem mengikuti arsitektur **offline-first, three-tier, serverless-oriented**:

### Client Tier
- Flutter mobile app
- React web dashboard

### Persistence Tier
- Supabase PostgreSQL
- Supabase Auth
- Supabase Storage

### Middleware Tier
Supabase Edge Functions untuk:
- panic alert orchestration
- photo watermark processing
- Midtrans webhook handling
- claims / auth-related service logic bila dibutuhkan

### External Services
- Mapbox
- Firebase Cloud Messaging
- Midtrans
- Twilio

---

## Important Technical Constraints

### Offline-first is mandatory
Fitur inti seperti:
- navigation
- doa contextual
- photo queue
harus tetap usable meskipun tanpa internet.

### Sensitive logic must stay on backend
- pricing calculation
- payment validation
- signature verification
- watermark processing
harus dilakukan di backend/edge, bukan dipercayakan ke client

### Production gating is strict
DX tools seperti:
- GPS spoofer
- alert loopback
- sandbox toggles
tidak boleh tersedia untuk regular production users

### Multi-tenant isolation is critical
Semua data B2B agency harus diproteksi via:
- Supabase RLS
- scoped claims
- strict access rules

---

## Key Risks
Beberapa area paling berisiko dalam sistem:

1. **panic alert reliability**
2. **silent mode / DND bypass behavior**
3. **offline sync conflicts**
4. **photo processing memory limits**
5. **state mismatch antara local app dan backend**
6. **incorrect access entitlement after trip end**
7. **consent and retention compliance mistakes**

---

## Current Source-of-Truth Strategy

### Global SSOT
Gunakan dokumen berikut sebagai titik rujukan utama:
- `docs/00_ai-context/global-summary.md`
- `docs/00_ai-context/system-overview.md`
- `docs/00_ai-context/feature-index.md`
- `docs/00_ai-context/system-rules.md`

### Feature SSOT
Untuk setiap feature:
- `prd.md` = product truth
- `trd.md` = technical truth
- `api.md` = contract truth
- `implementation.md` = execution truth
- `summary.md` = AI-optimized derived overview

### Decision SSOT
Semua keputusan formal tersimpan di:
- `docs/06_decisions/`

---

## Priority Features for Current Documentation Work
Fitur paling kritis yang harus dianggap prioritas tinggi:

1. `pdpl-consent`
2. `marketing-consent`
3. `panic-alert`
4. `subscription-paywall`
5. `rombongan-group-management`

Fitur-fitur ini mengunci:
- compliance
- monetization
- access control
- emergency delivery
- trip lifecycle

---

## AI Reading Order
Jika AI perlu memahami sistem dengan cepat, baca dalam urutan ini:

1. `docs/00_ai-context/global-summary.md`
2. `docs/00_ai-context/system-overview.md`
3. `docs/00_ai-context/feature-index.md`
4. `docs/00_ai-context/system-rules.md`
5. `docs/00_ai-context/feature-ownership-matrix.md`

Lalu untuk feature tertentu:
1. `docs/05_features/{feature}/summary.md`
2. `docs/05_features/{feature}/prd.md`
3. `docs/05_features/{feature}/trd.md`
4. `docs/05_features/{feature}/api.md`
5. `docs/05_features/{feature}/implementation.md`

---

## What Is Explicitly Out of Scope for MVP
- passport data storage
- biometric data storage
- server-side biometric processing
- generative AI voice interaction
- official Saudi Nusuk booking integration
- visa processing
- production exposure of local-only DX tools

---

## Summary in One Paragraph
Haramain Pro adalah platform B2B2C untuk Umrah/Hajj yang menggabungkan mobile safety companion offline-first dan web CRM dashboard travel agency. Sistem ini berfokus pada panic safety, offline maps, contextual prayer, rombongan coordination, monetization melalui B2C lifetime pass dan B2B volume licensing, serta retention melalui Jejak Ibadah dan alumni broadcast. Arsitektur utamanya menggunakan Flutter, React, Supabase, Edge Functions, Mapbox, Midtrans, FCM, dan Twilio, dengan aturan ketat terkait PDPL consent, trip lifecycle, marketing consent, and multi-tenant isolation.

---

## Related Documents
- `docs/00_ai-context/system-overview.md`
- `docs/00_ai-context/feature-index.md`
- `docs/00_ai-context/system-rules.md`
- `docs/03_technical/protocols/subscription-access-state-machine.md`
- `docs/03_technical/protocols/trip-lifecycle.md`
- `docs/06_decisions/011-group-invite-format-numeric-pin.md`
- `docs/06_decisions/012-subscription-access-state-machine.md`
- `docs/06_decisions/013-remove-passport-biometric-from-mvp.md`
- `docs/06_decisions/014-trip-lifecycle-and-gps-ttl.md`
- `docs/06_decisions/015-panic-alert-fallback-with-twilio.md`
- `docs/06_decisions/016-local-storage-strategy-isar.md`
- `docs/06_decisions/017-marketing-consent-for-b2b-broadcast.md`
