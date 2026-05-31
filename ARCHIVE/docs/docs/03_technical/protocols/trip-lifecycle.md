# Trip Lifecycle — Haramain Pro

> Owner: Onyx
> Status: Authoritative
> Note: This file defines the official lifecycle of a trip/rombongan, including trip dates, activation, extension, expiry, and downstream effects on access, retention, and operational behavior.

## Purpose
Dokumen ini mendefinisikan lifecycle resmi sebuah **trip/rombongan** di Haramain Pro.

Gunakan file ini untuk mengatur:
- kapan trip dianggap dimulai
- kapan trip dianggap aktif
- kapan trip dianggap selesai / expired
- siapa yang boleh membuat atau mengubah tanggal trip
- bagaimana trip memengaruhi:
  - B2B premium bypass
  - GPS retention purge
  - alumni retention countdown
  - media sync validity
  - operational coordination

Dokumen ini adalah source of truth untuk semua logic yang bergantung pada:
- `trip_start_at`
- `trip_end_at`

---

## Scope
Dokumen ini mencakup:

- definisi trip lifecycle state
- field wajib pada `rombongan`
- ownership dan authority untuk set / extend trip
- active/expired rules
- relation ke access state machine
- relation ke retention rules
- relation ke sync/media validity

Dokumen ini tidak membahas detail:
- paywall UI
- Midtrans flow
- detailed RLS policy SQL
- detailed media processing internals

---

## Core Principle
Trip lifecycle harus bersifat **eksplisit**, **time-bound**, dan **authoritative**.

Sistem tidak boleh menebak durasi trip dari:
- account creation date
- join date saja
- last activity
- upload timestamps

Anchor resmi adalah:
- `trip_start_at`
- `trip_end_at`

---

## Canonical Trip Fields

Setiap `rombongan` aktif wajib memiliki field berikut:

- `trip_start_at: timestamptz`
- `trip_end_at: timestamptz`

### Optional but recommended supporting fields
- `status`
- `extended_at`
- `extended_by`
- `agency_id`
- `muthawif_id`

### Default Rule
Jika tidak ditentukan manual:
- `trip_end_at = trip_start_at + 21 hari`

---

## Ownership and Authority Rules

## Travel Admin
Travel Admin adalah authority utama untuk:
- membuat rombongan
- menetapkan `trip_start_at`
- menetapkan `trip_end_at`
- menyetujui extension

## Muthawif
Muthawif dapat:
- melihat lifecycle trip
- mengajukan extension
- menjalankan operasional trip
- tetapi **tidak menjadi authority final** untuk extension tanpa approval admin

## Jamaah
Jamaah tidak dapat:
- menetapkan lifecycle rombongan B2B agency
- mengubah `trip_end_at` rombongan
- memaksa extension group state

### Exception
Untuk skenario non-B2B / manual trip context pribadi di masa depan, flow bisa berbeda.  
Namun untuk MVP B2B rombongan, authority utama tetap travel admin.

---

## Trip State Model

Trip memiliki state resmi berikut:

1. `draft`
2. `scheduled`
3. `active`
4. `completed`
5. `expired`
6. `purged_context_only` *(logical downstream state, optional for ops)*
7. `archived` *(optional organizational state)*

---

## State Definitions

## 1. `draft`
Trip/rombongan sudah dibuat secara awal, tetapi belum siap dijalankan.

### Characteristics
- dapat belum memiliki semua data final
- belum boleh memberi access aktif
- belum boleh dianggap sebagai active group

---

## 2. `scheduled`
Trip sudah valid secara struktur dan memiliki tanggal resmi, tetapi waktu sekarang masih sebelum `trip_start_at`.

### Characteristics
- PIN join bisa tersedia jika bisnis mengizinkan pre-join
- B2B access bypass belum aktif jika kebijakan mensyaratkan bypass hanya saat trip active
- itinerary setup dan coordination prep boleh dilakukan

