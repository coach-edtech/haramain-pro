-- Migration: Add user ban fields to profiles
-- Supports SuperAdmin ban/unban workflow

-- ============================================================
-- Add ban fields to profiles table
-- ============================================================
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name = 'profiles' AND column_name = 'banned_at') THEN
    ALTER TABLE profiles ADD COLUMN banned_at TIMESTAMPTZ;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name = 'profiles' AND column_name = 'banned_by') THEN
    ALTER TABLE profiles ADD COLUMN banned_by UUID REFERENCES profiles(id) ON DELETE SET NULL;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name = 'profiles' AND column_name = 'ban_reason') THEN
    ALTER TABLE profiles ADD COLUMN ban_reason TEXT;
  END IF;
END $$;

-- Indexes for ban lookups
CREATE INDEX IF NOT EXISTS idx_profiles_banned_at ON profiles(banned_at) WHERE banned_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_profiles_banned_by ON profiles(banned_by);

-- ============================================================
-- RLS: Only super_admin can read/write ban fields
-- (profiles table already has RLS enabled from earlier migrations)
-- ============================================================

-- Allow super_admin to read all profiles (existing policy likely already covers this,
-- but explicitly ensure banned users can be looked up)
DROP POLICY IF EXISTS "profiles_super_admin_all" ON profiles;
CREATE POLICY "profiles_super_admin_all" ON profiles
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'super_admin')
  );
