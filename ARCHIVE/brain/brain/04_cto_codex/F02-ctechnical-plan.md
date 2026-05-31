# Feature ID dan Nama

**F-02: Panic Button (Emergency Alert)**

## Technical Approach (detail)

Implement panic flow sebagai action global di mobile app yang selalu tersedia, tetapi memakai konfirmasi long-press atau modal confirm agar tidak mudah terpencet. Saat user trigger panic, app mengambil lokasi terbaru; bila GPS live tidak tersedia dalam SLA 3 detik, gunakan last known location yang masih valid dan sertakan `location_source` serta timestamp agar muthawif tahu akurasinya.

Untuk kondisi offline, request panic disimpan dalam local queue terenkripsi dan dikirim segera saat konektivitas kembali. Di sisi backend, edge function memvalidasi JWT, mengecek apakah user tergabung dalam rombongan aktif, mengambil muthawif beserta device token-nya, lalu mengirim FCM high-priority/critical alert. Semua panic event perlu disimpan di database untuk audit, deduplication, dan status delivery.

Di sisi muthawif, app menerima push dan memunculkan full-screen urgent alert dengan sound channel khusus. Koordinat panic ditampilkan di offline map agar tetap berguna tanpa internet. Dev-only simulator harus dipagari compile flag yang berbeda untuk debug/staging dan tidak ikut ke production artifact.

## Tech Stack Components

- Flutter global panic UI + background queue
- Geolocator/location service dengan cached last known position
- Supabase Edge Function untuk dispatch panic
- Firebase Cloud Messaging untuk push high-priority
- Native mobile notification channels
- Supabase Postgres untuk panic events dan delivery log
- Mapbox offline maps untuk visualisasi lokasi distress

## Database Schema (jika applicable)

### `panic_alerts`
- `id uuid primary key`
- `jamaah_id uuid not null`
- `rombongan_id uuid not null`
- `muthawif_id uuid not null`
- `latitude numeric(9,6) not null`
- `longitude numeric(9,6) not null`
- `location_source text not null` (`live`, `cached`)
- `triggered_at timestamptz not null`
- `status text not null` (`queued`, `sent`, `delivered`, `expired`, `failed`)
- `debounce_bucket text null`

### `device_registrations`
- `id uuid primary key`
- `user_id uuid not null`
- `platform text not null`
- `fcm_token text not null`
- `critical_alert_enabled boolean not null default false`
- `last_seen_at timestamptz not null default now()`

### `panic_delivery_logs`
- `id uuid primary key`
- `panic_alert_id uuid not null`
- `provider text not null default 'fcm'`
- `provider_message_id text null`
- `delivery_status text not null`
- `response_payload jsonb null`
- `created_at timestamptz not null default now()`

## API Endpoints (jika applicable)

- `POST /v1/panic-alerts`
  Submit panic alert dari client atau replay local queue.
- `GET /v1/panic-alerts/:id/status`
  Ambil status dispatch untuk feedback ke user/debug support.
- `POST /v1/dev/panic-simulate`
  Hanya untuk debug/staging, disabled total di production.

## Task Breakdown (numbered list)

1. Finalkan aturan debounce, expiry alert, dan cancel false alarm window.
2. Tambahkan tabel `panic_alerts`, `device_registrations`, dan `panic_delivery_logs`.
3. Implement registrasi FCM token dan capability critical alert per device.
4. Bangun panic CTA global dengan safeguard long-press/confirmation.
5. Implement location resolver dengan fallback ke cached coordinates.
6. Bangun local encrypted queue untuk panic offline.
7. Implement edge function dispatch panic ke muthawif berdasarkan rombongan aktif.
8. Konfigurasi notification channel kritis di Android dan iOS.
9. Integrasikan tampilan lokasi distress ke offline maps pada app muthawif.
10. Tambahkan dev-only simulator dengan compile-time guard.
11. Uji skenario online, offline, duplicate panic, no group, dan receiver offline.

## Risks & Mitigations

- Risiko bypass silent/DND tidak konsisten antar platform.
  Mitigasi: gunakan native critical alert capability, dokumentasikan fallback behavior, uji di device nyata.
- Risiko false positive akibat tap tidak sengaja.
  Mitigasi: long-press, confirm dialog, debounce 5 menit, dan optional cancel window singkat.
- Risiko panic gagal terkirim saat jaringan padat.
  Mitigasi: offline queue, retry backoff, cached location, observability delivery logs.
- Risiko user tanpa rombongan memicu fitur tanpa target.
  Mitigasi: validasi server-side dan error message yang jelas di client.

## Complexity Estimate

**Complex**

## Dependencies (file/fitur lain yang perlu selesai dulu)

- Bergantung pada [F03](/Volumes/StartUp/Haramain/brain/04_cto_codex/F03-ctechnical-plan.md) untuk offline map display yang stabil.
- Bergantung pada [F06](/Volumes/StartUp/Haramain/brain/04_cto_codex/F06-ctechnical-plan.md) untuk relasi jamaah-ke-muthawif via rombongan.
- Access gating dipengaruhi [F05](/Volumes/StartUp/Haramain/brain/04_cto_codex/F05-ctechnical-plan.md) bila panic termasuk premium dengan safety exception.
