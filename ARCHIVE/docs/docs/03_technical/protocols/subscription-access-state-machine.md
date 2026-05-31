# Subscription Access State Machine — Haramain Pro

> Owner: Onyx
> Status: Authoritative
> Note: This file defines the official entitlement model for trial, B2C lifetime purchase, and B2B trip-based access. All access-related implementation must follow this document.

## Purpose
Dokumen ini mendefinisikan aturan resmi untuk menentukan akses user terhadap fitur Haramain Pro, terutama yang berkaitan dengan:

- free trial
- B2C paid lifetime access
- B2B trip-based premium bypass
- entitlement resolution setelah trip berakhir
- prioritas jika user memiliki lebih dari satu sumber akses

Dokumen ini adalah **source of truth** untuk logic entitlement/access.  
UI, backend, edge, dan AI tools harus mengikuti aturan di file ini.

---

## Scope
Dokumen ini mencakup:

- model state akses user
- prioritas entitlement
- rule transisi antar state
- interaction antara B2C dan B2B access
- behavior saat trip selesai
- behavior saat settlement payment berhasil
- guidance implementasi untuk mobile, backend, dan edge

Dokumen ini tidak membahas:
- detail Midtrans API contract
- detail UX paywall screen
- detail RLS
- detail legal consent flow selain relasinya ke access gating

---

## Core Principle
Access user **tidak boleh** ditentukan secara ad-hoc per screen atau per komponen.

Semua fitur premium harus bergantung pada **satu model entitlement resmi** yang mempertimbangkan:

1. consent validity
2. trial validity
3. B2C lifetime purchase status
4. B2B trip-active status
5. trip lifecycle dates

---

## Access Layers
Entitlement Haramain Pro terdiri dari 4 lapisan logika utama:

1. **Consent gate**
2. **B2B trip-active access**
3. **B2C paid lifetime**
4. **Free trial / basic fallback**

Urutan ini penting karena:
- consent menentukan apakah user boleh masuk ke protected area
- B2B trip-active access dapat membypass paywall
- B2C lifetime memberi akses permanen
- free trial adalah fallback monetization path
- basic/free adalah state terendah

---

## Canonical Priority Order
Prioritas entitlement final adalah:

1. **B2B trip-active access**
2. **B2C paid lifetime**
3. **Free trial**
4. **Free/basic state**

### Important interpretation
- B2B trip-active access memiliki prioritas tertinggi selama trip masih aktif
- setelah trip berakhir, sistem harus mengevaluasi ulang apakah user punya B2C lifetime atau tidak
- B2C lifetime tidak hilang hanya karena user sedang berada dalam rombongan aktif
- trial tidak boleh “mengalahkan” B2B active access

---

## Canonical Access States

## 1. `blocked_no_consent`
User belum memberikan consent operasional yang diwajibkan.

### Behavior
- user tidak boleh masuk ke protected routes
- premium state tidak relevan sebelum consent valid
- onboarding / consent flow wajib muncul

### Examples
- first launch tanpa consent
- consent withdrawn
- local/server consent mismatch dengan safest-state = blocked

---

## 2. `trial_active`
User memiliki consent valid dan trial masih aktif, tetapi:
- belum punya B2C lifetime
- tidak sedang berada dalam trip B2B aktif

### Behavior
- user mendapatkan akses sesuai definisi trial
- countdown trial aktif
- paywall akan berlaku setelah trial habis

---

## 3. `b2c_lifetime_active`
User memiliki consent valid dan sudah membeli Haramain Safety Pass B2C secara sah.

### Behavior
- full premium access
- tidak dibatasi oleh durasi trial
- tetap full access setelah trip mana pun berakhir

---

## 4. `b2b_trip_active`
User memiliki consent valid dan sedang berada dalam rombongan dengan trip aktif.

