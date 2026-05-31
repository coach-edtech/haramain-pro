---
title: Auth Role Model
filename: auth-role-model.md
---

# Auth Role Model – Haramain Pro

Dokumen ini production-ready dan dimaksudkan sebagai acuan langsung untuk pengembangan mobile, backend, Supabase RLS, dan Edge Functions.  
Format menggunakan sintaks Markdown standar (heading, tabel, dan code block) sehingga bisa langsung disimpan sebagai `auth-role-model.md` di repo Anda.[web:16]

## Overview

Dokumen ini mendefinisikan model otorisasi utama dalam sistem Haramain Pro, mencakup:

- Role definition
- JWT claim structure
- Access resolution engine
- Agency binding lifecycle
- Permission matrix (action-based)

Dokumen ini adalah single source of truth untuk:

- Mobile feature gating
- Web dashboard permissions
- Supabase RLS policies
- Edge Function authorization

## 1. Role Definition

### 1.1 Available Roles

| Role        | Deskripsi                           |
| ----------- | ----------------------------------- |
| `jamaah`    | End-user (pilgrim), default role    |
| `muthawif`  | Field leader, mengelola rombongan   |
| `travel_admin` | B2B agency operator             |
| `sys_admin` | Internal system operator            |

### 1.2 Role Boundaries

#### jamaah

Hak:

- Join rombongan via PIN
- Akses offline map & doa
- Trigger panic alert
- Consume broadcast

Batasan (tidak bisa):

- Create rombongan
- Broadcast
- Akses CRM

#### muthawif

Hak:

- Semua hak `jamaah`
- Broadcast itinerary
- Terima panic alert
- Capture & upload foto
- Generate group PIN

Batasan (tidak bisa):

- Akses semua data agency
- Manage licensing

#### travel_admin

Hak:

- Create & manage rombongan
- Assign muthawif
- B2B licensing (bulk)
- Akses CRM Jejak Ibadah
- Alumni broadcast

Batasan (tidak bisa):

- Override system-level config
- Access data agency lain

#### sys_admin

Hak:

- Full system access
- Override trial & subscription
- Global test mode
- Access semua data

## 2. JWT Claim Model

JWT digunakan sebagai source of truth **operasional** untuk authorization di Supabase RLS dan Edge Functions (carrier state).

### 2.1 Claim Structure

```json
{
  "sub": "user_id",
  "role": "jamaah | muthawif | travel_admin | sys_admin",
  "agency_id": "uuid | null",
  "rombongan_ids": ["uuid"],
  "subscription_tier": "free_trial | active | expired",
  "trial_ends_at": "timestamp | null",
  "is_b2b_active": true,
  "b2b_trip_end_at": "timestamp | null"
}
```

### 2.2 Claim Rules

- `agency_id`:
  - `null` untuk jamaah tanpa B2B
  - wajib untuk `muthawif` & `travel_admin`
- `rombongan_ids`:
  - bisa lebih dari satu
  - digunakan untuk filtering data (RLS + Edge)
- `is_b2b_active`:
  - `true` jika user join rombongan aktif (trip berjalan)

### 2.3 Claim Refresh

Claim direfresh via `refresh-claims` Edge Function.

Trigger utama:

- Login
- Join group
- Subscription update
- Trip expiration

## 3. Access Resolution Engine (CORE LOGIC)

Ini adalah aturan utama sistem untuk menentukan akses user.

### 3.1 Priority Order

Urutan prioritas state:

1. B2B Active (Trip-based)
2. B2C Paid (Lifetime)
3. Free Trial
4. Expired

### 3.2 Access Rules (Pseudocode)

```text
IF is_b2b_active = true AND now < b2b_trip_end_at
    → FULL ACCESS (override all)

ELSE IF subscription_tier = active
    → FULL ACCESS (lifetime)

ELSE IF now < trial_ends_at
    → LIMITED ACCESS

ELSE
    → BLOCKED (paywall)
```

### 3.3 Access Levels

| Level   | Description             |
| ------- | ----------------------- |
| `FULL`  | Semua fitur aktif       |
| `LIMITED` | Tanpa panic + offline map |
| `BLOCKED` | Paywall               |

## 4. Agency Binding Lifecycle

### 4.1 Binding Sources

