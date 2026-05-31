-- Migration 010: Dashboard Schema v1.12
-- SuperAdmin Dashboard + Travel Admin Enhancement
-- Idempotent: uses CREATE TABLE IF NOT EXISTS, DO $$ blocks, DROP + CREATE

-- ============================================================
-- SEAT LICENSE PACKAGES (per-purchase bundles)
-- ============================================================
CREATE TABLE IF NOT EXISTS seat_license_packages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agency_id UUID REFERENCES agencies(id) ON DELETE CASCADE,
  package_name VARCHAR(255) NOT NULL,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  price_per_seat NUMERIC(12,0) NOT NULL CHECK (price_per_seat >= 0),
  total_price NUMERIC(12,0) NOT NULL CHECK (total_price >= 0),
  payment_status VARCHAR(20) DEFAULT 'pending'
    CHECK (payment_status IN ('pending', 'paid', 'cancelled', 'refunded')),
  payment_id UUID,
  invoice_url VARCHAR(500),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  paid_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_slp_agency_id ON seat_license_packages(agency_id);
CREATE INDEX IF NOT EXISTS idx_slp_payment_status ON seat_license_packages(payment_status);

-- ============================================================
-- SEAT LICENSE TRANSACTIONS (immutable ledger)
-- ============================================================
CREATE TABLE IF NOT EXISTS seat_license_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agency_id UUID REFERENCES agencies(id) ON DELETE CASCADE NOT NULL,
  type VARCHAR(20) NOT NULL CHECK (type IN ('purchase', 'consumed', 'refunded', 'adjustment')),
  quantity INTEGER NOT NULL,
  balance_after INTEGER NOT NULL,
  related_user_id UUID,
  related_package_id UUID REFERENCES seat_license_packages(id),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_slt_agency_id ON seat_license_transactions(agency_id);
CREATE INDEX IF NOT EXISTS idx_slt_type ON seat_license_transactions(type);
CREATE INDEX IF NOT EXISTS idx_slt_created_at ON seat_license_transactions(created_at DESC);

-- ============================================================
-- SEAT LICENSE ALERTS (low-stock threshold)
-- ============================================================
CREATE TABLE IF NOT EXISTS seat_license_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agency_id UUID REFERENCES agencies(id) ON DELETE CASCADE NOT NULL,
  threshold INTEGER NOT NULL CHECK (threshold >= 0),
  is_active BOOLEAN DEFAULT true,
  triggered_at TIMESTAMPTZ,
  acknowledged_at TIMESTAMPTZ,
  acknowledged_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sla_agency_active ON seat_license_alerts(agency_id, is_active)
  WHERE is_active = true;

-- ============================================================
-- REDEEM CODES (6-char alphanumeric)
-- ============================================================
CREATE TABLE IF NOT EXISTS redeem_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agency_id UUID REFERENCES agencies(id) ON DELETE CASCADE NOT NULL,
  code VARCHAR(10) UNIQUE NOT NULL,
  type VARCHAR(30) NOT NULL
    CHECK (type IN ('jama_redeem', 'team_invite', 'muthawif_invite')),
  status VARCHAR(20) DEFAULT 'available'
    CHECK (status IN ('available', 'used', 'expired', 'revoked')),
  created_by UUID NOT NULL,
  expires_at TIMESTAMPTZ,
  used_at TIMESTAMPTZ,
  used_by_user_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rc_code ON redeem_codes(code);
CREATE INDEX IF NOT EXISTS idx_rc_agency_id ON redeem_codes(agency_id);
CREATE INDEX IF NOT EXISTS idx_rc_status ON redeem_codes(status);

