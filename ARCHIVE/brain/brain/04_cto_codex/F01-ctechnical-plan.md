# Feature ID dan Nama

**F-01: Onboarding + PDPL Consent**

## Technical Approach (detail)

Bangun onboarding bertahap yang menjadi hard gate sebelum user bisa mengakses home screen atau fitur premium. Setelah auth berhasil, app memeriksa status consent server-side dan local cache; bila `pdpl_consent_granted` belum aktif, user diarahkan ke flow onboarding sampai selesai. Consent location wajib untuk melanjutkan, consent passport/biometric bersifat granular dan bisa diberikan nanti saat fitur terkait dipakai.

Semua consent harus dicatat sebagai audit event, bukan hanya flag terakhir, agar tim punya jejak legal kapan consent diberikan, ditarik, dan dari device mana. Saat user menekan withdraw consent, mobile melakukan immediate local purge untuk SQLite, SecureStorage, cached maps, queue foto, token session, dan cache konten sensitif. Setelah purge lokal, app membuat deletion job ke backend; bila offline, request dimasukkan ke local outbox dan dikirim saat koneksi pulih.

Trial 7 hari dimulai hanya setelah consent wajib selesai. Enforcement dilakukan server-side melalui profile/subscription state agar tidak bisa dibypass dari client. Di settings, sediakan halaman "Privacy & Data" untuk melihat status consent, menarik consent, dan memicu delete request. Flow restart setelah withdrawal harus mengarahkan user kembali ke onboarding pada app launch berikutnya.

## Tech Stack Components

- Flutter onboarding flow + route guard
- Supabase Auth untuk register/login/session
- Supabase Postgres untuk profile, consent event, deletion request
- Supabase Edge Function untuk submit deletion request dan revoke token/device registration
- Flutter Secure Storage + SharedPreferences + SQLite untuk local state yang bisa dipurge
- Connectivity listener + background retry queue
- Optional analytics/audit sink untuk compliance logging

## Database Schema (jika applicable)

### `profiles`
- `id uuid primary key` references auth user
- `pdpl_consent_granted boolean not null default false`
- `pdpl_consent_granted_at timestamptz null`
- `location_consent_granted boolean not null default false`
- `passport_biometric_consent_granted boolean not null default false`
- `trial_started_at timestamptz null`
- `consent_version text not null default 'v1'`
- `consent_withdrawn_at timestamptz null`

### `consent_events`
- `id uuid primary key`
- `user_id uuid not null`
- `event_type text not null` (`granted`, `withdrawn`, `updated`)
- `location_consent boolean`
- `passport_biometric_consent boolean`
- `terms_accepted boolean`
- `consent_version text not null`
- `source text not null` (`mobile_onboarding`, `settings`)
- `created_at timestamptz not null default now()`

### `data_deletion_requests`
- `id uuid primary key`
- `user_id uuid not null`
- `status text not null` (`queued`, `processing`, `completed`, `failed`)
- `requested_at timestamptz not null default now()`
- `processed_at timestamptz null`
- `failure_reason text null`

## API Endpoints (jika applicable)

- `GET /v1/me/privacy-status`
  Mengambil status consent dan apakah onboarding masih wajib.
- `POST /v1/onboarding/consent`
  Simpan consent wajib/opsional, buat audit event, start trial jika belum dimulai.
- `POST /v1/privacy/withdraw-consent`
  Tandai consent withdrawn, enqueue deletion request, revoke premium eligibility berbasis consent.
- `GET /v1/privacy/deletion-status`
  Mengecek progress delete request untuk UI settings/debug support.

## Task Breakdown (numbered list)

1. Finalkan wording consent, consent versioning, dan aturan legal copy dengan product/legal.
2. Tambahkan schema `profiles`, `consent_events`, dan `data_deletion_requests`.
3. Implement route guard mobile yang memblok akses bila consent wajib belum aktif.
4. Bangun UI onboarding multi-step dengan resume state lokal.
5. Implement endpoint submit consent dan audit trail.
6. Hubungkan start free trial ke event consent sukses.
7. Bangun halaman Settings > Privacy & Data.
8. Implement local purge manager untuk storage, DB, map cache, photo queue, dan tokens.
9. Implement endpoint withdrawal + deletion queue + retry offline.
10. Tambahkan test untuk first launch, partial onboarding, withdrawal offline, dan relaunch behavior.
11. Tambahkan observability untuk consent completion rate dan deletion backlog.

## Risks & Mitigations

- Risiko wording consent tidak cukup kuat secara legal.
  Mitigasi: versioned consent copy, review legal sebelum production, simpan audit event lengkap.
- Risiko purge lokal tidak lengkap sehingga data sensitif tertinggal.
  Mitigasi: satu `PurgeService` terpusat, checklist asset store, integration test per storage layer.
- Risiko deletion request gagal saat offline.
  Mitigasi: local outbox dengan retry exponential dan status UI yang jelas.
- Risiko trial mulai sebelum consent benar-benar granted.
  Mitigasi: trigger trial hanya di backend setelah endpoint consent sukses.

## Complexity Estimate

**Medium**

## Dependencies (file/fitur lain yang perlu selesai dulu)

- Menjadi fondasi untuk [F05](/Volumes/StartUp/Haramain/brain/04_cto_codex/F05-ctechnical-plan.md) karena trial dimulai setelah consent.
- Mempengaruhi retensi data untuk [F03](/Volumes/StartUp/Haramain/brain/04_cto_codex/F03-ctechnical-plan.md), [F04](/Volumes/StartUp/Haramain/brain/04_cto_codex/F04-ctechnical-plan.md), dan [F07](/Volumes/StartUp/Haramain/brain/04_cto_codex/F07-ctechnical-plan.md).
- Membutuhkan fondasi auth dan profile base schema.
