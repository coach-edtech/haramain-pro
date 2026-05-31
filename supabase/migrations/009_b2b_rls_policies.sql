-- Migration 009: B2B RLS Policies (self-contained)
-- Creates B2B tables if not exist, then adds RLS policies.
-- PostgreSQL 14 compatible (no CREATE POLICY IF NOT EXISTS)

-- ============================================================
-- agencies table first (needed by profiles.agency_id FK)
-- ============================================================
CREATE TABLE IF NOT EXISTS agencies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  address TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- Add agency_id to profiles if not exists
-- ============================================================
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'agency_id') THEN
    ALTER TABLE profiles ADD COLUMN agency_id UUID;
  END IF;
END
$$;

-- Add FK constraint separately (after agencies table exists)
-- First, NULL out any agency_id that points to a non-existent agency
UPDATE profiles SET agency_id = NULL
WHERE agency_id IS NOT NULL
AND agency_id NOT IN (SELECT id FROM agencies);

DO $$
BEGIN
  ALTER TABLE profiles ADD CONSTRAINT profiles_agency_id_fkey
    FOREIGN KEY (agency_id) REFERENCES agencies(id) ON DELETE SET NULL;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END
$$;

-- ============================================================
-- seat_licenses table
-- ============================================================
CREATE TABLE IF NOT EXISTS seat_licenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agency_id UUID,
  romongan_id UUID,
  license_key VARCHAR(100),
  valid_until TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add FK agency_id constraint (idempotent)
DO $$
BEGIN
  ALTER TABLE seat_licenses ADD CONSTRAINT seat_licenses_agency_id_fkey
    FOREIGN KEY (agency_id) REFERENCES agencies(id) ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL;
END
$$;

-- ============================================================
-- panic_responses table
-- ============================================================
CREATE TABLE IF NOT EXISTS panic_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  panic_alert_id UUID,
  responder_id UUID,
  response_type VARCHAR(20),
  responder_location_lat DECIMAL(10,8),
  responder_location_lng DECIMAL(11,8),
  responded_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add FK constraints for panic_responses (idempotent)
DO $$
BEGIN
  ALTER TABLE panic_responses ADD CONSTRAINT panic_responses_panic_alert_id_fkey
    FOREIGN KEY (panic_alert_id) REFERENCES panic_alerts(id) ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL;
END
$$;

DO $$
BEGIN
  ALTER TABLE panic_responses ADD CONSTRAINT panic_responses_responder_id_fkey
    FOREIGN KEY (responder_id) REFERENCES profiles(id) ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL;
END
$$;

-- ============================================================
-- geofence_prayers table
-- ============================================================
CREATE TABLE IF NOT EXISTS geofence_prayers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  latitude DECIMAL(10,8) NOT NULL,
  longitude DECIMAL(11,8) NOT NULL,
  radius_meters INTEGER DEFAULT 100,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- marketing_preferences table
-- Use DROP+CREATE to ensure clean schema (handles partial/missing columns)
-- ============================================================
DROP TABLE IF EXISTS marketing_preferences;
CREATE TABLE marketing_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  email_subscribe BOOLEAN DEFAULT true,
  push_enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- agencies RLS
-- ============================================================
ALTER TABLE agencies ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "agencies_public_read" ON agencies;
CREATE POLICY "agencies_public_read" ON agencies
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "agencies_admin_write" ON agencies;
CREATE POLICY "agencies_admin_write" ON agencies
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

-- ============================================================
-- seat_licenses RLS
-- ============================================================
ALTER TABLE seat_licenses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "seat_licenses_travel_read" ON seat_licenses;
CREATE POLICY "seat_licenses_travel_read" ON seat_licenses
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM agencies a
      JOIN profiles p ON p.agency_id = a.id
      WHERE a.id = seat_licenses.agency_id
      AND p.id = auth.uid()
      AND p.role IN ('travel_admin', 'super_admin', 'admin_haramain_pro')
    )
  );

DROP POLICY IF EXISTS "seat_licenses_travel_insert" ON seat_licenses;
CREATE POLICY "seat_licenses_travel_insert" ON seat_licenses
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.role = 'travel_admin'
      AND p.agency_id = seat_licenses.agency_id
    )
    OR
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.role IN ('super_admin', 'admin_haramain_pro')
    )
  );

DROP POLICY IF EXISTS "seat_licenses_admin_update" ON seat_licenses;
CREATE POLICY "seat_licenses_admin_update" ON seat_licenses
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.role IN ('super_admin', 'admin_haramain_pro')
    )
  );

