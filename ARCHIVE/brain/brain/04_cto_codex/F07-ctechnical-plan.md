# Feature ID dan Nama

**F-07: Jejak Ibadah Photo (CRM Gallery + Watermarking)**

## Technical Approach (detail)

Pisahkan fitur ini menjadi dua jalur: mobile capture-sync pipeline untuk muthawif dan web CRM gallery untuk agency. Di mobile, setiap foto yang diambil masuk ke queue lokal terlebih dahulu agar flow online dan offline seragam. Worker background memproses item queue satu per satu: validasi group aktif, ambil watermark config agency, kompres foto, tempel watermark, upload ke storage, lalu simpan metadata ke database. Original lokal dihapus segera setelah upload sukses agar patuh privasi.

Watermark sebaiknya diterapkan client-side agar offline capture tetap bisa memproses saat koneksi kembali tanpa perlu image worker eksternal. Namun logo agency harus di-cache lokal per rombongan aktif. Metadata lokasi dan timestamp disimpan terstruktur supaya dashboard bisa filter per trip, waktu, dan titik lokasi. Untuk gallery web, query harus berbasis rombongan dan agency ownership agar akses terkontrol.

Queue perlu state machine yang jelas: `pending`, `processing`, `failed_retryable`, `failed_terminal`, `synced`. Jika queue menumpuk, worker memprioritaskan FIFO. Karena ada PDPL constraint, location metadata harus punya retention job 30 hari bila user tidak punya consent album eksplisit atau jika policy final mengharuskannya.

## Tech Stack Components

- Flutter camera plugin
- Flutter image processing/compression library
- SQLite/local encrypted queue
- Supabase Storage untuk upload image
- Supabase Postgres untuk photo metadata
- Connectivity/background sync worker
- React web gallery untuk agency CRM

## Database Schema (jika applicable)

### `jejak_ibadah_photos`
- `id uuid primary key`
- `rombongan_id uuid not null`
- `agency_id uuid not null`
- `uploaded_by uuid not null`
- `storage_path text not null`
- `public_url text null`
- `captured_at timestamptz not null`
- `captured_lat numeric(9,6) null`
- `captured_lng numeric(9,6) null`
- `original_size_kb integer not null`
- `compressed_size_kb integer not null`
- `is_watermarked boolean not null default false`
- `watermark_logo_version text null`
- `synced_at timestamptz null`

### `agency_brand_assets`
- `id uuid primary key`
- `agency_id uuid not null`
- `asset_type text not null` (`logo`)
- `storage_path text not null`
- `version text not null`
- `is_active boolean not null default true`
- `created_at timestamptz not null default now()`

### Local queue table `photo_upload_queue` (mobile SQLite)
- `id text primary key`
- `rombongan_id text not null`
- `local_file_path text not null`
- `status text not null`
- `retry_count integer not null default 0`
- `last_error text null`
- `created_at text not null`

## API Endpoints (jika applicable)

- `POST /v1/jejak-ibadah/upload-url`
  Menghasilkan signed upload target dan metadata validation.
- `POST /v1/jejak-ibadah/photos`
  Menyimpan metadata setelah upload sukses.
- `GET /v1/jejak-ibadah/rombongans/:id/photos`
  Gallery listing dengan filter tanggal/lokasi/uploader.
- `POST /v1/jejak-ibadah/sync-retry`
  Opsional endpoint observability/manual retry trigger.

## Task Breakdown (numbered list)

1. Finalkan pipeline queue, ukuran kompresi, dan policy purge original file.
2. Tambahkan schema `jejak_ibadah_photos` dan `agency_brand_assets`.
3. Bangun camera capture flow dan local queue persistence.
4. Implement image compression + watermark service.
5. Implement signed upload + metadata save flow.
6. Bangun connectivity watcher dan background sync worker.
7. Tambahkan pending badge, sync status, dan manual retry UI di mobile.
8. Bangun gallery web per rombongan dengan filter inti.
9. Integrasikan logo agency dari dashboard B2B sebagai watermark source.
10. Tambahkan purge/retention job untuk metadata lokasi sesuai policy PDPL.
11. Uji skenario offline panjang, queue besar, logo berubah, dan storage device penuh.

## Risks & Mitigations

- Risiko proses image di client terlalu berat untuk device low-end.
  Mitigasi: resize sebelum watermark, worker serial, dan limit concurrency satu file.
- Risiko original file tertinggal di device.
  Mitigasi: delete setelah sync sukses, periodic cleanup job, encrypted local cache.
- Risiko logo agency belum tersedia saat offline sync.
  Mitigasi: cache logo terakhir, fallback upload tanpa watermark dengan audit warning bila rule bisnis mengizinkan.
- Risiko filter gallery lambat untuk trip besar.
  Mitigasi: index by `rombongan_id`, `captured_at`, `agency_id`, dan pagination.

## Complexity Estimate

**Complex**

## Dependencies (file/fitur lain yang perlu selesai dulu)

- Bergantung pada [F06](/Volumes/StartUp/Haramain/brain/04_cto_codex/F06-ctechnical-plan.md) untuk relasi rombongan.
- Logo/watermark source dan gallery web berasal dari [F08](/Volumes/StartUp/Haramain/brain/04_cto_codex/F08-ctechnical-plan.md).
- Consent dan retention location terkait [F01](/Volumes/StartUp/Haramain/brain/04_cto_codex/F01-ctechnical-plan.md).
- Premium gating B2C terkait [F05](/Volumes/StartUp/Haramain/brain/04_cto_codex/F05-ctechnical-plan.md) jika fitur ini dikunci untuk pengguna non-B2B.