User bisa terikat ke agency melalui:

- Join rombongan (via PIN)
- B2B license assignment
- Manual admin assignment

### 4.2 Lifecycle Flow

```text
UNBOUND → JOIN_GROUP → BOUND_ACTIVE → TRIP_COMPLETED → EXPIRED → UNBOUND
```

### 4.3 Rules

Binding aktif selama:

- `trip_start_at → trip_end_at`

Auto expire:

- 30 hari setelah `trip_end_at`

Multiple binding:

- DIDUKUNG (multi agency)

### 4.4 Post-Trip Behavior

| Condition    | Result                 |
| ------------ | ---------------------- |
| B2C paid     | retain full access     |
| Tidak bayar  | downgrade ke trial/expired |
| Data CRM     | tetap milik agency     |

## 5. Permission Matrix (Action-Based)

### 5.1 Core Actions

| Action                | Jamaah | Muthawif | Travel Admin | Sys Admin |
| --------------------- | :----: | :------: | :----------: | :-------: |
| Join Group            |  ✔     |    ✔     |      ✔       |    ✔      |
| Create Group          |  ✖     |    ✖     |      ✔       |    ✔      |
| Broadcast Message     |  ✖     |    ✔     |      ✔       |    ✔      |
| Panic Alert Trigger   |  ✔     |    ✔     |      ✔       |    ✔      |
| Receive Panic Alert   |  ✖     |    ✔     |      ✔       |    ✔      |
| Upload Photo          |  ✖     |    ✔     |      ✔       |    ✔      |
| View CRM Gallery      |  ✖     |    ✔     |      ✔       |    ✔      |
| Purchase B2C          |  ✔     |    ✔     |      ✔       |    ✔      |
| Purchase B2B License  |  ✖     |    ✖     |      ✔       |    ✔      |
| Override Trial        |  ✖     |    ✖     |      ✖       |    ✔      |
| Access All Data       |  ✖     |    ✖     |      ✖       |    ✔      |

## 6. Supabase RLS Mapping

### 6.1 Core Principle

Semua query ke database harus dibatasi berdasarkan:

- `auth.uid()`
- `agency_id`
- `rombongan_id`

### 6.2 Example Policy – Rombongan Access

```sql
USING (
  auth.uid() IN (
    SELECT user_id
    FROM rombongan_members
    WHERE rombongan_id = rombongan.id
  )
  OR agency_id = current_setting('request.jwt.claims.agency_id')::uuid
)
```

## 7. Edge Function Authorization

### 7.1 Required Checks

Semua Edge Function wajib melakukan:

- Validate JWT
- Check `role`
- Check `rombongan` scope
- Check access state (FULL/LIMITED/BLOCKED)

### 7.2 Example: Panic Alert

```text
IF role NOT IN ["jamaah", "muthawif"]
    → reject

IF rombongan_id NOT IN claims.rombongan_ids
    → reject
```

## 8. Failure Scenarios

| Scenario                             | Handling                 |
| ------------------------------------ | ------------------------ |
| Expired trip tapi masih akses        | Force refresh claims     |
| Multi-device mismatch                | Supabase realtime sync   |
| RLS bypass attempt                   | Reject via policy        |
| Claim stale                          | Re-fetch via Edge        |

## 9. Security Guarantees

- Zero cross-agency data leakage (RLS enforced)
- No client-side trust (semua verifikasi di server-side)
- Payment tidak bisa di-spoof (webhook only)
- Access terikat pada kombinasi: time + state + role

## 10. Key Design Decisions

- Access berbasis **state**, bukan hanya role
- B2B **selalu override** B2C
- Trip adalah unit utama kontrol akses
- JWT sebagai **carrier**, bukan ultimate source of truth
- RLS sebagai enforcement utama

## Penutup (Architect Note)

Ini bukan sekadar auth system.  
Ini adalah:

- Revenue protection system
- Data isolation system
- Experience control system

Kalau ini konsisten di semua layer:

- Dev akan cepat
- Bug minimal
- Scaling aman

Jika mau lanjut, langkah paling tepat berikutnya:

- `consent-matrix.md` (biar compliance nyambung ke auth), atau
- `rls-model.md` (biar langsung enforce ke DB)

Tinggal arahkan, saya lanjutkan.