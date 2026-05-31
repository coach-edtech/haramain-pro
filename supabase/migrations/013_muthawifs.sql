-- Migration 013: Muthawifs & Muthawif-Romongan junction tables
-- Idempotent: uses CREATE TABLE IF NOT EXISTS

-- ============================================================
-- muthawifs table (muthawif profiles managed by an agency)
-- ============================================================
CREATE TABLE IF NOT EXISTS muthawifs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  agency_id UUID NOT NULL REFERENCES agencies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  specialization TEXT, -- e.g. 'haji', 'umrah', 'turkey', 'aqsa'
  license_number TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(profile_id)
);

CREATE INDEX IF NOT EXISTS idx_muthawifs_agency_id ON muthawifs(agency_id);
CREATE INDEX IF NOT EXISTS idx_muthawifs_profile_id ON muthawifs(profile_id);
CREATE INDEX IF NOT EXISTS idx_muthawifs_is_active ON muthawifs(is_active) WHERE is_active = true;

-- ============================================================
-- muthawif_rombongan junction table
-- ============================================================
CREATE TABLE IF NOT EXISTS muthawif_rombongan (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  muthawif_id UUID NOT NULL REFERENCES muthawifs(id) ON DELETE CASCADE,
  romongan_id UUID NOT NULL REFERENCES rombangans(id) ON DELETE CASCADE,
  role_in_rombongan TEXT DEFAULT 'muthawif' CHECK (role_in_rombongan IN ('muthawif', 'assistant_muthawif', 'leader')),
  assigned_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(muthawif_id, romongan_id)
);

CREATE INDEX IF NOT EXISTS idx_mr_muthawif_id ON muthawif_rombongan(muthawif_id);
CREATE INDEX IF NOT EXISTS idx_mr_rombongan_id ON muthawif_rombongan(rombongan_id);

-- ============================================================
-- Enable RLS
-- ============================================================
ALTER TABLE muthawifs ENABLE ROW LEVEL SECURITY;
ALTER TABLE muthawif_rombongan ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- RLS Policies for muthawifs
-- ============================================================
-- Super / admin_haramain_pro can do everything
CREATE POLICY "muthawifs_super_admin_all" ON muthawifs FOR ALL USING (
  EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role IN ('super_admin', 'admin_haramain_pro'))
);

-- Travel admin can manage their agency's muthawifs
CREATE POLICY "muthawifs_travel_admin_crud" ON muthawifs FOR ALL USING (
  agency_id IN (
    SELECT agency_id FROM profiles WHERE id = auth.uid()
  )
);

-- Muthawif can read their own record
CREATE POLICY "muthawifs_self_read" ON muthawifs FOR SELECT USING (
  profile_id = auth.uid()
);

-- ============================================================
-- RLS Policies for muthawif_rombongan
-- ============================================================
-- Super / admin can do everything
CREATE POLICY "mr_super_admin_all" ON muthawif_rombongan FOR ALL USING (
  EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role IN ('super_admin', 'admin_haramain_pro'))
);

-- Travel admin can manage assignments for their agency's romongan
CREATE POLICY "mr_travel_admin_all" ON muthawif_rombongan FOR ALL USING (
  romongan_id IN (
    SELECT r.id FROM rombangans r WHERE r.agency_id IN (
      SELECT agency_id FROM profiles WHERE id = auth.uid()
    )
  )
);

-- Muthawif can read assignments for themselves
CREATE POLICY "mr_muthawif_read" ON muthawif_rombongan FOR SELECT USING (
  muthawif_id IN (SELECT id FROM muthawifs WHERE profile_id = auth.uid())
);