-- ============================================================
-- INVOICES
-- ============================================================
CREATE TABLE IF NOT EXISTS invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_number VARCHAR(50) UNIQUE NOT NULL,
  agency_id UUID REFERENCES agencies(id) ON DELETE CASCADE NOT NULL,
  billing_period_start DATE NOT NULL,
  billing_period_end DATE NOT NULL,
  active_pax_count INTEGER NOT NULL DEFAULT 0,
  price_per_seat NUMERIC(12,0) NOT NULL,
  subtotal NUMERIC(12,0) NOT NULL,
  adjustments NUMERIC(12,0) DEFAULT 0,
  total_due NUMERIC(12,0) NOT NULL,
  status VARCHAR(20) DEFAULT 'draft'
    CHECK (status IN ('draft', 'sent', 'paid', 'overdue', 'cancelled')),
  due_date DATE NOT NULL,
  paid_at TIMESTAMPTZ,
  paid_amount NUMERIC(12,0),
  payment_method VARCHAR(50),
  payment_proof_url VARCHAR(500),
  pdf_url VARCHAR(500),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  sent_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_inv_agency_id ON invoices(agency_id);
CREATE INDEX IF NOT EXISTS idx_inv_status ON invoices(status);
CREATE INDEX IF NOT EXISTS idx_inv_due_date ON invoices(due_date);

-- ============================================================
-- BILLING ADJUSTMENTS (credits, discounts, penalties)
-- ============================================================
CREATE TABLE IF NOT EXISTS billing_adjustments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id UUID REFERENCES invoices(id) ON DELETE CASCADE NOT NULL,
  type VARCHAR(20) NOT NULL CHECK (type IN ('credit', 'discount', 'penalty')),
  amount NUMERIC(12,0) NOT NULL,
  reason TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ba_invoice_id ON billing_adjustments(invoice_id);

-- ============================================================
-- USER ACTIVITY LOG
-- ============================================================
CREATE TABLE IF NOT EXISTS user_activity_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  event_type VARCHAR(50) NOT NULL,
  event_data JSONB,
  ip_address VARCHAR(45),
  device_id VARCHAR(255),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ual_user_id ON user_activity_log(user_id);
CREATE INDEX IF NOT EXISTS idx_ual_event_type ON user_activity_log(event_type);
CREATE INDEX IF NOT EXISTS idx_ual_created_at ON user_activity_log(created_at DESC);

-- ============================================================
-- FRAUD FLAGS
-- ============================================================
CREATE TABLE IF NOT EXISTS fraud_flags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  flag_type VARCHAR(50) NOT NULL,
  risk_score VARCHAR(10) DEFAULT 'medium'
    CHECK (risk_score IN ('low', 'medium', 'high', 'critical')),
  details JSONB,
  status VARCHAR(20) DEFAULT 'pending'
    CHECK (status IN ('pending', 'reviewed', 'false_positive', 'confirmed')),
  reviewed_by UUID,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ff_user_id ON fraud_flags(user_id);
CREATE INDEX IF NOT EXISTS idx_ff_status ON fraud_flags(status);
CREATE INDEX IF NOT EXISTS idx_ff_risk_score ON fraud_flags(risk_score);

-- ============================================================
-- SYSTEM METRICS
-- ============================================================
CREATE TABLE IF NOT EXISTS system_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  metric_type VARCHAR(50) NOT NULL,
  metric_value JSONB NOT NULL,
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sm_metric_type ON system_metrics(metric_type);
CREATE INDEX IF NOT EXISTS idx_sm_recorded_at ON system_metrics(recorded_at DESC);

-- ============================================================
-- PAYMENTS (Xendit integration)
-- ============================================================
CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agency_id UUID REFERENCES agencies(id) ON DELETE CASCADE,
  type VARCHAR(30) NOT NULL
    CHECK (type IN ('seat_license_purchase', 'invoice_payment', 'mandiri_subscription')),
  reference_id VARCHAR(100),
  amount NUMERIC(12,0) NOT NULL CHECK (amount >= 0),
  currency VARCHAR(10) DEFAULT 'IDR',
  payment_method VARCHAR(30),
  payment_status VARCHAR(20) DEFAULT 'pending'
    CHECK (payment_status IN ('pending', 'paid', 'failed', 'expired', 'cancelled')),
  xendit_payment_id VARCHAR(100),
  xendit_checkout_url VARCHAR(500),
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pay_agency_id ON payments(agency_id);
CREATE INDEX IF NOT EXISTS idx_pay_type ON payments(type);
CREATE INDEX IF NOT EXISTS idx_pay_status ON payments(payment_status);
CREATE INDEX IF NOT EXISTS idx_pay_xendit_id ON payments(xendit_payment_id);

