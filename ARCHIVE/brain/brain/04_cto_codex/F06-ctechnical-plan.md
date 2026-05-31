# Feature ID dan Nama

**F-06: B2B Group System (Rombongan)**

## Technical Approach (detail)

Rombongan harus menjadi domain entity inti karena dipakai oleh panic routing, itinerary broadcast, jejak ibadah gallery, dan paywall bypass sementara. Implement group lifecycle dari sisi backend terlebih dahulu: create group, generate invite code global unique, assign muthawif, join/leave group, deactivate/complete trip. Invite code perlu indeks unik case-insensitive dan sanitasi karakter ambigu.

Join flow pada mobile mendukung manual input dan QR scan. Setelah kode valid, backend memeriksa apakah user sudah berada di rombongan lain, apakah group masih aktif, lalu membuat membership record. Premium bypass tidak boleh mengubah subscription asli user; cukup buat entitlement override berdasarkan membership aktif dan trip status. Broadcast itinerary dikirim sebagai push melalui FCM dan juga disimpan sebagai feed agar bisa dibaca ulang.

Untuk skalabilitas dan kejelasan rule, lebih baik gunakan tabel membership eksplisit, bukan hanya `profiles.rombongan_id`. Ini memberi ruang untuk role, join history, soft leave, dan audit. Group completion oleh muthawif atau agency akan menutup override premium seluruh anggota.

## Tech Stack Components

- Supabase Postgres untuk rombongan, memberships, itinerary
- Supabase Edge Functions untuk generate code, join validation, broadcast send
- Flutter QR generation dan QR scanning
- Firebase Cloud Messaging untuk itinerary broadcast
- React/Flutter management UI untuk muthawif dan agency

## Database Schema (jika applicable)

### `rombongans`
- `id uuid primary key`
- `agency_id uuid not null`
- `name text not null`
- `invite_code text not null unique`
- `muthawif_id uuid not null`
- `is_active boolean not null default true`
- `trip_start_date date not null`
- `trip_end_date date null`
- `meeting_lat numeric(9,6) null`
- `meeting_lng numeric(9,6) null`
- `completed_at timestamptz null`
- `created_at timestamptz not null default now()`

### `rombongan_members`
- `id uuid primary key`
- `rombongan_id uuid not null`
- `user_id uuid not null`
- `role text not null default 'jamaah'`
- `joined_at timestamptz not null default now()`
- `left_at timestamptz null`
- `status text not null` (`active`, `left`, `removed`)
- unique active membership per user

### `itinerary_broadcasts`
- `id uuid primary key`
- `rombongan_id uuid not null`
- `title text not null`
- `location_name text not null`
- `meeting_lat numeric(9,6) null`
- `meeting_lng numeric(9,6) null`
- `meeting_time timestamptz not null`
- `message text null`
- `sent_by uuid not null`
- `sent_at timestamptz not null default now()`

## API Endpoints (jika applicable)

- `POST /v1/rombongans`
  Membuat rombongan dan generate invite code + QR payload.
- `POST /v1/rombongans/join`
  Join group via invite code.
- `POST /v1/rombongans/:id/leave`
  User keluar dari group aktif.
- `GET /v1/rombongans/:id/members`
  Ambil daftar anggota untuk muthawif/agency.
- `POST /v1/rombongans/:id/itineraries`
  Kirim itinerary broadcast ke semua anggota aktif.
- `POST /v1/rombongans/:id/complete`
  Menutup trip dan mencabut entitlement override.

## Task Breakdown (numbered list)

1. Finalkan domain model rombongan, membership rules, dan max group size.
2. Tambahkan schema `rombongans`, `rombongan_members`, dan `itinerary_broadcasts`.
3. Implement service generate invite code globally unique.
4. Bangun create group flow untuk muthawif/agency.
5. Implement join group via code input dan QR scan.
6. Hubungkan active membership ke entitlement override paywall.
7. Bangun member list dan join notifications untuk muthawif.
8. Implement itinerary broadcast storage + FCM dispatch.
9. Implement trip completion/deactivation dan revoke access.
10. Uji join/leave, duplicate membership, reassignment muthawif, dan panic routing.

## Risks & Mitigations

- Risiko model sederhana `profiles.rombongan_id` tidak cukup fleksibel.
  Mitigasi: gunakan membership table eksplisit sejak awal.
- Risiko invite code collision atau brute force.
  Mitigasi: unique index, rate limit join endpoint, uppercase normalization.
- Risiko premium bypass tidak tercabut saat trip selesai.
  Mitigasi: entitlement override terpisah dengan lifecycle event jelas.
- Risiko broadcast tidak hanya butuh push tetapi juga audit/readback.
  Mitigasi: simpan semua itinerary di DB, push hanya channel notifikasi.

## Complexity Estimate

**Complex**

## Dependencies (file/fitur lain yang perlu selesai dulu)

- Menjadi dependency utama untuk [F02](/Volumes/StartUp/Haramain/brain/04_cto_codex/F02-ctechnical-plan.md) dan [F07](/Volumes/StartUp/Haramain/brain/04_cto_codex/F07-ctechnical-plan.md).
- Override premium terhubung ke [F05](/Volumes/StartUp/Haramain/brain/04_cto_codex/F05-ctechnical-plan.md).
- Pembuatan package oleh agency berasal dari [F08](/Volumes/StartUp/Haramain/brain/04_cto_codex/F08-ctechnical-plan.md).
