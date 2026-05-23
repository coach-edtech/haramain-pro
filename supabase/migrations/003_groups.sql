-- Groups table (for Jamaah group feature)
CREATE TABLE groups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  pin_hash TEXT NOT NULL,
  created_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  qr_data TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Group members table
CREATE TABLE group_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member' CHECK (role IN ('owner', 'member')),
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(group_id, user_id)
);

-- Broadcast logs table
CREATE TABLE broadcast_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  sent_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_groups_created_by ON groups(created_by);
CREATE INDEX idx_group_members_group_id ON group_members(group_id);
CREATE INDEX idx_group_members_user_id ON group_members(user_id);
CREATE INDEX idx_broadcast_logs_group_id ON broadcast_logs(group_id);
CREATE INDEX idx_broadcast_logs_sent_at ON broadcast_logs(sent_at DESC);

-- RLS Policies for groups
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE broadcast_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "group_self_read" ON groups FOR SELECT USING (
  created_by = auth.uid() OR 
  EXISTS (SELECT 1 FROM group_members gm WHERE gm.group_id = groups.id AND gm.user_id = auth.uid())
);
CREATE POLICY "group_member_read" ON groups FOR SELECT USING (
  EXISTS (SELECT 1 FROM group_members gm WHERE gm.group_id = groups.id AND gm.user_id = auth.uid())
);
CREATE POLICY "group_self_insert" ON groups FOR INSERT WITH CHECK (created_by = auth.uid());
CREATE POLICY "group_members_self_insert" ON group_members FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "group_members_read" ON group_members FOR SELECT USING (
  user_id = auth.uid() OR
  EXISTS (SELECT 1 FROM groups g WHERE g.id = group_members.group_id AND g.created_by = auth.uid())
);
CREATE POLICY "broadcast_logs_read" ON broadcast_logs FOR SELECT USING (
  EXISTS (SELECT 1 FROM group_members gm WHERE gm.group_id = broadcast_logs.group_id AND gm.user_id = auth.uid())
);
CREATE POLICY "broadcast_logs_insert" ON broadcast_logs FOR INSERT WITH CHECK (sender_id = auth.uid());
