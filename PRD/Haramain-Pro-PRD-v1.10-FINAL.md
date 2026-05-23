# HARAMAIN PRO — Product Requirements Document
|**Version:** 1.10-FINAL
|**Date:** May 02, 2026
|**Status:** FINAL — Ready for Engineering Handoff
|**Author:** Coach Chaidir (Founder)
|**CTO Review:** Hermes
|**Document Owner:** Founder + Engineering Lead (Trae)
|**OQ Status:** ✅ ALL RESOLVED — 21/21 Open Questions Closed

---

---

## Changelog v1.10-FINAL

| # | Change | Description |
|---|--------|-------------|
| Fix | Enterprise = White Label customer | Enterprise tier ONLY untuk Travel yang beli White Label — tanpa White Label, maks tier Medium |
| Fix | Hapus Revenue Share 30% Sales Agent | Sales Agent TIDAK membeli Safety Pass — lisensi disediakan oleh Travel; biaya Haramain Pro sudah include dalam paket Umrah yang dibayar Jamaah |
| Fix | White Label Dasbor Web | White Label Travel HARUS punya Travel Admin Dashboard |

## Changelog v1.6

|| Change | Description |
|--------|-------------|
| Feature: Panic Button Response | Panic Alert diterima Muthawif DAN Team-Support; keduanya bisa respons dengan "Stay, saya jemput" atau "Saya di sini" (kirim lokasi) |
| Feature: UX Accessibility Tooltip | First-time popup guide untuk setiap fitur — agar user non-tech-savvy bisa paham tanpa training |
| Feature: Panic Alert Schema | Extended panic_alerts table dengan response_type + responder_location |

## Changelog v1.5

|| Change | Description |
|--------|-------------|
| Feature: Informasi Umrah | Koleksi konten edukasi (video/audio/teks) oleh SuperAdmin, free untuk semua user — termasuk Sales Agent tool untuk prospek |

## Changelog v1.4

|| Change | Description |
|--------|-------------|
| Pricing Restructure | B2C: Safety Pass Rp 120rb lifetime; B2B: 4-tier (Independent Rp 90rb, Small 45pax Rp 75rb, Medium 90pax Rp 60rb, Enterprise Rp 50rb+WL Rp 30jt+Rp 12jt/yr); Lisensi satuan Rp 90rb |
| Feature: Panic Button Lifecycle — Mandiri | Auto-activate H-3 sebelum keberangkatan, auto-deactivate H+1 setelah pulang, re-activation via renew atau new invitation code |
| Feature: Mandatory Departure Date Input | Jamaah Mandiri wajib input tanggal keberangkatan + durasi untuk Panic Button activation |
| Feature: Invitation Approval Flow | Jamaah Travel yang di-invite Admin bisa Accept/Decline; 7-day expiration |
| Fix: Jejak Ibadah Removed from Mandiri | Album Foto dihapus dari scope Mandiri — user menyimpan sendiri via WhatsApp |
| Fix: Panic Button Anti-Abuse | Panic Button tidak bisa disalahgunakan setelah pulang — auto-off + reactivation required |

## Changelog v1.3
|| Change | Description |
|--------|-------------|
| Feature: Sales Agen Role | New role added — independent agent who acquires prospects for Travel |
| Feature: Lead Attribution System | Unique sales_agent_code per Agen; all installs via Agen link auto-attributed |
| Feature: Prospect Dashboard | Simple CRM: nama, no HP, status prospek (install/respons/minat/belum) |
| Feature: Bank Content | Poster gallery with Travel logo watermark — downloadable for social media |
| Feature: Test-Code (Demo & Prospect Activation) | Two use cases: (1) Sales Agen → Panic Button demo; (2) SuperAdmin → Travel prospect free trial (10 codes, full Premium access) |
| Feature: Sales Katalog Paket | View available packages with pricing, dates, seat availability |
| Feature: QR Business Card | Personal QR code for nametag/namecard — scans open app download + referral |
| Feature: Sales Earnings | Simple earnings dashboard — converted leads, estimated commission |
| Feature: Deep Link + Referral | Share links contain sales_agent_id for attribution tracking |

## Changelog v1.2 (continued)
|| Change | Description |
|--------|-------------|
| Feature: Role System | New role hierarchy (Travel Admin, Team-Support, Muthawif, Jamaah, Muthawif-Mandiri) |
| Feature: Role Privilege Matrix | Feature access control per role with revocation flow |
| Feature: White Label | Multi-tenant app launcher architecture for PPIU branding |
| Feature: Umrah Mandiri | Self-signup flow, Muthawif-Mandiri self-activation, Rp 120.000 Safety Pass |
| Feature: Multi-Grup Alumni | Users can join alumni groups from multiple travels |
| Feature: Jejak Ibadah (Album) | 13 sub-features: Kamera, PDF Album, Location Timeline, ZIP Download, Social Share, Comments, Voting, Analytics, Challenges, Memory Notif, Bundle Upsell |
| Feature: Travel Umrah Operations | 16 sub-features: Paket Mgmt, Seat Inventory, Grup Creation, Invite Muthawif/TS, Alumni Lifecycle, Admin Alumni, Itinerary, Broadcast, Revoke, Daily Schedule, WhatsApp Reminder, Muthawif Report, Dashboard Overview, Revenue Summary |
| Schema Update | Added `travels` table, updated `users` role enum, `travel_id`, `is_paid_user`, `invitation_code` |
| OQ Resolution | ✅ ALL 21 Open Questions RESOLVED — see Section 11 |
| Freemium Model | Panic Button + Jejak Ibadah + Geo-Doa → Premium; Nadhira KB-constrained; departure date validation |
| B2B Travel Pricing | 4-tier: Independent Rp 90rb, Small 45pax Rp 75rb, Medium 90pax Rp 60rb, Enterprise Rp 50rb+WL Rp 30jt+Rp 12jt/yr |
| Video Removed | Jejak Ibadah: hapus video clip storage, foto compress on-device |
| Nadhira AI | KB-constrained (RAG), 30-day window from departure date |

## Changelog v1.1
|| Change | Description |
|--------|-------------|
| CTO Review Fix | Refactored ALL User Stories to INVEST format with Given/When/Then AC |
| Gap: Offline Sync | Added Offline Sync Strategy section with conflict resolution |
| Gap: Panic Error States | Added Panic Button error handling & fallback logic |
| Gap: Photo Storage Model | Added storage cost estimation & limits |
| Gap: Legal Placeholders | Converted to actionable Open Questions with deadlines |
| Gap: Tech Debt | Added Load Test & Rate Limiting sections |

---

# SECTION 1: Ringkasan Eksekutif

**Haramain Pro** adalah ekosistem digital B2B2C keselamatan dan koordinasi ibadah Haji & Umrah Indonesia.

## Problem Statement
Setiap tahun 1.5 juta+ Jamaah Umrah dan 250K Haji Indonesia beribadah di lingkungan yang asing, padat, dan sering tanpa sinyal internet. Ribuan tersesat, panik, dan tidak mampu berkomunikasi dengan pemimpin rombongan mereka.

## Solusi
Satu platform terintegrasi dengan tiga pilar:
1. **Keselamatan Luring (Offline Safety)** — Peta offline, Panic Button yang menembus mode senyap, panduan doa kontekstual
2. **Manajemen Rombongan Digital** — Koordinasi real-time Muthawif ↔ Jamaah
3. **Mesin CRM Agen Travel** — Album foto ber-watermark sebagai alat retensi

## Target Tahun 1
- Revenue: **Rp 11–13 Miliar**
- Jamaah: **110,000–130,000**
- Mitra Agen B2B: **40–70 aktif**

---

# SECTION 2: Aktor & Personas

## 2.1 Peta Aktor Sistem

|| Aktor | Tier | Channel | Peran Kritis |
|-------|------|---------|--------------|
|| Travel Admin | B2B Client | Dasbor Web | Admin penuh untuk akun Travel Umrah-nya |
|| Team-Support | B2B Field | Mobile App | Pendamping jamaah, bantu Muthawif selama ibadah |
|| Muthawif | B2B Field | Mobile App | Pembimbing rombongan, coordinator, fotografer |
|| Jamaah | End User | Mobile App | Pengguna fitur keselamatan & navigasi |
|| Muthawif-Mandiri | End User (Self-Signup) | Mobile App | Pembimbing kelompok mandiri (keluarga/teman) |
|| Admin Sistem | Internal | Dasbor Web (/admin) | Operator platform & compliance |
|| SDAIA/Regulator | Eksternal Pasif | Audit only | Memastikan kepatuhan PDPL Saudi |

## 2.2 Hierarki Role

```
Travel Umrah (PPIU)
├── Travel Admin (1 per travel)
│   ├── Team-Support (N per travel)
│   └── Muthawif (N per travel)
│       └── Jamaah (N per travel)
│
Umrah Mandiri (Self-Signup)
└── Muthawif-Mandiri (self-activated)
    └── Jamaah (di-invite ke grup Muthawif-Mandiri)
```

## 2.3 Role Definitions

### 2.3.1 Travel Admin
- **Access:** Dasbor Web penuh untuk travel-nya
- ** Responsibilities:** Kelola akun Team-Support & Muthawif · Beli lisensi seat · Kelola paket Umrah · Monitoring grup · Broadcast ke alumni
- **Invite:** Kirim kode aktivasi ke Team-Support & Muthawif (gratis, berlaku selamanya sampai di-revoke)

### 2.3.2 Team-Support
- **Access:** Mobile App dengan fitur terbatas (bukan Panic Button)
- ** Responsibilities:** Pendamping Jamaah, bantu Muthawif selama perjalanan
- **Constraints:** Tidak punya Panic Button · Tidak bisa terima broadcast · Tidak punya fitur doa berbasis lokasi

### 2.3.3 Muthawif
- **Access:** Mobile App dengan Panic Button aktif
- ** Responsibilities:** Coordinator upacara · Fotografer · Broadcast jadwal ke Jamaah
- **Constraints:** Tidak punya Panic Button (karena Muthawif bukan yang dalam bahaya) · Dapat invite dari Travel Admin

### 2.3.4 Jamaah
- **Access:** Mobile App — semua fitur keselamatan
- **Join:** Via PIN grup dari Muthawif (bypass paywall) atau sign-up mandiri (Rp 120.000/tahun)
- **Features:** Panic Button · Peta offline · Doa kontekstual · Album foto

### 2.3.5 Muthawif-Mandiri
- **Access:** Mobile App — semua fitur (level Jamaah + jadi Muthawif)
- **Sign-up:** Mandiri, Rp 120.000/tahun
- **Self-Activation:** Set status jadi "Muthawif-Mandiri" untuk membuat grup sendiri
- **Constraints:** Grup terbatas untuk keluarga/teman (max 15 orang) · Tidak ada integrasi travel

### 2.3.6 Sales Agen
- **Access:** Mobile App — Sales Agen dashboard & marketing tools
- **Role:** Independent agent yang merekomendasikan Travel Umrah ke prospek
- **Responsibilities:**
  - Acquiring prospects: ajak prospek install app / white-label app
  - Demo fitur Panic Button via test-code
  - Share Bank Content (poster) ke media sosial / WhatsApp
  - Track status prospek: baru install → sudah dapat respons → sudah minat → belum minat
  - Jual paket umrah (via katalog) — tidak handle payment, hanya orientasi
- **Invite:** Diberikan `sales_agent_code` unik oleh Travel Admin
- **Constraints:**
  - Tidak punya Panic Button untuk diri sendiri (bukan Jamaah)
  - Tidak bisa lihat data Jamaah individu — hanya aggregate prospect
  - Tidak bisa akses keuangan Travel — hanya earnings sendiri
  - Revoked saat tidak aktif (Travel Admin bisa revoke kapan saja)

## 2.4 Role Privilege Matrix

### 2.4.1 Fitur per Role

||| Fitur | Jamaah | Muthawif | Team-Support | Travel Admin | Muthawif-Mandiri | Sales Agen |
|-------|--------|---------|-----------|--------------|--------------|-----------------|------------|
||| Panic Button (send) | ✅ | ❌ | ❌ | N/A | ✅ | ❌ |
| Panic Alert Response (receive + respond) | ❌ | ✅ | ✅ | N/A | ❌ | ❌ |
||| Peta Offline | ✅ | ✅ | ✅ | N/A | ✅ | ❌ |
||| Doa Kontekstual (lokasi) | ✅ | ✅ | ❌ | N/A | ✅ | ❌ |
||| Broadcast Jadwal | ❌ | ✅ | ❌ | ✅ | ✅ | ❌ |
||| Terima Broadcast | ✅ | ✅ | ❌ | ✅ | ✅ | ❌ |
||| Kamera (foto watermark) | ❌ | ✅ | ✅ | N/A | ❌ | ❌ |
||| Album Foto (view) | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
||| Grup Rombongan (buat) | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ |
||| Grup Rombongan (join) | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
||| Invite Jamaah ke grup | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ |
||| Kelola Team-Support | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ |
||| Beli Lisensi Seat | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ |
||| Dasbor Web Analytics | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ |
||| Paywall (Rp 120.000) | Via travel | Gratis (diundang) | Gratis (diundang) | N/A | Bayar sendiri | N/A |
||| Prospect Dashboard | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ |
||| Bank Content (poster) | ❌ | ❌ | ❌ | ✅ (manage) | ❌ | ✅ |
||| Test-Code Panic Button | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ (Use Case 1) |
| Test-Code (Travel Prospect Free Trial) | ✅ (SuperAdmin generates) | ❌ | ❌ | ❌ | ❌ | ❌ |
||| Katalog Paket | ❌ | ❌ | ❌ | ✅ (manage) | ❌ | ✅ (view) |
||| Sales Earnings | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
||| QR Business Card | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Informasi Umrah | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

### 2.4.2 Join Multi-Grup Alumni

- **Semua role** (kecuali Travel Admin) bisa join **multi-grup Alumni** dari travel berbeda
- Trigger: dapat invitasi dari Muthawif atau Muthawif-Mandiri
- Impact: Jamaah yang travel ke Maktour lalu ke Patuna bisa dapat broadcast dari keduanya

### 2.4.3 Revocation Flow (Travel Admin revoke Team-Support/Muthawif)

```
Travel Admin klik "Revoke Access" untuk user X
    → invitation_revoked_at = NOW()
    → User X buka app → System cek invitation_revoked_at
    → Jika revoked:
        → Show screen: "Akses dari [Travel Name] telah dicabut"
        → Show CTA: "Aktivasi sendiri Rp 120.000/tahun" atau "Hubungi travel"
    → User X tidak otomatis logout (session tetap aktif)
    → Fitur tetap jalan tapi: Panic Button hilang, broadcast berhenti
```

## 2.5 Persona Detail

### Persona 1: Pak Hendra — Muthawif Lapangan
- **Usia:** 48 tahun, guru/ustadz, literasi teknologi menengah
- **Device:** Android mid-range, koneksi tidak stabil
- **Role:** Muthawif (diundang Travel Admin, gratis)
- **Pain Points:** Koordinasi via WhatsApp kacau · Peserta tersasar di Masjidil Haram
- **Goals:** Broadcast jadwal 1 klik · Panic alert senyap · Peta offline · Foto watermark otomatis
- **Anti-Goals (constraints):** Tidak bisa gunakan Panic Button untuk diri sendiri

### Persona 2: Bu Siti — Jamaah Peserta (Rentan)
- **Usia:** 55 tahun, pemula Umrah, literasi teknologi rendah
- **Device:** iPhone SE atau Android entry-level
- **Role:** Jamaah (join via PIN dari Muthawif)
- **Pain Points:** HP di mode senyap · Masjid sangat luas · Tidak hafal rute
- **Goals:** Panic Button 1 ketuk · Peta 'Find My Way Home' · Haptic notification
- **Willingness to Pay:** Gratis (seat license dibayar Travel)

### Persona 3: Pak Budi — Travel Admin (PPIU)
- **Usia:** 42 tahun, pemilik travel Umrah
- **Role:** Travel Admin
- **Pain Points:** Tidak ada data alumni · Foto tanpa branding · Kehilangan kontak pasca-perjalanan
- **Goals:** Beli lisensi bulk · Dasbor CRM foto · Broadcast ke alumni · Kelola Team-Support & Muthawif
- **Willingness to Pay:** Rp 50–60rb per Jamaah (seat license)

### Persona 4: Kak Rina — Team-Support
- **Usia:** 30 tahun, karyawan travel, literasi teknologi menengah
- **Role:** Team-Support (diundang Travel Admin, gratis)
- **Device:** Android mid-range
- **Pain Points:** Harus следить Jamaah yang tersesat · Tidak punya alat Panic
- **Goals:** Koordinasi real-time · Lihat status Jamaah
- **Anti-Goals (constraints):** Tidak ada Panic Button · Tidak terima broadcast dari agen lain

### Persona 5: Pak Ahmad — Muthawif-Mandiri
- **Usia:** 38 tahun, pemimpin keluarga besar, berangkat Umrah secara mandiri
- **Role:** Muthawif-Mandiri (self-activated)
- **Device:** iPhone 14
- **Context:** Umrah dengan 8 orang keluarga + 2 teman dekat
- **Pain Points:** Tidak pakai travel · Bingung koordinasi · Takut ada keluarga tersesat
- **Goals:** Buat grup sendiri · Bagikan PIN ke keluarga · Koordinasi itinerary
- **Willingness to Pay:** Rp 120.000/tahun (bayar sekali, охватывает grup)

### Persona 6: Bu Siti — Jamaah dari Grup Mandiri
- **Usia:** 60 tahun, anggota keluarga Pak Ahmad
- **Role:** Jamaah (di-invite ke grup Muthawif-Mandiri)
- **Device:** Android entry-level
- **Pain Points:** Literasi HP rendah · Takut sendirian di Masjid
- **Goals:** Panic Button · Peta offline · Doa kontekstual
- **Willingness to Pay:** Gratis (ditanggung Pak Ahmad)

---

# SECTION 3: Kebutuhan Fungsional

## 3.1 Modul Keselamatan & Navigasi (B2C)

### 3.1.1 Peta Luring (Offline Map)

**Deskripsi:** Peta offline berbasis OpenStreetMap (OSM) covering Makkah & Madinah — self-hosted tiles, no licensing cost.

