# Feature ID dan Nama

**F-04: Virtual Muthawif (Location-Contextual Prayer Surfacing)**

## Technical Approach (detail)

Implement Virtual Muthawif sebagai kombinasi geofence engine, content repository offline, dan presentation layer. Semua konten doa, transliterasi, terjemahan, metadata lokasi, dan prioritas overlap dibundel dalam asset JSON versioned. Audio sebaiknya menjadi optional downloadable pack agar install size awal tidak terlalu besar; bila audio belum ada, text tetap tampil penuh.

Deteksi lokasi menggunakan geofencing untuk trigger hemat baterai, ditambah location polling ringan saat app aktif untuk mempercepat surfacing di area padat. Ketika beberapa geofence overlap, gunakan priority matrix di data konten agar keputusan tidak hardcoded di UI. Surface content harus bisa muncul dari background notification, tetapi auto-play audio tetap dilarang agar tidak mengganggu ibadah.

Sediakan juga manual lookup list berdasarkan lokasi sehingga fitur tetap berguna walau background geofence dibatasi OS. Karena ini konten religius, pipeline update sebaiknya editorial dan versioned; perubahan konten dikirim sebagai JSON patch saat online dan disimpan lokal untuk offline usage.

## Tech Stack Components

- Flutter geofence/background location plugin
- Local JSON asset repository untuk prayer library
- Optional audio pack downloader + local file manager
- Local notification service
- Flutter UI untuk content cards dan manual lookup
- Optional backend manifest endpoint untuk content version check

## Database Schema (jika applicable)

MVP bisa tanpa tabel backend bila konten dibundel. Jika ingin update terkelola:

### `prayer_content_versions`
- `id uuid primary key`
- `version text not null unique`
- `manifest_url text not null`
- `is_active boolean not null default true`
- `published_at timestamptz not null default now()`

## API Endpoints (jika applicable)

- `GET /v1/virtual-muthawif/content-manifest`
  Mengembalikan versi konten aktif, checksum, dan daftar patch.
- `GET /v1/virtual-muthawif/audio-manifest`
  Mengembalikan daftar audio pack optional yang tersedia.

## Task Breakdown (numbered list)

1. Finalkan daftar lokasi, radius, dan canonical overlap priority.
2. Siapkan schema JSON untuk lokasi, doa, transliterasi, terjemahan, dan notes.
3. Implement offline content repository dan parser versioned.
4. Bangun geofence registration/background callbacks.
5. Implement surfacing UI + local notifications + dismiss behavior.
6. Tambahkan manual lookup/browse list untuk semua lokasi.
7. Implement audio player dan optional audio pack download.
8. Tambahkan online content update manifest dan patch apply.
9. Uji overlap geofence, GPS inaccuracy, app background/terminated, dan missing audio.

## Risks & Mitigations

- Risiko geofence background dibatasi OS sehingga trigger tidak konsisten.
  Mitigasi: fallback manual lookup, local notification strategy, dan location refresh saat app foreground.
- Risiko app size membesar karena audio.
  Mitigasi: pisahkan audio menjadi optional pack, compress aggressively, cache manifest.
- Risiko kesalahan konten doa berdampak reputasional.
  Mitigasi: editorial review, versioning, immutable published manifests, dan rollback cepat.
- Risiko overlap lokasi membingungkan user.
  Mitigasi: explicit priority ranking di content data dan test di area overlap.

## Complexity Estimate

**Complex**

## Dependencies (file/fitur lain yang perlu selesai dulu)

- Memanfaatkan capability location dan offline map dari [F03](/Volumes/StartUp/Haramain/brain/04_cto_codex/F03-ctechnical-plan.md).
- Consent location dan retensi data diatur oleh [F01](/Volumes/StartUp/Haramain/brain/04_cto_codex/F01-ctechnical-plan.md).
- Dapat menjadi bagian dari premium gating di [F05](/Volumes/StartUp/Haramain/brain/04_cto_codex/F05-ctechnical-plan.md).
