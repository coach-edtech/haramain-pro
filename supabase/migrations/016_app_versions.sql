-- Migration 016: app_versions table
-- Stores version history for mobile/web app releases

CREATE TABLE IF NOT EXISTS app_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  version TEXT NOT NULL,
  version_code INTEGER NOT NULL,
  platform TEXT NOT NULL CHECK (platform IN ('ios', 'android', 'web')),
  release_type TEXT NOT NULL CHECK (release_type IN ('stable', 'beta', 'alpha')),
  release_notes TEXT,
  is_mandatory BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  published_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES profiles(id),
  UNIQUE(platform, version_code),
  UNIQUE(platform, version)
);

CREATE INDEX IF NOT EXISTS idx_app_versions_platform ON app_versions(platform);
CREATE INDEX IF NOT EXISTS idx_app_versions_version_code ON app_versions(version_code DESC);
CREATE INDEX IF NOT EXISTS idx_app_versions_published_at ON app_versions(published_at DESC);
CREATE INDEX IF NOT EXISTS idx_app_versions_is_active ON app_versions(is_active) WHERE is_active = TRUE;

-- Enable RLS
ALTER TABLE app_versions ENABLE ROW LEVEL SECURITY;

-- Super admin has full access
CREATE POLICY "app_versions_super_admin_all" ON app_versions FOR ALL USING (
  EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role IN ('super_admin', 'admin_haramain_pro'))
);

-- Anyone authenticated can read active versions
CREATE POLICY "app_versions_auth_read" ON app_versions FOR SELECT USING (
  is_active = TRUE AND auth.uid() IS NOT NULL
);