### Recommended default
Untuk MVP, pre-join boleh diperbolehkan, tetapi entitlement premium bypass sebaiknya aktif saat group sudah valid dan trip context aktif menurut aturan implementasi.

---

## 3. `active`
Trip dianggap aktif jika:

```text
now >= trip_start_at
AND now <= trip_end_at
AND group is not administratively cancelled
```plaintext

### Characteristics
- B2B access bypass dapat aktif
- panic routing berlaku ke context group ini
- itinerary / meeting point relevance berlaku
- media capture terkait group ini valid
- GPS retention countdown belum dimulai

---

## 4. `completed`
Trip telah mencapai akhir operasional utama, biasanya saat:

```text
now > trip_end_at
```plaintext

Tetapi istilah `completed` dapat dipakai secara business-facing/ops-facing sebelum seluruh downstream retention selesai.

### Characteristics
- B2B active premium bypass berhenti
- media sync mungkin masih memiliki aturan grace/fail-safe tergantung implementasi
- alumni retention countdown mulai relevan
- GPS purge countdown dimulai

---

## 5. `expired`
Trip tidak lagi valid untuk entitlement aktif dan operasional group active flows.

### Characteristics
- group-based premium bypass tidak boleh berlaku lagi
- panic/group coordination tidak boleh diasumsikan aktif seperti saat trip berjalan
- join attempts harus ditolak
- media sync harus ditangani sesuai error-safe policy

### Important note
Dalam banyak implementasi MVP, `completed` dan `expired` dapat diperlakukan hampir sama untuk logic backend, tetapi tetap berguna dibedakan secara konseptual.

---

## 6. `purged_context_only`
Ini bukan state produk yang harus selalu diekspos ke user, tetapi berguna secara internal untuk menandai bahwa:
- data location/GPS yang terkait trip sudah melewati retention
- context operasional aktif trip sudah tidak berlaku

---

## 7. `archived`
Optional organizational state untuk history/admin browsing.  
Tidak memengaruhi entitlement secara langsung.

---

## Canonical Active Rule
Sebuah trip dianggap **active** jika dan hanya jika:

- `trip_start_at` ada
- `trip_end_at` ada
- current time berada di antara keduanya
- rombongan tidak ditandai invalid/cancelled

### Canonical expression
```text
trip_is_active =
  trip_start_at != null
  AND trip_end_at != null
  AND now >= trip_start_at
  AND now <= trip_end_at
  AND rombongan_status not in [cancelled, invalid]
```plaintext

---

## Canonical Expired Rule
Sebuah trip dianggap **expired** jika:

```text
now > trip_end_at
```plaintext

atau
- group secara administratif dinonaktifkan / cancelled

---

## Relationship to Access Entitlement

Trip lifecycle secara langsung memengaruhi entitlement.

### Rule 1
Jika trip aktif dan user adalah member rombongan valid:
- final access state dapat menjadi `b2b_trip_active`

### Rule 2
Jika trip berakhir:
- B2B bypass berhenti
- sistem harus mengevaluasi ulang:
  - apakah user punya B2C lifetime?
  - apakah trial masih aktif?
  - jika tidak keduanya, fallback ke basic/free

### Rule 3
Trip lifecycle **tidak menghapus** B2C lifetime.
Trip hanya memberi access sementara selama active window.

### Related document
- `subscription-access-state-machine.md`

---

## Relationship to Retention Rules

## GPS / Location History
Retention GPS mengikuti aturan:

```text
purge_at = trip_end_at + 30 hari
```plaintext

### Meaning
- sebelum `purge_at`, data masih dapat dipertahankan sesuai kebutuhan operasional/compliance
- setelah `purge_at`, GPS/location history harus dihapus permanen

---

## Alumni Marketing Retention
Retention marketing/alumni default:

```text
marketing_retention_until = trip_end_at + 365 hari
```plaintext

Kecuali:
- user opt-out
- consent dicabut
- aturan bisnis/consent lain mempersingkat retention

---

