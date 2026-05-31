# System Rules — Haramain Pro

> Owner: Onyx
> Status: Authoritative
> Note: This file defines the non-negotiable system rules, architectural constraints, and implementation guardrails for Haramain Pro. AI tools and human contributors must treat these rules as binding unless superseded by an approved decision file.

## Purpose
Dokumen ini berisi aturan global yang **tidak boleh dilanggar** saat:
- membuat PRD/TRD/implementation plan
- menulis prompt untuk Antigravity
- mengimplementasikan code di Trae
- mereview hasil implementasi
- membuat keputusan teknis lanjutan

Jika ada konflik antara dokumen lain dan file ini, maka:
1. cek decision files di `docs/06_decisions/`
2. jika belum ada keputusan formal, file ini dianggap berlaku

---

## Rule Hierarchy
Gunakan urutan prioritas berikut saat ada konflik dokumentasi:

1. **Approved decision files** di `docs/06_decisions/`
2. **System rules** di file ini
3. **Feature-level PRD/TRD/API/Implementation docs**
4. **Starter docs / child specs / execution notes**
5. **Prompt sementara / chat reasoning / draft notes**

### Important principle
- `summary.md` membantu pemahaman cepat, tetapi **bukan** sumber keputusan final
- decision files dan system rules lebih tinggi prioritasnya daripada summary atau prompt

---

## Product Boundary Rules

### Rule 1 — Haramain Pro is an offline-first pilgrimage companion
Produk ini harus diperlakukan sebagai:
- mobile safety companion untuk jamaah dan muthawif
- B2B CRM/operations dashboard untuk travel agency
- bukan super-app serba bisa

### Rule 2 — MVP scope is intentionally constrained
Yang termasuk dalam scope inti:
- offline maps
- panic alert
- contextual prayer
- rombongan join and trip access
- trial/paywall
- Jejak Ibadah media flow
- B2B licensing
- alumni broadcast dengan consent yang valid

Yang **tidak** termasuk dalam scope MVP:
- passport data storage
- biometric data storage
- server-side biometric processing
- generative AI voice interaction
- official Saudi Nusuk booking integration
- visa processing
- unrestricted production DX tools

### Rule 3 — Do not expand scope casually
Setiap penambahan fitur yang menyentuh:
- compliance
- payments
- identity
- emergency handling
- retention rules
harus diperlakukan sebagai perubahan besar dan perlu update dokumen formal

---

## Compliance Rules

### Rule 4 — Operational consent is mandatory before protected access
User tidak boleh mengakses fitur protected sebelum consent operasional yang diwajibkan diberikan secara sah.

### Rule 5 — MVP does not store passport or biometric data
Untuk MVP:
- tidak ada penyimpanan passport
- tidak ada penyimpanan biometric
- tidak ada pemrosesan biometric/passport di server

Jika suatu hari dibutuhkan identity verification:
- perlakukan sebagai feature baru
- jangan menyelundupkan ke scope existing

### Rule 6 — Marketing consent is separate from operational consent
Marketing consent:
- tidak boleh digabung diam-diam dengan PDPL operational consent
- harus explicit opt-in
- harus mudah di-opt-out
- harus divalidasi sebelum broadcast dilakukan

### Rule 7 — Consent withdrawal must exist in production
Fitur withdrawal consent dan deletion request bukan hanya DX tool.
Itu adalah bagian legal/compliance yang harus tersedia di production.

### Rule 8 — Retention must follow declared lifecycle
Retention tidak boleh ditentukan secara sembarang.
Minimal berlaku:
- GPS/location history dipurge berdasarkan `trip_end_at + 30 hari`
- marketing retention mengikuti aturan consent dan lifecycle yang sah

---

## Access and Monetization Rules

### Rule 9 — Access must follow the official entitlement model
Akses user harus mengikuti state machine resmi, bukan logic improvisasi per screen.

### Rule 10 — Priority order for entitlement is fixed
Prioritas akses:
1. B2B trip-active access
2. B2C paid lifetime
3. Free trial
4. Free/basic state

### Rule 11 — B2B access bypass is temporary
B2B group-based premium bypass hanya berlaku selama trip aktif.
Setelah `trip_end_at`:
- jika user punya B2C lifetime → tetap full access
- jika tidak → fallback ke trial/free sesuai kondisi

