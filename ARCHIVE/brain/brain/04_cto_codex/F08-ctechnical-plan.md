# Feature ID dan Nama

**F-08: B2B Agency Dashboard**

## Technical Approach (detail)

Bangun dashboard web React sebagai control plane untuk agency, sementara domain authority tetap berada di Supabase backend. Modul utamanya: registration & approval, seat license commerce, package/rombongan management, CRM gallery, dan broadcast alumni. Agency registration menghasilkan tenant record yang berstatus `pending_approval`; hanya setelah admin approve agency dapat membeli lisensi dan membuat package.

Seat license harus dikelola sebagai ledger, bukan hanya counter, agar pembelian, konsumsi seat oleh package, refund, dan audit tetap terlacak. Volume pricing dihitung backend pada saat quote dan di-freeze saat order dibuat. Setelah webhook Midtrans settlement, ledger kredit ditambahkan ke agency. Package creation memilih muthawif terdaftar, membuat rombongan, lalu seat tersedia dikurangi sesuai alokasi kebijakan bisnis.

Gallery Jejak Ibadah di dashboard membaca metadata dari storage/database dan membatasi akses berdasar ownership agency. Broadcast alumni perlu menyimpan audience snapshot, payload, dan delivery result agar agency punya riwayat kampanye. Upload dokumen PPIU dan logo agency memakai storage bucket terpisah dengan akses ketat.

## Tech Stack Components

- React web app
- Supabase Auth untuk agency admin accounts
- Supabase Postgres untuk agencies, approvals, seat ledger, packages, broadcasts
- Supabase Storage untuk license document, logo, dan gallery assets
- Supabase Edge Functions untuk quote checkout, webhook, broadcast dispatch
- Midtrans Snap API untuk pembayaran B2B
- Firebase Cloud Messaging untuk alumni broadcast

## Database Schema (jika applicable)

### `agencies`
- `id uuid primary key`
- `company_name text not null`
- `ppiu_license_number text not null`
- `ppiu_document_path text not null`
- `logo_asset_id uuid null`
- `status text not null` (`pending_approval`, `approved`, `rejected`, `suspended`)
- `approved_at timestamptz null`
- `created_at timestamptz not null default now()`

### `agency_admin_users`
- `id uuid primary key`
- `agency_id uuid not null`
- `user_id uuid not null unique`
- `role text not null default 'admin'`
- `created_at timestamptz not null default now()`

### `agency_seat_ledger`
- `id uuid primary key`
- `agency_id uuid not null`
- `entry_type text not null` (`purchase_credit`, `package_allocation`, `refund_debit`, `manual_adjustment`)
- `quantity integer not null`
- `unit_price numeric(12,2) null`
- `reference_type text null`
- `reference_id uuid null`
- `created_at timestamptz not null default now()`

### `agency_orders`
- `id uuid primary key`
- `agency_id uuid not null`
- `order_id text not null unique`
- `seat_quantity integer not null`
- `price_per_seat numeric(12,2) not null`
- `discount_rate numeric(5,2) not null`
- `gross_amount numeric(12,2) not null`
- `status text not null`
- `provider_payload jsonb null`
- `created_at timestamptz not null default now()`

### `broadcast_campaigns`
- `id uuid primary key`
- `agency_id uuid not null`
- `title text not null`
- `message text not null`
- `audience_filter jsonb not null`
- `recipient_count integer not null`
- `status text not null` (`draft`, `queued`, `sent`, `partial_failed`, `failed`)
- `sent_at timestamptz null`

## API Endpoints (jika applicable)

- `POST /v1/agencies/register`
  Registrasi agency + upload metadata PPIU/logo.
- `POST /v1/agencies/:id/approve`
  Admin internal approve/reject agency.
- `POST /v1/agencies/:id/license-quote`
  Menghitung volume pricing untuk jumlah seat.
- `POST /v1/agencies/:id/license-checkout`
  Membuat Midtrans checkout untuk pembelian seat.
- `POST /v1/webhooks/midtrans-agency`
  Webhook settlement pembelian seat B2B.
- `POST /v1/agencies/:id/packages`
  Membuat package/rombongan dan assign muthawif.
- `GET /v1/agencies/:id/gallery`
  Mengambil CRM gallery per filter.
- `POST /v1/agencies/:id/broadcasts`
  Membuat dan mengirim broadcast ke alumni terpilih.

## Task Breakdown (numbered list)

1. Finalkan tenant model agency, approval workflow, dan kebijakan seat consumption.
2. Tambahkan schema `agencies`, `agency_admin_users`, `agency_seat_ledger`, `agency_orders`, dan `broadcast_campaigns`.
3. Bangun registration flow dengan upload dokumen PPIU dan logo.
4. Implement internal admin approval/rejection flow.
5. Implement backend quote calculator dan checkout Midtrans seat purchase.
6. Implement webhook settlement yang menambah credit ke seat ledger.
7. Bangun dashboard overview: seat balance, packages, gallery, broadcasts.
8. Integrasikan create package + assign muthawif + create rombongan.
9. Bangun CRM gallery filters dan photo detail view.
10. Implement alumni audience builder dan broadcast dispatch/reporting.
11. Tambahkan RBAC, audit log, dan test untuk approval/payment/broadcast edge cases.

## Risks & Mitigations

- Risiko model seat berbasis counter sulit diaudit.
  Mitigasi: gunakan ledger immutable sejak awal.
- Risiko registration fraud atau dokumen tidak valid.
  Mitigasi: approval manual admin, status pending default, storage access terbatas.
- Risiko volume pricing dihitung beda antara UI dan backend.
  Mitigasi: source of truth di backend, UI hanya menampilkan hasil quote server.
- Risiko broadcast massal gagal sebagian tanpa visibilitas.
  Mitigasi: simpan delivery report, retry batch, dan tampilkan failure count.

## Complexity Estimate

**Complex**

## Dependencies (file/fitur lain yang perlu selesai dulu)

- Membuat dan mengelola rombongan untuk [F06](/Volumes/StartUp/Haramain/brain/04_cto_codex/F06-ctechnical-plan.md).
- Menyediakan logo agency dan gallery backend untuk [F07](/Volumes/StartUp/Haramain/brain/04_cto_codex/F07-ctechnical-plan.md).
- Seat purchase Midtrans memakai pola serupa dengan [F05](/Volumes/StartUp/Haramain/brain/04_cto_codex/F05-ctechnical-plan.md), tetapi domain order dan pricing berbeda.