## Media / Jejak Ibadah
Foto tidak otomatis mengikuti aturan purge GPS.

Media mengikuti:
- consent scope
- album/business retention rules
- status sync/watermark
- ownership and archival rules yang lebih spesifik

### Important distinction
Jangan menyamakan:
- GPS retention
dengan
- photo/media retention

---

## Join and Membership Timing Rules

## Pre-join
Sistem boleh mengizinkan jamaah join sebelum `trip_start_at` jika:
- rombongan valid
- agency membuka join lebih awal
- backend mengizinkan pre-association

Namun, implementasi harus jelas apakah:
- premium bypass aktif saat join
- atau baru aktif ketika trip benar-benar active

### Recommended MVP stance
- membership boleh dibuat saat pre-join
- `b2b_trip_active` entitlement mengikuti trip active window

---

## Join after expiry
Jika `trip_end_at` telah lewat:
- join request harus ditolak
- gunakan error seperti `GROUP_EXPIRED`

---

## Membership after trip end
User bisa tetap punya riwayat membership setelah trip berakhir, tetapi:
- bukan berarti entitlement masih aktif
- bukan berarti group flows masih valid

---

## Extension Rules

## Who can extend
- Travel Admin: final authority
- Muthawif: dapat request extension
- Sys Admin: dapat override bila perlu operasional

## What extension changes
Jika extension disetujui:
- `trip_end_at` diperbarui
- semua turunan lifecycle harus mengikuti:
  - B2B active window
  - GPS purge schedule
  - marketing retention anchor
  - possible sync validity windows

## Rule
Extension tidak boleh dilakukan secara implicit.
Harus ada perubahan eksplisit pada source of truth `trip_end_at`.

---

## Cancellation / Invalidity Rules

Trip dapat menjadi invalid sebelum `trip_end_at` lewat jika:
- rombongan dibatalkan
- terjadi administrative override
- agency/sys_admin menonaktifkan group

### Consequences
- B2B access bypass berhenti
- join baru ditolak
- group-dependent operations harus fail safely
- panic routing harus mengikuti state valid terbaru

---

## Downstream Operational Effects

## 1. Subscription / Premium Access
- aktif saat trip active
- berhenti saat expired/cancelled
- fallback ke B2C lifetime / trial/basic

## 2. Group Join
- valid hanya selama rules group mengizinkan
- tidak valid setelah group expired/cancelled

## 3. Panic Alert Context
- panic routing ke muthawif group harus hanya memakai group context yang valid
- jangan gunakan expired group sebagai context emergency aktif tanpa aturan khusus

## 4. Itinerary / Meeting Point
- hanya relevan untuk active/scheduled group
- setelah expired, data hanya historical

## 5. Media Sync
Jika sync berjalan saat group sudah expired:
- server harus bisa menolak dengan aman
- gunakan error seperti `GROUP_EXPIRED`
- client harus memindahkan file ke status aman / archived if required

## 6. Retention Jobs
- GPS purge timer bergantung pada `trip_end_at`
- marketing retention countdown bergantung pada `trip_end_at`

---

## Canonical Lifecycle Scenarios

## Scenario A — Normal B2B Trip
1. travel admin membuat rombongan
2. set `trip_start_at` dan `trip_end_at`
3. jamaah join group
4. trip menjadi active
5. B2B access bypass berlaku
6. trip ends
7. user fallback ke B2C lifetime / trial / free
8. GPS retention purge countdown berjalan

---

## Scenario B — User Buys B2C During Active Trip
1. user sedang dalam group active
2. user membeli B2C lifetime
3. selama trip aktif, runtime state tetap `b2b_trip_active`
4. setelah trip end, state menjadi `b2c_lifetime_active`

---

## Scenario C — Group Expired Before Pending Media Sync
1. muthawif capture photo saat offline
2. queue tersimpan lokal
3. trip berakhir sebelum sync
4. sync mencoba upload
5. backend mendeteksi group expired
6. upload ditolak aman
7. client menangani item queue tanpa data corruption