-- ============================================================
-- panic_responses RLS
-- ============================================================
ALTER TABLE panic_responses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "panic_responses_travel_read" ON panic_responses;
CREATE POLICY "panic_responses_travel_read" ON panic_responses
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.role IN ('muthawif', 'team_support', 'travel_admin', 'super_admin', 'admin_haramain_pro')
    )
  );

DROP POLICY IF EXISTS "panic_responses_travel_insert" ON panic_responses;
CREATE POLICY "panic_responses_travel_insert" ON panic_responses
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.role IN ('muthawif', 'team_support', 'travel_admin', 'super_admin', 'admin_haramain_pro')
    )
  );

-- ============================================================
-- geofence_prayers RLS
-- ============================================================
ALTER TABLE geofence_prayers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "geofence_prayers_public_read" ON geofence_prayers;
CREATE POLICY "geofence_prayers_public_read" ON geofence_prayers
  FOR SELECT USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "geofence_prayers_admin_write" ON geofence_prayers;
CREATE POLICY "geofence_prayers_admin_write" ON geofence_prayers
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

-- ============================================================
-- marketing_preferences RLS
-- ============================================================
ALTER TABLE marketing_preferences ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "marketing_prefs_self_read" ON marketing_preferences;
CREATE POLICY "marketing_prefs_self_read" ON marketing_preferences
  FOR SELECT USING (profile_id = auth.uid());

DROP POLICY IF EXISTS "marketing_prefs_self_update" ON marketing_preferences;
CREATE POLICY "marketing_prefs_self_update" ON marketing_preferences
  FOR UPDATE USING (profile_id = auth.uid());

DROP POLICY IF EXISTS "marketing_prefs_self_insert" ON marketing_preferences;
CREATE POLICY "marketing_prefs_self_insert" ON marketing_preferences
  FOR INSERT WITH CHECK (profile_id = auth.uid());

-- ============================================================
-- nrc_registrations RLS
-- ============================================================
ALTER TABLE nrc_registrations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "nrc_self_read" ON nrc_registrations;
CREATE POLICY "nrc_self_read" ON nrc_registrations
  FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "nrc_self_insert" ON nrc_registrations;
CREATE POLICY "nrc_self_insert" ON nrc_registrations
  FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "nrc_travel_read" ON nrc_registrations;
CREATE POLICY "nrc_travel_read" ON nrc_registrations
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.role IN ('travel_admin', 'team_support', 'muthawif', 'super_admin', 'admin_haramain_pro')
    )
  );

-- ============================================================
-- fcm_tokens RLS
-- ============================================================
ALTER TABLE fcm_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "fcm_tokens_self_manage" ON fcm_tokens;
CREATE POLICY "fcm_tokens_self_manage" ON fcm_tokens
  FOR ALL USING (user_id = auth.uid());

-- ============================================================
-- groups RLS
-- ============================================================
DROP POLICY IF EXISTS "groups_members_read" ON groups;
CREATE POLICY "groups_members_read" ON groups
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM group_members gm WHERE gm.group_id = id AND gm.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "groups_members_insert" ON groups;
CREATE POLICY "groups_members_insert" ON groups
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "group_members_self_read" ON group_members;
CREATE POLICY "group_members_self_read" ON group_members
  FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "group_members_join" ON group_members;
CREATE POLICY "group_members_join" ON group_members
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL
    AND user_id = auth.uid()
  );

DROP POLICY IF EXISTS "broadcast_logs_members_read" ON broadcast_logs;
CREATE POLICY "broadcast_logs_members_read" ON broadcast_logs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM group_members gm
      WHERE gm.group_id = broadcast_logs.group_id
      AND gm.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "broadcast_logs_members_insert" ON broadcast_logs;
CREATE POLICY "broadcast_logs_members_insert" ON broadcast_logs
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL
    AND sender_id = auth.uid()
  );

-- ============================================================
-- Indexes (idempotent)
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_panic_responses_panic_alert_id ON panic_responses(panic_alert_id);
CREATE INDEX IF NOT EXISTS idx_panic_responses_responder_id ON panic_responses(responder_id);
CREATE INDEX IF NOT EXISTS idx_agencies_name ON agencies(name);
CREATE INDEX IF NOT EXISTS idx_geofence_prayers_name ON geofence_prayers(name);
CREATE INDEX IF NOT EXISTS idx_seat_licenses_agency_id ON seat_licenses(agency_id);
CREATE INDEX IF NOT EXISTS idx_seat_licenses_romongan_id ON seat_licenses(romongan_id);
CREATE INDEX IF NOT EXISTS idx_marketing_preferences_profile_id ON marketing_preferences(profile_id);