**Spesifikasi:**
| Parameter | Value |
|-----------|-------|
| Coverage Area | Makkah + Madinah city boundaries + indoor Masjidil Haram + Masjid Nabawi |
| Max Size | 300MB (untuk kompatibilitas entry-level devices) |
| Indoor Detail | Floor-level layout Masjidil Haram & Masjid Nabawi |
| Search | Input Bahasa Indonesia → koordinat tujuan |
| Offline Capability | 100% offline setelah download |

**Technical Implementation:**
- OSM SDK dengan custom offline tiles
- Pre-download sebelum departure via WiFi
- Tile storage: SQLite database on device

**⚠️ Open Question RESOLVED (OQ-02):**
- **Decision:** OpenStreetMap (OSM) + self-hosted tiles
- **Vendor:** OSM tiles + Qwant maps (open source, no licensing fee)
- **Indoor Positioning:** Dead-reckoning via gyroscope (skip BLE/WiFi calibration di awal)
- **Coverage:** Makkah + Madinah OSM coverage sudah decent untuk area utama
- **Rationale:** OSM opensource, no licensing cost, self-hosted tile server ± Rp 500rb-1jt/bulan
- **Timeline:** Verify OSM coverage Makkah/Madinah sebelum dev start — jika ada gap area kritis, baru pertimbangkan indoor positioning solution lain

---

### 3.1.2 Panic Button

**Deskripsi:** Fitur keselamatan inti — satu ketuk untuk kirim alert ke Muthawif，不管 mode senyap.

**User Flow:**
```
Jamaah ketuk Panic Button (layar utama)
    → App ambil koordinat GPS terakhir (cached, bisa offline)
    → Payload: { jamaah_id, grup_id, coordinates, timestamp }
    → Kirim via FCM Critical Alert (priority high)
    → Muthawif DAN Team-Support terima: audio beep + haptic + visual alert
    → Koordinat tampil di peta offline Muthawif & Team-Support
    → Muthawif / Team-Support dapat pilih respons:

        a. "Stay, saya jemput" — Jamaah tetap di tempat, tim menuju
        b. "Saya di sini" — Tim kirim lokasi mereka, Jamaah datang sendiri
           (Berguna ketika Muthawif sedang bawa rombongan, tidak bisa tinggalkan grup)

    → Alert status berubah: active → acknowledged
    → Jamaah lihat respons di layar: nama + lokasi di peta
```

**Spesifikasi Teknis:**

| Parameter | Value |
|-----------|-------|
| Panic Payload Size | < 1KB (GPS coords + timestamp + IDs) |
| End-to-End Latency | < 5 detik (target P95) |
| GPS Accuracy | < 10 meter (jika outdoors) |
| Silent Mode Bypass | Critical Alert FCM — iOS & Android |
| Retry Policy | 3 retries dengan exponential backoff (1s, 2s, 4s) |
| Fallback if All Fail | Local storage queue + visual "Alert Pending" indicator |

**⚠️ CRITICAL Alert Entitlement (iOS) — RESOLVED (OQ-01):**
- Apple memerlukan entitle khusus untuk Critical Alert yang bypass DND
- Request harus diajukan ke Apple via Developer Portal
- Approval timeline: 2–6 minggu
- **Action: Ajukan SEKARANG (Bulan 1 development)**

**⚠️ CRITICAL Alert Fallback Plan:**
- Jika Apple **menolak** Critical Alert entitlement:
  1. **Silent push + SMS fallback:** Panic kirim via silent push notification (priority high, no sound) + SMS gateway (Twilio/Nexmo) sebagai backup
  2. **Biaya SMS:** ± Rp 200-500 per Panic alert (acceptable cost untuk emergency)
  3. **Local alarm:** Jika no network sama sekali — local alarm sound + stored emergency contact di local storage
- **Tidak ada feature block** jika Critical Alert ditolak — hanya degraded reliability
- Fallback SMS infrastructure: deploy bersamaan dengan Critical Alert submission

**Error States & Edge Cases:**

| Scenario | Behavior |
|----------|----------|
| FCM server down | Local queue + "Pending" indicator + auto-retry when online |
| GPS unavailable | Kirim last-known coordinates + flag "GPS unavailable" |
| No network for 7+ days | Queue persists locally, sync when network available |
| Muthawif / Team-Support offline | FCM handles delivery when they come online |
| Duplicate panic presses | Debounce 30 detik — ignore subsequent presses |
| Panic pressed accidentally | Muthawif can dismiss with "False Alarm" reason |

---

### 3.1.3 Muthawif Virtual — Panduan Doa Kontekstual

**Deskripsi:** Teks/audio doa otomatis berbasis GPS geofence saat Jamaah mendekati lokasi suci.

**Geofence Locations (v1):**
- Ka'bah (Masjidil Haram)
- Area Sa'i (Safa-Marwa)
- Raudhah (Masjid Nabawi)
- Jabal Rahmah
- Muzdalifah
- Arafah

**Spesifikasi:**
| Parameter | Value |
|-----------|-------|
| Geofence Trigger Radius | 50 meter (configurable per location) |
| Detection Latency | < 30 detik setelah masuk area |
| Content Format | 3-layer: Arab + Latin + Terjemahan Indonesia |
| Audio Mode | Earphone-only (kepatuhan regulasi Saudi) |
| Content Update | OTA — tanpa update aplikasi |
| Offline | Library doa tersimpan lokal setelah onboarding |

**⚠️ Regulatory Note RESOLVED (OQ-06):**
- Audio doa via earphone **diperbolehkan** di dalam masjid (otoritas Saudi mengizinkan)
- Doa berbasis geo-location masuk **Premium** tier (bukan free)
- Doa-doa text list (non-geo) tetap **Free** tier

---

## 3.2 Manajemen Rombongan

### 3.2.1 Grup Rombongan (Muthawif)

**User Flow:**
```
Muthawif buat grup
    → Sistem generate: QR code + PIN 6 digit (alfanumerik)
    → Muthawif share ke Jamaah (via WhatsApp / kertas / verbal)
    → Jamaah masuk PIN → auto-join grup (bypass paywall B2C)
    → Muthawif lihat daftar anggota + status real-time
```

**Spesifikasi:**

| Parameter | Value |
|-----------|-------|
| PIN Format | 6 digit alfanumerik (e.g., "HM7X2K") |
| PIN Validity | 30 hari atau sampai grup diubah status ke "Alumni" |
| Max Anggota per Grup | 100 |
| Broadcast Payload | Text + optional image + link |
| Broadcast Latency | < 3 detik end-to-end via FCM |

**Fitur Status Kegiatan:**
- Jamaah bisa set status: "Istirahat di Hotel" / "Belanja" / "Lainnya" + estimasi durasi
- Muthawif lihat semua status di dasbor

**Grup Alumni Flow:**
```
Ibadah selesai (Muthawif mark: "Kembali ke Indonesia")
    → Grup ubah status → "Alumni"
    → Jamaah tetap akses album foto
    → Agen bisa broadcast promosi ke Alumni
```

---

## 3.3 Fitur Ibadah Mode

**Deskripsi:** Mode khusus saat di area masjid — bisukan semua notifikasi kecuali Panic.

**Behavior:**
| Condition | Action |
|-----------|--------|
| Masuk geofence masjid | Rekomendasi "Aktifkan Ibadah Mode?" (toast) |
| Ibadah Mode ON | Semua notifikasi umum silent, Panic Alert tetap ON |
| Ibadah Mode ON | Haptic reminder untuk jadwal salat berikutnya |
| Ibadah Mode ON | Tampilkan countdown下一个 salat |
| Keluar geofence | Auto-deactivate atau manual toggle |

---

## 3.4 Jejak Ibadah (Album Digital)

### Overview

**Jejak Ibadah** adalah album digital yang menyimpan momen spiritual perjalanan Umrah/Haji Jamaah. Terintegrasi dalam **grup Alumni Travel Umrah** — hanya member grup yang bisa mengakses album travel-nya masing-masing.

**Access Control:**
- Album hanya bisa diakses oleh user yang merupakan **member grup Alumni** dari travel tersebut
- Upload foto: hanya **Muthawif, Team-Support, atau Travel Admin**
- View/Download: semua **member grup Alumni** (termasuk Jamaah)

---

### 3.4.1 Kamera Jejak Ibadah

**Deskripsi:** Kamera dalam app untuk foto dengan watermark otomatis.

**Spesifikasi:**

|| Parameter | Value |
|-----------|-------|
| Capture | Via in-app camera (bukan system camera) |
| Offline | Foto di-queue lokal, sync saat online |
| Max Queue Size | 500 foto atau 2GB (tergantung device) |
| Sync Trigger | Auto-sync setiap 5 menit jika online, atau manual |
| Compression | Server-side, target 1MB per foto |
| Watermark | Logo travel pojok kanan bawah, 15% opacity |
| Video Clips | DIHAPUS — video storage会造成 biaya besar |

**Video Clips:** DIHAPUS (OQ-JI-02 resolved)
- Video clip storage会造成 storage cost yang sangat besar (ratusan ribu jamaah × clip video)
-替代方案: Muthawif/Team-Support bisa share video via WhatsApp/alat lain
- Tidak ada video upload pipeline di v1

**Photo Compression:**
- Semua foto di-compress on-device sebelum upload
- Target: 1MB per foto (quality 75% JPEG)
- Algoritma: Flutter image package (built-in resize + compress)
- Benefit: Mengurangi storage cost + bandwidth usage

**Voice Caption:**
- Setelah capture foto, Muthawif bisa **record voice note** (max 30 detik)
- Voice di-attach ke foto sebagai metadata
- Jamaah bisa play voice saat view foto
- Format: AAC, tersimpan terpisah dari foto

---

### 3.4.2 Custom Watermark per Paket

**Deskripsi:** Setiap paket Umrah bisa punya watermark unik.

|| Parameter | Value |
|-----------|-------|
| Watermark per Paket | Logo travel + nama paket |
| Position | Bottom-right corner |
| Opacity | 15% (configurable 10-25%) |
| Multiple Watermarks | Support hingga 2 watermark (travel logo + paket badge) |

**Paket Badge Examples:**
- "Paket Premium" → gold badge watermark
- "Paket Hemat" → silver badge watermark
- "Special Ramadan" → themed border overlay

---

### 3.4.3 PDF Album Book (Auto-Generated)

**Deskripsi:** System generate PDF album style coffee-table book yang bisa didownload Jamaah.

**Output Format:**
```
Cover Page:
  - Judul: "Jejak Ibadah Kami di Tanah Suci"
  - Nama Travel (jika via travel)
  - Tanggal perjalanan
  - Foto cover: auto选出 1 foto terbaik

Pages:
  - Setiap halaman: 1-2 foto besar + caption (tanggal, lokasi)
  - Layout: full-bleed photo dengan thin border
  - Momen section: "Kepulangan", "Wukuf", "Aqiqah", dll

End Pages:
  - Statistik: total foto, total Jamaah, durasi perjalanan
  - QR Code ke album digital online
  - Watermark travel di setiap halaman
```

**Spesifikasi:**

|| Parameter | Value |
|-----------|-------|
| Page Count | 20-40 pages (dynamic) |
| Photo per Page | 1-4 foto (layout varies) |
| Resolution | 300 DPI, print-ready |
| File Size | ~15-30MB per PDF |
| Generation Trigger | Manual (Travel Admin klik "Generate PDF") |
| Download Access | Jamaah dalam grup Alumni |
| Generation Time | < 60 detik (async, notification when ready) |

**Template Design:** Arabian aesthetic — dark navy/gold accents, geometric borders, sunrise/sunset imagery for dividers.

---

### 3.4.4 Location Timeline

**Deskripsi:** Foto di-plot di peta perjalanan sebagai visual storytelling.

**User Experience:**
```
Album View → Tab "Timeline"
    → Map view: pin dropped di setiap lokasi foto
    → Pin clusters: zoom in untuk lihat individual photos
    → Tap pin → popup: thumbnail + caption + timestamp
    → Route line: garis penghubung antar lokasi (urutan waktu)
```

**Spesifikasi:**

|| Parameter | Value |
|-----------|-------|
| Map Provider | OpenStreetMap (self-hosted offline tiles) |
| Clustering | Photos dalam radius 50m di-cluster |
| Route | Polyline connecting photos by timestamp |
| Markers | Custom icon per location type (Masjid, Museum, Mercado) |
| Timeline Scrubber | Slider untuk filter foto by date range |

**Lokasi Categories:**
- Masjidil Haram
- Masjid Nabawi
- Areas ziarah (Jabal Rahmah, Arafah, dll)
- Mercado (belanja)
- Hotel
- Restaurant
- Lainnya

---

### 3.4.5 Download All + ZIP

**Deskripsi:** Jamaah bisa download semua foto dalam 1 klik sebagai ZIP file.

**Spesifikasi:**

|| Parameter | Value |
|-----------|-------|
| Format | ZIP file (photos + optional video clips) |
| Naming | `{travel_name}_{paket}_{tanggal}.zip` |
| Max Size | 500MB per download (Jika lebih, pecah per date range) |
| Resolution | Original (bukan compressed) |
| Watermark | Watermark tetap ada di downloaded photos |
| Expiry Link | Download link expires 7 hari |
| Download Speed | Streaming (not blocking) |

**User Flow:**
```
Jamaah → Album → "Download Semua Foto"
    → Show size estimate + waktu download
    → Confirm
    → System generate ZIP (background)
    → Notification: "Album siap didownload"
    → Open link → browser download / native share sheet
```

---

### 3.4.6 Share to WhatsApp / Instagram / TikTok

**Deskripsi:** Deep link untuk share foto/video langsung ke social media.

**Spesifikasi:**

| Platform | Format | Behavior |
|----------|--------|----------|
| WhatsApp | Single photo + caption | Share sheet → WhatsApp |
| Instagram Stories | Single photo/video (max 15s) | Share sheet → Instagram |
| TikTok | Video clip 15s | Share sheet → TikTok |
| Link | Shared album link | Short URL (bit.ly style) |

**Photo Selection:**
- Muthawif bisa select foto → "Share ke Media Sosial"
- Caption auto-generate: "Momen tak terlupakan dari perjalanan umrah kami ✨ [travel_name] [date]"
- Logo travel watermark tetap ada di shared content

**Link Sharing (for non-social):**
- Generate shareable link ke album/page tertentu
- Link bisa di-share via WhatsApp DM, SMS, email
- Halaman yang di-link: bisa public preview (tanpa full album access)

---

### 3.4.7 Comment & React

**Deskripsi:** Jamaah bisa comment dan react di foto dalam album grup Alumni.

**Spesifikasi:**

|| Parameter | Value |
|-----------|-------|
| Reactions | ❤️ 😍 😄 🙏 👍 (5 emoji reactions) |
| Comments | Text, max 500 karakter |
| Comment Thread | Flat (no nested replies) |
| Edit/Delete | Owner bisa edit/delete comment sendiri |
| Moderation | Travel Admin bisa delete any comment |
| Notification | Notif ke foto owner + commenter when new comment |

**Access:**
- Semua member grup Alumni bisa comment/react
- Comment tidak bisa di-comment ulang (flat thread)
- Report button: "Laporkan konten tidak pantas"

---

### 3.4.8 Best Moment Voting

**Deskripsi:** Jamaah vote foto favorit, foto dengan vote tertinggi jadi "Featured".

**Spesifikasi:**

|| Parameter | Value |
|-----------|-------|
| Vote Options | 1 vote per Jamaah per voting period |
| Voting Period | 7 hari setelah travel selesai |
| Winner Count | Top 3 foto |
| Winner Badge | "⭐ Momen Pilihan Jamaah" overlay |
| Display | Winner foto di highlight posisi album |

**User Flow:**
```
Travel Admin → Album → "Mulai Voting"
    → Show all photos from trip
    → Jamaah vote (1 per orang)
    → 7 hari: voting closed
    → Winner announced + notification
    → Winner badge auto-applied
```

**Analytics Available for Travel Admin:**
- Total votes per foto
- Voter demographics
- Most voted moment (by location category)

---

### 3.4.9 Album Analytics (Heatmap)

**Deskripsi:** Travel Admin bisa lihat analytics foto — mana yang paling banyak didownload, di-share, dll.

**Metrics Available:**

|| Metric | Description |
|--------|-------------|
| View Count | Berapa kali foto di-view |
| Download Count | Berapa kali foto didownload |
| Share Count | Berapa kali foto di-share |
| Reaction Count | Total reactions |
| Engagement Rate | (View + Download + Share) / Total Jamaah |
| Location Popularity | Lokasi mana yang paling banyak difoto |

**Heatmap View:**
- Map overlay: warna indicate photo density
- Filter by date range, by Jamaah segment
- Export: CSV download for Travel Admin

---

### 3.4.10 Alumni Challenge / Contest

**Deskripsi:** Periodic challenges untuk engage alumni, dengan physical prize.

**Example Challenges:**

| Challenge | Rules | Prize |
|-----------|-------|-------|
| "Foto Paling Berkesan" | Submit foto lama dari perjalanan lalu | Gift box Saudi dates + zam-zam water |
| "Jejak Perjalanan" | Upload foto paling epic dari travel terdahulu | Free upgrade paket next travel |
| "Ziarah Throwback" | Best throwback foto dari Masjidil Haram | Free seat license untuk next umrah |
| "Ramadan Memory" | Foto dari Ramadan Umrah | Gift hamper |

**Spesifikasi:**

|| Parameter | Value |
|-----------|-------|
| Submission Period | 14 hari |
| Voting Period | 7 hari |
| Winner Announcement | Live / announcement page |
| Entry Eligibility | Hanya alumni dari travel yang sudah pernah bekerja sama |
| Physical Prize Delivery | Via travel agent atau kirim langsung |

---

### 3.4.11 "One Year Ago" Memory Notification

**Deskripsi:** Notifikasi pengingat annual — "1 tahun lalu Anda beribadah di Tanah Suci."

**Spesifikasi:**

|| Parameter | Value |
|-----------|-------|
| Trigger | Tepat 1 tahun setelah travel_end_date |
| Timing | 09:00 AM user local time |
| Content | "一年前今天 — Satu tahun lalu, Anda merasakan kedamaian di Masjidil Haram. 🌅 Buka Jejak Ibadah untuk mengenang momen tersebut." |
| CTA Button | "Lihat Album" → deep link ke album |
| Opt-out | User bisa disable di Settings |