---

## Scenario D — Trip Extended
1. group aktif mendekati `trip_end_at`
2. muthawif request extension
3. travel admin approve
4. `trip_end_at` diperbarui
5. B2B active access tetap berjalan sesuai end date baru
6. GPS purge schedule ikut bergeser

---

## Data Contract Guidance

Minimal table `rombongan` harus mendukung:

- `id`
- `agency_id`
- `muthawif_id`
- `invite_pin`
- `is_active`
- `trip_start_at`
- `trip_end_at`
- `created_at`

### Optional but useful
- `status`
- `extended_at`
- `extended_by`
- `cancelled_at`
- `cancelled_by`

---

## Validation Rules

### Required validations
- `trip_start_at` wajib ada untuk trip valid
- `trip_end_at` wajib ada untuk trip valid
- `trip_end_at >= trip_start_at`
- extension tidak boleh menghasilkan end date di masa lalu
- join tidak boleh diterima untuk trip expired/cancelled
- entitlement resolver tidak boleh menganggap trip aktif tanpa valid date window

---

## Error Relevance
Trip lifecycle berkaitan erat dengan error seperti:

- `GROUP_EXPIRED`
- `INVALID_GROUP_PIN`
- `CONSENT_REQUIRED`
- `RLS_FORBIDDEN`

Detail resmi ada di:
- `error-catalog.md`

---

## Pseudocode Reference

```ts
function isTripActive(group, now) {
  if (!group) return false;
  if (!group.tripStartAt || !group.tripEndAt) return false;
  if (group.status === "cancelled" || group.status === "invalid") return false;

  return now >= group.tripStartAt && now <= group.tripEndAt;
}

function resolveGpsPurgeAt(group) {
  return addDays(group.tripEndAt, 30);
}

function resolveMarketingRetentionUntil(group) {
  return addDays(group.tripEndAt, 365);
}
```plaintext

---

## Testing Requirements

Minimal harus diuji:

1. trip with valid dates becomes active on time
2. expired trip no longer grants B2B access
3. join request fails after trip expiry
4. extension updates downstream timing correctly
5. cancelled trip behaves as inactive immediately
6. GPS purge schedule is computed from `trip_end_at`
7. media sync safely handles expired group state

---

## Implementation Guidance

### For Mobile
- jangan hanya mengandalkan local flag `isGroupActive`
- gunakan time-aware evaluation
- tampilkan trip state dengan jelas bila relevan

### For Backend
- jadikan `trip_end_at` sebagai source of truth untuk expiry-related logic
- jangan biarkan access logic tersebar tak konsisten

### For Edge
- semua operation yang bergantung pada group validity harus re-check lifecycle
- terutama:
  - media sync
  - panic routing
  - privileged group operations

---

## Summary
Trip lifecycle adalah fondasi untuk:
- B2B entitlement
- retention
- group validity
- panic context
- media sync validity

Prinsip utamanya:
- trip harus punya start dan end date yang eksplisit
- `trip_end_at` adalah anchor utama untuk expiry dan retention
- extension/cancellation harus mengubah source of truth secara formal
- downstream systems tidak boleh mengira-ngira lifecycle dari sinyal lain

---

## Related Decisions
- `docs/06_decisions/011-group-invite-format-numeric-pin.md`
- `docs/06_decisions/012-subscription-access-state-machine.md`
- `docs/06_decisions/014-trip-lifecycle-and-gps-ttl.md`
- `docs/06_decisions/017-marketing-consent-for-b2b-broadcast.md`

## Related Documents
- `docs/03_technical/protocols/subscription-access-state-machine.md`
- `docs/03_technical/protocols/trip-model.md`
- `docs/03_technical/data-model/rombongan.md`
- `docs/03_technical/data-model/location-history.md`
- `docs/05_features/rombongan-group-management/`
- `docs/05_features/subscription-paywall/`
- `docs/05_features/jejak-ibadah/`