-- ============================================================
-- PILGRIM LIFECYCLE (CRM)
-- ============================================================
CREATE TABLE IF NOT EXISTS pilgrim_lifecycle (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  agency_id UUID REFERENCES agencies(id) ON DELETE CASCADE,
  stage VARCHAR(20) NOT NULL
    CHECK (stage IN ('prospect', 'booked', 'active', 'alumni', 'churned')),
  stage_changed_at TIMESTAMPTZ DEFAULT NOW(),
  booking_date DATE,
  departure_date DATE,
  return_date DATE,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pl_user_id ON pilgrim_lifecycle(user_id);
CREATE INDEX IF NOT EXISTS idx_pl_agency_id ON pilgrim_lifecycle(agency_id);
CREATE INDEX IF NOT EXISTS idx_pl_stage ON pilgrim_lifecycle(stage);

-- ============================================================
-- COMMUNICATION LOGS (CRM)
-- ============================================================
CREATE TABLE IF NOT EXISTS communication_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  agency_id UUID REFERENCES agencies(id) ON DELETE CASCADE,
  type VARCHAR(30) NOT NULL
    CHECK (type IN ('broadcast', 'manual_note', 'phone_call', 'whatsapp', 'email')),
  direction VARCHAR(10) NOT NULL CHECK (direction IN ('inbound', 'outbound')),
  content TEXT NOT NULL,
  created_by UUID NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cl_user_id ON communication_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_cl_agency_id ON communication_logs(agency_id);
CREATE INDEX IF NOT EXISTS idx_cl_created_at ON communication_logs(created_at DESC);

-- ============================================================
-- ALUMNI REVIEWS
-- ============================================================
CREATE TABLE IF NOT EXISTS alumni_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  agency_id UUID REFERENCES agencies(id) ON DELETE CASCADE,
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  review_text TEXT,
  is_published BOOLEAN DEFAULT false,
  admin_response TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ar_agency_id ON alumni_reviews(agency_id);
CREATE INDEX IF NOT EXISTS idx_ar_is_published ON alumni_reviews(is_published) WHERE is_published = true;

-- ============================================================
-- SALES AGENTS (Travel Admin team)
-- ============================================================
CREATE TABLE IF NOT EXISTS sales_agents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agency_id UUID REFERENCES agencies(id) ON DELETE CASCADE NOT NULL,
  user_id UUID NOT NULL,
  agent_code VARCHAR(20) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  commission_rate NUMERIC(5,2) DEFAULT 0 CHECK (commission_rate >= 0 AND commission_rate <= 100),
  status VARCHAR(20) DEFAULT 'active'
    CHECK (status IN ('active', 'inactive', 'revoked')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sa_agency_id ON sales_agents(agency_id);
CREATE INDEX IF NOT EXISTS idx_sa_user_id ON sales_agents(user_id);

-- ============================================================
-- COLUMN ADDITIONS TO EXISTING TABLES
-- ============================================================

-- agencies: seat_balance + wl_status
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name = 'agencies' AND column_name = 'seat_balance') THEN
    ALTER TABLE agencies ADD COLUMN seat_balance INTEGER DEFAULT 0;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name = 'agencies' AND column_name = 'wl_status') THEN
    ALTER TABLE agencies ADD COLUMN wl_status VARCHAR(20) DEFAULT 'standard'
      CHECK (wl_status IN ('standard', 'white_label', 'enterprise'));
  END IF;
END $$;

-- profiles: fraud flagging
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name = 'profiles' AND column_name = 'is_fraud_flagged') THEN
    ALTER TABLE profiles ADD COLUMN is_fraud_flagged BOOLEAN DEFAULT false;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name = 'profiles' AND column_name = 'fraud_flag_reason') THEN
    ALTER TABLE profiles ADD COLUMN fraud_flag_reason TEXT;
  END IF;
