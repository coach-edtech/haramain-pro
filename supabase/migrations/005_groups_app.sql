-- Migration 005: Groups table matching GroupModel from app code
-- Drops old tables and recreates with correct column names

BEGIN;

-- Drop old tables if exist (from migration 003)
DROP TABLE IF EXISTS broadcast_logs CASCADE;
DROP TABLE IF EXISTS group_members CASCADE;
DROP TABLE IF EXISTS groups CASCADE;

-- Recreate groups table matching GroupModel fields
CREATE TABLE groups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  pin TEXT NOT NULL UNIQUE,           -- Plain PIN, indexed for fast lookup
  qr_data TEXT,                        -- QR code payload
  muthawif_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  max_members INTEGER DEFAULT 100,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Recreate group_members table
CREATE TABLE group_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  user_name TEXT NOT NULL DEFAULT '',
  role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'member')),
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(group_id, user_id)
);

-- Recreate broadcast_logs table
CREATE TABLE broadcast_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  sender_name TEXT NOT NULL DEFAULT '',
  message TEXT NOT NULL,
  image_url TEXT,
  sent_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_groups_pin ON groups(pin);
CREATE INDEX idx_groups_muthawif_id ON groups(muthawif_id);
CREATE INDEX idx_group_members_group_id ON group_members(group_id);
CREATE INDEX idx_group_members_user_id ON group_members(user_id);
CREATE INDEX idx_broadcast_logs_group_id ON broadcast_logs(group_id);
CREATE INDEX idx_broadcast_logs_sent_at ON broadcast_logs(sent_at DESC);

-- RLS
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE broadcast_logs ENABLE ROW LEVEL SECURITY;

-- Groups: owner (muthawif) can do everything, members can read
CREATE POLICY "groups_select" ON groups FOR SELECT USING (
  muthawif_id = auth.uid() OR
  EXISTS (SELECT 1 FROM group_members gm WHERE gm.group_id = groups.id AND gm.user_id = auth.uid())
);
CREATE POLICY "groups_insert" ON groups FOR INSERT WITH CHECK (muthawif_id = auth.uid());
CREATE POLICY "groups_update" ON groups FOR UPDATE USING (muthawif_id = auth.uid());
CREATE POLICY "groups_delete" ON groups FOR DELETE USING (muthawif_id = auth.uid());

-- Group members: user can manage their own membership, muthawif can manage all in their group
CREATE POLICY "group_members_select" ON group_members FOR SELECT USING (
  user_id = auth.uid() OR
  EXISTS (SELECT 1 FROM groups g WHERE g.id = group_members.group_id AND g.muthawif_id = auth.uid())
);
CREATE POLICY "group_members_insert" ON group_members FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "group_members_delete" ON group_members FOR DELETE USING (
  user_id = auth.uid() OR
  EXISTS (SELECT 1 FROM groups g WHERE g.id = group_members.group_id AND g.muthawif_id = auth.uid())
);

-- Broadcast logs: group members can read, sender can insert
CREATE POLICY "broadcast_logs_select" ON broadcast_logs FOR SELECT USING (
  EXISTS (SELECT 1 FROM group_members gm WHERE gm.group_id = broadcast_logs.group_id AND gm.user_id = auth.uid())
);
CREATE POLICY "broadcast_logs_insert" ON broadcast_logs FOR INSERT WITH CHECK (sender_id = auth.uid());

COMMIT;
