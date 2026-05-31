-- Migration 015: User ban + session invalidation support
-- Adds is_banned, banned_at, ban_reason, banned_by columns to profiles
-- Session invalidation is handled via Supabase Auth Admin API directly by the edge function

-- Add ban-related columns to profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_banned BOOLEAN DEFAULT FALSE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS banned_at TIMESTAMPTZ;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS ban_reason TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS banned_by UUID REFERENCES profiles(id);

-- Create index for fast banned user lookups
CREATE INDEX IF NOT EXISTS idx_profiles_is_banned ON profiles(is_banned) WHERE is_banned = TRUE;

-- Note: To invalidate existing sessions, the user_ban edge function calls
-- the Supabase Auth admin API. Ensure SUPABASE_SERVICE_ROLE_KEY is set.
