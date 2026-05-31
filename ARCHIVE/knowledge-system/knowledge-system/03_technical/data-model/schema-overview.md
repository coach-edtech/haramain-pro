# Schema Overview — Haramain Pro (HARDENED FULL)

Version: 2.1  
Status: PRODUCTION-GRADE DATA MODEL (FINAL)  
Authority: MUST align with SYSTEM_BLUEPRINT.md  

---

## 1. DESIGN PRINCIPLES

### 1.1 Non-Negotiable Rules

- ALL tables MUST have:
  - id (UUID PRIMARY KEY)
  - created_at (TIMESTAMPTZ, UTC)
- ALL access MUST be enforced by RLS
- ALL timestamps MUST use UTC
- NO boolean for business state → use ENUM/TEXT CHECK
- ALL critical tables MUST include:
  - user_id OR agency_id OR rombongan_id
- ALL writes MUST go through Edge Functions (service role)

---

## 2. EXTENSIONS

```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

---

## 3. CORE TABLES

---

## 3.1 profiles

```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),

  role TEXT NOT NULL CHECK (role IN ('jamaah','muthawif','travel_admin','sys_admin')),
  agency_id UUID NULL,
  is_admin BOOLEAN DEFAULT FALSE,

  subscription_tier TEXT NOT NULL CHECK (subscription_tier IN ('free_trial','active','expired')),
  trial_ends_at TIMESTAMPTZ NULL,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

RULES:
- role MUST NOT be set from client
- is_admin ONLY via direct DB or secure admin path

---

## 3.2 user_consents

```sql
CREATE TABLE user_consents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id),

  pdpl_consent_granted BOOLEAN NOT NULL,
  location_consent_granted BOOLEAN NOT NULL,
  photo_consent_granted BOOLEAN NOT NULL,
  notification_consent_granted BOOLEAN NOT NULL,

  consent_version TEXT NOT NULL,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 3.3 marketing_preferences

```sql
CREATE TABLE marketing_preferences (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id),

  marketing_consent_granted BOOLEAN NOT NULL DEFAULT FALSE,

  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 3.4 rombongan

```sql
CREATE TABLE rombongan (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  agency_id UUID NOT NULL,
  muthawif_id UUID NOT NULL REFERENCES profiles(id),

  trip_start_at TIMESTAMPTZ NOT NULL,
  trip_end_at TIMESTAMPTZ NOT NULL,

  created_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT valid_trip CHECK (trip_start_at < trip_end_at)
);
```

---

## 3.5 rombongan_members

```sql
CREATE TABLE rombongan_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  rombongan_id UUID NOT NULL REFERENCES rombongan(id),
  user_id UUID NOT NULL REFERENCES profiles(id),

  role TEXT NOT NULL CHECK (role IN ('member','muthawif')),

  joined_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE (rombongan_id, user_id)
);
```

---

## 3.6 panic_alerts

```sql
CREATE TABLE panic_alerts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  user_id UUID NOT NULL,
  rombongan_id UUID NOT NULL,

  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,

  delivery_layer TEXT CHECK (delivery_layer IN ('FCM','TWILIO')),
  fallback_used BOOLEAN DEFAULT FALSE,
  failure_reason TEXT NULL,

  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 3.7 transactions

```sql
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  user_id UUID NOT NULL,
  midtrans_order_id TEXT UNIQUE NOT NULL,

  status TEXT NOT NULL CHECK (status IN ('pending','settlement','expire','cancel')),
  amount INTEGER NOT NULL,

  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 3.8 gps_tracks

```sql
CREATE TABLE gps_tracks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  user_id UUID NOT NULL,
  rombongan_id UUID NOT NULL,

  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,

  recorded_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 3.9 photos

```sql
CREATE TABLE photos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  client_photo_id UUID UNIQUE NOT NULL,

  user_id UUID NOT NULL,
  rombongan_id UUID NOT NULL,

  storage_path TEXT NOT NULL,
  hash_sha256 TEXT NOT NULL,

  processed BOOLEAN DEFAULT FALSE,

  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 4. INDEX STRATEGY

```sql
CREATE INDEX idx_members_user ON rombongan_members(user_id);
CREATE INDEX idx_members_group ON rombongan_members(rombongan_id);

CREATE INDEX idx_photos_group ON photos(rombongan_id);

CREATE INDEX idx_gps_user_time ON gps_tracks(user_id, recorded_at);
```

---

## 5. RLS BASELINE

```sql
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE rombongan ENABLE ROW LEVEL SECURITY;
ALTER TABLE rombongan_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_consents ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE gps_tracks ENABLE ROW LEVEL SECURITY;
ALTER TABLE photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE panic_alerts ENABLE ROW LEVEL SECURITY;
```

RULE:
- DEFAULT DENY
- explicit policies required

---

## 6. DATA RETENTION POLICY

| Table | TTL | Enforcement |
|------|-----|------------|
| gps_tracks | 30 days | pg_cron |
| panic_alerts | 1 year | pg_cron |
| transactions | 7 years | compliance |
| photos | 2 years | scheduled job |

---

## 7. SECURITY RULES

- NO direct client insert for sensitive tables
- ALL writes MUST go through Edge (service role)
- NO JSONB for permission logic
- NO dynamic schema fields

---

## 8. FINAL RULE

Schema is the FOUNDATION of system integrity.

If schema is wrong:
→ all higher layers will fail