END $$;

-- profiles: fraud_review_notes
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name = 'profiles' AND column_name = 'fraud_review_notes') THEN
    ALTER TABLE profiles ADD COLUMN fraud_review_notes TEXT;
  END IF;
END $$;

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

-- seat_license_packages
ALTER TABLE seat_license_packages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "slp_super_admin_all" ON seat_license_packages;
CREATE POLICY "slp_super_admin_all" ON seat_license_packages
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'super_admin')
  );

DROP POLICY IF EXISTS "slp_travel_admin_read" ON seat_license_packages;
CREATE POLICY "slp_travel_admin_read" ON seat_license_packages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.role IN ('travel_admin', 'admin_haramain_pro')
      AND p.agency_id = seat_license_packages.agency_id
    )
  );

DROP POLICY IF EXISTS "slp_travel_admin_insert" ON seat_license_packages;
CREATE POLICY "slp_travel_admin_insert" ON seat_license_packages
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.role IN ('travel_admin', 'super_admin')
      AND p.agency_id = seat_license_packages.agency_id
    )
  );

-- seat_license_transactions
ALTER TABLE seat_license_transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "slt_super_admin_all" ON seat_license_transactions;
CREATE POLICY "slt_super_admin_all" ON seat_license_transactions
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'super_admin')
  );

DROP POLICY IF EXISTS "slt_travel_admin_read" ON seat_license_transactions;
CREATE POLICY "slt_travel_admin_read" ON seat_license_transactions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.role IN ('travel_admin', 'admin_haramain_pro')
      AND p.agency_id = seat_license_transactions.agency_id
    )
  );

-- seat_license_alerts
ALTER TABLE seat_license_alerts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "sla_super_admin_all" ON seat_license_alerts;
CREATE POLICY "sla_super_admin_all" ON seat_license_alerts
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'super_admin')
  );

DROP POLICY IF EXISTS "sla_travel_admin_read" ON seat_license_alerts;
CREATE POLICY "sla_travel_admin_read" ON seat_license_alerts
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.role IN ('travel_admin', 'admin_haramain_pro')
      AND p.agency_id = seat_license_alerts.agency_id
    )
  );

DROP POLICY IF EXISTS "sla_travel_admin_insert" ON seat_license_alerts;
CREATE POLICY "sla_travel_admin_insert" ON seat_license_alerts
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.role IN ('travel_admin', 'super_admin')
      AND p.agency_id = seat_license_alerts.agency_id
    )
  );

-- redeem_codes
ALTER TABLE redeem_codes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "rc_super_admin_all" ON redeem_codes;
CREATE POLICY "rc_super_admin_all" ON redeem_codes
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'super_admin')
  );

DROP POLICY IF EXISTS "rc_travel_admin_all" ON redeem_codes;
CREATE POLICY "rc_travel_admin_all" ON redeem_codes
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.role IN ('travel_admin', 'super_admin')
      AND p.agency_id = redeem_codes.agency_id
    )
  );

DROP POLICY IF EXISTS "rc_user_redeem" ON redeem_codes;
CREATE POLICY "rc_user_redeem" ON redeem_codes
  FOR SELECT USING (status = 'available');

-- invoices
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "inv_super_admin_all" ON invoices;
CREATE POLICY "inv_super_admin_all" ON invoices
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'super_admin')
  );

DROP POLICY IF EXISTS "inv_travel_admin_read" ON invoices;
CREATE POLICY "inv_travel_admin_read" ON invoices
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.role IN ('travel_admin', 'admin_haramain_pro')
      AND p.agency_id = invoices.agency_id
    )
  );

-- billing_adjustments
ALTER TABLE billing_adjustments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "ba_super_admin_all" ON billing_adjustments;
CREATE POLICY "ba_super_admin_all" ON billing_adjustments
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'super_admin')
  );