**Content Variations (randomized per user):**
- Caption with trip details (location names, number of photos)
- Include 1 featured photo from the trip
- Mood: nostalgic, warm, gratitude-focused

---

### 3.4.12 Album Bundle Cross-Sell

**Deskripsi:** Travel Admin bisa upsell add-on packages.

**Bundle Options:**

|| Bundle | Price | Includes |
|--------|-------|---------| 
| Basic Album | Included | Foto + basic album view |
| Album + PDF Book | +Rp 25.000 | Basic + PDF coffee-table book |
| Album + Video Clip Package | +Rp 50.000 | Basic + video clips compilation |
| Premium Package | +Rp 100.000 | Foto + PDF book + video clips + drone footage |

**Purchase Flow:**
```
Jamaah → Album → "Upgrade ke Premium Package"
    → Show comparison table
    → Bayar via Midtrans
    → Payment confirmed → unlock additional content
```

**Note:** Muthawif/Team-Support upload video clips yang sama (15 detik) — tidak perlu profesional videographer.

---

### 3.4.13 Storage Cost Model (Updated)

|| Variable | Assumption | Calculation |
|----------|-----------|-------------|
| Total Jamaah Tahun 1 | 100,000 | Target |
| Foto per Jamaah (avg) | 50 foto | Rata-rata |
| Total Foto Tahun 1 | 5,000,000 foto | |
| Video Clips per Jamaah | 5 clips | Avg 5 x 10MB |
| Total Video Storage | 5 TB | 5,000,000 × 10MB |
| Avg Photo Size (compressed) | 1 MB | |
| Total Photo Storage | 5 TB | 5,000,000 × 1MB |
| Voice Captions | 0.5 MB | 5,000,000 × 0.5MB |
| **Total Storage** | **~10.5 TB** | Photos + Videos + Voice |
| Monthly Storage Cost | ~$241/mo | 10.5 TB × $0.023 |
| Year 1 Cost | **~$2,900** | $241 × 12 |

**⚠️ Note:** Include buffer 3x untuk safety: **~$4,140/tahun**. Video clips sudah dihapus dari scope — ini significantly mengurangi storage cost dari estimasi sebelumnya.


**Cost Optimization Strategies:**
- Photo dedup: SHA-256 hash per photo, skip duplicate uploads
- CDN caching for popular photos (reduce origin storage reads)
- Auto-purge: hapus foto after 24 months (no video to purge)

---

### 3.4.14 Album Access Control Summary

|| Role | Upload | View | Download | Comment/React | Analytics | Moderation |
|-------|-------|-------|--------|-------------|--------------|-----------|------------|
| Jamaah | ❌ | ✅ (group only) | ✅ | ✅ | ✅ | ❌ | ❌ |
| Muthawif | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| Team-Support | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| Travel Admin | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Muthawif-Mandiri | ⚠️ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| Admin Sistem | ❌ | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ |

---

### 3.4.15 Open Questions — Jejak Ibadah

|| ID | Question | Owner | Deadline | Status | Resolution |
|----|----------|-------|----------|--------|-----------|-------------|
| OQ-JI-01 | PDF generation: server-side atau third-party service (e.g., Docuseal)? | Engineering | Month 3 | ✅ Resolved | **Server-side** (Node.js/Python) — lebih control + no Docuseal subscription |
| OQ-JI-02 | Video clip storage: separate bucket dari photos? | Engineering | Month 3 | ✅ Resolved | **HAPUS video clip** — storage cost terlalu besar |
| OQ-JI-03 | Physical prize untuk challenge:谁来承担 cost? Travel atau platform? | Business | Month 1 | ✅ Resolved | **HAPUS physical prize** —纯 digital challenge only |
| OQ-JI-04 | Should video clips be compressed locally on device before upload? | Engineering | Month 3 | ✅ Resolved | **Ya, untuk foto** — compress on-device 75% JPEG, target 1MB/foto |
| OQ-JI-05 | Album bundle pricing: fixed atau percentage? | Business | Month 1 | ✅ Resolved | **Fix price per user type** — Umrah Mandiri Rp 120.000, Jamaah Travel included |

---

## 3.5 Dasbor Web Agen Travel (B2B)

**Modules:**

| Module | Features |
|--------|----------|
| Onboarding | Daftar dengan nomor PPIU + upload logo |
| Seat License | Beli grosir via Midtrans, diskon volume auto |
| Paket Management | Buat paket Umrah, assign Muthawif |
| Grup Monitoring | Real-time grup status + anggota |
| Galeri CRM | Semua foto ber-watermark agensi |
| Broadcast | Push notif ke alumni (filterable) |
| Analytics | ROI dashboard, lisensi aktif/terpakai |

**Spesifikasi:**

| Parameter | Value |
|-----------|-------|
| Seat License Min Purchase | 1 |
| Discount Tiers | ≤100: Rp 90K/pax, 101-500: Rp 80K/pax, ≥501: Rp 70K/pax |
| Max Simultaneous Broadcast | 10,000 recipients per job |
| Broadcast Rate Limit | 1,000/ detik (FCM throttle) |
| Report Export | CSV download |

---

## 3.6 White Label Platform

### Overview
White Label memungkinkan Travel Umrah (PPIU) memiliki app branded sendiri (nama + logo + warna) di Play Store dan App Store, tapi pengelolaan datanya tetap terpusat di Haramain Pro.

**Contoh:** Maktour, Patuna Travel, Alhijaz Indowisata — masing-masing punya app sendiri tapi satu backend.

### Arsitektur White Label

```
┌─────────────────────────────────────────────────────────┐
│                  HARAMAIN PRO BACKEND                     │
│          (Single Supabase Instance — Terpusat)           │
│                                                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────────┐  │
│  │ Maktour  │  │ Patuna   │  │ Alhijaz Indowisata   │  │
│  │ App      │  │ App      │  │ App                  │  │
│  └────┬─────┘  └────┬─────┘  └──────────┬───────────┘  │
│       │             │                    │               │
│       │    ┌────────┴────────┐          │               │
│       └──► │  Shared DB     │◄──────────┘               │
│            │  (travel_id     │                           │
│            │   isolation)    │                           │
│            └────────────────┘                           │
└─────────────────────────────────────────────────────────┘
```

### Launcher App Architecture

White Label app adalah **launcher** yang memanggil Haramain Pro:

```
User install "Maktour Umrah" dari Play Store
    → App adalah thin wrapper: splash screen + theme apply + deeplink ke Haramain Pro
    → Haramain Pro Core App ter-install di device (hidden/invisible launcher)
    → Semua logic, data, FCM tetap di Haramain Pro
    → White Label app hanya: branding shell + config deeplink
```

**Alternative (No Core App):**
```
Haramain Pro tidak perlu pre-install
    → White Label app fetch config dari: api.haramainpro.com/config/{travel_slug}
    → Config berisi: app name, logo URL, theme colors, subdomain
    → App set theme + navigate ke main flow
    → Semua Native Component (Flutter) langsung jalan
```

### Konsep "App dalam App" (Multi-Tenant)

| Aspek | Implementasi |
|-------|-------------|
| Database | Single DB, `travel_id` column untuk isolation |
| Auth | Shared Supabase Auth, role + travel_id |
| FCM | Single project, payload includes `travel_id` untuk routing |
| Storage | Single bucket, path prefix `/travels/{travel_id}/` |
| Analytics | Single Firebase project, dimension `travel_id` |
| Push Notifications | Includes `travel_id` tag, FCM topic per travel |

### Fitur yang Di-Support untuk White Label

| Fitur | White Label Support |
|-------|-------------------|
| Panic Button | ✅ |
| Peta Offline | ✅ |
| Doa Kontekstual | ✅ |
| Grup Rombongan | ✅ (hanya melihat anggota travel-nya) |
| Kamera + Watermark | ✅ (logo travel) |
| Broadcast | ✅ (hanya ke Jamaah travel-nya) |
| Album Foto | ✅ |
| Dasbor Web | ✅ (versi Travel Admin, bisa kustom branding white label) |

### Fitur yang Tidak Di-Support

- View Jamaah dari travel lain
- Cross-travel broadcast
- Analytics agregat lintas travel
- User tanpa `travel_id` tidak bisa login via White Label app

### White Label Configuration per Travel

|| Parameter | Description |
|----------|-------------|
| `app_name` | e.g., "Maktour Umrah" |
| `app_store_id` | ID di App Store / Play Store |
| `logo_url` | App icon + splash logo |
| `theme_primary_color` | Hex color |
| `theme_accent_color` | Hex color |
| `contact_email` | Support email |
| `privacy_policy_url` | URL ke privacy policy travel |

### Technical Requirements

| Requirement | Value |
|------------|-------|
| Max White Label Apps | Unlimited (per whitelist di backend) |
| App Size Overhead | < 5MB per White Label app |
| Build Time per App | < 10 menit (CI/CD pipeline) |
| App Store Submission | **Haramain Pro team submits** (pusat) — travel owns developer accounts |
| Backend Config Update | Real-time (no app update needed) |

### User Experience Flow

```
User download "Maktour Umrah" dari Play Store
    → Splash: logo Maktour (3 detik)
    → Check: Apakah user sudah punya account?
        → Jika ya: Langsung ke Home (dengan tema Maktour)
        → Jika tidak: Tampilkan Sign Up / Sign In
    → Semua screen: header berwarna tema Maktour
    → Panic Button: tetap hijau, logo Maktour di pojok
    → Album: watermark "Maktour Umrah"
    → Broadcast: dari Maktour Admin
```

### Open Questions

|| ID | Question | Owner | Deadline | Status | Resolution |
|----|----------|-------|----------|--------|-----------|-------------|
| OQ-WL-01 | Flutter app bundling: 1 codebase → multiple app entries, atau separate builds? | Engineering | Month 2 | ✅ Resolved | **1 codebase multi-entry** — simpler maintenance, single codebase dengan flavor per travel |
| OQ-WL-02 | Submit ke App Store oleh masing-masing travel, atau pusat? | Legal | Month 1 | ✅ Resolved | **Haramain Pro submits** — tim pusat yang submit ke App Store; travel owns accounts (developer account travel) |
| OQ-WL-03 | Revenue sharing model untuk White Label? | Business | Month 1 | ✅ Resolved | **Fixed pricing:** Rp 30.000.000 lisensi lifetime + Rp 12.000.000 maintenance/tahun (mulai tahun ke-2) + Rp 50.000 per Jamaah |

---

## 3.7 Umrah Mandiri

### Overview
Umrah Mandiri adalah jalur self-service untuk user yang berangkat Umrah tanpa travel — kelompok keluarga, komunitas, atau individu yang ingin koordinasi sendiri.

**Revenue:** Rp 120.000 per user per tahun (Safety Pass).

### User Journey: Sign-Up to Active

```
User download Haramain Pro dari App Store / Play Store
    → Sign Up (email + phone verification)
    → Pilih: "Umrah Mandiri"
    → Bayar Rp 120.000 via Midtrans (QRIS / VA / e-Wallet)
    → Payment confirmed → Account activated
    → Home screen: "Aktifkan sebagai Muthawif?"
        → Jika "Ya": Self-activation (skip payment lagi)
        → Jika "Tidak": Tetap Jamaah, bisa join grup orang lain
```

### Self-Activation: Muthawif-Mandiri

**Trigger:** User yang sudah bayar Rp 120.000 bisa set diri sebagai "Muthawif-Mandiri"

**Flow:**
```
User → Settings → "Jadi Muthawif Mandiri"
    → Show explanation: "Anda akan bisa buat grup untuk keluarga/teman Anda"
    → Confirm
    → Role upgrade: Jamaah → Muthawif-Mandiri
    → Ability: Buat 1 grup (max 15 anggota)
    → Grup created → Generate PIN 6 digit
    → Share PIN via WhatsApp / SMS / verbal
```

### Grup Muthawif-Mandiri

| Parameter | Value |
|-----------|-------|
| Max Anggota | 15 orang |
| PIN Validity | 12 bulan (seumur hidup subscription) |
| Fitur Grup | Panic Button (anggota), Broadcast, Peta Offline, Doa Kontekstual |
| Fitur Tidak Ada | Kamera watermark, Dasbor Web, Jejak Ibadah (Album Foto) | Muthawif-Mandiri bukan fotografer; Jamaah Mandiri cenderung simpan foto sendiri via WhatsApp |
| Grup Alumni | Auto-convert ke Alumni setelah travel selesai |

### Panic Button Lifecycle — Umrah Mandiri

**Input Tanggal Keberangkatan (Mandatory):**
```
User → Settings → "Input Tanggal Keberangkatan"
    → Pilih tanggal keberangkatan (date picker)
    → Pilih durasi trip (dropdown: 7, 9, 12, 14 hari)
    → Sistem compute: travel_end_date = departure_date + durasi
    → Simpan di user profile
```

**Activation Schedule:**
| Trigger | Panic Button State |
|---------|-------------------|
| H-3 sebelum keberangkatan | ACTIVE |
| Selama trip (departure → travel_end_date) | ACTIVE |
| H+1 setelah travel_end_date | **DEACTIVATED** |
| Subscription expired | **DEACTIVATED** |

**Auto-Deactivation:**
```
Sistem auto-detect: travel_end_date + 1 day reached
    → Panic Button: OFF
    → User mendapat notifikasi: "Perjalanan Anda telah selesai. Panic Button non-aktif."
    → Re-activation: lihat bawah
```

**Re-Activation Mechanisms:**

|| Scenario | How to Reactivate |
|----------|-------------------|
| Renew Safety Pass | User renew Rp 120.000 → input new departure date → Panic Button aktif H-3 |
| Join Travel baru | Dapat invitation code dari Travel → Panic Button aktif saat grup aktif |
| Hybrid (occasionally join travel) | Pakai invitation code dari Travel; Panic Button aktif saat di grup travel |

**Anti-Abuse Design:**
- Panic Button hanya aktif saat user DALAM PERJALANAN UMRAH (terverifikasi via tanggal)
- Setelah pulang: auto-off, tidak bisa digunakan untuk kirim sinyal ke grup yang sedang bertugas
- Re-activation memerlukan either: new payment (renew) atau new invitation code (join travel)

### Fitur yang Available untuk Muthawif-Mandiri

| Fitur | Available | Notes |
|-------|-----------|-------|
| Panic Button | ✅ | Untuk Jamaah di grup-nya |
| Peta Offline | ✅ | |
| Doa Kontekstual | ✅ | |
| Broadcast Jadwal | ✅ | |
| Terima Broadcast | ✅ | Dari Haramain Pro official |
| Grup Rombongan | ✅ | Max 15 orang |
| Invite Jamaah | ✅ | Via PIN |
| Album Foto | ❌ | Tidak ada fotografer |

### Jamaah dari Grup Mandiri

- Jamaah yang di-invite ke grup Muthawif-Mandiri dapat **semua fitur Jamaah**
- Mereka **tidak bayar** (ditanggung Muthawif-Mandiri)
- Panic Button tersedia
- **Jejak Ibadah (Album Foto): TIDAK ADA** — sesuai keputusan, masing-masing Jamaah Mandiri cenderung menyimpan foto/video sendiri via WhatsApp atau media sosial. Tidak ada value add dari album in-app.

### Monetisasi Model

| Product | Price | Frequency | Revenue Model |
|---------|-------|-----------|-------------|
| Safety Pass (Jamaah Mandiri) | Rp 120.000 | Per user, lifetime 1 tahun | B2C direct |
| Muthawif-Mandiri | Included | Dalam Safety Pass Rp 120.000 | B2C bundled |
| Grup Jamaah (max 15) | Included | Dalam Safety Pass Muthawif | B2C bundled |

**Revenue Kalkulasi:**
```
Muthawif-Mandiri bayar Rp 120.000
    → охватывает max 15 Jamaah (dirinya + 14 lainnya)
    → Avg revenue per Jamaah: Rp 120.000 / 15 = Rp 8.000/pax
    → Compare: Travel B2B seat license Rp 50-60rb/pax
```

### Perbandingan: B2C Mandiri vs B2B Travel

| Aspek | Jamaah via Travel | Jamaah Mandiri |
|-------|------------------|----------------|
| Harga | Rp 50-60rb (seat license) | Rp 120.000 (Safety Pass) |
| Pembayar | Travel Admin | User sendiri |
| Panic Button | ✅ | ✅ |
| Peta Offline | ✅ | ✅ |
| Doa Kontekstual | ✅ | ✅ |
| Album Foto | ✅ (Muthawif fotografer) | ⚠️ (manual foto) |
| Broadcast | ✅ | ✅ |
| Dasbor Web | ❌ | ❌ |

### Open Questions

|| ID | Question | Owner | Deadline | Status | Resolution |
|----|----------|-------|----------|--------|-----------|-------------|
| OQ-UM-01 | Apakah Muthawif-Mandiri bisa upgrade ke fitur Travel Admin (beli seat license untuk orang lain)? | Business | Month 1 | ✅ Resolved | **Ya** — Muthawif-Mandiri (biasanya Ustadz) bisa upgrade ke Travel Admin, beli seat license dengan harga lebih murah dari harga retail |
| OQ-UM-02 | Apakah grup Muthawif-Mandiri bisa di-convert ke grup Travel? | Product | Month 2 | ✅ Resolved | **Tidak bisa** — user Umrah Mandiri cenderung simpan & share foto via WhatsApp/media sosial, tidak perlu grup Alumni atau Jejak Ibadah |
| OQ-UM-03 | Payment flow: Pay dulu, atau trial dulu lalu paywall? | Business | Month 1 | ✅ Resolved | **Freemium (trial dulu lalu paywall)** — see Freemium Model di bawah |

---

### Freemium Model — Umrah Mandiri

#### Tier Definitions

|| Fitur | Free | Premium |
|-------|------|--------|
| Daily Schedule (in-app) | ✅ | ✅ |
| Doa-doa (text list) | ✅ | ✅ |
| AI Nadhira (10 q&A/day) | ✅ | ✅ |
| Muthawif contact info | ✅ | ✅ |
| Basic profile | ✅ | ✅ |
| **Panic Button** | ❌ | ✅ |
| **Doa by geo-location** | ❌ | ✅ |
| **Jejak Ibadah** (foto album, compressed) | ❌ | ✅ |
| **Download offline schedule** | ❌ | ✅ |
| **AI Nadhira unlimited** | ❌ | ✅ |
| **Export album PDF** | ❌ | ✅ |
| **Emergency SMS fallback** | ❌ | ✅ |

