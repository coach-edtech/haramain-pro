-- Migration 015: User ban + session invalidation support
-- Consolidated from 015_user_ban_fields + 015_user_ban_sessions
-- Adds is_banned, banned_at, ban_reason, banned_by columns to profiles
-- Session invalidation handled via Supabase Auth Admin API by the edge function

-- ============================================================
-- Add ban-related columns to profiles (idempotent)
-- ============================================================
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name = 'profiles' AND column_name = 'is_banned') THEN
    ALTER TABLE profiles ADD COLUMN is_banned BOOLEAN DEFAULT FALSE;
  END IF;
END $$;

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
                 WHERE table_name = 'profiles' AND column_name = 'ban_reason') THEN
    ALTER TABLE profiles ADD COLUMN ban_reason TEXT;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name = 'profiles' AND column_name = 'banned_by') THEN
    ALTER TABLE profiles ADD COLUMN banned_by UUID REFERENCES profiles(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Indexes for ban lookups
CREATE INDEX IF NOT EXISTS idx_profiles_is_banned ON profiles(is_banned) WHERE is_banned = TRUE;
CREATE INDEX IF NOT EXISTS idx_profiles_banned_at ON profiles(banned_at) WHERE banned_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_profiles_banned_by ON profiles(banned_by);

-- ============================================================
-- RLS: SuperAdmin full access to profiles (covers ban fields)
-- ============================================================
DROP POLICY IF EXISTS "profiles_super_admin_all" ON profiles;
CREATE POLICY "profiles_super_admin_all" ON profiles
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'super_admin')
  );

-- Note: To invalidate existing sessions, call the Supabase Auth Admin API
-- with SUPABASE_SERVICE_ROLE_KEY in the edge function.