### Rule 12 — No client-side trust for pricing
Harga final dan total pembayaran:
- tidak boleh dianggap benar dari client
- harus dihitung atau diverifikasi di backend

### Rule 13 — Payment unlock depends on verified settlement
Unlock premium tidak boleh terjadi hanya karena user membuka checkout.
Unlock harus bergantung pada status settlement yang valid dan diverifikasi.

---

## Group / Trip Rules

### Rule 14 — Group invite must use 6-digit numeric PIN only
Format join group resmi:
- **6-digit numeric PIN**
- regex validasi: `^\d{6}$`
- leading zero diperbolehkan

### Rule 15 — Alphanumeric invite codes are not allowed for MVP group join
Jangan membuat variant alphanumeric untuk group PIN kecuali ada keputusan resmi baru.

### Rule 16 — Trip lifecycle must be explicit
Setiap rombongan aktif harus memiliki:
- `trip_start_at`
- `trip_end_at`

### Rule 17 — Trip end is the anchor for multiple downstream behaviors
`trip_end_at` adalah anchor resmi untuk:
- B2B access expiry
- GPS retention purge
- alumni retention countdown
- trip completion lifecycle

---

## Mobile Architecture Rules

### Rule 18 — Mobile client must remain offline-first
Fitur lapangan tidak boleh didesain dengan asumsi koneksi stabil selalu tersedia.

### Rule 19 — Isar is the official local database for MVP
Untuk MVP:
- **Isar = primary local database**
- file system = media/map storage
- SQLite bukan storage resmi utama untuk MVP

### Rule 20 — Local storage must be bounded
Implementasi mobile wajib memperhatikan:
- footprint local maps
- queue size
- sync backlog
- stale local artifacts

### Rule 21 — Battery-sensitive features must be implemented conservatively
Background GPS, geofence logic, sync loop, dan queue processing tidak boleh dibuat secara agresif hingga merusak usability perangkat.

---

## Safety and Emergency Rules

### Rule 22 — Panic Alert is safety-critical
Panic Alert harus diperlakukan sebagai fitur dengan tingkat kehati-hatian tertinggi.

### Rule 23 — Panic delivery must support layered fallback
Minimal delivery strategy:
1. FCM push / critical alert path
2. Twilio voice fallback
3. SMS / WhatsApp fallback
4. local loopback hanya untuk testing non-production

### Rule 24 — Emergency logic must not depend on a single provider path
Jangan mendesain panic delivery yang hanya sukses jika satu entitlement atau satu provider bekerja sempurna.

### Rule 25 — False panic safeguards are required
Panic trigger harus memiliki perlindungan terhadap trigger yang tidak disengaja, misalnya:
- countdown window
- throttle / rate limit
- retry logic yang masuk akal

---

## Backend and Security Rules

### Rule 26 — Supabase is the core backend source of truth
Auth, persistence, RLS, storage, and realtime state harus berakar pada Supabase sebagai backend utama.

### Rule 27 — RLS is mandatory for tenant isolation
Semua data lintas agency harus dilindungi oleh:
- Row Level Security
- role-aware scoping
- agency-aware filtering

### Rule 28 — Sensitive operations must run in backend/edge
Operasi berikut tidak boleh diandalkan pada client:
- payment signature verification
- final price calculation
- watermark processing
- privileged claims assignment
- service-role access
- emergency orchestration logic yang sensitif

### Rule 29 — Client apps must not contain privileged secrets
Client bundle hanya boleh berisi key yang memang aman untuk client.
Secret sensitif harus disimpan di:
- Supabase Vault
- GitHub Actions secrets
- secure CI/CD environment

---

## DX and Production Gating Rules

### Rule 30 — DX tools must not leak to regular production users
Fitur seperti:
- GPS spoofer
- panic loopback
- sandbox toggles
- diagnostic-only tools

tidak boleh terlihat atau bisa dipakai oleh user biasa di production.

### Rule 31 — Some admin tools may exist in production only behind strict admin gating
Jika ada tool yang legal/operationally required di production, maka:
- harus dilindungi dengan admin gating yang kuat
- tidak boleh accessible by default