### Behavior
- premium access aktif selama `trip_end_at` belum lewat
- paywall B2C dibypass selama trip aktif
- state ini berlaku walaupun user sebelumnya:
  - masih trial
  - trial sudah habis
  - sudah punya B2C lifetime

---

## 5. `basic_free`
User memiliki consent valid tetapi:
- trial tidak aktif
- tidak punya B2C lifetime
- tidak sedang berada dalam trip B2B aktif

### Behavior
- hanya fitur basic/free yang tersedia
- premium features terkunci
- paywall dapat ditampilkan

---

## State Resolution Table

| Consent Valid | Trial Active | B2C Lifetime | B2B Trip Active | Final Access State |
|---|---|---|---|---|
| No | Any | Any | Any | `blocked_no_consent` |
| Yes | No | No | No | `basic_free` |
| Yes | Yes | No | No | `trial_active` |
| Yes | No | Yes | No | `b2c_lifetime_active` |
| Yes | Yes | Yes | No | `b2c_lifetime_active` |
| Yes | Any | No | Yes | `b2b_trip_active` |
| Yes | Any | Yes | Yes | `b2b_trip_active` |

### Interpretation
Jika `B2B Trip Active = Yes`, maka final state adalah `b2b_trip_active` selama trip belum berakhir, meskipun user juga punya B2C lifetime.  
Namun, **B2C lifetime tetap tersimpan** dan akan menjadi state berikutnya setelah trip berakhir.

---

## State Meaning by User Perspective

| State | User-facing Meaning |
|---|---|
| `blocked_no_consent` | Anda harus menyelesaikan consent sebelum menggunakan fitur ini |
| `trial_active` | Anda sedang menikmati masa trial |
| `b2c_lifetime_active` | Anda memiliki akses premium lifetime |
| `b2b_trip_active` | Anda memiliki akses premium melalui grup/trip aktif |
| `basic_free` | Anda sedang berada di mode dasar / perlu upgrade untuk fitur premium |

---

## Transition Rules

## Transition A — First Valid Consent
```text
blocked_no_consent -> trial_active
```plaintext

### Condition
- user menyelesaikan consent dengan valid
- trial dimulai
- user belum punya B2C lifetime
- user belum berada dalam trip B2B aktif

---

## Transition B — Trial Expires
```text
trial_active -> basic_free
```plaintext

### Condition
- waktu trial berakhir
- user tidak punya B2C lifetime
- user tidak berada dalam trip aktif B2B

---

## Transition C — B2C Purchase Succeeds
```text
trial_active -> b2c_lifetime_active
basic_free -> b2c_lifetime_active
b2b_trip_active -> b2c_lifetime_active (effective after trip ends, but purchase recorded immediately)
```plaintext

### Condition
- Midtrans settlement valid diterima
- purchase diverifikasi
- profile/entitlement diperbarui

### Important nuance
Jika user sedang berada dalam `b2b_trip_active`, maka:
- state final saat trip aktif tetap `b2b_trip_active`
- tetapi B2C lifetime tercatat dan akan mengambil alih setelah trip berakhir

---

## Transition D — Join Active Rombongan
```text
trial_active -> b2b_trip_active
basic_free -> b2b_trip_active
b2c_lifetime_active -> b2b_trip_active (display/access state only)
```plaintext

### Condition
- user berhasil join rombongan aktif
- `trip_end_at` belum lewat
- backend memvalidasi group dan membership

### Important nuance
Jika user sudah memiliki B2C lifetime:
- jangan menurunkan status ownership-nya
- hanya final runtime state yang dihitung sebagai `b2b_trip_active` selama trip masih aktif

---

## Transition E — Trip Ends
```text
b2b_trip_active -> b2c_lifetime_active
b2b_trip_active -> trial_active
b2b_trip_active -> basic_free
```plaintext

### Condition
- `trip_end_at` telah lewat
- rombongan tidak lagi memberi akses aktif

### Resolution order after trip end
Setelah trip berakhir, sistem mengevaluasi ulang:

