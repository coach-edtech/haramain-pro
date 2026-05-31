-- Migration 014: Audit Logs Table
-- Platform-wide audit trail for sensitive/admin actions
-- Idempotent: uses CREATE TABLE IF NOT EXISTS

-- ============================================================
-- audit_logs table
-- ============================================================
CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- WHO performed the action
  user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  user_email TEXT,
  user_role TEXT,
  
  -- WHAT action was performed
  action VARCHAR(100) NOT NULL,
  action_type VARCHAR(50) NOT NULL CHECK (action_type IN (
    'CREATE', 'READ', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT',
    'APPROVE', 'REJECT', 'SUSPEND', 'ACTIVATE', 'EXPORT', 'IMPORT',
    'PAYMENT', 'REFUND', 'TRANSFER', 'ASSIGN', 'UNASSIGN',
    'PANIC', 'EMERGENCY', 'SYSTEM', 'OTHER'
  )),
  
  -- WHICH resource was affected
  resource_type VARCHAR(100) NOT NULL,  -- e.g. 'profiles', 'rombongan', 'agencies', 'payments'
  resource_id UUID,                     -- The affected row's ID
  
  -- Additional context
  metadata JSONB DEFAULT '{}',          -- Free-form extra data (before/after values, request details, etc.)
  
  -- IP / request tracing
  ip_address INET,
  user_agent TEXT,
  request_id UUID,                      -- For correlating related log entries
  
  -- Timestamp
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- Indexes for common query patterns
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action_type ON audit_logs(action_type);
CREATE INDEX IF NOT EXISTS idx_audit_logs_resource ON audit_logs(resource_type, resource_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_request_id ON audit_logs(request_id) WHERE request_id IS NOT NULL;

-- ============================================================
-- Enable RLS
-- ============================================================
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- RLS Policies
-- SuperAdmin and admin_haramain_pro have full read access
-- Service role (anon + authenticated) can INSERT via the edge function only
-- ============================================================
CREATE POLICY "audit_logs_super_admin_read" ON audit_logs FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM profiles p
    WHERE p.id = auth.uid()
    AND p.role IN ('super_admin', 'admin_haramain_pro')
  )
);

CREATE POLICY "audit_logs_super_admin_all" ON audit_logs FOR ALL USING (
  EXISTS (
    SELECT 1 FROM profiles p
    WHERE p.id = auth.uid()
    AND p.role IN ('super_admin', 'admin_haramain_pro')
  )
);
