# consent-matrix.md

## Overview

Dokumen ini mendefinisikan **Consent Matrix** untuk Haramain Pro sesuai dengan regulasi Saudi PDPL (Personal Data Protection Law).

Tujuan utama:

* Memastikan semua fitur berbasis data memiliki consent yang valid
* Menjadi referensi tunggal untuk mobile, backend, dan RLS
* Mengatur lifecycle consent (grant, revoke, purge)

Consent dibagi menjadi dua kategori utama:

1. **Core PDPL Consent (mandatory)**
2. **Marketing Consent (optional)**

---

## 1. Consent Categories

### 1.1 Core PDPL Consent (Mandatory)

| Consent Type      | Required | Deskripsi                                   |
| ----------------- | -------- | ------------------------------------------- |
| Location (GPS)    | ✔        | Untuk navigation, panic alert, geofence doa |
| Photo Access      | ✔        | Untuk Jejak Ibadah (capture & upload)       |
| Push Notification | ✔        | Untuk panic alert & broadcast               |

Tanpa consent ini:
➡️ User tidak bisa menggunakan aplikasi

---

### 1.2 Marketing Consent (Optional)

| Consent Type     | Required | Deskripsi                |
| ---------------- | -------- | ------------------------ |
| Alumni Broadcast | ✖        | Promo dari travel agency |

Tanpa consent ini:
➡️ User tetap bisa pakai aplikasi
➡️ Tidak menerima broadcast marketing

---

## 2. Consent State Model

### 2.1 States

| State          | Deskripsi                       |
| -------------- | ------------------------------- |
| NOT_GRANTED    | Belum pernah memberikan consent |
| GRANTED        | Consent aktif                   |
| WITHDRAWN      | Consent ditarik user            |
| PENDING_DELETE | Menunggu penghapusan data       |
| PURGED         | Data sudah dihapus              |

---

### 2.2 State Transitions

```
NOT_GRANTED → GRANTED → WITHDRAWN → PENDING_DELETE → PURGED
```

---

## 3. Consent Enforcement Rules

### 3.1 Global Rule

```
IF core consent NOT granted
    → BLOCK ALL FEATURES
```

---

### 3.2 Feature-Level Enforcement

| Feature             | Required Consent | Behavior jika tidak ada consent |
| ------------------- | ---------------- | ------------------------------- |
| Offline Map         | Location         | Feature disabled                |
| Panic Button        | Location + Push  | Cannot trigger                  |
| Virtual Muthawif    | Location         | Tidak muncul doa                |
| Photo Capture       | Photo            | Camera disabled                 |
| Photo Upload        | Photo            | Queue blocked                   |
| Broadcast Receive   | Push             | Tidak menerima notifikasi       |
| Marketing Broadcast | Marketing        | Tidak dikirim                   |

---

## 4. Consent Storage Model

### 4.1 Tables

#### user_consents

| Field            | Type      | Deskripsi            |
| ---------------- | --------- | -------------------- |
| user_id          | uuid      | FK ke profile        |
| location_consent | boolean   | GPS consent          |
| photo_consent    | boolean   | Media consent        |
| push_consent     | boolean   | Notification consent |
| granted_at       | timestamp | Waktu grant          |
| withdrawn_at     | timestamp | Waktu withdraw       |

---

#### marketing_preferences

| Field            | Type      | Deskripsi         |
| ---------------- | --------- | ----------------- |
| user_id          | uuid      | FK ke profile     |
| marketing_opt_in | boolean   | Broadcast consent |
| updated_at       | timestamp | Last update       |

---

## 5. Consent Capture Flow (Onboarding)

### 5.1 Steps

1. PDPL Notice Screen
2. Location Consent (mandatory)
3. Photo Consent (mandatory)
4. Push Notification Consent (mandatory)
5. Marketing Consent (optional)

---

### 5.2 Rules

* User tidak bisa skip core consent
* Consent harus explicit (checkbox + action)
* Tidak boleh pre-checked

---

## 6. Consent Withdrawal Flow

### 6.1 Trigger

User klik:
➡️ "Withdraw Consent & Delete Data"

---

### 6.2 System Behavior

1. Update DB → status WITHDRAWN
2. Revoke access (force logout / block)
3. Trigger deletion job
4. Clear local storage

---

### 6.3 Local Purge Scope

* Isar DB
* Offline maps
* Photo queue
* Tokens
* Cache

---

## 7. Data Deletion Policy (PDPL)

### 7.1 Immediate Deletion

* User request deletion
* Consent withdrawn

---

### 7.2 Scheduled Deletion

| Data           | TTL                      |
| -------------- | ------------------------ |
| GPS history    | 30 hari setelah trip_end |
| Marketing data | 365 hari                 |
| Photo metadata | mengikuti trip lifecycle |

---

### 7.3 Cron Job

```sql
DELETE FROM gps_tracks WHERE purge_at < NOW();
```

---

## 8. Offline Handling

### 8.1 Scenario

User withdraw consent saat offline

### 8.2 Behavior

* Queue deletion request
* Disable fitur sensitif
* Retry saat online

---

## 9. Edge Function Enforcement

Semua endpoint wajib:

```
IF consent NOT granted
    → return 403 CONSENT_REQUIRED
```

---

## 10. Error Mapping

| Code              | Condition         | Message                               |
| ----------------- | ----------------- | ------------------------------------- |
| CONSENT_REQUIRED  | Consent belum ada | "Izinkan akses untuk melanjutkan"     |
| CONSENT_WITHDRAWN | Sudah ditarik     | "Anda telah menonaktifkan akses data" |

---

## 11. Security & Compliance Guarantees

* Semua consent tercatat (audit trail)
* Tidak ada implicit consent
* Data tidak diproses tanpa izin
* User bisa withdraw kapan saja
* Data dihapus sesuai PDPL

---

## 12. Key Design Decisions

1. Consent dipisah antara core & marketing
2. Consent menjadi gate utama fitur
3. Withdrawal = hard stop (bukan soft)
4. Offline tetap menghormati consent
5. Backend selalu enforce (bukan hanya UI)

---

## Penutup (Architect Note)

Consent di Haramain Pro bukan sekadar legal requirement.

Ini adalah:

* Trust system
* Data control layer
* Compliance backbone

Jika implementasi ini konsisten:

* Risiko legal rendah
* UX tetap aman
* Data lifecycle terkontrol penuh
