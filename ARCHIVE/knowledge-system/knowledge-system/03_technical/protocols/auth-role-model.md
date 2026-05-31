# `auth-role-model.md`

## Overview

Dokumen ini mendefinisikan **model otorisasi utama** dalam sistem Haramain Pro, mencakup:

* Role definition
* JWT claim structure
* Access resolution engine
* Agency binding lifecycle
* Permission matrix (action-based)

Dokumen ini adalah **single source of truth** untuk:

* Mobile feature gating
* Web dashboard permissions
* Supabase RLS policies
* Edge Function authorization

---

## 1. Role Definition

### 1.1 Available Roles

| Role           | Deskripsi                         |
| -------------- | --------------------------------- |
| `jamaah`       | End-user (pilgrim), default role  |
| `muthawif`     | Field leader, mengelola rombongan |
| `travel_admin` | B2B agency operator               |
| `sys_admin`    | Internal system operator          |

---

### 1.2 Role Boundaries

#### `jamaah`

* Join rombongan via PIN
* Access offline map & doa
* Trigger panic alert
* Consume broadcast

❌ Tidak bisa:

* Create rombongan
* Broadcast
* Akses CRM

---

#### `muthawif`

* Semua hak `jamaah`
* Broadcast itinerary
* Terima panic alert
* Capture & upload foto
* Generate group PIN

❌ Tidak bisa:

* Akses semua data agency
* Manage licensing

---

#### `travel_admin`

* Create & manage rombongan
* Assign muthawif
* B2B licensing (bulk)
* Akses CRM Jejak Ibadah
* Alumni broadcast

❌ Tidak bisa:

* Override system-level config
* Access other agencies data

---

#### `sys_admin`

* Full system access
* Override trial & subscription
* Global test mode
* Access semua data

---

## 2. JWT Claim Model

JWT digunakan sebagai **source of truth untuk authorization di Supabase RLS dan Edge Functions**.

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

---

### 2.2 Claim Rules

* `agency_id`:

  * null untuk jamaah tanpa B2B
  * wajib untuk muthawif & travel_admin

* `rombongan_ids`:

  * bisa lebih dari satu
  * digunakan untuk filtering data

* `is_b2b_active`:

  * true jika user join rombongan aktif

---

### 2.3 Claim Refresh

* Dijalankan via `refresh-claims` Edge Function
* Trigger:

  * Login
  * Join group
  * Subscription update
  * Trip expiration

---

## 3. Access Resolution Engine (CORE LOGIC)

Ini adalah **aturan utama sistem** untuk menentukan akses user.

### 3.1 Priority Order

1. B2B Active (Trip-based)
2. B2C Paid (Lifetime)
3. Free Trial
4. Expired

---

### 3.2 Access Rules

```
IF is_b2b_active = true AND now < b2b_trip_end_at
    → FULL ACCESS (override all)

ELSE IF subscription_tier = active
    → FULL ACCESS (lifetime)

ELSE IF now < trial_ends_at
    → LIMITED ACCESS

ELSE
    → BLOCKED (paywall)
```

---

### 3.3 Access Levels

| Level   | Description               |
| ------- | ------------------------- |
| FULL    | Semua fitur aktif         |
| LIMITED | Tanpa panic + offline map |
| BLOCKED | Paywall                   |

---

## 4. Agency Binding Lifecycle

### 4.1 Binding Sources

User bisa terikat ke agency melalui:

1. Join rombongan (via PIN)
2. B2B license assignment
3. Manual admin assignment

---

### 4.2 Lifecycle Flow

```
UNBOUND → JOIN_GROUP → BOUND_ACTIVE → TRIP_COMPLETED → EXPIRED → UNBOUND
```

---

### 4.3 Rules

* Binding aktif selama:

  * `trip_start_at` → `trip_end_at`

* Auto expire:

  * 30 hari setelah `trip_end_at`

* Multiple binding:

  * DIDUKUNG (multi agency)

---

### 4.4 Post-Trip Behavior

| Condition   | Result                     |
| ----------- | -------------------------- |
| B2C paid    | retain full access         |
| Tidak bayar | downgrade ke trial/expired |
| Data CRM    | tetap milik agency         |

---

## 5. Permission Matrix (Action-Based)

### 5.1 Core Actions

| Action               | Jamaah | Muthawif | Travel Admin | Sys Admin |
| -------------------- | ------ | -------- | ------------ | --------- |
| Join Group           | ✔      | ✔        | ✔            | ✔         |
| Create Group         | ✖      | ✖        | ✔            | ✔         |
| Broadcast Message    | ✖      | ✔        | ✔            | ✔         |
| Panic Alert Trigger  | ✔      | ✔        | ✔            | ✔         |
| Receive Panic Alert  | ✖      | ✔        | ✔            | ✔         |
| Upload Photo         | ✖      | ✔        | ✔            | ✔         |
| View CRM Gallery     | ✖      | ✔        | ✔            | ✔         |
| Purchase B2C         | ✔      | ✔        | ✔            | ✔         |
| Purchase B2B License | ✖      | ✖        | ✔            | ✔         |
| Override Trial       | ✖      | ✖        | ✖            | ✔         |
| Access All Data      | ✖      | ✖        | ✖            | ✔         |

---

## 6. Supabase RLS Mapping

### 6.1 Core Principle

* Semua query harus berbasis:

  * `auth.uid()`
  * `agency_id`
  * `rombongan_id`

---

### 6.2 Example Policy

#### Rombongan Access

```sql
USING (
  auth.uid() IN (
    SELECT user_id FROM rombongan_members
    WHERE rombongan_id = rombongan.id
  )
  OR agency_id = current_setting('request.jwt.claims.agency_id')::uuid
)
```

---

## 7. Edge Function Authorization

### 7.1 Required Checks

Semua Edge Function wajib:

1. Validate JWT
2. Check role
3. Check rombongan scope
4. Check access state

---

### 7.2 Example: Panic Alert

```ts
IF role NOT IN ["jamaah", "muthawif"]
    → reject

IF rombongan_id NOT IN claims.rombongan_ids
    → reject
```

---

## 8. Failure Scenarios

| Scenario                      | Handling               |
| ----------------------------- | ---------------------- |
| Expired trip tapi masih akses | Force refresh claims   |
| Multi-device mismatch         | Supabase realtime sync |
| RLS bypass attempt            | Reject via policy      |
| Claim stale                   | Re-fetch via Edge      |

---

## 9. Security Guarantees

* Zero cross-agency data leakage (RLS enforced)
* No client-side trust (all verified server-side)
* Payment cannot be spoofed (webhook only)
* Access tied to time + state + role

---

## 10. Key Design Decisions

1. **Access berbasis state, bukan role saja**
2. **B2B selalu override B2C**
3. **Trip adalah unit utama kontrol akses**
4. **JWT sebagai carrier, bukan source of truth**
5. **RLS sebagai enforcement utama**

---

## Penutup (Architect Note)

Ini bukan sekadar auth system.

Ini adalah:
👉 Revenue protection system
👉 Data isolation system
👉 Experience control system

Kalau ini konsisten di semua layer:

* Dev akan cepat
* Bug minimal
* Scaling aman

---