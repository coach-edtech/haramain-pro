# Schema Conflicts Analysis — trd.md vs schema-overview.md

## Date: 2026-04-27
## Sources:
- `docs/paraflow-product-docs/paraflow/Feature Plan/trd.md`
- `knowledge-system/03_technical/data-model/schema-overview.md`

## Status: RESOLVED
**Decision: schema-overview.md is authoritative. trd.md is for reference only.**

---

## Summary of Conflicts

| Aspect | schema-overview.md (AUTHORITY) | trd.md (Paraflow - Reference Only) |
|--------|-------------------------------|-------------------------------------|
| **Table naming** | `profiles` | `users` |
| **Auth integration** | References `auth.users(id)` | Separate `users` table |
| **Roles** | `jamaah`, `muthawif`, `travel_admin`, `sys_admin` | `pilgrim`, `muthawif`, `agency`, `admin` |
| **Subscription tiers** | `free_trial`, `active`, `expired` | `free`, `premium`, `b2b_group` |
| **Consent storage** | Separate tables: `user_consents`, `marketing_preferences` | Combined in `users` table |
| **Transaction tables** | Single `transactions` table | Split: `b2c_transactions`, `license_purchases` |
| **Group tables** | `rombongan`, `rombongan_members` | `umrah_packages`, `package_members` |
| **Photo table** | `photos` (simple) | `jejak_ibadah_photos` (with watermarked URLs) |
| **GPS table** | `gps_tracks` (simple) | `gps_tracking_history` (with altitude, accuracy, purge_after) |
| **Additional tables** | — | `agencies`, `geofence_prayers`, `itinerary_broadcasts` |
| **Backend style** | Supabase (Edge Functions) | NestJS/Prisma |

---

## Detailed Conflict Analysis

### 1. Core User Table

**schema-overview.md (CORRECT):**
```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  role TEXT NOT NULL CHECK (role IN ('jamaah','muthawif','travel_admin','sys_admin')),
  agency_id UUID NULL,
  subscription_tier TEXT NOT NULL CHECK (subscription_tier IN ('free_trial','active','expired')),
  ...
);
```