#### Premium Access

|| User Type | How to Get Premium | Price |
|-----------|------------|-----------------|-------|
| Jamaah via Travel | Included dalam seat license | Rp 50.000/pax (dibayar Travel) |
| Umrah Mandiri | Upgrade manual via app | **Rp 120.000/lifetime** |

#### AI Nadhira — Premium Activation Flow

```
User tap "Upgrade Premium Rp 120.000"
    → Modal: "Masukkan tanggal keberangkatan Umrah Anda"
    → User pilih tanggal (date picker)
    → Sistem validasi:
        → Jika tanggal >= today → Premium aktif
        → Jika tanggal < today → error: "Tanggal tidak valid"
    → AI Nadhira unlimited aktif selama 30 hari dari tanggal keberangkatan
    → 3 hari sebelum 30 hari berakhir → notifikasi reminder
    → Setelah 30 hari → revert ke 10 q&A/day (not deleted, just limited)
```

#### AI Nadhira — Knowledge Base Constraint

Nadhira hanya serve pertanyaan berdasarkan Knowledge Base (KB) yang dilatih:

**KB Phase 1 Documents:**
| Document | Source |
|----------|--------|
| Panduan Umrah Resmi Kemenag | kemenkung.go.id |
| Kumpulan Doa Umrah & Haji | Opensource Islamic docs |
| Mapa插 Maps & Routes Makkah-Madinah | OSM-based |
| Saudi Visa & Immigration Guide | Saudi gov portals |
| Emergency Procedures | First-principles |

**Refusal Behavior:**
```
User: "buatkan saya puisi cinta untuk pacar"
Nadhira: "Maaf, saya hanya bisa membantu pertanyaan yang berkaitan dengan Umrah, Haji, dan ibadah lainnya. Apakah ada yang bisa saya bantu tentang ibadah Anda?"
```

---

## 3.8 Travel Umrah Operations

### Overview

Section ini menjelaskan workflow operasional Travel Umrah (PPIU) dalam mengelola Jamaah dan rombongan menggunakan **Dasbor Web Travel Admin**.

**Prinsip:** Data sensitif (pembayaran, data pribadi, dokumen passport) **tidak disimpan** di platform. Platform hanya mengelola: grup, itinerary, broadcast, dan album foto.

---

### 3.8.1 Paket Umrah Management

**Deskripsi:** Travel Admin membuat dan mengelola paket Umrah dengan detail行程.

**Spesifikasi:**

|| Parameter | Value |
|-----------|-------|
| Field | Nama paket, durasi (hari), tanggal berangkat, tanggal pulang |
| Seat per Paket | Max kapasitas per keberangkatan |
| Muthawif Assignment | Assign Muthawif ke paket |
| Status Paket | Draft / Open Booking / Closed / Completed |

**User Flow:**
```
Travel Admin → Dasbor → "Paket Baru"
    → Input: Nama paket, durasi, tanggal berangkat & pulang
    → Input: Jumlah seat (max kapasitas)
    → Assign Muthawif (dropdown dari list Muthawif yang sudah di-invite)
    → Assign Team-Support (max 3)
    → Save as "Draft"

Travel Admin → "Open Booking"
    → Paket muncul di landing page (jika ada public catalog)
    → Jamaah mulai booking (via travel's own sales channel, bukan dari app)
```

---

### 3.8.2 Seat Inventory Tracking

**Deskripsi:** Travel Admin bisa lihat实时available seats per paket.

**Spesifikasi:**

|| Parameter | Value |
|-----------|-------|
| Display | Available / Total seats |
| Update Trigger | Manual adjustment by Admin |
| Alert | "Seat < 10 tersisa" notification to Admin |

**Dashboard View:**
```
Paket: Ramadan Premium 2026
├── Keberangkatan: March 1, 2026
├── Seat: 35 / 45 (10 tersisa)
├── Jamaah Registered: 35 orang
└── Status: Open Booking
```

---

### 3.8.3 Grup Rombongan Creation

**Deskripsi:** Setelah paket dibuat dan Jamaah sudah ter-booking, Travel Admin membuat grup rombongan dalam system.

**Step-by-Step Flow:**

**Step 1: Travel Admin buat grup**
```
Travel Admin → Dasbor → Paket [Nama] → "Buat Grup Rombongan"
    → Input: Nama grup (auto-generate dari nama paket)
    → Sistem generate PIN 6 digit (e.g., "HM7X2K")
    → Grup status: "Active"
```

**Step 2: Instruksi ke Jamaah untuk install app**
```
Travel Admin → Kirim pesan ke Jamaah (via WhatsApp/SMS/manual)
    → Template: "Selamat datang di [Paket Nama]! 
    Unduh app Haramain Pro di: [link]
    Lalu masukkan kode grup: [PIN]"
```

**Step 3: Jamaah join grup via PIN**
```
Jamaah install app Haramain Pro
    → Sign Up / Sign In
    → Input PIN grup: [PIN]
    → Sistem verify: PIN valid + belum expired
    → Jamaah masuk grup (bypass paywall — seat license sudah dibayar via travel)
    → Jamaah bisa akses: Panic Button, Peta Offline, Album, Itinerary
```

**Step 4: Alternative — Travel Admin input no HP Jamaah**

```
Travel Admin → Dasbor → Grup → "Tambah Jamaah"
    → Input: Nama, No HP, Email
    → Sistem kirim push notification: "[Nama Travel] mengundang Anda join grup [Nama Paket]"
    → Jamaah buka app → Show modal:
        → "[Nama Travel] mengundang Anda join grup [Nama Paket]"
        → [Terima] → Premium aktif + join grup + notification ke grup
        → [Tolak] → Tetap free user, tidak masuk grup
    → Invitation expires after 7 days if no response
    → Admin can resend or cancel invitation
```

---

### 3.8.4 Invite Muthawif ke Grup

**Deskripsi:** Travel Admin generate invite untuk Muthawif.

**User Flow:**
```
Travel Admin → Dasbor → Grup → "Invite Muthawif"
    → Pilih dari list Muthawif yang sudah terdaftar di platform
    → Atau input baru: Nama, No HP, Email
    → Sistem kirim: "Anda diundang sebagai Muthawif untuk grup [Nama] di Haramain Pro"
    → Muthawif install app → login → auto-assigned ke grup
    → Role: Muthawif (di-granted akses via travel invitation)
```

**Constraints:**
- Muthawif invitation berlaku selamanya (selama travel tidak revoke)
- Max 1 Muthawif per grup (atau 1 Muthawif utama + 1 deputy)

---

### 3.8.5 Invite Team-Support ke Grup

**Deskripsi:** Travel Admin invite Team-Support untuk membantu Muthawif selama perjalanan.

**User Flow:**
```
Travel Admin → Dasbor → Grup → "Invite Team-Support"
    → Input: Nama, No HP, Email
    → Sistem kirim invite
    → Team-Support install app → login → auto-assigned ke grup
    → Role: Team-Support
```

**Constraints:**
- Max 3 Team-Support per grup (sesuai rules dari监管部门)
- Team-Support tidak punya Panic Button (constraints dalam Role Privilege Matrix)

---

### 3.8.6 Grup Lifecycle: Active → Alumni

**Deskripsi:** Grup berubah status setelah perjalanan selesai.

**Trigger:** H+1 setelah tanggal pulang (travel_end_date + 1 day)

**User Flow — Auto Conversion:**
```
Sistem auto-detect: travel_end_date + 1 day reached
    → Grup status: "Active" → "Alumni"
    → Nama grup: auto-rename → "[Nama Paket] [Tanggal Berangkat] — Alumni"
    → Contoh: "Ramadan Premium March 2026 — Alumni"
    → Jamaah tetap bisa akses Album Foto
    → Admin tetap bisa broadcast ke Alumni
    → Panic Button: OFF (perjalanan sudah selesai)
```

**Manual Trigger (Travel Admin):**
```
Travel Admin → Dasbor → Grup → "Akhiri Perjalanan"
    → Confirm modal: "Ubah status ke Alumni?"
    → Sistem execute conversion
    → Grup masuk list "Alumni Groups"
```

**Alumni Group Features:**
- Album Foto: read-only (tidak bisa upload baru)
- Broadcast: Admin bisa kirim pesan ke semua alumni
- Jamaah bisa share album ke social media
- Jamaah tetap bisa download foto

---

### 3.8.7 Admin Grup Alumni

**Deskripsi:** Travel Admin bisa menunjuk Admin tambahan untuk grup Alumni (retensi dan marketing).

**Spesifikasi:**

|| Parameter | Value |
|-----------|-------|
| Max Admin per Alumni Group | 3 |
| Role Name | "Admin Alumni" |
| Access | Broadcast, View Analytics, Moderate Comments |
| Constraints | Tidak bisa upload foto, tidak bisa ubah paket |

**User Flow:**
```
Travel Admin → Dasbor → Alumni Group → "Tambah Admin Alumni"
    → Input: Nama, No HP, Email
    → Sistem kirim invite
    → Admin Alumni install app → login → role upgraded
```

---

### 3.8.8 Itinerary Management

**Deskripsi:** Admin buat itinerary perjalanan yang bisa dilihat semua member grup.

**Spesifikasi:**

|| Parameter | Value |
|-----------|-------|
| Format | Daily schedule (jam per aktivitas) |
| Content per Item | Waktu, aktivitas, lokasi, catatan |
| Notification | Push notif 1 jam sebelum aktivitas berikutnya |
| Language | Bahasa Indonesia (default), Arab (optional) |

**Itinerary Structure:**
```
Tanggal: Hari ke-3 (March 5, 2026)

| Waktu | Aktivitas | Lokasi | Catatan |
|-------|-----------|--------|---------|
| 04:30 | Bangun + Bersiap | Hotel | |
| 05:00 | Sarapan | Restoran Hotel | |
| 06:00 | Berangkat ke Masjidil Haram | | Bus tersedia |
| 06:30 | Tiba di Masjidil Haram | Masjidil Haram | |
| ... | ... | ... | |

Pengingat:
- Bawa botol zam-zam
- Jaket tebal (AC masjid kuat)
```

**User View (Mobile App):**
```
Jamaah → Home → Tab "Itinerary"
    → List view: semua hari
    → Tap hari → detail schedule
    → Notification reminder 1 jam sebelumnya
    → "Lihat di Peta" → open location di offline map
```

---

### 3.8.9 Broadcast Messaging

**Deskripsi:** Admin Travel kirim pesan broadcast ke semua member grup (active atau alumni).

**Use Cases:**
- Reminder jadwal pembayaran
- Reminder persiapan perjalanan
- Itinerary update
- Info penting selama perjalanan
- Promo paket baru (ke alumni)

**Spesifikasi:**

|| Parameter | Value |
|-----------|-------|
| Content Type | Text + optional image |
| Max Length | 500 karakter (text) |
| Image | Single image (JPG/PNG, max 1MB) |
| Delivery | FCM push notification + in-app notification center |
| Rate Limit | 1 broadcast per 5 menit (prevent spam) |
| History | All broadcasts logged, Admin bisa lihat delivery status |

**User Flow:**
```
Admin → Dasbor → Grup → "Broadcast"
    → Compose: "Jamaah sekalian, besok keberangkatan 04:00 AM..."
    → Preview notification
    → Send
    → Sistem kirim FCM → all members
    → Report: Sent to 45 recipients, Delivered 44, Failed 1
```

**Target Options:**
- Grup Active saja
- Alumni saja
- Semua member (active + alumni)
- Filter by: sudah dapat Panic alert (ya/tidak)

---

### 3.8.10 Revoke Muthawif / Team-Support Access

**Deskripsi:** Travel Admin cabut akses Muthawif atau Team-Support.

**Spesifikasi:** (sudah ada di Section 2.4.3 — reference saja)

**User Flow:**
```
Travel Admin → Dasbor → Grup → Tab "Team"
    → Klik user: "Pak Hendra (Muthawif)"
    → Tombol: "Cabut Akses"
    → Confirm modal: "Yakin cabut akses Pak Hendra?"
    → Klik "Ya"
    → invitation_revoked_at = NOW()
    → User still logged in, tapi fitur dibatasi:
        - Panic Button: OFF
        - Broadcast: tidak bisa kirim
        - Team view: anggota grup hidden
```

**Revocation Reasons (optional logging):**
- Perjalanan selesai
- Pelanggaran rules
- Request dari Muthawif sendiri

---

### 3.8.11 Daily Schedule (Rundown Perjalanan)

**Deskripsi:** Rundown detail per hari yang dikirim sebagai push notification ke Jamaah.

**Spesifikasi:**

|| Parameter | Value |
|-----------|-------|
| Format | "Hari ke-X: [Judul]" + list aktivitas per jam |
| Timing | Auto-send 21:00 hari sebelumnya (configurable) |
| Channel | FCM push notification |
| In-App | Also visible di Itinerary tab |

**Daily Notification Example:**
```
📅 Hari ke-3 — Wednesday, March 5, 2026

🕔 04:30 — Bangun + Bersiap
🕔 05:00 — Sarapan pagi
🕔 06:00 — Berangkat ke Masjidil Haram
🕔 07:00 — Tiba di Masjidil Haram
...
🕥 16:00 — Pulang ke hotel

💡 Tips: Bawa botol zam-zam untuk air dari sumber!
```

---

### 3.8.12 WhatsApp Reminder Automation

**Deskripsi:** Sistem kirim reminder otomatis via WhatsApp (lewat integration).

**Reminder Triggers:**

| Trigger | Timing | Channel |
|---------|--------|---------|
| Booking confirmation | Immediate | WhatsApp |
| 7 hari sebelum keberangkatan | Auto | WhatsApp |
| 1 hari sebelum keberangkatan | Auto | WhatsApp |
| H+1 (perjalanan selesai) | Auto | WhatsApp |

**WhatsApp Integration:**
```
Platform → Integration: WhatsApp Business API
    → Template messages (pre-approved by WhatsApp)
    → Reminder: "Assalamualaikum [Nama], perjalanan Umrah Anda tinggal 7 hari! 🕋"
    → CTA: "Buka Haramain Pro" → deep link
```

**⚠️ Note:** WhatsApp Business API memerlukan approval dan biaya per message. Consideration untuk Phase 2.

---

### 3.8.13 Muthawif Performance Report

**Deskripsi:** Travel Admin bisa lihat report performa Muthawif berdasarkan feedback Jamaah.

**Metrics:**

|| Metric | Source |
|--------|--------|
| Total Jamaah ditangan | Number of Jamaah in group |
| Trip Count | Number of trips completed |
| Panic Alert Count | How many panic alerts triggered |
| Album Photo Count | Photos uploaded |
| Jamaah Rating | Rating dari Jamaah (1-5 stars) |

**Jamaah Rating Flow:**
```
After travel_end_date + 3 days
    → Push notification: "Rate perjalanan Anda bersama [Muthawif Name]"
    → Jamaah → Rating screen (1-5 stars + optional comment)
    → Anonymous aggregation untuk Muthawif
    → Travel Admin lihat average rating per Muthawif
```

---

### 3.8.14 Dashboard Paket Overview

**Deskripsi:** Satu halaman view semua paket Travel.

**Dashboard Display:**
```
Travel Admin → Home Dashboard

┌─────────────────────────────────────────────────┐
│ Ramadan 2026 Packages                             │
├─────────────────────────────────────────────────┤
│ Paket: Ramadan Premium        [45/45] ✅ Full   │
│ Depart: March 1, 2026         [10 remaining] ⚠️ │
│ Paket: Ramadan Economy        [20/45] ✅ Full   │
│ Depart: March 5, 2026         [25 remaining] 🟢 │
├─────────────────────────────────────────────────┤
│ Upcoming Departures (7 days)                    │
│ - March 1: Ramadan Premium (45 pax)             │
│ - March 3: Ramadan Economy (20 pax)             │
└─────────────────────────────────────────────────┘
```

**Alerts on Dashboard:**
- "Package almost full" (seat < 10)
- "New booking from [source]"
- "Muthawif belum di-assign ke paket [nama]"

---

### 3.8.15 Revenue & Sales Dashboard (Read-Only Summary)

**Deskripsi:** Tampilkan summary sales — bukan detail transaksi.

**Display Only:**
```
|Total Jamaah (YTD)|Total Revenue (YTD)|
|      1,250          |  Rp 875,000,000  |
```

**Constraints:**
- Tidak ada detail pembayaran per Jamaah (UU PDP)
- Tidak ada outstanding payment tracking
- Hanya aggregate numbers

---

### 3.8.16 Open Questions — Travel Operations

|| ID | Question | Owner | Deadline | Status | Resolution |
|----|----------|-------|----------|--------|-----------|-------------|
| OQ-TO-01 | WhatsApp Business API: use official partner atau alternatif? | Business | Month 2 | ✅ Resolved | **Manual via Admin Travel** — invitation code sistem; Admin generate & share code ke Jamaah (easy copy) |
| OQ-TO-02 | Daily schedule auto-send: push notification atau in-app only? | Product | Month 2 | ✅ Resolved | **In-app only** (default) — push notification opsional per user preference |
| OQ-TO-03 | Muthawif performance rating: anonymous atau visible? | Business | Month 1 | ✅ Resolved | **Anon untuk Muthawif** (tidak terlihat siapa yang rating) — visible untuk Admin Travel (agregat) |
| OQ-TO-04 | Should Travel Admin bisa create "sub-admin"? | Product | Month 2 | ✅ Resolved | **Ya** — multi-level admin: **Direktor** = Travel Admin penuh, **Karyawan** = sub-admin dengan akses lebih terbatas |

---

## 3.10 Sales Agen Marketing Tools (B2B)

---

### 3.10.1 Prospect Dashboard (CRM)

**Deskripsi:** Sales Agen punya dashboard sederhana untuk tracking prospek dari awal sampai conversion.

**Spesifikasi:**

