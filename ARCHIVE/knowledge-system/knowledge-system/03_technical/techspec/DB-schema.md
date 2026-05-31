# Tech Spec: Database Schema Reference

_Source: PRD v1.10-FINAL Section 10.2_
_Status: COMPLETE — All tables defined_

---

## Schema Overview

All tables use Supabase PostgreSQL. RLS policies enforce data isolation per `travel_id`.

---

## Core Tables

### `users`

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE,
  phone VARCHAR(20) UNIQUE,
  name VARCHAR(255) NOT NULL,
  role VARCHAR(20) NOT NULL,
  -- 'jamaah' | 'muthawif' | 'travel_admin' | 'support' | 'super_admin'
  travel_id UUID REFERENCES travels(id),
  is_active BOOLEAN DEFAULT TRUE,
  last_login_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### `travels`

```sql
CREATE TABLE travels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(100) UNIQUE,
  logo_url TEXT,
  brand_color VARCHAR(7),
  tier VARCHAR(20) DEFAULT 'independent',
  -- 'independent' | 'small' | 'medium' | 'enterprise'
  is_white_label BOOLEAN DEFAULT FALSE,
  wl_subdomain VARCHAR(100),
  is_approved BOOLEAN DEFAULT FALSE,
  ppiu_license_number VARCHAR(100),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### `rombongan`

```sql
CREATE TABLE rombongan (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  travel_id UUID REFERENCES travels(id),
  name VARCHAR(255) NOT NULL,
  invite_code VARCHAR(10) UNIQUE,
  departure_date DATE,
  return_date DATE,
  muthawif_id UUID REFERENCES users(id),
  status VARCHAR(20) DEFAULT 'pending',
  -- 'pending' | 'active' | 'completed'
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### `rombongan_members`

```sql
CREATE TABLE rombongan_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rombongan_id UUID REFERENCES rombongan(id),
  user_id UUID REFERENCES users(id),
  invitation_status VARCHAR(20) DEFAULT 'pending',
  -- 'pending' | 'accepted' | 'declined' | 'expired'
  invitation_sent_at TIMESTAMPTZ,
  invitation_expires_at TIMESTAMPTZ,
  joined_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(rombongan_id, user_id)
);
```

### `trips`

```sql
CREATE TABLE trips (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rombongan_id UUID REFERENCES rombongan(id),
  user_id UUID REFERENCES users(id),
  departure_date DATE NOT NULL,
  return_date DATE NOT NULL,
  status VARCHAR(20) DEFAULT 'upcoming',
  -- 'upcoming' | 'active' | 'completed'
  panic_enabled BOOLEAN DEFAULT FALSE,
  panic_enabled_at TIMESTAMPTZ,
  panic_disabled_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## Safety Pass & Payments

### `safety_pass`

```sql
CREATE TABLE safety_pass (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) UNIQUE,
  purchased_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  -- NULL = lifetime
  status VARCHAR(20) DEFAULT 'active',
  -- 'active' | 'expired' | 'cancelled'
  payment_id UUID REFERENCES payments(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### `payments`

```sql
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  travel_id UUID REFERENCES travels(id),
  amount INTEGER NOT NULL,
  -- in rupiah
  currency VARCHAR(3) DEFAULT 'IDR',
  status VARCHAR(20) DEFAULT 'pending',
  -- 'pending' | 'completed' | 'failed' | 'refunded'
  midtrans_order_id VARCHAR(100),
  midtrans_transaction_id VARCHAR(100),
  payment_type VARCHAR(50),
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### `seat_licenses`

```sql
CREATE TABLE seat_licenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  travel_id UUID REFERENCES travels(id),
  quantity INTEGER NOT NULL,
  purchased_at TIMESTAMPTZ DEFAULT NOW(),
  payment_id UUID REFERENCES payments(id),
  expires_at TIMESTAMPTZ,
  status VARCHAR(20) DEFAULT 'active',
  -- 'active' | 'used' | 'expired'
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### `license_usages`

```sql
CREATE TABLE license_usages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seat_license_id UUID REFERENCES seat_licenses(id),
  user_id UUID REFERENCES users(id),
  used_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## Panic Alert

### `panic_alerts`

```sql
CREATE TABLE panic_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  trip_id UUID REFERENCES trips(id),
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  status VARCHAR(20) DEFAULT 'pending',
  -- 'pending' | 'responded' | 'resolved' | 'expired'
  response_type VARCHAR(20),
  -- 'stay' | 'here'
  responder_id UUID REFERENCES users(id),
  responder_location_lat DECIMAL(10, 8),
  responder_location_lng DECIMAL(11, 8),
  responded_at TIMESTAMPTZ,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## Content & Media

### `informasi_umrah`

```sql
CREATE TABLE informasi_umrah (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(255) NOT NULL,
  content_type VARCHAR(20) NOT NULL,
  -- 'video' | 'audio' | 'text'
  content_url TEXT NOT NULL,
  thumbnail_url TEXT,
  description TEXT,
  created_by UUID REFERENCES users(id),
  is_published BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### `informasi_umrah_views`

```sql
CREATE TABLE informasi_umrah_views (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  informasi_id UUID REFERENCES informasi_umrah(id),
  user_id UUID REFERENCES users(id),
  viewed_at TIMESTAMPTZ DEFAULT NOW()
);
```

### `photos`

```sql
CREATE TABLE photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  travel_id UUID REFERENCES travels(id),
  storage_path TEXT NOT NULL,
  width INTEGER,
  height INTEGER,
  taken_at TIMESTAMPTZ,
  location_lat DECIMAL(10, 8),
  location_lng DECIMAL(11, 8),
  watermark_applied BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### `album_photos`

```sql
CREATE TABLE album_photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  album_id UUID REFERENCES albums(id),
  photo_id UUID REFERENCES photos(id),
  position INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### `albums`

```sql
CREATE TABLE albums (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rombongan_id UUID REFERENCES rombongan(id),
  name VARCHAR(255),
  cover_photo_id UUID REFERENCES photos(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## Invitations & Referrals

### `invitations`

```sql
CREATE TABLE invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
 rombongan_id UUID REFERENCES rombongan(id),
  invite_code VARCHAR(10) UNIQUE,
  max_uses INTEGER,
  uses_count INTEGER DEFAULT 0,
  expires_at TIMESTAMPTZ,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### `referrals`

```sql
CREATE TABLE referrals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_id UUID REFERENCES users(id),
  referred_id UUID REFERENCES users(id),
  referral_code VARCHAR(20) NOT NULL,
  converted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## Support & Notifications

### `notifications`

```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  title VARCHAR(255) NOT NULL,
  body TEXT,
  data JSONB,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### `panic_alert_responses`

```sql
CREATE TABLE panic_alert_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alert_id UUID REFERENCES panic_alerts(id),
  responder_id UUID REFERENCES users(id),
  response_type VARCHAR(20) NOT NULL,
  location_lat DECIMAL(10, 8),
  location_lng DECIMAL(11, 8),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## Audit & Security

### `audit_logs`

```sql
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID,
  action VARCHAR(100) NOT NULL,
  target_table VARCHAR(50),
  target_id UUID,
  metadata JSONB,
  ip_address INET,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### `test_codes`

```sql
CREATE TABLE test_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code VARCHAR(20) UNIQUE NOT NULL,
  use_case VARCHAR(20) NOT NULL,
  -- 'sales_demo' | 'travel_trial'
  sales_agent_id UUID REFERENCES users(id),
  travel_id UUID REFERENCES travels(id),
  is_full_premium_access BOOLEAN DEFAULT TRUE,
  is_used BOOLEAN DEFAULT FALSE,
  used_by UUID REFERENCES users(id),
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## RLS Policies (Summary)

All tables with `travel_id` column enforce:

```sql
-- Users can only see their own travel's data
CREATE POLICY "travel_isolation" ON table_name
  FOR ALL
  USING (travel_id = auth.jwt() ->> 'travel_id');
```

For `panic_alerts`: Support role can read ALL alerts. Muthawif can read alerts where `trip_id` matches their `rombongan_id`.

---

_Maintained by: Hermes (CTO)_
_Last Updated: 2026-05-02 (v1.10-FINAL)_
