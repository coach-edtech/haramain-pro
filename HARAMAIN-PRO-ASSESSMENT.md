# Assessment Report: Haramain Pro Codebase

## Overview
- Repo sudah punya 2 app utama: Mobile Flutter ([apps/haramain_pro](file:///Volumes/StartUp/Haramain-Pro/apps/haramain_pro)) dan Web Dashboard React/Vite ([apps/web-dashboard](file:///Volumes/StartUp/Haramain-Pro/apps/web-dashboard)).
- Backend sudah disiapkan via Supabase: migrations ([supabase/migrations](file:///Volumes/StartUp/Haramain-Pro/supabase/migrations)) + Edge Functions ([supabase/functions](file:///Volumes/StartUp/Haramain-Pro/supabase/functions)).
- Implementasi yang paling terlihat “end-to-end” adalah Panic Alert: Mobile memanggil Edge Function ([panic_service.dart](file:///Volumes/StartUp/Haramain-Pro/apps/haramain_pro/lib/features/panic/panic_service.dart#L270-L331)), Edge Function insert + kirim FCM ([fcm-panic-alert/index.ts](file:///Volumes/StartUp/Haramain-Pro/supabase/functions/fcm-panic-alert/index.ts#L87-L187)), plus fallback Twilio ([twilio-voice-fallback/index.ts](file:///Volumes/StartUp/Haramain-Pro/supabase/functions/twilio-voice-fallback/index.ts)).
- Banyak bagian masih scaffold/demo: login mobile belum pakai Supabase Auth (placeholder delay) ([main.dart](file:///Volumes/StartUp/Haramain-Pro/apps/haramain_pro/lib/main.dart#L411-L517)), user/grup masih dummy ([main.dart](file:///Volumes/StartUp/Haramain-Pro/apps/haramain_pro/lib/main.dart#L262-L265)).

## Architecture
- Stack (sesuai README/techspec):
  - Mobile: Flutter/Dart (Material3, feature modules) ([main.dart](file:///Volumes/StartUp/Haramain-Pro/apps/haramain_pro/lib/main.dart))
  - Web Dashboard: React + TypeScript + Vite + Tailwind ([apps/web-dashboard/package.json](file:///Volumes/StartUp/Haramain-Pro/apps/web-dashboard/package.json))
  - Backend: Supabase (Auth/DB/Storage) + Edge Functions Deno TypeScript ([supabase/functions](file:///Volumes/StartUp/Haramain-Pro/supabase/functions))
  - Maps: OSM (tile online + rancangan offline tiles) ([offline_map_screen.dart](file:///Volumes/StartUp/Haramain-Pro/apps/haramain_pro/lib/features/map/screens/offline_map_screen.dart))
- Pola struktur mobile:
  - `lib/features/<feature>` untuk UI + feature-scoped services (contoh: [features/map](file:///Volumes/StartUp/Haramain-Pro/apps/haramain_pro/lib/features/map), [features/panic](file:///Volumes/StartUp/Haramain-Pro/apps/haramain_pro/lib/features/panic))
  - `lib/services` untuk cross-cutting (contoh: [location_service.dart](file:///Volumes/StartUp/Haramain-Pro/apps/haramain_pro/lib/services/location_service.dart), [storage_service.dart](file:///Volumes/StartUp/Haramain-Pro/apps/haramain_pro/lib/services/storage_service.dart))
  - Banyak service pakai singleton `instance` (mudah dipakai, tapi rawan duplikasi/inisialisasi terlupa).
- Strengths:
  - Modular per-feature, relatif mudah “dibongkar per fitur”.
  - Panic sudah punya layering (FCM → Twilio fallback) yang sesuai requirement high urgency.
  - Web dashboard sudah punya auth via Supabase JS dan routing dasar.
- Catatan pola yang perlu dirapikan:
  - Ada 2 implementasi yang overlap untuk FCM handling: [firebase_service.dart](file:///Volumes/StartUp/Haramain-Pro/apps/haramain_pro/lib/firebase/firebase_service.dart) vs [fcm_service.dart](file:///Volumes/StartUp/Haramain-Pro/apps/haramain_pro/lib/services/fcm_service.dart).
  - Auth state management ada (ChangeNotifier) tapi belum dipakai di UI routing/login ([auth_state.dart](file:///Volumes/StartUp/Haramain-Pro/apps/haramain_pro/lib/auth/auth_state.dart)).

## Existing Components

### auth: status, completeness
- Ada wrapper Supabase Auth yang cukup standard: signup/signin/signout/reset ([auth_service.dart](file:///Volumes/StartUp/Haramain-Pro/apps/haramain_pro/lib/auth/auth_service.dart)).
- Tetapi flow auth di mobile belum implement:
  - `LoginScreen` masih placeholder (tidak memanggil `AuthService.signIn`) ([main.dart](file:///Volumes/StartUp/Haramain-Pro/apps/haramain_pro/lib/main.dart#L431-L452)).
  - Routing masih “cek session → home/login” di Splash ([main.dart](file:///Volumes/StartUp/Haramain-Pro/apps/haramain_pro/lib/main.dart#L179-L195)) tapi karena login dummy, session tidak benar-benar dibuat.
- Kesimpulan: auth layer ada, tapi belum “wired up” ke UI + role-based routing (completeness rendah).

### panic: status, completeness
- Mobile:
  - Trigger panic button + UX/haptic sudah ada ([panic_button_widget.dart](file:///Volumes/StartUp/Haramain-Pro/apps/haramain_pro/lib/features/panic/panic_button_widget.dart)).
  - PanicService sudah punya retry + exponential backoff + offline queue via SharedPreferences ([panic_service.dart](file:///Volumes/StartUp/Haramain-Pro/apps/haramain_pro/lib/features/panic/panic_service.dart#L188-L417)).
  - Receive alert via FirebaseService handler dan navigasi ke screen responder ([main.dart](file:///Volumes/StartUp/Haramain-Pro/apps/haramain_pro/lib/main.dart#L283-L312)).
  - Screen responder sudah ada ([panic_alert_screen.dart](file:///Volumes/StartUp/Haramain-Pro/apps/haramain_pro/lib/features/panic/panic_alert_screen.dart)).
- Backend:
  - Table + RLS untuk `panic_alerts` sudah ada ([002_panic_alerts.sql](file:///Volumes/StartUp/Haramain-Pro/supabase/migrations/002_panic_alerts.sql)).
  - Edge Function `fcm-panic-alert` melakukan auth check, insert record, cari token responder, dan send FCM ([fcm-panic-alert/index.ts](file:///Volumes/StartUp/Haramain-Pro/supabase/functions/fcm-panic-alert/index.ts#L92-L220)).
  - Edge Function Twilio fallback ada ([twilio-voice-fallback/index.ts](file:///Volumes/StartUp/Haramain-Pro/supabase/functions/twilio-voice-fallback/index.ts)).
- Gap besar di panic:
  - Response dari responder saat ini hanya update local history di device (SharedPreferences) ([panic_service.dart](file:///Volumes/StartUp/Haramain-Pro/apps/haramain_pro/lib/features/panic/panic_service.dart#L473-L497)), belum update record `panic_alerts` di Supabase (belum ada endpoint/edge function untuk respond/resolve).
  - Di mobile masih pakai `demo_jamaah_id` dan `demo_grup_id` ([main.dart](file:///Volumes/StartUp/Haramain-Pro/apps/haramain_pro/lib/main.dart#L262-L265)).
- Kesimpulan: panic paling “maju” dibanding modul lain (completeness menengah), tapi masih perlu “response flow” + integrasi role & grup.

### map: status, completeness
- UI map + search + route basic sudah ada:
  - Map screen pakai `flutter_map` dan search Nominatim ([offline_map_screen.dart](file:///Volumes/StartUp/Haramain-Pro/apps/haramain_pro/lib/features/map/screens/offline_map_screen.dart), [map_search_service.dart](file:///Volumes/StartUp/Haramain-Pro/apps/haramain_pro/lib/features/map/services/map_search_service.dart)).
  - Routing pakai OSRM public API (online) ([navigation_service.dart](file:///Volumes/StartUp/Haramain-Pro/apps/haramain_pro/lib/features/map/services/navigation_service.dart)).
- Offline maps:
  - Ada OfflineTileService untuk download tile ke storage lokal ([offline_tile_service.dart](file:///Volumes/StartUp/Haramain-Pro/apps/haramain_pro/lib/features/map/services/offline_tile_service.dart)).
  - Tetapi service punya `initialize()` yang belum terlihat dipanggil dari app startup; tanpa init, `_prefs`/directory bisa null dan fitur offline cenderung tidak jalan dengan benar.
  - Tile source masih mengarah ke public OSM / URL list region, belum terlihat implementasi self-hosted tile server seperti keputusan di README/techspec.
- Kesimpulan: map ada kerangka UI online (completeness rendah-menengah). Offline-first (download + serve tile offline + routing offline) belum mature.

### services: status, completeness
- location_service: berfungsi (permission handling + getCurrentLocation) ([location_service.dart](file:///Volumes/StartUp/Haramain-Pro/apps/haramain_pro/lib/services/location_service.dart)).
- storage_service: cukup rapi (validasi ekstensi/size, Supabase Storage buckets) + ada helper untuk offline map tiles via bucket `offline_maps` ([storage_service.dart](file:///Volumes/StartUp/Haramain-Pro/apps/haramain_pro/lib/services/storage_service.dart)).
- payment_service: berisiko tinggi dan belum production-ready:
  - Ada placeholder key Midtrans dan pola call langsung dari client (serverKey) ([payment_service.dart](file:///Volumes/StartUp/Haramain-Pro/apps/haramain_pro/lib/services/payment_service.dart#L11-L20)).
  - Webhook handler ada di client-side service (seharusnya backend).
- photo_queue_service: indikasi belum bisa build:
  - Menggunakan Isar + codegen (`part 'photo_queue_service.g.dart'`) ([photo_queue_service.dart](file:///Volumes/StartUp/Haramain-Pro/apps/haramain_pro/lib/services/photo_queue_service.dart#L1-L9)) tetapi dependency `isar` tidak ada di [pubspec.yaml](file:///Volumes/StartUp/Haramain-Pro/apps/haramain_pro/pubspec.yaml#L30-L59).
- Kesimpulan: services campuran antara “siap pakai” (location, storage) dan “draft/konsep” (payment, photo_queue).

## Gaps
- Mobile auth & role system:
  - Implement login/signup pakai Supabase Auth + persist session.
  - Implement role-based routing (Jamaah vs Muthawif vs Team-Support vs Travel Admin) sesuai PRD.
  - Hilangkan demo IDs dan ambil `user.id` + `rombongan/grup` dari DB.
- Panic lifecycle yang sesuai PRD:
  - Backend endpoint/edge function untuk responder action (responded_by, responded_at, response_type).
  - Push update ke jamaah + audit trail.
  - Activation/deactivation lifecycle (H-3/H+1) belum terlihat implementasinya di app.
- Offline maps sesuai keputusan “OSM self-hosted tiles”:
  - Self-host tile server + mekanisme download region yang sesuai batas storage.
  - Serve tiles offline di `flutter_map` (bukan hanya download file).
  - Routing offline (atau minimal self-host OSRM) untuk mengurangi ketergantungan internet.
- Payment:
  - Pindahkan semua transaksi + server key + webhook handler ke backend (Edge Function/server).
  - Implement subscription state machine sesuai techspec.
- Hardening & cleanup:
  - Konsolidasikan Firebase/FCM service (pilih satu, buang duplikasi).
  - Rapikan naming (jamaaah/grup/rombongan, rombangans typo di migrations) agar tidak jadi tech debt permanen.

## Risks
- Build stability: `photo_queue_service.dart` kemungkinan mematahkan build karena Isar tidak ada di dependency dan file g.dart belum terbentuk.
- Security:
  - Payment service mengandung pola yang bisa mengarah ke kebocoran credential (server key di client) ([payment_service.dart](file:///Volumes/StartUp/Haramain-Pro/apps/haramain_pro/lib/services/payment_service.dart#L11-L20)).
  - Banyak konstanta credential masih placeholder/hardcoded ([constants.dart](file:///Volumes/StartUp/Haramain-Pro/apps/haramain_pro/lib/config/constants.dart#L70-L89)).
- Functional mismatch vs PRD:
  - Panic dual responder (Muthawif + Team-Support) belum terlihat di query role di Edge Function (masih `muthawif` + `admin`) ([fcm-panic-alert/index.ts](file:///Volumes/StartUp/Haramain-Pro/supabase/functions/fcm-panic-alert/index.ts#L195-L202)).
  - Response flow belum tersimpan ke DB, sehingga “aksi responder” tidak bisa diaudit/ditampilkan lintas device.
- Offline-first risk:
  - Maps saat ini masih sangat bergantung internet (Nominatim + OSRM public), sehingga risiko besar di kondisi Saudi “sering tanpa sinyal” (PRD problem statement).

## Recommendation
- **Partial rebuild (recommended)**: lanjutkan codebase yang ada, tapi lakukan refactor terarah pada fondasi (auth + role routing + data model + konsolidasi services) sebelum mengerjakan fitur besar lainnya.
- Alasan:
  - Panic + Supabase Edge Functions sudah memberi baseline yang bernilai untuk diteruskan.
  - Namun kalau diteruskan tanpa perapihan fondasi, tech debt akan cepat membengkak (naming mismatch, duplikasi service, placeholder, build break).

