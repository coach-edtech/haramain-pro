# Feature ID dan Nama

**F-05: B2C Paywall + Midtrans Integration**

## Technical Approach (detail)

Gunakan server-authoritative entitlement model. Client hanya membaca status premium, trial, dan paywall copy; keputusan unlock premium tetap berasal dari backend berdasarkan `trial_started_at`, `trial_ends_at`, subscription lifetime, atau override rombongan aktif. Midtrans Snap token harus selalu dibuat server-side agar kredensial aman dan order bisa diikat ke user yang valid.

Payment lifecycle dibagi menjadi `created -> pending -> settled -> failed/expired/refunded`. Saat user membuka checkout, backend membuat order dan menyimpan snapshot harga serta product type. Webhook Midtrans memverifikasi signature SHA512, lalu mengubah status payment dan entitlement user di satu transaksi database. Untuk UX cepat, client subscribe ke Realtime atau polling singkat agar premium aktif muncul beberapa detik setelah settlement.

Paywall enforcement harus terjadi di dua level: UI gate pada fitur premium dan server-side policy pada endpoint sensitif. Trial banner dihitung dari server timestamp untuk menghindari manipulasi jam device. Untuk safety-sensitive panic, product perlu keputusan eksplisit apakah fitur sepenuhnya premium atau ada limited emergency mode; teknisnya jangan diasumsikan tanpa keputusan bisnis.

## Tech Stack Components

- Flutter paywall UI + trial banner
- Supabase Postgres untuk subscription, entitlement, payments
- Supabase Edge Functions untuk create checkout dan webhook handler
- Midtrans Snap API
- Supabase Realtime/polling untuk entitlement refresh
- Feature flag/config service untuk paywall copy dan safety exception

## Database Schema (jika applicable)

### `subscriptions`
- `id uuid primary key`
- `user_id uuid not null unique`
- `tier text not null` (`free`, `trial`, `active`)
- `trial_started_at timestamptz null`
- `trial_ends_at timestamptz null`
- `activated_at timestamptz null`
- `source text not null` (`trial`, `midtrans`, `agency_override`)
- `expires_at timestamptz null`

### `payments`
- `id uuid primary key`
- `user_id uuid not null`
- `order_id text not null unique`
- `provider text not null default 'midtrans'`
- `product_code text not null`
- `gross_amount numeric(12,2) not null`
- `status text not null` (`created`, `pending`, `settlement`, `expire`, `cancel`, `refund`)
- `snap_token text null`
- `provider_payload jsonb null`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

### `entitlement_overrides`
- `id uuid primary key`
- `user_id uuid not null`
- `source_type text not null` (`rombongan`)
- `source_id uuid not null`
- `active_from timestamptz not null`
- `active_until timestamptz null`
- `status text not null`

## API Endpoints (jika applicable)

- `GET /v1/subscription/status`
  Mengambil status trial, premium, remaining days, dan source entitlement.
- `POST /v1/payments/midtrans/checkout`
  Membuat order dan Snap token untuk Haramain Safety Pass.
- `POST /v1/webhooks/midtrans`
  Webhook Midtrans dengan verifikasi signature.
- `POST /v1/subscription/restore`
  Refresh entitlement setelah reinstall/login ulang.

## Task Breakdown (numbered list)

1. Finalkan business rules: trial exact expiry, panic safety exception, refund behavior.
2. Tambahkan schema `subscriptions`, `payments`, dan `entitlement_overrides`.
3. Implement backend entitlement calculator terpusat.
4. Bangun trial start trigger saat onboarding consent selesai.
5. Bangun UI banner countdown dan paywall screens.
6. Implement checkout endpoint yang membuat Midtrans Snap token.
7. Implement webhook verification dan transaction-safe entitlement activation.
8. Integrasikan Realtime/polling refresh di client.
9. Tambahkan server-side guards pada endpoint premium.
10. Uji settlement, pending, failed webhook, reinstall, dan group override interaction.

## Risks & Mitigations

- Risiko user memanipulasi waktu device untuk memperpanjang trial.
  Mitigasi: semua perhitungan berbasis server timestamp.
- Risiko webhook telat atau gagal sehingga unlock tidak instan.
  Mitigasi: idempotent webhook handler, retry, dan status `processing/pending` yang terlihat user.
- Risiko aturan premium bertabrakan dengan rombongan bypass.
  Mitigasi: entitlement calculator tunggal dengan precedence yang jelas.
- Risiko claim marketing tidak sinkron dengan refund process.
  Mitigasi: dokumentasikan SOP refund dan kaitkan perubahan status refund ke entitlement revoke.

## Complexity Estimate

**Complex**

## Dependencies (file/fitur lain yang perlu selesai dulu)

- Trial start bergantung pada [F01](/Volumes/StartUp/Haramain/brain/04_cto_codex/F01-ctechnical-plan.md).
- Entitlement override terhubung ke [F06](/Volumes/StartUp/Haramain/brain/04_cto_codex/F06-ctechnical-plan.md).
- Mengendalikan akses premium untuk [F02](/Volumes/StartUp/Haramain/brain/04_cto_codex/F02-ctechnical-plan.md), [F03](/Volumes/StartUp/Haramain/brain/04_cto_codex/F03-ctechnical-plan.md), [F04](/Volumes/StartUp/Haramain/brain/04_cto_codex/F04-ctechnical-plan.md), dan [F07](/Volumes/StartUp/Haramain/brain/04_cto_codex/F07-ctechnical-plan.md).