1. apakah user punya B2C lifetime?
   - jika ya → `b2c_lifetime_active`
2. jika tidak, apakah trial masih aktif?
   - jika ya → `trial_active`
3. jika tidak → `basic_free`

---

## Transition F — Consent Withdrawn
```text
trial_active -> blocked_no_consent
b2c_lifetime_active -> blocked_no_consent
b2b_trip_active -> blocked_no_consent
basic_free -> blocked_no_consent
```plaintext

### Condition
- consent withdrawn
- legal access revoked

### Important note
Consent gate lebih tinggi daripada entitlement.

---

## Official Business Rules

### Rule 1 — B2B invite bypass is temporary
B2B access hanya berlaku:
- saat user terikat pada rombongan aktif
- dan `trip_end_at` belum terlewati

### Rule 2 — B2B access does not convert into B2C purchase
Join rombongan B2B:
- **bukan pembelian**
- tidak boleh dianggap sebagai ownership B2C lifetime

### Rule 3 — B2C purchase is permanent
Jika user membeli B2C lifetime:
- akses lifetime tercatat permanen
- tetap berlaku setelah trip B2B mana pun berakhir

### Rule 4 — Trial does not outrank active group access
Jika user masih trial lalu join rombongan:
- state final harus `b2b_trip_active`
- bukan `trial_active`

### Rule 5 — No double-charging confusion
Jika user membeli B2C saat sedang berada dalam B2B active trip:
- payment tetap valid
- ownership B2C lifetime tetap tercatat
- setelah trip selesai user tetap full access
- jangan menampilkan logika yang membingungkan seolah purchase “tertunda” atau “hilang”

---

## Access Capability Model

## Basic Feature Buckets
Untuk implementasi awal, akses dibagi ke dalam 3 bucket:

### 1. `basic_features`
Contoh:
- fitur gratis non-premium tertentu
- informational content dasar
- onboarding and settings access yang memang harus tersedia

### 2. `trial_premium_features`
Fitur premium yang boleh dipakai saat trial:
- offline maps
- panic button
- premium safety features
- contextual premium usability yang memang termasuk trial scope

### 3. `full_premium_features`
Fitur penuh untuk:
- B2C lifetime
- B2B active trip

> Detail final per-feature capability dapat dipetakan di feature docs.
> State machine ini menentukan **entitlement class**, bukan rincian UI per tombol.

---

## Entitlement Evaluation Contract

### Inputs required
Entitlement service minimal harus mempertimbangkan:

- `consent_valid: boolean`
- `trial_started_at: datetime | null`
- `trial_ends_at: datetime | null`
- `b2c_lifetime_active: boolean`
- `active_group_membership: boolean`
- `trip_end_at: datetime | null`
- current time

### Output required
Service harus menghasilkan minimal:

- `access_state`
- `premium_enabled: boolean`
- `premium_reason`
- `trip_context_active: boolean`
- `paywall_required: boolean`

### Example output
```json
{
  "accessState": "b2b_trip_active",
  "premiumEnabled": true,
  "premiumReason": "active_group_trip",
  "tripContextActive": true,
  "paywallRequired": false
}
```plaintext

---

## UI Behavior Guidance

## For `blocked_no_consent`
- redirect ke onboarding / consent flow
- jangan tampilkan premium logic seolah user eligible

## For `trial_active`
- tampilkan countdown trial
- premium features aktif sesuai scope trial
- paywall teaser/banner boleh tampil

## For `b2c_lifetime_active`
- tampilkan premium active state
- jangan tampilkan countdown trip sebagai source premium utama
- boleh tampilkan album lifetime context bila relevan

## For `b2b_trip_active`
- tampilkan bahwa premium aktif melalui trip/group
- jika relevan, tampilkan tanggal akhir trip
- jangan misleading seolah user sudah membeli lifetime jika belum

## For `basic_free`
- tampilkan paywall / upgrade prompts
- premium features harus terkunci

