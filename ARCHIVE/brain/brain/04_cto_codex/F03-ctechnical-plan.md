# Feature ID dan Nama

**F-03: Offline Maps**

## Technical Approach (detail)

Offline maps sebaiknya diimplementasikan sebagai managed download, bukan dibundel langsung di binary, agar ukuran app store package tetap terkendali dan tile pack bisa diperbarui tanpa full app release. Pada first run, app memeriksa apakah pack Makkah dan Madinah sudah tersedia; jika belum, user ditawari download dengan estimasi ukuran. Download memakai background task dengan progress tersimpan lokal agar status tetap konsisten walau app direstart.

Untuk menjaga batas 300MB, gunakan dua region pack terpisah dengan zoom bounds yang sudah dipotong sesuai use case display, bukan navigasi detail. Metadata tile pack disimpan lokal dan, bila perlu, di server untuk telemetri. Di settings, sediakan manajemen cache: lihat ukuran, hapus, dan refresh maps. Developer coordinate injection harus berada di dev menu dan dikunci oleh environment flag.

Map service yang sama dipakai oleh panic feature dan muthawif map screen, sehingga perlu abstraksi tunggal `MapRepository/OfflineMapManager`. Bila storage device kurang, download dibatalkan dengan pesan yang jelas dan rekomendasi clear space.

## Tech Stack Components

- Flutter Mapbox SDK dengan offline pack support
- Background download/task manager
- Geolocator untuk location updates
- Local persistent metadata store (SQLite/SharedPreferences)
- Path provider/file system manager
- Optional telemetry untuk map download success/failure

## Database Schema (jika applicable)

Tidak wajib ada schema backend untuk MVP. Jika ingin observability lintas device:

### `map_pack_events`
- `id uuid primary key`
- `user_id uuid null`
- `pack_name text not null`
- `event_type text not null` (`download_started`, `download_completed`, `deleted`, `failed`)
- `size_mb integer null`
- `created_at timestamptz not null default now()`

## API Endpoints (jika applicable)

- `GET /v1/map-packs/manifest`
  Mengembalikan daftar region, versi pack, checksum, dan ukuran estimasi.
- `POST /v1/dev/map-coordinate-injection`
  Dev/staging only untuk spoof testing, tidak tersedia di production.

## Task Breakdown (numbered list)

1. Finalkan strategi offline pack: region bounds, zoom levels, dan target size per kota.
2. Implement `OfflineMapManager` dan local metadata persistence.
3. Bangun prompt download awal dan progress UI.
4. Integrasikan background download/resume/cancel.
5. Implement render map tanpa koneksi dan blue-dot positioning.
6. Tambahkan settings untuk delete/refresh pack.
7. Tambahkan handling low storage dan recovery flow.
8. Integrasikan service ini dengan layar panic dan layar muthawif.
9. Tambahkan dev-only coordinate injection.
10. Uji ukuran final pack, background behavior, restart app, dan offline render.

## Risks & Mitigations

- Risiko ukuran tile melebihi 300MB.
  Mitigasi: kunci zoom range, split pack per kota, ukur real pack di QA device sebelum release.
- Risiko SDK offline behavior berbeda per platform.
  Mitigasi: satu abstraction service, smoke test iOS/Android pada device nyata.
- Risiko first-launch friction terlalu tinggi karena download besar.
  Mitigasi: download non-blocking, jelaskan manfaat, allow defer namun beri CTA yang jelas.
- Risiko fitur dev spoofing bocor ke production.
  Mitigasi: compile flag, CI check terhadap env production, dan test artifact inspection.

## Complexity Estimate

**Medium**

## Dependencies (file/fitur lain yang perlu selesai dulu)

- Menjadi fondasi visual untuk [F02](/Volumes/StartUp/Haramain/brain/04_cto_codex/F02-ctechnical-plan.md) dan [F04](/Volumes/StartUp/Haramain/brain/04_cto_codex/F04-ctechnical-plan.md).
- Data retention/location purge harus patuh ke [F01](/Volumes/StartUp/Haramain/brain/04_cto_codex/F01-ctechnical-plan.md).