DROP POLICY IF EXISTS "ba_travel_admin_read" ON billing_adjustments;
CREATE POLICY "ba_travel_admin_read" ON billing_adjustments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN invoices i ON i.agency_id = p.agency_id
      WHERE p.id = auth.uid()
      AND p.role IN ('travel_admin', 'admin_haramain_pro')
      AND i.id = billing_adjustments.invoice_id
    )
  );

-- payments
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "pay_super_admin_all" ON payments;
CREATE POLICY "pay_super_admin_all" ON payments
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'super_admin')
  );

DROP POLICY IF EXISTS "pay_travel_admin_all" ON payments;
CREATE POLICY "pay_travel_admin_all" ON payments
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.role IN ('travel_admin', 'super_admin')
      AND p.agency_id = payments.agency_id
    )
  );

-- pilgrim_lifecycle
ALTER TABLE pilgrim_lifecycle ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "pl_super_admin_all" ON pilgrim_lifecycle;
CREATE POLICY "pl_super_admin_all" ON pilgrim_lifecycle
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'super_admin')
  );

DROP POLICY IF EXISTS "pl_travel_admin_all" ON pilgrim_lifecycle;
CREATE POLICY "pl_travel_admin_all" ON pilgrim_lifecycle
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.role IN ('travel_admin', 'team_support', 'muthawif', 'super_admin', 'admin_haramain_pro')
      AND p.agency_id = pilgrim_lifecycle.agency_id
    )
  );

DROP POLICY IF EXISTS "pl_user_read_own" ON pilgrim_lifecycle;
CREATE POLICY "pl_user_read_own" ON pilgrim_lifecycle
  FOR SELECT USING (user_id = auth.uid());

-- communication_logs
ALTER TABLE communication_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "cl_super_admin_all" ON communication_logs;
CREATE POLICY "cl_super_admin_all" ON communication_logs
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'super_admin')
  );

DROP POLICY IF EXISTS "cl_travel_admin_all" ON communication_logs;
CREATE POLICY "cl_travel_admin_all" ON communication_logs
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.role IN ('travel_admin', 'team_support', 'super_admin', 'admin_haramain_pro')
      AND p.agency_id = communication_logs.agency_id
    )
  );

DROP POLICY IF EXISTS "cl_user_read_own" ON communication_logs;
CREATE POLICY "cl_user_read_own" ON communication_logs
  FOR SELECT USING (user_id = auth.uid());

-- alumni_reviews (public read for published, admin write)
ALTER TABLE alumni_reviews ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "ar_public_read_published" ON alumni_reviews;
CREATE POLICY "ar_public_read_published" ON alumni_reviews
  FOR SELECT USING (is_published = true);

DROP POLICY IF EXISTS "ar_travel_admin_all" ON alumni_reviews;
CREATE POLICY "ar_travel_admin_all" ON alumni_reviews
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.role IN ('travel_admin', 'super_admin', 'admin_haramain_pro')
      AND p.agency_id = alumni_reviews.agency_id
    )
  );

-- user_activity_log (admin only)
ALTER TABLE user_activity_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "ual_super_admin_all" ON user_activity_log;
CREATE POLICY "ual_super_admin_all" ON user_activity_log
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'super_admin')
  );

DROP POLICY IF EXISTS "ual_admin_read" ON user_activity_log;
CREATE POLICY "ual_admin_read" ON user_activity_log
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.role IN ('admin_haramain_pro')
    )
  );

-- fraud_flags
ALTER TABLE fraud_flags ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "ff_super_admin_all" ON fraud_flags;
CREATE POLICY "ff_super_admin_all" ON fraud_flags
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'super_admin')
  );

DROP POLICY IF EXISTS "ff_admin_read" ON fraud_flags;
CREATE POLICY "ff_admin_read" ON fraud_flags
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.role IN ('admin_haramain_pro')
    )
  );

-- system_metrics
ALTER TABLE system_metrics ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "sm_super_admin_all" ON system_metrics;
CREATE POLICY "sm_super_admin_all" ON system_metrics
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'super_admin')
  );

