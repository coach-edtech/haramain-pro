# rls-model.md

## Overview

Dokumen ini mendefinisikan **Row Level Security (RLS) Model** untuk Haramain Pro.

Tujuan:

* Menjamin **isolasi data antar agency (multi-tenant)**
* Menjadi **enforcement layer utama authorization** di backend
* Menghilangkan ketergantungan pada trust di client

RLS diimplementasikan di **Supabase PostgreSQL** dan menjadi satu-satunya mekanisme valid untuk akses data.

---

## 1. Core Principles

### 1.1 Zero Trust Client

* Client TIDAK dipercaya
* Semua akses divalidasi di database

---

### 1.2 Tenant Isolation

* Setiap agency = tenant
* Tidak boleh ada akses lintas agency

---

### 1.3 Role + Scope Based Access

Akses ditentukan oleh:

```
role + agency_id + rombongan_id
```

---

### 1.4 Deny by Default

* Semua tabel: RLS ENABLED
* Tanpa policy → NO ACCESS

---

## 2. JWT Claim Mapping

RLS membaca claim dari JWT:

```sql
current_setting('request.jwt.claims', true)::json
```

### 2.1 Helper Extraction

```sql
-- user id
(auth.uid())

-- role
(current_setting('request.jwt.claims.role', true))

-- agency_id
(current_setting('request.jwt.claims.agency_id', true))::uuid
```

---

## 3. Table-Level Security Model

### 3.1 profiles

#### SELECT

```sql
USING (
  id = auth.uid()
  OR (
    (current_setting('request.jwt.claims.role', true)) = 'travel_admin'
    AND agency_id = (current_setting('request.jwt.claims.agency_id', true))::uuid
  )
  OR (current_setting('request.jwt.claims.role', true)) = 'sys_admin'
)
```

#### UPDATE

```sql
USING (id = auth.uid())
```

---

### 3.2 rombongan

#### SELECT

```sql
USING (
  EXISTS (
    SELECT 1 FROM rombongan_members rm
    WHERE rm.user_id = auth.uid()
    AND rm.rombongan_id = rombongan.id
  )
  OR agency_id = (current_setting('request.jwt.claims.agency_id', true))::uuid
  OR (current_setting('request.jwt.claims.role', true)) = 'sys_admin'
)
```

#### INSERT

```sql
WITH CHECK (
  (current_setting('request.jwt.claims.role', true)) IN ('travel_admin', 'sys_admin')
)
```

---

### 3.3 rombongan_members

#### SELECT

```sql
USING (
  user_id = auth.uid()
  OR rombongan_id IN (
    SELECT rm.rombongan_id FROM rombongan_members rm
    WHERE rm.user_id = auth.uid()
  )
)
```

---

### 3.4 transactions

#### SELECT

```sql
USING (
  user_id = auth.uid()
  OR (current_setting('request.jwt.claims.role', true)) = 'sys_admin'
)
```

#### INSERT / UPDATE

❌ Tidak boleh dari client

✔ Hanya via Service Role (Edge Function)

---

### 3.5 jejak_ibadah_photos

#### SELECT

```sql
USING (
  rombongan_id IN (
    SELECT rm.rombongan_id FROM rombongan_members rm
    WHERE rm.user_id = auth.uid()
  )
  OR agency_id = (current_setting('request.jwt.claims.agency_id', true))::uuid
)
```

#### INSERT

```sql
WITH CHECK (
  uploaded_by = auth.uid()
)
```

---

### 3.6 user_consents

#### SELECT

```sql
USING (
  user_id = auth.uid()
  OR (current_setting('request.jwt.claims.role', true)) = 'sys_admin'
)
```

---

### 3.7 marketing_preferences

#### SELECT / UPDATE

```sql
USING (user_id = auth.uid())
```

---

## 4. Service Role Bypass

### 4.1 Principle

* Edge Functions menggunakan **Service Role Key**
* Bypass semua RLS

---

### 4.2 Allowed Operations

* Payment webhook update
* Photo watermark upload
* Panic alert dispatch
* Consent purge

---

### 4.3 Restriction

* Tidak boleh expose ke client
* Hanya di server-side

---

## 5. Cross-Tenant Protection

### 5.1 Rule

```
agency_id MUST match JWT claim
```

---

### 5.2 Enforcement

Semua query wajib filter:

```sql
agency_id = claim_agency_id
```

---

## 6. Rombongan Scope Enforcement

### 6.1 Rule

User hanya bisa akses data jika:

```
user ∈ rombongan_members
```

---

### 6.2 Example

```sql
EXISTS (
  SELECT 1 FROM rombongan_members
  WHERE user_id = auth.uid()
)
```

---

## 7. Role-Based Restrictions

### 7.1 Travel Admin

* Hanya agency sendiri

### 7.2 Muthawif

* Hanya rombongan yang dia kelola

### 7.3 Jamaah

* Hanya data pribadi + group

### 7.4 Sys Admin

* Full access

---

## 8. Common Attack Scenarios

### 8.1 Query Manipulation

❌ User inject WHERE condition

✔ RLS tetap enforce

---

### 8.2 ID Enumeration

❌ Tebak UUID

✔ Ditolak oleh RLS

---

### 8.3 Cross Agency Access

❌ Agency A akses Agency B

✔ Ditolak oleh policy

---

## 9. Testing Strategy

### 9.1 Tenant Isolation Test

* Login sebagai Agency A
* Query rombongan
* Assert: hanya data A

---

### 9.2 Negative Test

* Force query agency lain
* Assert: 0 rows

---

### 9.3 SQL Verification

```sql
SET role = 'authenticated';
SET request.jwt.claims = '{"agency_id": "A"}';

SELECT * FROM rombongan;
```

---

## 10. Performance Considerations

* Gunakan index pada:

  * agency_id
  * rombongan_id
  * user_id

* Hindari subquery berat tanpa index

---

## 11. Key Design Decisions

1. RLS = primary enforcement layer
2. Semua akses berbasis claim
3. Service Role untuk operasi sensitif
4. Deny by default
5. Multi-tenant isolation strict

---

## Penutup (Architect Note)

RLS bukan sekadar fitur keamanan.

Ini adalah:

* Boundary utama sistem
* Pelindung data user & agency
* Enforcement layer paling kritikal

Jika RLS benar:

* Data aman
* Compliance terjaga
* Scaling multi-tenant aman

Jika RLS salah:

* Data leak
* Legal risk
* Trust hancur