### Rule 32 — Local test convenience must never compromise live safety integrity
Tool test tidak boleh mengacaukan emergency flow production atau menyebabkan false-positive real-world behavior.

---

## Media and Sync Rules

### Rule 33 — Client must pre-compress media before upload workflows
Untuk mencegah memory issues di edge/media processing, client harus melakukan pre-compression sebelum upload.

### Rule 34 — Group validity must be re-checked during media sync
Jika group sudah expired atau invalid saat sync berjalan:
- server harus menolak upload secara aman
- client harus menangani hasil itu tanpa corrupting local queue state

### Rule 35 — Watermark processing is server-side responsibility
Client boleh menyiapkan asset, tetapi watermark compositing final harus dilakukan server-side / edge-side.

---

## AI and Documentation Rules

### Rule 36 — Do not infer critical business rules from partial documents
Sebelum membuat keputusan implementasi, AI harus membaca:
- relevant decision files
- protocol docs terkait
- feature docs terkait
- file ini

### Rule 37 — Use feature docs as the unit of implementation context
Untuk coding/refactor/bugfix, AI sebaiknya membaca:
1. `summary.md`
2. `prd.md`
3. `trd.md`
4. `api.md`
5. `implementation.md`

### Rule 38 — Do not use starter docs as final truth without verification
Beberapa file awal dibuat sebagai starter content. Jika behavior bersifat kritikal, AI harus memprioritaskan:
- Onyx-authored authoritative docs
- decision files
- protocol docs

### Rule 39 — Child specifications are official supporting documents
Child specs bukan catatan sampingan. Mereka adalah dokumen pendukung resmi untuk domain teknis yang lebih rinci.

### Rule 40 — Any unresolved contradiction must be surfaced, not silently guessed
Jika AI menemukan konflik aturan:
- jangan menebak diam-diam
- tandai konflik
- minta klarifikasi atau cek decision file terbaru

---

## Feature-Specific Global Constraints

### PDPL Consent
- no passport/biometric in MVP
- withdrawal path wajib
- deletion path wajib
- safest-state wins jika local/server mismatch

### Marketing Consent
- separate opt-in
- easy opt-out
- must gate alumni broadcast eligibility

### Offline Maps
- max 300MB local map footprint
- storage circuit breaker wajib

### Panic Alert
- fallback berlapis wajib
- reliability lebih penting daripada elegansi implementasi

### Subscription Paywall
- unlock harus berbasis verified settlement
- access state tidak boleh dihitung secara liar di banyak tempat

### Rombongan
- numeric PIN only
- trip dates wajib
- trip context memengaruhi access dan retention

### Jejak Ibadah
- offline queue wajib aman
- pre-compression wajib
- expired group handling wajib

### DX Tools
- non-production by default
- admin-gated jika ada exposure tertentu

---

## Review Checklist for Any New Change
Sebelum menyetujui perubahan baru, cek:

1. Apakah perubahan ini melanggar consent/compliance rule?
2. Apakah perubahan ini mengubah access state logic?
3. Apakah perubahan ini menyentuh trip lifecycle?
4. Apakah perubahan ini menambah data sensitif baru?
5. Apakah perubahan ini memindahkan logic sensitif ke client?
6. Apakah perubahan ini bisa bocor ke production?
7. Apakah perubahan ini perlu decision file baru?
8. Apakah perubahan ini perlu update feature docs atau protocol docs?

---

## Summary
System rules ini adalah guardrails utama Haramain Pro.  
Semua implementation, prompt, dan review harus menghormati prinsip berikut:

- offline-first
- compliance-first for protected data/features
- strict entitlement logic
- strict tenant isolation
- layered safety delivery
- explicit production gating
- feature-based documentation discipline
- no silent assumptions on unresolved critical rules

---

## Related Documents
- `docs/00_ai-context/global-summary.md`
- `docs/00_ai-context/system-overview.md`
- `docs/00_ai-context/feature-index.md`
- `docs/00_ai-context/feature-ownership-matrix.md`
- `docs/03_technical/protocols/subscription-access-state-machine.md`
- `docs/03_technical/protocols/trip-lifecycle.md`
- `docs/03_technical/protocols/auth-role-model.md`
- `docs/03_technical/protocols/consent-matrix.md`
- `docs/03_technical/non-functional-requirements.md`
- `docs/06_decisions/`