**trd.md (REFERENCE ONLY - Wrong for Supabase):**
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  role VARCHAR(20) CHECK (role IN ('pilgrim', 'muthawif', 'agency', 'admin')),
  subscription_tier VARCHAR(20) DEFAULT 'free' CHECK (subscription_tier IN ('free', 'premium', 'b2b_group')),
  ...
);
```

**Resolution:** schema-overview.md is correct. Supabase uses `auth.users` for authentication, so profiles table references it. Role names in trd.md are semantically different.

---

### 2. Consent Management

**schema-overview.md (CORRECT):**
- `user_consents` — PDPL consent flags (location, photo, notification, pdpl)
- `marketing_preferences` — Separate table for marketing opt-in
- Separate tables enforce that withdrawal of one doesn't affect the other

**trd.md (Missing proper separation):**
- Combined consent fields in `users` table
- Does not have separate `marketing_preferences` table

**Resolution:** schema-overview.md is correct. PDPL requires strict separation.

---

### 3. Transaction Tables

**schema-overview.md (CORRECT):**
```sql
CREATE TABLE transactions (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  midtrans_order_id TEXT UNIQUE NOT NULL,
  status TEXT CHECK (status IN ('pending','settlement','expire','cancel')),
  amount INTEGER NOT NULL,
  ...
);
```
Single table handles both B2C and B2B via `amount` field differentiation.

**trd.md (Over-engineered):**
- `b2c_transactions` — separate table
- `license_purchases` — separate table with agency_id, quantity, discount calculations

**Resolution:** schema-overview.md is correct. Single transaction table is simpler and sufficient.

---

### 4. Group/Rombongan Tables

**schema-overview.md (AUTHORITY):**
- `rombongan` — group/trip entity
- `rombongan_members` — membership join table

**trd.md (Different naming):**
- `umrah_packages` — same concept, different name
- `package_members` — same concept, different name

**Resolution:** schema-overview.md naming (`rombongan`) is Arabic/Indonesian appropriate.

---

### 5. Photo Storage

**schema-overview.md (CORRECT):**
```sql
CREATE TABLE photos (
  id UUID PRIMARY KEY,
  client_photo_id UUID UNIQUE NOT NULL,
  user_id UUID NOT NULL,
  rombanngan_id UUID NOT NULL,
  storage_path TEXT NOT NULL,
  hash_sha256 TEXT NOT NULL,
  processed BOOLEAN DEFAULT FALSE,
  ...
);
```
Storage path is stored; watermark URLs are generated server-side.

**trd.md (REFERENCE):**
- `jejak_ibadah_photos` has `original_url`, `compressed_url`, `watermarked_url` as columns
- This is appropriate for S3-based storage

**Resolution:** Both approaches valid. schema-overview.md approach defers URL generation to processing time.

---

### 6. GPS Tracking

**schema-overview.md (CORRECT - Minimal):**
```sql
CREATE TABLE gps_tracks (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  rombanngan_id UUID NOT NULL,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  recorded_at TIMESTAMPTZ,
  ...
);
```

**trd.md (More fields):**
```sql
CREATE TABLE gps_tracking_history (
  ...
  latitude DECIMAL(10,8),
  longitude DECIMAL(11,8),
  accuracy DECIMAL(8,2),
  altitude DECIMAL(8,2),
  purge_after TIMESTAMP,  -- PDPL 30-day auto-purge
  ...
);
```

**Resolution:** trd.md has better fields for GPS (altitude, accuracy for pilgrim safety tracking). Consider adding to schema-overview.md.

---

### 7. Missing Tables in schema-overview.md

**trd.md has tables that schema-overview.md doesn't:**

| Table | Purpose | Add to schema? |
|-------|---------|----------------|
| `agencies` | B2B travel agency details | YES — needed for B2B flow |
| `geofence_prayers` | Sacred location coordinates + prayer content | YES — needed for F04 Virtual Muthawif |
| `itinerary_broadcasts` | Muthawif broadcasts to group members | NO — can be derived from existing tables |

**Resolution:** Add `agencies` and `geofence_prayers` tables to schema-overview.md.

---

## Recommended Actions

### 1. IMMEDIATE — Add Missing Tables

Add to `schema-overview.md`:

```sql
-- agencies table (from trd.md, ADAPTED for Supabase)
CREATE TABLE agencies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id),
  agency_name TEXT NOT NULL,
  ppiu_license_number TEXT UNIQUE NOT NULL,
  logo_storage_path TEXT,
  total_seats_purchased INTEGER DEFAULT 0,
  seats_used INTEGER DEFAULT 0,
  seats_available INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- geofence_prayers table (from trd.md)
CREATE TABLE geofence_prayers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  location_name TEXT NOT NULL,
  location_name_ar TEXT,
  center_lat DOUBLE PRECISION NOT NULL,
  center_lng DOUBLE PRECISION NOT NULL,
  radius_meters INTEGER NOT NULL,
  prayer_text_ar TEXT NOT NULL,
  prayer_text_latin TEXT NOT NULL,
  prayer_text_id TEXT NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 2. GPS Enhancement

Consider adding `accuracy` and `altitude` fields to `gps_tracks` table for better location quality tracking.

---

## Conclusion

**schema-overview.md is the AUTHORITATIVE schema for Haramain Pro.**

The trd.md schema was generated by Paraflow assuming a NestJS/Prisma backend, not Supabase. The conflicts above do not indicate errors in schema-overview.md — they indicate that trd.md should not be used as the implementation reference.

**Use trd.md for:**
- API endpoint specifications (already in separate section)
- File structure reference
- Implementation timeline reference

**DO NOT use trd.md for:**
- Database schema implementation
- Backend architecture decisions