```
Sales Agen → Home Dashboard

┌─────────────────────────────────────────────┐
│ Sales Agen: [Nama]     [QR] [Earnings]      │
├─────────────────────────────────────────────┤
│ Prospek Saya        Total: [N]              │
├─────────────────────────────────────────────┤
│ [Search: nama / no HP...]                  │
├─────────────────────────────────────────────┤
│ 📱 Andi Wijaya     0812-xxxx-xxxx           │
│    Status: ✅ Sudah Minat                   │
│    Paket: Umrah Ramadan 2026                │
│    Waktu: 2 hari lalu                      │
├─────────────────────────────────────────────┤
│ 📱 Budi Santoso    0857-xxxx-xxxx          │
│    Status: 🔔 Sudah Respons                 │
│    Paket: Umrah Regular Mei 2026            │
│    Waktu: 5 jam lalu                        │
├─────────────────────────────────────────────┤
│ 📱 Siti Aminah     0813-xxxx-xxxx          │
│    Status: 📥 Baru Install                  │
│    Paket: —                                │
│    Waktu: 1 jam lalu                       │
└─────────────────────────────────────────────┘
```

**Status Prospek Options:**

| Status | Label | Keterangan |
|--------|-------|-----------|
| 1 | 📥 Baru Install | Prospek baru install via link Agen |
| 2 | 🔔 Sudah Respons | Prospek sudah baca/balas chat Agen |
| 3 | ✅ Sudah Minat | Prospek tertarik dan minta info lebih |
| 4 | ❌ Belum Minat | Tidak tertarik (arsipkan) |
| 5 | 🎫 Booker | Sudah booking / confirm keberangkatan |

**Fitur:**
- Tambah prospek manual (nama + no HP)
- Edit status prospek
- Filter: semua / aktif / arsip
- Sort: terbaru / nama / paket
- Search by nama atau no HP

---

### 3.10.2 Lead Attribution System

**Deskripsi:** Setiap install via link/QR dari Sales Agen otomatis tercatat.

**Deep Link Format:**
```
https://haramain.app/dl?ref={sales_agent_code}
https://play.google.com/store/apps/details?id=com.haramain.pro&ref={sales_agent_code}
https://apps.apple.com/app/haramain-pro/idXXXXXXXX?ref={sales_agent_code}
```

**Attribution Flow:**
```
Prospek klik link ref=AGEN001
    → Open App Store / Play Store → Install
    → First open → System baca referral code dari install referrer
    → Create lead: {sales_agent_id, prospect_name, timestamp, paket_id}
    → Prospek muncul di Sales Agen prospect dashboard

Jika prospek install TANPA ref code (organic):
    → No attribution
    → Tidak muncul di Sales Agen manapun
```

**Database:**
```sql
leads
  - id (UUID)
  - sales_agent_id (FK → sales_agents)
  - prospect_name
  - prospect_phone
  - paket_id (FK → paket, nullable)
  - status: enum(installed, respons, minat, arsip, booker)
  - attributed_at (timestamp)
  - last_contact_at (timestamp)
  - notes (text, optional)
  - created_at
```

---

### 3.10.3 Test-Code (Demo & Prospect Activation)

**Deskripsi:** Kode demo untuk dua use case:

1. **Sales Agen → Prospect (Panic Button demo):** Sales Agen generate kode sekali pakai untuk demo Panic Button ke calon Jamaah. Hanya unlock Panic Button demo — test alert masuk ke demo inbox, bukan emergency system.

2. **SuperAdmin → Travel Prospect (Free Trial):** SuperAdmin (tim Haramain Pro) generate 10 kode per Travel prospect untuk internal employee testing dan Manasik (latihan sebelum keberangkatan). Kode unlock **full Premium access** — semua fitur kecuali White Label branding.

**Kapan ini penting:**
> "Calon Jamaah harus coba Panic Button untuk percaya fitur ini berfungsi"
> "Travel perlu uji coba full app sebelum commit ke paket berbayar"

**Spesifikasi:**

```
USE CASE 1: Sales Agen → Panic Button Demo
Sales Agen → "Demo Panic Button"
    → Tap "Generate Test Code"
    → System generate: 6-digit code (e.g., "PB-8472")
    → Code expires: 30 minutes
    → Code usable: 1x only (after use → "Code sudah dipakai")
    → Show screen: "Kode Demo: PB-8472"
    → Agen share ke prospek via WhatsApp / langsung ketik di HP prospek

Prospek input code di HP sendiri:
    → "Ada kode demo dari Agen?"
    → Input: PB-8472
    → Panic Alert triggered — Muthawif/Agen dapat notifikasi
    → Prospek melihat: "Panic Button WORKS — Anda berhasil kirim alert"
    → Demo complete → Code marked as used

USE CASE 2: SuperAdmin → Travel Prospect (Free Trial)
SuperAdmin dashboard → "Generate Prospect Codes"
    → Input: Nama Travel, contact person
    → System generate: 10 codes (e.g., "TR-0001-01" s/d "TR-0001-10")
    → Codes unlock full Premium access (all features except White Label)
    → Validity: 30 days from generation OR first use
    → Travel distribute ke internal employees untuk testing + Manasik
```

**Constraints:**
- Use Case 1 (Sales Agen):
  - 1 code per Sales Agen per hari (prevent abuse)
  - Admin Travel bisa set limit: "max 5 test-code/hari"
  - Code tidak bisa digunakan untuk emergency real — hanya trigger test alert
  - Test alert tidak masuk ke emergency response system, hanya ke demo inbox
- Use Case 2 (SuperAdmin → Travel):
  - Default: 10 codes per new Travel prospect
  - Codes non-transferable (bound to Travel account)
  - Codes expire 30 days after generation
  - Upgrade ke paid tier: kode tidak perlu di-revoke — tinggal aktivasi paket di dashboard

---

### 3.10.4 Bank Content (Poster Gallery)

**Deskripsi:** Koleksi poster siap download dengan logo Travel watermark untuk posting media sosial / WhatsApp.

**Spesifikasi:**

```
Sales Agen → "Bank Content"
    → Gallery poster (ratio 1:1)
    → Filter: All / Umrah / Haji / Promo / Testimonial
    → Tap poster → Preview full screen
    → Tap "Download" → Save to device
    → Tap "Share" → Share sheet (WhatsApp, Instagram, TikTok)

Poster download: Logo Travel di TOP-CENTER sebagai watermark
Poster share: Embedded referral link (haramain.app/dl?ref=AGEN001)
```

**Poster Templates (awal):**
- "Daftar Umrah Ramadan 2026" — 1 poster
- "Jadwal Keberangkatan" — list format
- "5 Alasan Umrah di [Travel Name]" — testimonial style
- "Safety First: Panic Button" — feature highlight
- "Momen Tak Terlupakan" — Jejak Ibadah highlight
- "Promo [Bulan] Diskon X%" — seasonal promo

**Admin Travel bisa:**
- Upload poster custom (JPEG/PNG, 1:1, max 2MB)
- Set visibility: all agents / specific agents
- Track download count per poster

---

### 3.10.5 Katalog Paket (View-Only)

**Deskripsi:** Sales Agen bisa展示 paket umrah yang tersedia untuk presentasi ke prospek.

**Spesifikasi:**

```
Sales Agen → "Katalog Paket"
    → List paket yang di-publish oleh Travel Admin
    → Setiap paket card:

┌─────────────────────────────────────┐
│ 🌙 Umrah Ramadan Premium 2026       │
│ 12 Hari — 15 Feb - 28 Feb 2026     │
│ Sisa: 5 kursi                      │
│ Hotel: ⭐⭐⭐⭐ Swissotel             │
│ Maskapai: Garuda Indonesia         │
│                                     │
│ 💰 Rp 28,500,000 / pax             │
│                                     │
│ [📱 WhatsApp Agen] [📋 Detail]      │
└─────────────────────────────────────┘
```

**Constraints:**
- Sales Agen hanya bisa VIEW — tidak bisa edit paket
- Jika tidak ada paket (Travel belum publish): show "Belum ada paket aktif"
- Paket menampilkan: nama, tanggal, harga, sisa kursi, hotel bintang, maskapai
- Travel Admin yang kelola paket (create/edit)

---

### 3.10.6 QR Business Card

**Deskripsi:** Generate QR code personal yang jika discan langsung buka landing page download + referral code otomatis.

**Spesifikasi:**

```
Sales Agen → "QR Saya"
    → Generate QR: https://haramain.app/dl?ref=AGEN001
    → Display QR code (PNG, bisa di-screenshot)
    → Bisa download PNG (high-res)
    → Tampilan:

┌───────────────────────┐
│   [QR Code]           │
│                       │
│   Nama: Budi Santoso   │
│   Sales Agen          │
│   [Nama Travel]        │
│                       │
│   Scan untuk install   │
│   app Haramain Pro     │
└───────────────────────┘
```

**Use Case:**
- Print di nametag / namecard fisik
- Tempel di meja counter
- Kirim via WhatsApp ke prospek

---

### 3.10.7 Sales Earnings Dashboard

**Deskripsi:** Sales Agen bisa lihat estimasi earnings berdasarkan prospek yang berhasil di-convert.

**Spesifikasi:**

```
Sales Agen → "Earnings Saya"
    → Summary card:

┌─────────────────────────────────────┐
│ 💰 Estimasi Earnings Saya           │
│                                     │
│ Total Prospek:      47              │
│ Booker (sudah konfirmasi):  12      │
│ Estimasi Komisi:    Rp 6,000,000   │
│                                     │
│ (Komisi: Rp 500,000 per Booker)    │
└─────────────────────────────────────┘

→ Bottom: List Booker
  - Andi Wijaya — Umrah Ramadan 2026 — 💰 Rp 500,000
  - Siti Aminah — Umrah Regular Mei 2026 — 💰 Rp 500,000
  - ...
```

**Rules:**
- Estimasi saja — actual payment sesuai kebijakan Travel
- Booking = Jamaah yang sudah confirm dan ada di grup keberangkatan
- Earnings tidak include komisi dari Travel lain (sales agen bisa collaborate multiple travels)
- Travel Admin yang approve dan proses pembayaran komisi (bukan system)

---

## 3.11 Informasi Umrah (Konten Edukasi)

**Deskripsi:** Koleksi konten edukasi tentang Umrah — tata cara ibadah, tips menabung, panduan persiapan — dalam format video, audio, dan teks. Dibuat oleh SuperAdmin (tim Haramain Pro). **Free untuk semua user** (tidak perlu Safety Pass).

**Tujuan:**
- Sales Agen bisa share konten ke prospek sebagai nilai tambah sebelum booking
- Jamaah belajar sebelum berangkat
- Diferensiasi dari WhatsApp broadcast (yang hanya text/links, tidak ada video/audio player)

**Spesifikasi:**

```
User → "Informasi Umrah"
    → List konten (filterable by category):

┌─────────────────────────────────────┐
│ 📚 Informasi Umrah                  │
├─────────────────────────────────────┤
│ 🔍 Search...                        │
│                                     │
│ KATEGORI:                           │
│ [Semua] [Tata Cara] [Tips] [Doa]  │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 🎬 Tata Cara Umrah dari A-Z     │ │
│ │ Video · 12:34 · 2.4K views     │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 🎧 Doa-Doa Umrah (Audio)       │ │
│ │ Audio · 45:00 · 1.8K views     │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 💰 Tips Menabung Umrah 2026    │ │
│ │ Teks · Bacaan 5 menit          │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘

→ Tap item → Full screen player
    → Video: inline player dengan kontrol (play/pause/seek/volume)
    → Audio: background play supported
    → Teks: scrollable article view
    → Share button: kirim link ke WhatsApp
```

**Konten Categories:**
| Category | Contoh Konten |
|----------|---------------|
| Tata Cara | Video panduan ihram, sai, melempar jamrah |
| Tips | Tips menabung umrah, packing list, persiapan mental |
| Doa | Koleksi audio doa Umrah (bisa diputar saat di masjid) |
| Info | Jadwal Musim Umrah, perbedaan Umrah رمضان vs regular |

**Constraints:**
- Hanya SuperAdmin yang bisa create/edit/delete konten
- Travel Admin dan Sales Agen bisa share (bukan create)
- Semua konten free — tidak ada paywall
- Video/Audio di-host di CDN (cost borne by Haramain Pro)
- Minimum 3 sample konten saat launch (SuperAdmin responsibility)

**Access Level:**
| Role | View | Share | Create/Edit |
|------|------|-------|------------|
| Jamaah | ✅ | ✅ | ❌ |
| Sales Agen | ✅ | ✅ | ❌ |
| Travel Admin | ✅ | ✅ | ❌ |
| SuperAdmin | ✅ | ✅ | ✅ |

---

## 3.9 Onboarding & Kepatuhan PDPL Saudi

**Consent Flow (Wajib — tidak bisa di-skip):**

```
User buka app (first time)
    → Screen 1: Penjelasan data yang dikumpulkan (lokasi, foto, kontak darurat)
    → Screen 2: Persetujuan lokasi "Aktifkan layanan lokasi?"
    → Screen 3: Privacy Policy + Terms of Service (Bahasa Indonesia + Arab)
    → Screen 4: Checkbox "Saya menyetujui" + tombol "Lanjutkan"
    → Consent tersimpan di DB + local storage
```

**Data Retention Rules:**

| Data Type | Retention | Trigger |
|-----------|-----------|---------|
| GPS Location History | 30 hari | After travel end date |
| Album Foto (perjalanan) | 24 bulan | After travel end date |
| Account Data | Until deletion | User requests deletion |
| Panic Alert Logs | 12 bulan | Auto-purge |

**Withdrawal Flow:**
```
User → Settings → "Hapus Data Saya"
    → Confirmation modal
    → Delete: local storage + server data
    → Account deactivated
    → Re-login requires fresh consent
```

---

# SECTION 4: Model Monetisasi

## 4.1 B2C Pricing

| Tier | Price | Access |
|------|-------|--------|
| Free | Rp 0 | peta online + Geo-Doa + Jejak Ibadah (baca) + Nadhira AI (30 hari dari keberangkatan) |
| Haramain Safety Pass | Rp 120,000 lifetime | Peta offline + Panic Button + Muthawif Virtual + Jejak Ibadah (upload unlimited) + Nadhira AI extended |

> **Catatan:** Jamaah yang diundang via grup Travel (PIN dari Muthawif) mendapat akses premium gratis selama perjalanan — biaya ditanggung oleh Travel.

## 4.2 B2B Travel Pricing

### 4.2.1 Travel Tiers

| Level | Commitment | Price/pax | Min Total | Max Pax/Order |
|-------|-----------|-----------|-----------|---------------|
| Independent (Tanpa Komitmen) | Tidak ada | Rp 90,000 | Rp 90,000/order | Unlimited |
| Small | 45 pax/bulan | Rp 75,000 | Rp 3,375,000 | 45 |
| Medium | 90 pax/bulan | Rp 60,000 | Rp 5,400,000 | 90 |
| Enterprise | White Label customer | Rp 50,000 | Custom quote | Unlimited |

> Enterprise tier ONLY untuk Travel yang membeli Lisensi White Label. Tanpa White Label, tier maksimum adalah Medium.
> Maksimum 45 pax per grup keberangkatan — sesuai kapasitas bus transportasi di Makkah & Madinah.

### 4.2.2 White Label (Enterprise Only)

| Item | Price |
|------|-------|
| Lisensi White Label | Rp 30,000,000 (sekali bayar, lifetime) |
| Biaya Maintenance | Rp 12,000,000/tahun (mulai tahun ke-2) |

White Label mencakup: custom branding (logo, warna, nama app), subdomain sendiri, dashboard eksklusif Travel.

### 4.2.3 Lisensi Satuan (All Tiers)

Travel di semua level (Independent, Small, Medium, Enterprise) dapat membeli lisensi satuan di luar komitmen dengan harga:

| Item | Price |
|------|-------|
| Lisensi satuan | Rp 90,000/pax |

Digunakan untuk: menambah quota di luar paket, atau untuk jamaah tambahan di luar komitmen bulanan.

---

# SECTION 5: User Stories & Acceptance Criteria

> Semua User Stories dalam format: **As a / I want / So that** dengan **INVEST criteria** dan **Given/When/Then acceptance criteria**.

---

## Epic 1: Keselamatan Jamaah

---

### US-01: Download Peta Offline Sebelum Berangkat

**As a** Jamaah  
**I want** mengunduh peta offline sebelum keberangkatan  
**So that** saya bisa menavigasi tanpa internet di Saudi Arabia

**INVEST Assessment:**
| Criteria | Status | Notes |
|----------|--------|-------|
| Independent | ✅ | Bisa dilakukan sebelum trip |
| Negotiable | ✅ | Timing download fleksibel |
| Valuable | ✅ | Core safety feature |
| Estimable | ✅ | Straightforward download feature |
| Small | ✅ | Fits in 1 sprint |
| Testable | ✅ | Clear AC |

**Acceptance Criteria:**

```
Scenario: Download peta offline berhasil
Given saya di screen "Download Peta"
And saya terhubung WiFi
When saya tap "Download Sekarang" (300MB)
Then progress bar menampilkan download progress
And saya melihat estimasi waktu tersisa
And setelah selesai, notifikasi "Peta siap digunakan" muncul
And peta tersimpan di storage perangkat

Scenario: Download peta offline gagal (network error)
Given saya sedang download
When koneksi WiFi terputus
Then download pause secara otomatis
And saya melihat toast "Koneksi terputus. Download akan resume otomatis."
And resume download ketika WiFi kembali

Scenario: Download peta offline dibatalkan user
Given saya sedang download
When saya tap "Batal"
Then download berhenti
And storage yang ter-download dihapus
And saya kembali ke screen sebelumnya

Scenario: Storage tidak cukup
Given saya di screen "Download Peta"
And storage perangkat < 300MB
When saya tap "Download"
Then saya melihat alert "Storage tidak cukup. Bebas {X}MB. Butuh 300MB."
And saya ditawarkan opsi "Hapus Cache" atau "Lihat Cara Mengosongkan Ruang"
```

**Edge Cases:**
- Download di-background (app minimized)
- Battery saver mode aktif
- Download di device lain (share via QR code ke device baru)

**Priority:** Must Have (MVP)

---

### US-02: Panic Button — Kirim Alert Darurat

**As a** Jamaah  
**I want** menekan Panic Button untuk memanggil Muthawif  
**So that** saya bisa mendapat bantuan cepat saat tersesat atau darurat

