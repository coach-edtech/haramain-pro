-- Migration 007: Refactoring Schema Completion
-- Adds columns to panic_alerts, creates panic_responses, agencies, geofence_prayers, seat_licenses, marketing_preferences

-- Add columns to panic_alerts
ALTER TABLE panic_alerts ADD COLUMN IF NOT EXISTS response_type VARCHAR(20) DEFAULT NULL;
ALTER TABLE panic_alerts ADD COLUMN IF NOT EXISTS responder_location_lat DECIMAL(10,8) DEFAULT NULL;
ALTER TABLE panic_alerts ADD COLUMN IF NOT EXISTS responder_location_lng DECIMAL(11,8) DEFAULT NULL;
ALTER TABLE panic_alerts ADD COLUMN IF NOT EXISTS accuracy DECIMAL(10,2) DEFAULT NULL;
ALTER TABLE panic_alerts ADD COLUMN IF NOT EXISTS altitude DECIMAL(10,2) DEFAULT NULL;
ALTER TABLE panic_alerts ADD COLUMN IF NOT EXISTS message TEXT DEFAULT NULL;

-- Create panic_responses table
CREATE TABLE IF NOT EXISTS panic_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  panic_alert_id UUID REFERENCES panic_alerts(id) ON DELETE CASCADE,
  responder_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  response_type VARCHAR(20),
  responder_location_lat DECIMAL(10,8),
  responder_location_lng DECIMAL(11,8),
  responded_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create agencies table
CREATE TABLE IF NOT EXISTS agencies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  address TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create geofence_prayers table
CREATE TABLE IF NOT EXISTS geofence_prayers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  latitude DECIMAL(10,8) NOT NULL,
  longitude DECIMAL(11,8) NOT NULL,
  radius_meters INTEGER DEFAULT 100,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create seat_licenses table
CREATE TABLE IF NOT EXISTS seat_licenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agency_id UUID REFERENCES agencies(id) ON DELETE CASCADE,
  romongan_id UUID,
  license_key VARCHAR(100),
  valid_until TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create marketing_preferences table
CREATE TABLE IF NOT EXISTS marketing_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  email_subscribe BOOLEAN DEFAULT true,
  push_enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for new tables
CREATE INDEX IF NOT EXISTS idx_panic_responses_panic_alert_id ON panic_responses(panic_alert_id);
CREATE INDEX IF NOT EXISTS idx_panic_responses_responder_id ON panic_responses(responder_id);
CREATE INDEX IF NOT EXISTS idx_agencies_name ON agencies(name);
CREATE INDEX IF NOT EXISTS idx_geofence_prayers_name ON geofence_prayers(name);
CREATE INDEX IF NOT EXISTS idx_seat_licenses_agency_id ON seat_licenses(agency_id);
CREATE INDEX IF NOT EXISTS idx_seat_licenses_romongan_id ON seat_licenses(romongan_id);
CREATE INDEX IF NOT EXISTS idx_marketing_preferences_profile_id ON marketing_preferences(profile_id);