DROP POLICY IF EXISTS "sm_admin_read" ON system_metrics;
CREATE POLICY "sm_admin_read" ON system_metrics
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.role IN ('admin_haramain_pro')
    )
  );

-- sales_agents
ALTER TABLE sales_agents ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "sa_super_admin_all" ON sales_agents;
CREATE POLICY "sa_super_admin_all" ON sales_agents
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'super_admin')
  );

DROP POLICY IF EXISTS "sa_travel_admin_all" ON sales_agents;
CREATE POLICY "sa_travel_admin_all" ON sales_agents
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.role IN ('travel_admin', 'super_admin')
      AND p.agency_id = sales_agents.agency_id
    )
  );

-- ============================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================

-- Function: consume_seat (called when Jamaah redeems + activates)
CREATE OR REPLACE FUNCTION consume_seat()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE agencies
  SET seat_balance = seat_balance - 1
  WHERE id = NEW.agency_id
    AND seat_balance >= 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Insufficient seat balance or agency not found';
  END IF;

  -- Log transaction
  INSERT INTO seat_license_transactions
    (agency_id, type, quantity, balance_after, related_user_id, related_package_id, notes)
  VALUES (
    NEW.agency_id,
    'consumed',
    1,
    (SELECT seat_balance FROM agencies WHERE id = NEW.agency_id),
    NEW.id,
    NULL,
    'Auto-consumed on user activation'
  );

  -- Fire low-stock alert if needed
  PERFORM check_low_stock_alert(NEW.agency_id);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function: refund_seat
CREATE OR REPLACE FUNCTION refund_seat(p_agency_id UUID, p_package_id UUID DEFAULT NULL)
RETURNS VOID AS $$
BEGIN
  UPDATE agencies
  SET seat_balance = seat_balance + 1
  WHERE id = p_agency_id;

  INSERT INTO seat_license_transactions
    (agency_id, type, quantity, balance_after, related_package_id, notes)
  VALUES (
    p_agency_id,
    'refunded',
    1,
    (SELECT seat_balance FROM agencies WHERE id = p_agency_id),
    p_package_id,
    'Manual refund by admin'
  );
END;
$$ LANGUAGE plpgsql;

-- Function: check_low_stock_alert
CREATE OR REPLACE FUNCTION check_low_stock_alert(p_agency_id UUID)
RETURNS VOID AS $$
DECLARE
  v_threshold INTEGER;
  v_balance INTEGER;
BEGIN
  SELECT threshold INTO v_threshold
  FROM seat_license_alerts
  WHERE agency_id = p_agency_id
    AND is_active = true
    AND triggered_at IS NULL;

  IF v_threshold IS NOT NULL THEN
    SELECT seat_balance INTO v_balance FROM agencies WHERE id = p_agency_id;

    IF v_balance < v_threshold THEN
      UPDATE seat_license_alerts
      SET triggered_at = NOW()
      WHERE agency_id = p_agency_id
        AND is_active = true
        AND triggered_at IS NULL;
    END IF;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Trigger: auto-create pilgrim_lifecycle record on profile creation
-- (handles new Jamaah coming through redeem code flow)
CREATE OR REPLACE FUNCTION handle_new_jamaah_lifecycle()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.role IN ('pilgrim', 'jamaah') THEN
    INSERT INTO pilgrim_lifecycle (user_id, agency_id, stage)
    VALUES (NEW.id, NEW.agency_id, 'prospect')
    ON CONFLICT DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_profile_create_lifecycle ON profiles;
CREATE TRIGGER on_profile_create_lifecycle
  AFTER INSERT ON profiles
  FOR EACH ROW EXECUTE FUNCTION handle_new_jamaah_lifecycle();

-- ============================================================
-- UPDATE UPDATED_AT TIMESTAMP
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to tables with updated_at
DROP TRIGGER IF EXISTS payments_updated_at ON payments;
CREATE TRIGGER payments_updated_at
  BEFORE UPDATE ON payments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