**INVEST Assessment:**
| Criteria | Status | Notes |
|----------|--------|-------|
| Independent | ✅ | Independen dari fitur lain |
| Negotiable | ✅ | UX bisa didiskusikan |
| Valuable | ✅ | Core safety feature — primary reason to pay |
| Estimable | ⚠️ | Perlu FCM Critical Alert setup + testing |
| Small | ✅ | Fits in 1 sprint (setelah FCM ready) |
| Testable | ✅ | Clear AC |

**Acceptance Criteria:**

```
Scenario: Panic Button ditekan — happy path
Given saya di layar utama aplikasi
And saya sudah bergabung dengan grup (via PIN)
When saya tap tombol Panic (warna merah, terlihat jelas)
Then haptic feedback (vibration 200ms)
And screen berubah merah dengan countdown 3 detik
And saya tap lagi untuk konfirmasi "Ya, Kirim Panic"
Then loading spinner muncul max 2 detik
And notifikasi "Panic Terkirim ✓" muncul
And koordinat GPS terakhir saya terkirim ke Muthawif via FCM Critical Alert

Scenario: Panic Button ditekan — konfirmasi tidak jadi
Given saya di layar konfirmasi Panic
When countdown 3 detik selesai
And saya tidak tap konfirmasi
Then Panic tidak dikirim
And saya kembali ke layar utama

Scenario: Panic Button ditekan — GPS unavailable
Given saya menekan Panic
And GPS tidak tersedia (indoor/disabled)
When saya konfirmasi kirim Panic
Then Panic tetap terkirim
And payload include: { gps_available: false, last_known_coords: null }
And notifikasi ke Muthawif: "Panic dari [Nama], GPS unavailable"

Scenario: Panic Button ditekan — offline (FCM queued)
Given saya menekan Panic
And saya tidak memiliki koneksi internet
When saya konfirmasi kirim Panic
Then Panic masuk local queue dengan status "Pending"
And saya melihat notifikasi "Panic disimpan. Akan dikirim saat online."
And icon kecil di corner: "⚠️ Panic Pending"
When koneksi tersedia
Then Panic otomatis terkirim
And notifikasi "Panic Terkirim ✓" muncul

Scenario: Panic sent — delivery confirmation
Given Muthawif menerima Panic Alert
When alert masuk
Then audio beep khusus berbunyi (即使 HP silent)
And haptic vibration pattern: [long-short-long]
And screen menampilkan: "[Nama Jamaah] butuh bantuan!"
And koordinat tampil di peta dengan icon merah
And Muthawif bisa tap koordinat untuk lihat rute

Scenario: Panic duplicate press (debounce)
Given saya sudah menekan Panic
And Panic belum confirmed/dibatalkan
When saya tekan Panic lagi dalam 30 detik
Then Panic tidak diproses ulang
And toast "Panic sudah dikirim" muncul
```

**Error States:**

| Error | User Feedback | System Action |
|-------|---------------|---------------|
| FCM server down | "Panic disimpan. Akan dikirim saat server pulih." | Queue locally |
| FCM rate limit | "Panic disimpan. Mencoba ulang..." | Exponential backoff retry |
| All retries failed | "Gagal mengirim Panic. Hubungi Muthawif langsung." | Show Muthawif contact |
| Muthawif offline | Panic tetap dikirim ke FCM | FCM delivers when Muthawif online |

**⚠️ CRITICAL (iOS):** Critical Alert entitlement harus disetujui Apple sebelum testing. Request via Apple Developer Portal.

**Priority:** Must Have (MVP)

---

### US-03: Panduan Doa Kontekstual Otomatis

**As a** Jamaah  
**I want** panduan doa muncul otomatis saat mendekati Ka'bah atau lokasi suci  
**So that** saya bisa berdoa dengan benar tanpa harus mencari teks doa

**INVEST Assessment:**
| Criteria | Status | Notes |
|----------|--------|-------|
| Independent | ✅ | Bisa test secara lokal dengan mock GPS |
| Negotiable | ✅ | Content dan UX bisa didiskusikan |
| Valuable | ✅ | High perceived value |
| Estimable | ⚠️ | Geofencing library integration needed |
| Small | ✅ | Fits in 1 sprint |
| Testable | ✅ | GPS spoofing bisa untuk test |

**Acceptance Criteria:**

```
Scenario: Masuk geofence Ka'bah — text mode
Given Ibadah Mode aktif
And saya berjalan masuk radius 50m dari Ka'bah
When GPS mendeteksi saya masuk geofence
Then dalam 30 detik, doa Ka'bah muncul otomatis
And tampil dengan 3 layer: Arab (besar) + Latin + Terjemahan
And saya bisa scroll untuk baca lengkap
And bottom sheet dengan tombol "Tutup"

Scenario: Masuk geofence — audio mode
Given saya menggunakan earphone
And saya masuk geofence
When GPS mendeteksi masuk geofence
Then popup "Deteksi earphone. Aktifkan audio panduan doa?"
When saya tap "Ya"
Then audio doa diputar via earphone
And notifikasi di background: "Memutar: Doa Ka'bah"

Scenario: Keluar geofence
Given saya sedang melihat panduan doa
When GPS mendeteksi saya keluar geofence (radius > 50m)
Then dalam 30 detik, panduan doa auto-close
And saya melihat toast "Anda keluar dari area [Lokasi]"

Scenario: Multiple geofence overlap
Given saya di area yang masuk 2 geofence sekaligus
When GPS mendeteksi overlap
Then prioritas: Ka'bah > Sa'i > Raudhah > lainnya
And tampil doa dengan prioritas tertinggi

Scenario: Offline — geofence content available
Given saya sudah download peta offline
And saya masuk geofence
When tidak ada koneksi internet
Then doa tetap muncul (content tersimpan lokal)
And tidak ada network call yang gagal
```

**Edge Cases:**
- Battery saver mengurangi GPS polling frequency
- Rapid entry/exit (walking around boundary) — debounce 30 detik
- Content library update via OTA

**Priority:** Should Have (v1.1)

---

### US-04: Cari Rute Pulang ke Hotel

**As a** Jamaah  
**I want** mencari rute kembali ke hotel dengan input teks Bahasa Indonesia  
**So that** saya bisa menemukan jalan pulang即使 tersesat

**INVEST Assessment:**
| Criteria | Status | Notes |
|----------|--------|-------|
| Independent | ✅ | Testable dengan offline map |
| Negotiable | ✅ | UX search bisa didiskusikan |
| Valuable | ✅ | Core navigation use case |
| Estimable | ✅ | OSM search integration |
| Small | ✅ | Fits in 1 sprint |
| Testable | ✅ | Testable dengan offline tiles |

**Acceptance Criteria:**

```
Scenario: Search lokasi — online
Given saya di screen Peta Offline
And saya mengetik di search bar "Hotel Al Kiswah"
When saya tap "Cari"
Then hasil pencarian menampilkan: Hotel Al Kiswah + alamat + jarak
And saya tap hasil
Then peta focus ke lokasi hotel
And tampil tombol "Rute ke Sini"
And saya tap "Rute ke Sini"
Then navigasi turn-by-turn dimulai (offline)

Scenario: Search lokasi — offline
Given saya tidak memiliki koneksi internet
And saya di screen Peta Offline
When saya ketik "Hotel Al Kiswah"
Then hasil pencarian offline ditampilkan
And proses sama dengan online

Scenario: Search dengan typo
Given saya mengetik "Hotel Al Kiswah" dengan typo "Kiswa"
When saya tap "Cari"
Then sistem tampil hasil "Apakah maksud: Hotel Al Kiswah?"
When saya tap hasil yang disarankan
Then navigasi proceeds normal

Scenario: Lokasi tidak ditemukan
Given saya mengetik "Hotel XYZ Tidak Ada"
When saya tap "Cari"
Then tampil "Lokasi tidak ditemukan. Coba kata kunci lain."

Scenario: Offline search — no results cached
Given saya offline
And saya search untuk lokasi yang tidak ada di offline tiles
Then tampil "Lokasi tidak ditemukan. Unduh peta tambahan untuk area ini."
```

**Edge Cases:**
- Search history (recent searches stored locally)
- Favorite locations (bookmark for offline access)
- Input bahasa Inggris → translasi ke Bahasa Indonesia

**Priority:** Must Have (MVP)

---

## Epic 2: Koordinasi Muthawif

---

### US-05: Buat Grup Rombongan dengan QR/PIN

**As a** Muthawif  
**I want** membuat grup rombongan dan invite Jamaah via QR code dan PIN  
**So that** saya bisa mengorganisir Jamaah dengan mudah

**INVEST Assessment:**
| Criteria | Status | Notes |
|----------|--------|-------|
| Independent | ✅ | Feature standalone |
| Negotiable | ✅ | QR vs PIN bisa diskusikan |
| Valuable | ✅ | Core coordination feature |
| Estimable | ✅ | QR generation + PIN logic |
| Small | ✅ | 1 sprint |
| Testable | ✅ | Testable dengan mock Jamaah |

**Acceptance Criteria:**

```
Scenario: Muthawif buat grup baru
Given saya login sebagai Muthawif
And saya di screen "Buat Grup Baru"
When saya isi: Nama Grup (e.g., "Umrah Reguler 2026"), Tanggal keberangkatan
And saya tap "Buat Grup"
Then sistem generate: QR code unik + PIN 6 digit (e.g., "HM7X2K")
And saya melihat screen dengan QR code besar + PIN tulis besar
And opsi share: WhatsApp / Copy Link / Download QR

Scenario: Jamaah join grup via PIN
Given Jamaah buka app
And di screen utama, tap "Gabung Grup"
When saya masukkan PIN: "HM7X2K"
And saya tap "Gabung"
Then saya melihat: "Berhasil! Anda bergabung dengan [Nama Grup]"
And saya tidak dikenakan paywall (gratis akses selama perjalanan)
And status saya di grup: "Anggota"

Scenario: Jamaah join grup via QR
Given Jamaah buka app
And tap "Scan QR" (permission kamera)
When saya scan QR code grup
Then proceed sama dengan join via PIN

Scenario: PIN invalid/expired
Given Jamaah masukkan PIN: "XXXXXX"
When PIN tidak valid
Then tampil "PIN tidak valid. Periksa dan coba lagi."
And 3x salah → tampil "Terlalu banyak percobaan. Coba 5 menit lagi."

Scenario: Muthawif view anggota grup
Given saya di screen grup
Then saya melihat:
  - Total anggota: [N]
  - Daftar: Nama + Status (Aktif/Tidak Aktif) + Last Seen
  - Filter: "Semua" / "Aktif Sekarang" / "Panic Pending"

Scenario: Grup berubah jadi Alumni
Given perjalanan selesai
When saya tap "Akhiri Perjalanan" + konfirmasi
Then grup status ubah ke "Alumni"
And Jamaah tetap bisa akses album foto
And grup disappear dari Muthawif active list
```

**Edge Cases:**
- Muthawif reset PIN (generate new) — old PIN invalid
- Jamaah leave grup manually
- Muthawif kick Jamaah from grup
- Same Jamaah join multiple grups (allowed — track per-grup)

**Priority:** Must Have (MVP)

---

### US-06: Broadcast Jadwal ke Semua Anggota

**As a** Muthawif  
**I want** broadcast jadwal ke semua anggota grup dengan satu aksi  
**So that** semua Jamaah mendapat info terbaru sekaligus

**INVEST Assessment:**
| Criteria | Status | Notes |
|----------|--------|-------|
| Independent | ✅ | Independent dari fitur lain |
| Negotiable | ✅ | Format broadcast bisa vary |
| Valuable | ✅ | Core coordination feature |
| Estimable | ✅ | FCM push notification |
| Small | ✅ | 1 sprint |
| Testable | ✅ | Testable dengan test devices |

**Acceptance Criteria:**

```
Scenario: Broadcast text berhasil
Given saya di screen grup
And saya tap "Broadcast"
When saya ketik: "Rendezvous di Pintu King Abdul Aziz, 4:00 PM"
And saya tap "Kirim"
Then notifikasi push terkirim ke semua anggota
And saya lihat: "Terkirim ke [N] anggota"
And broadcast tersimpan di riwayat

Scenario: Broadcast dengan image
Given saya di screen broadcast
When saya tap "Tambah Foto"
And saya pilih dari galeri
Then foto di-attached
And saya ketik caption
When saya tap "Kirim"
Then push notification dengan image thumbnail terkirim

Scenario: Broadcast gagal sebagian (partial failure)
Given saya broadcast ke 50 anggota
And 3 anggota tidak receive (offline)
When saya tap "Kirim"
Then saya lihat: "Terkirim ke 47/50 anggota"
And opsi "Kirim Ulang" untuk yang gagal

Scenario: Jamaah terima broadcast
Given saya Jamaah
And saya di grup "Umrah Reguler 2026"
When broadcast masuk
Then saya lihat push notification di lockscreen
And saya buka app → notifikasi di tab "Jadwal"
And saya lihat: "[Muthawif]: Rendezvous di Pintu King Abdul Aziz, 4:00 PM"

Scenario: Muthawif view broadcast history
Given saya Muthawif
When saya buka "Riwayat Broadcast"
Then saya lihat list semua broadcast
And tiap entry: timestamp + content + delivery count
And saya bisa resend / delete draft
```

**Edge Cases:**
- Broadcast saat offline — queue and send when online
- Large group (100 members) — batching FCM sends
- Muthawif spam prevention: max 10 broadcasts per hari per grup

**Priority:** Must Have (MVP)

---

### US-07: Terima Panic Alert dengan Koordinat

**As a** Muthawif  
**I want** menerima panic alert dari Jamaah dengan koordinat di peta  
**So that** saya bisa menemukan dan membantu Jamaah cepat

**Acceptance Criteria:**

```
Scenario: Muthawif terima Panic Alert
Given saya Muthawif
And HP saya dalam mode silent/DND
When Panic Alert masuk
Then audio beep khusus berbunyi (even on silent)
And haptic vibration pattern: [long-short-long]
And screen unlock otomatis ke alert
And saya melihat:
  - "[Nama Jamaah] butuh bantuan!"
  - Timestamp: "2 menit yang lalu"
  - Koordinat di peta (icon merah + pulse)
  - Tombol: "Lihat Rute" | "Telepon" | "Dismiss"

Scenario: Muthawif lihat rute ke Jamaah
Given saya di screen Panic Alert
When saya tap "Lihat Rute"
Then openstreetmap/offline map membuka
And tampil turn-by-turn ke koordinat Jamaah
And estimasi waktu tempuh

Scenario: Muthawif telepon Jamaah dari alert
Given saya di screen Panic Alert
When saya tap "Telepon"
Then langsung dial ke nomor Jamaah
And log panggilan tersimpan

Scenario: Muthawif dismiss Panic (false alarm)
Given saya di screen Panic Alert
When saya tap "Dismiss"
Then saya pilih alasan: "False Alarm" / "Jamaah sudah ditemukan" / "Lainnya"
And alert tersimpan di log dengan status "Dismissed: [reason]"
And Jamaah NOTIFIED: "Muthawif telah membatalkan alert Anda"

Scenario: Multiple Panic simultaneously
Given 2 Jamaah menekan Panic hampir bersamaan
When alerts masuk
Then saya lihat list Panic
And排序: newest first
And badge count: "2 Panic Aktif"
And saya harus resolve satu per satu

Scenario: Muthawif offline saat Panic sent
Given Jamaah press Panic
And Muthawif sedang offline
When Muthawif kembali online
Then Panic alert tetap masuk (FCM queuing)
And timestamp menunjukkan kapan Panic originais sent
```

**Priority:** Must Have (MVP)

---

### US-08: Foto dengan Watermark Agensi Otomatis

**As a** Muthawif  
**I want** foto momen ibadah dengan watermark logo agensi  
**So that** foto bisa untuk CRM tanpa edit manual

**INVEST Assessment:**
| Criteria | Status | Notes |
|----------|--------|-------|
| Independent | ⚠️ | Depends on grup setup + agensi logo upload |
| Negotiable | ✅ | Watermark position/size negotiable |
| Valuable | ✅ | CRM differentiator for agents |
| Estimable | ✅ | Server-side image processing |
| Small | ✅ | 1 sprint (backend + SDK) |
| Testable | ✅ | Testable dengan mock images |

**Acceptance Criteria:**

```
Scenario: Muthawif foto dengan watermark
Given saya Muthawif
And saya di grup dengan agensi [Nama Agen]
And saya buka camera dalam app
When saya ambil foto
Then foto di-compress (1MB target)
And watermark logo agensi di-bottom-right corner (15% opacity)
And foto masuk queue sync
When sync (device online)
Then foto upload ke server
And foto masuk galeri CRM agen (filtered by grup)

Scenario: Foto saat offline
Given saya ambil foto
And device offline
When saya tidak memiliki koneksi
Then foto masuk local queue
And indicator: "[N] foto menunggu sync"
When koneksi tersedia
Then auto-sync

Scenario: Queue full (device storage)
Given local queue sudah 500 foto atau 2GB
When saya coba ambil foto baru
Then alert: "Storage penuh. Hapus foto lama atau upload sekarang."
And saya offered: "Upload Semua Sekarang" atau "Hapus Terlama"

Scenario: Jamaah view fotoalbum grup
Given saya Jamaah
When saya buka "Album Perjalanan"
Then saya lihat semua foto dari Muthawif
And foto watermark agensi visible
And saya bisa download / share ke WhatsApp
And shared foto include watermark

Scenario: Agen view foto di dashboard
Given saya Agen
When saya buka galeri CRM
Then saya filter: per paket Umrah / per tanggal / per Muthawif
And semua foto ber-watermark logo saya
And saya bisa download / share ke alumni
```

**Edge Cases:**
- Multiple Muthawif in same grup — all photos merged
- Muthawif change during trip — new Muthawif photos still watermarked
- Privacy: Jamaah can hide specific photos from album

**Priority:** Should Have (v1.1)

---

## Epic 3: Agen Travel (B2B)

---

### US-09: Beli Seat License via Midtrans

**As a** Agen Travel  
**I want** membeli seat license untuk Jamaah saya  
**So that** Jamaah bisa akses fitur premium tanpa bayar individual