---

## Backend Enforcement Guidance

### Rule
Entitlement resolution sebaiknya dihitung secara konsisten oleh backend/shared logic, lalu dicerminkan ke client.

### Avoid
- menghitung entitlement berbeda-beda di banyak screen
- mengandalkan hanya local flag
- mengandalkan join group state tanpa cek `trip_end_at`

### Preferred approach
- ada satu shared resolver/service
- mobile membaca hasil state resolver atau menghitung via aturan yang identik
- settlement dan trip expiry mengubah source-of-truth backend state

---

## Edge Cases

## Edge Case 1 — User trial active, then joins group
### Expected result
Final state: `b2b_trip_active`

---

## Edge Case 2 — User trial expired, then joins group
### Expected result
Final state: `b2b_trip_active`

---

## Edge Case 3 — User already bought lifetime, then joins group
### Expected result
Final runtime state: `b2b_trip_active`
Underlying permanent ownership: `b2c_lifetime_active`

After trip ends:
- state returns to `b2c_lifetime_active`

---

## Edge Case 4 — User buys B2C while still in active trip
### Expected result
- purchase succeeds
- B2C ownership recorded immediately
- active runtime state remains `b2b_trip_active` until trip ends
- after trip ends → `b2c_lifetime_active`

---

## Edge Case 5 — Trip ends while app is offline
### Expected result
- local app may temporarily show stale state
- on next sync or reliable local time evaluation, state must resolve correctly
- safest consistent result should be applied once trip_end is known

---

## Edge Case 6 — Consent withdrawn while user has premium
### Expected result
Final state: `blocked_no_consent`

Consent gate overrides access entitlement.

---

## Edge Case 7 — Group expired before queued operation sync
### Expected result
- media sync or premium bypass dependent behavior must fail safely
- use error such as `GROUP_EXPIRED` where applicable
- do not continue assuming group-based premium access

---

## Error Relevance
State machine ini berkaitan erat dengan error berikut:

- `CONSENT_REQUIRED`
- `TRIAL_EXPIRED`
- `GROUP_EXPIRED`
- `PAYMENT_PENDING`
- `RLS_FORBIDDEN`

Detail resmi ada di:
- `docs/03_technical/protocols/error-catalog.md`

---

## Pseudocode Reference

```ts
function resolveAccessState(input): AccessState {
  if (!input.consentValid) {
    return "blocked_no_consent";
  }

  const groupActive =
    input.activeGroupMembership &&
    input.tripEndAt != null &&
    now() <= input.tripEndAt;

  if (groupActive) {
    return "b2b_trip_active";
  }

  if (input.b2cLifetimeActive) {
    return "b2c_lifetime_active";
  }

  const trialActive =
    input.trialEndsAt != null &&
    now() <= input.trialEndsAt;

  if (trialActive) {
    return "trial_active";
  }

  return "basic_free";
}
```plaintext

---

## Testing Requirements

Minimal harus diuji:

1. first consent grants trial
2. trial expires to basic
3. valid settlement upgrades to B2C lifetime
4. group join upgrades runtime state to B2B trip active
5. trip end resolves back to B2C or trial/basic
6. consent withdrawal blocks access regardless of previous premium state
7. stale local state is corrected after sync

---

## Related Decisions
- `docs/06_decisions/012-subscription-access-state-machine.md`
- `docs/06_decisions/014-trip-lifecycle-and-gps-ttl.md`
- `docs/06_decisions/017-marketing-consent-for-b2b-broadcast.md`

---

## Related Documents
- `docs/05_features/subscription-paywall/`
- `docs/05_features/rombongan-group-management/`
- `docs/05_features/pdpl-consent/`
- `docs/03_technical/protocols/trip-lifecycle.md`
- `docs/03_technical/protocols/consent-matrix.md`
- `docs/03_technical/data-model/subscription.md`
- `docs/03_technical/data-model/rombongan.md`