**INVEST Assessment:**
| Criteria | Status | Notes |
|----------|--------|-------|
| Independent | ✅ | Standalone feature |
| Negotiable | ⚠️ | Pricing tiers fixed, qty negotiable |
| Valuable | ✅ | Core B2B purchase |
| Estimable | ✅ | Midtrans integration straightforward |
| Small | ✅ | 1 sprint |
| Testable | ✅ | Testable dengan Midtrans sandbox |

**Acceptance Criteria:**

```
Scenario: Beli license — happy path
Given saya di dashboard Agen
And saya di screen "Beli Seat License"
When saya masukkan jumlah: 200
Then sistem calculate:
  - 101-500 tier → Rp 80,100/pax
  - Total: Rp 16,020,000
And saya lihat diskon: "-11% (tier 101-500)"
And saya tap "Checkout"
Then redirect ke Midtrans Snap
When saya bayar dengan bank transfer / QRIS / e-wallet
And payment success
Then saya lihat: "Pembayaran berhasil! [N] lisensi aktif."
And lisensi muncul di "Lisensi Aktif: 200"
And setiap license terpakai, balance decrements

Scenario: Beli license — partial payment failure
Given saya bayar via Midtrans
When payment pending/failed
Then saya lihat status "Menunggu Pembayaran"
And saya bisa retry atau cancel

Scenario: Check license balance
Given saya sudah beli 200 lisensi
And 47 terpakai (Jamaah activate)
When saya check "Lisensi Aktif"
Then saya lihat: "200 Total | 47 Terpakai | 153 Tersisa"

Scenario: License expired unused
Given saya beli lisensi
And tidak digunakan dalam 12 bulan
Then lisensi expire
And saya lihat: "Lisensi expired. Apakah ingin perpanjang?"
```

**Payment Flow:**
```
User → Midtrans Snap → Payment → Webhook → Update DB → Email confirmation
```

**Priority:** Must Have (MVP)

---

### US-10: Lihat Galeri Foto Rombongan dengan Branding

**As a** Agen Travel  
**I want** melihat semua foto perjalanan dengan watermark logo saya  
**So that** saya bisa gunakan untuk promosi ke alumni

**Acceptance Criteria:**

```
Scenario: View galeri — filtered by paket
Given saya Agen
When saya buka "Galeri CRM"
And saya filter: Paket "Umrah Regular Mei 2026"
Then saya lihat semua foto dari grup2 dalam paket tersebut
And setiap foto ada watermark logo agensi
And saya bisa scroll / search

Scenario: Download foto
Given saya lihat foto
When saya tap "Download"
Then foto didownload ke device (original quality)

Scenario: Share foto to WhatsApp
Given saya lihat foto
When saya tap "Share" → "WhatsApp"
Then foto dikirim ke WA (dengan watermark)
And link: "Lihat album lengkap di Haramain Pro"

Scenario: Bulk download
Given saya di galeri
When saya select [N] foto + tap "Download Terpilih"
Then zip file generated
And download started

Scenario: Filter combinations
Given saya di galeri
When saya filter: Paket + Tanggal Range + Muthawif
Then result sesuai filter
```

**Priority:** Must Have (MVP)

---

### US-11: Broadcast Promosi ke Alumni

**As a** Agen Travel  
**I want** kirim broadcast promosi ke alumni perjalanan  
**So that** saya bisa retensi dan upsell untuk perjalanan berikutnya

**INVEST Assessment:**
| Criteria | Status | Notes |
|----------|--------|-------|
| Independent | ✅ | Standalone |
| Negotiable | ✅ | Message content flexible |
| Valuable | ✅ | Retention driver |
| Estimable | ✅ | FCM segmentation |
| Small | ✅ | 1 sprint |
| Testable | ✅ | Testable dengan small segment |

**Acceptance Criteria:**

```
Scenario: Broadcast promo — text only
Given saya Agen
When saya buka "Broadcast Alumni"
And saya filter: "Semua alumni" atau spesifik grup
And saya ketik: "Promo Umrah Ramadan 2027! Diskon 10% untuk alumni."
And saya tap "Kirim"
Then push notification terkirim ke semua recipient
And saya lihat: "Terkirim ke [N] alumni"

Scenario: Broadcast promo — with image
Given saya di screen broadcast
When saya attach promo image
And saya ketik caption
And saya tap "Kirim"
Then push dengan image thumbnail terkirim

Scenario: Open rate tracking
Given saya broadcast promo
When recipients buka notification
Then saya bisa see: "Terkirim [N] | Dibaca [M] | Open Rate [X%]"

Scenario: Schedule broadcast
Given saya buat broadcast
When saya tap "Jadwalkan"
And saya pilih tanggal/waktu
Then broadcast queued
And auto-send pada waktu yang dijadwalkan
```

**Edge Cases:**
- User opt-out dari promotions (different from consent)
- Spam prevention: max 1 broadcast per week per alumni segment
- FCM rate limit: 1,000 sends/second

**Priority:** Should Have (v1.1)

---

### US-12: Tracking ROI Lisensi

**As a** Agen Travel  
**I want** tracking ROI dari lisensi yang saya beli  
**So that** saya bisa ukur efektivitas investasi

**INVEST Assessment:**
| Criteria | Status | Notes |
|----------|--------|-------|
| Independent | ✅ | Standalone |
| Negotiable | ✅ | Metrics negotiable |
| Valuable | ✅ | Important for B2B decision making |
| Estimable | ✅ | Simple DB queries |
| Small | ✅ | Dashboard only |
| Testable | ✅ | Testable |

**Acceptance Criteria:**

```
Scenario: View ROI dashboard
Given saya Agen
When saya buka "ROI Saya"
Then saya lihat:
  - Total lisensi tersedia vs terpakai
  - Jumlah Jamaah yang menggunakan link referral saya
  - Conversion rate: Jamaah → Safety Pass upgrade
  - Avg revenue per Jamaah

Scenario: Export laporan
Given saya di ROI dashboard
When saya tap "Export CSV"
Then CSV download dengan semua data
And filename: "ROI_Report_[NamaAgen]_[Tanggal].csv"

Scenario: View per-grup breakdown
Given saya di ROI dashboard
When saya tap "Detail per Grup"
Then saya lihat list grup dengan metrics:
  - Grup: [Nama] | Jamaah: [N] | Terpakai: [M] | Upgrade: [X]
  - Revenue: [Rp Y]
```

**Priority:** Could Have (v2.0)

---

# SECTION 6: Scope Definition

## 6.1 In Scope (MVP — v1.0)

### Keselamatan
- ✅ Peta Offline Makkah & Madinah (300MB)
- ✅ Panic Button dengan FCM Critical Alert
- ✅ Panic delivery < 5 detik (P95)
- ✅ Offline queue + retry for Panic
- ✅ Cari rute dengan input Bahasa Indonesia

### Koordinasi
- ✅ Grup Muthawif dengan QR + PIN
- ✅ Broadcast jadwal (text + image)
- ✅ Panic alert ke Muthawif dengan peta
- ✅ Status kegiatan anggota (Istirahat/Belanja/Lainnya)
- ✅ Ibadah Mode (geofence-based mute)
- ✅ Muthawif Virtual text mode (geofence trigger)
- ✅ Grup Alumni (automatic after trip)

### CRM & B2B
- ✅ Onboarding Agen dengan verifikasi PPIU
- ✅ Beli Seat License via Midtrans + diskon volume
- ✅ Dasbor Agen: paket management, monitoring grup
- ✅ Galeri foto ber-watermark
- ✅ Broadcast promosi ke alumni (v1.1: add scheduling)
- ✅ B2C paywall dengan free trial 7 hari

### Compliance
- ✅ Onboarding consent gate (PDPL Saudi + UU PDP)
- ✅ Data retention rules (30 hari GPS, 24 bulan foto)
- ✅ User data deletion flow

## 6.2 Out of Scope (v1.0)

### Not in MVP
- ❌ Indoor map Masjidil Haram level floor (vendor TBD)
- ❌ Audio mode Muthawif Virtual (need regulatory validation)
- ❌ Photo capture dengan system camera (in-app only)
- ❌ Leaderboard / ranking learners
- ❌ XP / points gamification
- ❌ Certificate generation PDF
- ❌ Multi-language support (Arab, Inggris)
- ❌ PWA — native app only
- ❌ Integration dengan maskapai API
- ❌ Integration dengan Nusuk.sa official
- ❌ WhatsApp bot or voice bot
- ❌ AI generative voice interaction
- ❌ Visa processing atau Nusuk booking

### Future (v2.0+)
- 🔜 Real-time location sharing (opt-in, consent-based)
- 🔜 Analytics dashboard lanjutan
- 🔜 Afiliasi hotel (Agoda, Traveloka, InvolveAsia)
- 🔜 Ekspansi Malaysia/Brunei
- 🔜 Multi-language UI

## 6.3 Dependencies

| Dependency | Owner | Status | Blocker? |
|------------|-------|--------|----------|
| OSM Tiles (self-hosted) | CTO/Trae | ✅ Resolved — OSM opensource | No blocker |
| Firebase Cloud Messaging + Critical Alert | iOS Lead | Setup | ⚠️ Critical — needs entitlement request Bulan 1 |
| Indoor Map Provider (Masjidil Haram) | Product + Legal | Placeholder | ⚠️ High — decision Bulan 2 |
| Midtrans Snap API | CTO/Trae | Integration ready | ✅ No blocker |
| Supabase (DB + Auth + Storage + Edge Functions) | CTO/Trae | Setup | ✅ No blocker |
| Legal Counsel (PDPL Saudi + Indonesia) | Founder | Hiring | ⚠️ High — needed Bulan 2 |
| Apple Developer Account + Entitlement Request | iOS Lead | Not started | ⚠️ Critical — start Bulan 1 |
| SDAIA NRC Registration | Legal | Pending | ⚠️ Critical — **HARD REQUIREMENT**. Verify with legal counsel before launch. Operating without NRC = risk of app shutdown in Saudi. Timeline: 4-8 weeks. |

## 6.4 Assumptions

1. Jamaah Indonesia bersedia membayar Rp 120.000 untuk ketenangan pikiran
2. Agen PPIU termotivasi untuk diferensiasi via teknologi
3. OSM tiles untuk Makkah/Madinah dapat di-host sendiri dalam 300MB
4. FCM Critical Alert berfungsi di Android tanpa izin khusus
5. Apple menyetujui Critical Alert entitlement untuk use case keselamatan (dengan SMS fallback plan jika ditolak)
6. 50,000 Jamaah per tahun mau upgrade ke Safety Pass
7. 60,000 Jamaah melalui agen B2B per tahun
8. Indoor foto di area masjid diizinkan otoritas Saudi ✅ (OQ-03 RESOLVED)

## 6.5 Open Questions

|| ID | Question | Owner | Deadline | Status | Resolution |
|----|----------|-------|----------|--------|-----------|-------------|
| OQ-01 | Apakah Apple menyetujui Critical Alert entitlement? | CTO/iOS Lead | Bulan 1 | ✅ Resolved | Ajukan + SMS fallback (Twilio/Nexmo) sebagai contingency — tidak ada feature block jika ditolak |
| OQ-02 | Vendor indoor map mana yang dipilih? | Product + Legal | Bulan 2 | ✅ Resolved | **OSM + self-hosted tiles** — opensource, no licensing fee |
| OQ-03 | Apakah foto di area masjid diizinkan? | Legal | Bulan 2 | ✅ Resolved | **Ya, diizinkan** — foto di area masjid diizinkan otoritas Saudi |
| OQ-04 | Apakah revenue share 30% perlu perjanjian reseller formal? | Legal | Bulan 3 | ✅ Resolved | **Hapus revenue share** — White Label fixed pricing (Rp 30jt + Rp 12jt/thn) |
| OQ-05 | Berapa biaya NRC registration SDAIA? | Legal/Finance | Bulan 2 | ✅ Resolved | **Verify via SDAIA/SEVE portal** — bukan month-1 blocker. Est. SAR 1,000-5,000 |
| OQ-06 | Apakah audio doa via earphone dilarang di dalam masjid? | Legal | Bulan 2 | ✅ Resolved | **Diperbolehkan** — audio doa via earphone diizinkan di dalam masjid |
| OQ-07 | Apakah Kemenag terbuka untuk endorsement? | Founder/BD | Bulan 4 | ✅ Resolved | **Tidak perlu endorsement** pemerintah — hapus dari scope |

---

# SECTION 7: Offline Sync Strategy

> Design document untuk offline-first architecture.

## 7.1 Data Types & Sync Priority

| Data Type | Read/Write | Sync Trigger | Conflict Resolution | Storage |
|-----------|------------|--------------|---------------------|---------|
| Panic Alert | Write (Jamaah) | Immediate (when online) + Queue when offline | Server wins (timestamp) | Last 100 alerts |
| Photo Queue | Write (Muthawif) | Every 5 min (if online) | Server wins (append) | Local SQLite, max 2GB |
| Broadcast Messages | Read (Jamaah) | On receive (FCM) + Poll if missed | N/A | Last 30 days |
| Group Members | Read/Write | On join/leave + sync periodic | Server wins | Cached locally |
| Doa Content | Read only | On app update (OTA) | N/A | Pre-loaded |
| Map Tiles | Read only | On download (WiFi) | N/A | 300MB on device |

## 7.2 Sync Protocol

### Panic Alert Flow
```
Jamaah press Panic
    → Write to local queue (SQLite)
    → Try send via FCM
    → If success: mark "sent"
    → If fail: keep "pending" + retry exponential backoff
    → Background job checks queue every 30 seconds
    → On success: mark "confirmed"
    → On max retries (3): show "Gagal. Hubungi Muthawif langsung."
```

### Photo Sync Flow
```
Muthawif capture photo
    → Save to local SQLite queue (blob + metadata)
    → Thumbnail generated locally
    → When online:
        → Upload original to Supabase Storage
        → Edge function: compress + watermark
        → Update CRM album
        → Mark "synced" in local queue
    → When offline:
        → Stay in queue
        → Sync when connectivity returns
```

### Conflict Resolution Rules
- **Server wins** untuk: group membership, license counts, consent status
- **Client wins** untuk: photo timestamps (use EXIF if available)
- **Last write wins** untuk: broadcast message read status
- **Manual merge** untuk: Jamaah name edits (flag for review)

## 7.3 Offline Storage Limits

| Storage Type | Max Size | Auto-purge Policy |
|-------------|----------|-------------------|
| Photo queue | 2GB or 500 photos | Oldest deleted when full |
| Panic queue | 100 alerts | Oldest deleted after 30 days |
| Map tiles | 300MB | Manual re-download |
| Doa content | 50MB | Auto-update via OTA |
| Broadcast cache | 30 days | Auto-delete older |

## 7.4 UX Accessibility — First-Time Feature Tooltip

**Principle:** UI/UX Haramain Pro harus menampilkan popup guide saat pertama kali setiap fitur dibuka — agar pengguna siapapun bisa memahami apa yang ada di layar tanpa training khusus.

**Spesifikasi:**

| Parameter | Value |
|-----------|-------|
| Trigger | Pertama kali user membuka suatu fitur (di-detect via local flag) |
| Display | Overlay tooltip di atas elemen UI yang relevan |
| Content per feature | 1-3 kalimat singkat + ilustrasi/icon |
| Dismiss | Tap diluar tooltip atau swipe |
| Re-show option | Ada "Tampilkan lagi" di Settings |

**Contoh Tooltip per Fitur:**

```
Fitur: Panic Button
Tooltip: "Tekan tombol ini jika Anda tersesat atau butuh bantuan.
         Muthawif & Team Support akan langsung tahu lokasi Anda."

Fitur: Broadcast Jadwal
Tooltip: "Kirim pengumuman ke seluruh Jamaah di grup Anda.
         Pesan akan muncul di layar mereka bahkan saat HP disilent."

Fitur: Jejak Ibadah
Tooltip: "Simpan foto kenangan ibadah Anda di album grup.
         Foto otomatis di-watermark dengan nama Travel."
```

**Constraints:**
- Tooltip hanya muncul sekali per fitur (save ke local storage)
- Tidak mengganggu alur utama user
- Teks singkat, icon, tidak ada video autoplay
- Multi-bahasa: Indonesia (default) + Arab

---

# SECTION 8: Non-Functional Requirements

## 8.1 Performance

| Metric | Target | Measurement |
|--------|--------|-------------|
| App cold start | < 3 seconds | Manual + automated |
| Map tile render (offline) | < 2 seconds | Profiling |
| Panic Alert E2E | < 5 seconds (P95) | Load test |
| Photo upload (per photo) | < 10 seconds (4G) | Network test |
| FCM broadcast latency | < 3 seconds | Load test |
| Web dashboard load | < 2 seconds | APM |

## 8.2 Scalability

| Scenario | Target | Strategy |
|---------|--------|----------|
| Concurrent users (Haji peak) | 50,000 | Supabase plan scaling + FCM throttling |
| Broadcast to 10,000 | < 30 seconds total | FCM batching + rate limit |
| Photo upload burst (100 Muthawif simultaneously) | 100 photos/minute | CDN + async processing |
| Database writes (Panic alerts) | 100/second | Connection pooling |

## 8.3 Availability

| Service | SLA | Notes |
|---------|-----|-------|
| Mobile App | 99.5% | Excluding scheduled maintenance |
| Web Dashboard | 99.5% | Supabase managed |
| FCM | 99.9% | Google's SLA |
| Supabase Backend | 99.9% | Supabase managed |
| OSM Tile Server | 99.5% | Self-hosted, monitor required |

## 8.4 Security

|| Requirement | Implementation |
|-------------|----------------|
| Data at rest | AES-256 encryption (Supabase) |
| Data in transit | TLS 1.3 |
| Authentication | Supabase Auth (JWT) |
| Authorization | Row Level Security (RLS) |
| Admin routes | is_admin = true check at DB level |
| API keys | Supabase Vault (never in source code) |
| Panic payload | Encrypted end-to-end |
| Audit log | All admin actions logged |
| Secrets rotation | API keys rotated every 90 days |

### Audit Log Specification

|| Parameter | Value |
|-----------|-------|
| Logged events | All admin actions: create/update/delete user, group, paket; login events; permission changes |
| Log format | `{timestamp, actor_user_id, action, target_table, target_id, ip_address, user_agent}` |
| Retention | 24 months minimum |
| Access control | Admin only; immutable (no delete) |
| Storage | Separate `audit_logs` table in Supabase |

### Security Audit Schedule

|| Audit Type | Frequency | Owner |
|-----------|-----------|--------|
| Penetration Testing | Annual + before major launch | External vendor |
| Vulnerability Scan | Monthly (automated) | Engineering |
| Code Security Review | Per release (CI/CD gate) | Engineering |
| Dependency Audit | Monthly (`npm audit`) | Engineering |
| Incident Response Plan | Tested annually | Operations |

## 8.5 Privacy & Compliance

| Regulation | Requirement | Implementation |
|------------|-------------|----------------|
| PDPL Saudi (SDAIA) | Consent gate + data deletion | Onboarding flow + Settings → Delete |
| UU PDP Indonesia | Data protection + DPO | Privacy policy + consent |
| Apple Critical Alert | Entitlement approval | Developer portal request |
| SDAIA NRC Registration | **HARD REQUIREMENT** — verify with legal counsel BEFORE launch. Operating without NRC may result in app shutdown in Saudi. | Legal counsel to verify + submit application. Estimated cost: SAR 1,000-5,000. Timeline: 4-8 weeks. |

## 8.6 Device Compatibility

| Device Class | Target Spec | Min OS |
|-------------|-------------|--------|
| iOS High-end | iPhone 12+ | iOS 15+ |
| iOS Entry | iPhone SE 2020 | iOS 15+ |
| Android High-end | 4GB RAM, 64GB storage | Android 10+ |
| Android Entry | 2GB RAM, 32GB storage | Android 8+ |

---

# SECTION 9: Success Metrics

## 9.1 Business KPIs (Go/No-Go 6 Bulan)

| KPI | Minimum | Ideal | Measurement |
|-----|---------|-------|-------------|
| MRR | Rp 2 Milyar | Rp 2.5 Milyar | Midtrans + DB |
| Agen B2B Aktif | 40 | 70 | Admin dashboard |
| Jamaah Safety Pass | 50,000 | 80,000 | DB profiles |
| Trial → Paid (B2C) | 35% | 50% | Cohort analytics |
| Retensi 30 Hari | 50% | 65% | Event tracking |

## 9.2 Product & Safety KPIs

| Metric | Target | Frequency |
|--------|--------|----------|
| Panic Alert E2E (P95) | < 5 detik | Real-time |
| DND Bypass Success Rate | > 95% (iOS & Android) | Weekly test |
| App Crash Rate | < 0.5% | Daily (Crashlytics) |
| App Store Rating | > 4.5 bintang | Monthly |
| NPS Jamaah | > 45 | Per batch |
| Panic resolved via app | Track & report | Per Umrah season |

## 9.3 Technical KPIs

| Metric | Target |
|--------|--------|
| API Response Time (P95) | < 200ms |
| Database Query Time (P95) | < 100ms |
| FCM Delivery Rate | > 99.5% |
| Photo Sync Success Rate | > 98% |
| Offline Map Download Success | > 99% |

---

# SECTION 10: Technical Architecture

## 10.1 Technology Stack

| Layer | Technology | Notes |
|-------|------------|-------|
| Mobile App | Flutter (iOS + Android) | Single codebase |
| Backend | Supabase (PostgreSQL + Auth + Storage + Realtime) | Open source, RLS |
| Edge Functions | Supabase Edge Functions (Deno) | API orchestration |
| Offline Maps | OpenStreetMap (OSM) + self-hosted tiles | ✅ Resolved OQ-02 — OSM opensource, no licensing fee |
| Push Notifications | Firebase Cloud Messaging (FCM) | Critical alerts |
| Payments | Midtrans Snap & Core API | QRIS, VA, e-Wallet |
| Image Processing | Sharp.js (server-side) | Compression + watermark |
| CRM/Broadcast | FCM + Make.com webhook | Mass notification |
| Analytics | Firebase Analytics + Mixpanel | Event tracking |

## 10.2 Database Schema (High-Level)

```
users
  - id (UUID)
  - email
  - phone
  - role: enum(jamaah, muthawif, team_support, travel_admin, muthawif_mandiri, sales_agent, admin)
  - travel_id (FK → travels, nullable untuk mandiri & sales_agent non-affiliated)
  - is_paid_user: boolean
  - invitation_code (nullable, untuk Team-Support & Muthawif dari travel)
  - invitation_revoked_at (nullable, timestamp jika travel revoke)
  - created_at
  - consent_timestamp
  - travel_end_date

travels
  - id (UUID)
  - name (e.g., "Maktour", "Patuna Travel", "Alhijaz Indowisata")
  - ppiu_license_number
  - logo_url
  - white_label_domain (subdomain untuk white label)
  - is_verified
  - seat_balance
  - created_at

agens
  - id (UUID)
  - user_id (FK → users)
  - ppiu_license_number
  - logo_url
  - is_verified
  - seat_balance

sales_agents
  - id (UUID)
  - user_id (FK → users)
  - travel_id (FK → travels, nullable — agent bisa kerja sama dengan multiple travels)
  - sales_agent_code (UNIQUE, e.g., "AGEN001")
  - commission_per_booker (Rp, default: 500000)
  - daily_test_code_limit (int, default: 5)
  - is_active (boolean)
  - created_at

leads
  - id (UUID)
  - sales_agent_id (FK → sales_agents)
  - prospect_name
  - prospect_phone
  - paket_id (FK → paket, nullable)
  - status: enum(installed, respons, minat, arsip, booker)
  - attributed_at (timestamp)
  - last_contact_at (timestamp)
  - notes (text, nullable)
  - created_at

test_codes
  - id (UUID)
  - use_case (enum: 'panic_demo', 'travel_prospect_trial')
  - sales_agent_id (FK → sales_agents, nullable — only for panic_demo)
  - travel_id (FK → travels, nullable — only for travel_prospect_trial)
  - code (VARCHAR, UNIQUE, e.g., "PB-8472" or "TR-0001-01")
  - is_full_premium_access (boolean, default: false — true for travel_prospect_trial)
  - expires_at (timestamp)
  - used_at (nullable, timestamp)
  - used_by_user_id (FK → users, nullable)
  - created_at

bank_content
  - id (UUID)
  - travel_id (FK → travels)
  - title
  - category: enum(umrah, haji, promo, testimonial)
  - image_url
  - is_active (boolean)
  - download_count (int, default: 0)
  - created_at

rombongan
  - id (UUID)
  - muthawif_id (FK → users)
  - agen_id (FK → agens)
  - name
  - pin (6 char)
  - status: enum(active, alumni)
  - departure_date
  - created_at

rombongan_members
  - id (UUID)
  - rombongan_id (FK → romongan)
  - user_id (FK → users)
  - role_in_group: enum(jamaah, muthawif, team_support)
  - joined_at (timestamp)
  - left_at (nullable, timestamp — when group becomes alumni)

rombongan_invitations
  - id (UUID)
  - rombongan_id (FK → romongan)
  - invitee_phone
  - invitee_name
  - status: enum(pending, accepted, declined, expired)
  - created_at
  - expires_at
  - responded_at (nullable, timestamp)

paket
  - id (UUID)
  - travel_id (FK → travels)
  - name (e.g., "Umrah Premium 9 Hari")
  - duration_days (int)
  - departure_date
  - return_date
  - seat_total (int)
  - seat_available (int)
  - price_per_pax (Rp)
  - is_active (boolean)
  - created_at

daily_schedule
  - id (UUID)
  - rombongan_id (FK → romongan)
  - date
  - time (TIME, e.g., "05:00")
  - title (e.g., "Shalat Subuh berjamaah")
  - location_name
  - location_lat (decimal, nullable)
  - location_lng (decimal, nullable)
  - notes (text, nullable)
  - order_index (int)

photos
  - id (UUID)
  - user_id (FK → users)
  - rombongan_id (FK → romongan, nullable)
  - album_id (FK → albums, nullable)
  - storage_path (URL ke Supabase Storage)
  - thumbnail_path (URL)
  - width (int)
  - height (int)
  - file_size_kb (int)
  - sha256_hash (untuk dedup)
  - location_lat (decimal, nullable)
  - location_lng (decimal, nullable)
  - location_name (text, nullable)
  - taken_at (timestamp)
  - uploaded_at (timestamp)
  - is_featured (boolean, default: false)
  - vote_count (int, default: 0)

albums
  - id (UUID)
  - rombongan_id (FK → romongan)
  - name
  - status: enum(active, alumni, deleted)
  - created_at
  - album_start_date (date)
  - album_end_date (date)

comments
  - id (UUID)
  - photo_id (FK → photos)
  - user_id (FK → users)
  - content (text, max 500)
  - created_at
  - updated_at
  - is_deleted (boolean, soft delete)

reactions
  - id (UUID)
  - photo_id (FK → photos)
  - user_id (FK → users)
  - emoji (enum: heart, love, laugh, pray, thumbs_up)
  - created_at

notifications
  - id (UUID)
  - user_id (FK → users)
  - type: enum(panic_alert, broadcast, invitation, schedule_reminder, alumni_memory, system)
  - title
  - body (text)
  - data (JSONB, nullable — e.g., {romongan_id, panic_location})
  - is_read (boolean, default: false)
  - created_at

panic_alerts
  - id (UUID)
  - user_id (FK → users — sender)
  - rombongan_id (FK → romongan)
  - location_lat (decimal)
  - location_lng (decimal)
  - location_name (text, nullable)
  - message (text, nullable)
  - status: enum(active, acknowledged, resolved)
  - acknowledged_by (FK → users, nullable)
  - acknowledged_at (timestamp, nullable)
  - response_type: enum('stay_and_pickup', 'im_here', nullable)
  - responder_location_lat (decimal, nullable)
  - responder_location_lng (decimal, nullable)
  - resolved_at (timestamp, nullable)
  - created_at

locations
  - id (UUID)
  - name (e.g., "Masjidil Haram")
  - category: enum(masjid, zona, pintu, landmark)
  - latitude (decimal)
  - longitude (decimal)
  - radius_meters (int, geofence radius)
  - city (text, nullable)
  - country (text, default: "SA")
  - is_active (boolean)

user_settings
  - id (UUID)
  - user_id (FK → users, UNIQUE)
  - departure_date (date, nullable — untuk Mandiri Panic Button lifecycle)
  - trip_duration_days (int, nullable)
  - panic_enabled (boolean, default: true)
  - one_year_memory_notif_enabled (boolean, default: true)
  - daily_schedule_reminder_enabled (boolean, default: true)
  - updated_at

user_panic_codes
  - id (UUID)
  - user_id (FK → users)
  - code (6-char, UNIQUE)
  - type: enum(test, emergency)
  - expires_at (timestamp)
  - used_at (nullable, timestamp)
  - used_by_user_id (FK → users, nullable)
  - created_at

broadcast_messages
  - id (UUID)
  - sender_user_id (FK → users)
  - rombongan_id (FK → romongan, nullable — null = broadcast to all)
  - title
  - body (text)
  - sent_at (timestamp)

bank_content_downloads
  - id (UUID)
  - bank_content_id (FK → bank_content)
  - user_id (FK → users)
  - downloaded_at (timestamp)

informasi_umrah
  - id (UUID)
  - title (VARCHAR)
  - description (text, nullable)
  - category: enum('tata_cara', 'tips', 'doa', 'info')
  - content_type: enum('video', 'audio', 'teks')
  - content_url (VARCHAR — CDN URL)
  - thumbnail_url (VARCHAR, nullable)
  - duration_seconds (int, nullable — for video/audio)
  - view_count (int, default: 0)
  - is_published (boolean, default: false)
  - created_by (FK → users — SuperAdmin)
  - created_at
  - updated_at

informasi_umrah_views
  - id (UUID)
  - informasi_umrah_id (FK → informasi_umrah)
  - user_id (FK → users)
  - viewed_at (timestamp)

---

# SECTION 11: Open Questions Resolved — Consolidated Appendix

> **Status: ✅ ALL 21 OPEN QUESTIONS RESOLVED — May 01, 2026**

This section consolidates all Open Question resolutions from throughout the PRD into a single reference.

---

## 11.1 Compliance & Legal (OQ-01 → OQ-07)

|| ID | Question | Resolution | Impact |
|----|----------|-----------|--------|
| OQ-01 | Apple Critical Alert approval? | Ajukan + SMS fallback (Twilio/Nexmo) contingency — tidak ada feature block jika ditolak | Panic Button: Ajukan Critical Alert + SMS fallback |
| OQ-02 | Indoor map vendor? | **OSM + self-hosted tiles** — opensource, no licensing fee | Eliminates Mapbox cost |
| OQ-03 | Foto di area masjid? | **Diizinkan** oleh otoritas Saudi | Jejak Ibadah tidak terblokir |
| OQ-04 | Revenue share 30% perlu reseller agreement? | **Hapus revenue share** — White Label fixed pricing only | Simplifies legal |
| OQ-05 | NRC SDAIA registration cost? | Verify via SDAIA/SEVE portal — **bukan month-1 blocker** | Deferred |
| OQ-06 | Audio doa via earphone dilarang? | **Diperbolehkan** di dalam masjid | Geo-location doa feature tidak terblokir |
| OQ-07 | Kemenag endorsement? | **Hapus dari scope** — tidak perlu endorsement pemerintah | Simplifies go-to-market |

---

## 11.2 Travel Operations (OQ-TO-01 → OQ-TO-04)

|| ID | Question | Resolution | Impact |
|----|----------|-----------|--------|
| OQ-TO-01 | WhatsApp Business API? | **Manual via Admin Travel** — invitation code sistem; Admin generate & share code (easy copy) | Tidak perlu WhatsApp API cost |
| OQ-TO-02 | Daily schedule push notification? | **In-app only (default)** — push opsional per user preference | Reduces notification spam |
| OQ-TO-03 | Muthawif rating visibility? | **Anon untuk Muthawif** (visible ke Admin Travel agregat) | Privacy + accountability |
| OQ-TO-04 | Sub-admin access? | **Ya** — multi-level: Direktor = Travel Admin penuh, Karyawan = sub-admin (akses terbatas) | Org management |

---

## 11.3 White Label (OQ-WL-01 → OQ-WL-03)

|| ID | Question | Resolution | Impact |
|----|----------|-----------|--------|
| OQ-WL-01 | Flutter build strategy? | **1 codebase multi-entry** — single codebase dengan flavor per travel (bundle ID berbeda) | Simplified maintenance |
| OQ-WL-02 | App Store submission? | **Haramain Pro team submits** — pusat yang submit; travel owns developer accounts | Streamlined launch |
| OQ-WL-03 | Revenue model? | **Fixed pricing:** Rp 30.000.000 lisensi lifetime + Rp 12.000.000 maintenance/tahun (mulai yr 2) + Rp 50.000 per Jamaah | Predictable revenue |

---

## 11.4 Jejak Ibadah (OQ-JI-01 → OQ-JI-05)

|| ID | Question | Resolution | Impact |
|----|----------|-----------|--------|
| OQ-JI-01 | PDF generation? | **Server-side** (Node.js/Python) — lebih control, no third-party subscription | ~Rp 300rb/bulan |
| OQ-JI-02 | Video clip storage? | **HAPUS video clip** — storage cost terlalu besar (ratusan ribu jamaak × clip video) | Eliminates major cost |
| OQ-JI-03 | Physical prize untuk challenge? | **HAPUS physical prize** — digital challenge only | No prize logistics |
| OQ-JI-04 | Video compression on-device? | **Ya, untuk foto** — compress on-device 75% JPEG, target 1MB/foto | Reduces upload size |
| OQ-JI-05 | Album bundle pricing? | **Fix price per user type** — Umrah Mandiri Rp 120.000, Jamaah Travel included dalam seat license | Simple billing |

---

## 11.5 Umrah Mandiri (OQ-UM-01 → OQ-UM-03)

|| ID | Question | Resolution | Impact |
|----|----------|-----------|--------|
| OQ-UM-01 | Muthawif-Mandiri bisa upgrade ke Travel Admin? | **Ya** — Muthawif-Mandiri (biasanya Ustadz) bisa upgrade, beli seat license dengan harga lebih murah | Upsell path |
| OQ-UM-02 | Grup Alumni/Jejak Ibadah untuk Mandiri? | **Tidak perlu** — user Mandiri cenderung simpan & share via WhatsApp/media sosial | Feature simplification |
| OQ-UM-03 | Freemium model? | **Freemium** — trial dulu lalu paywall; Panic Button + Jejak Ibadah + Geo-Doa = Premium | Acquisition funnel |

---

## 11.6 Cost Impact Summary

### Costs Eliminated by OQ Resolutions

| Item | Original Estimate | Resolution | Savings |
|------|-------------------|------------|---------|
| Indoor Map Vendor (Mapbox/HERE) | Rp 50-100jt/tahun | OSM self-hosted | ~Rp 50-100jt/tahun |
| Video Clip Storage | Rp 4,560rb/tahun | DIHAPUS | ~Rp 4,560rb/tahun |
| WhatsApp Business API | Rp 5-10rb/contact | Manual code system | ~Rp 5-10rb/contact |
| Physical Prize Logistics | TBD | DIHAPUS | Admin cost avoided |
| Revenue Share Legal | Reseller agreement cost | Hapus 30% rev share | Legal cost avoided |

### Net New Costs

| Item | Cost | Notes |
|------|------|-------|
| Server-side PDF (Node.js) | ~Rp 300rb/bulan | PDF album generation |
| OSM tile hosting | ~Rp 500rb-1jt/bulan | If self-hosting tiles |
| SMS Fallback (Twilio) | ~Rp 200-500/push | Panic Button contingency |

---

## 11.7 Next Steps After OQ Resolution

All 21 Open Questions are now **RESOLVED**. The PRD is ready for:

1. **Technical Specification Phase** — Architecture, API contracts, database schema finalization
2. **Engineering Kickoff** — Sprint planning dengan Trae.ai
3. **MVP Scope Lock** — Fitur yang masuk Bulan 1-2: Panic Button, Jejak Ibadah (foto only), AI Nadhira (KB-constrained), Daily Schedule, White Label (core)

---

*Document: Haramain-Pro-PRD-v1.6.md*
*Last Updated: May 02, 2026*
*CTO Review: Hermes*
