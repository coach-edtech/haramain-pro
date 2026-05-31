-- Migration 011: Dashboard Schema Addendum
-- RPC functions + fix balance calculation
-- References: 010_dashboard_schema.sql

-- ============================================================
-- RPC: consume_seat_batch (for bulk code generation)
-- ============================================================
CREATE OR REPLACE FUNCTION consume_seat_batch(p_agency_id UUID, p_count INTEGER DEFAULT 1)
RETURNS VOID AS $$
BEGIN
  UPDATE agencies
  SET seat_balance = seat_balance - p_count
  WHERE id = p_agency_id
    AND seat_balance >= p_count;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Insufficient seat balance or agency not found';
  END IF;

  -- Log transaction
  INSERT INTO seat_license_transactions
    (agency_id, type, quantity, balance_after, notes)
  VALUES (
    p_agency_id,
    'consumed',
    p_count,
    (SELECT seat_balance FROM agencies WHERE id = p_agency_id),
    'Bulk consumed via redeem code generation'
  );

  PERFORM check_low_stock_alert(p_agency_id);
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- RPC: add_seat_balance (called on Xendit payment success)
-- ============================================================
CREATE OR REPLACE FUNCTION add_seat_balance(p_agency_id UUID, p_quantity INTEGER, p_package_id UUID DEFAULT NULL)
RETURNS VOID AS $$
DECLARE
  v_new_balance INTEGER;
BEGIN
  UPDATE agencies
  SET seat_balance = seat_balance + p_quantity
  WHERE id = p_agency_id
  RETURNING seat_balance INTO v_new_balance;

  INSERT INTO seat_license_transactions
    (agency_id, type, quantity, balance_after, related_package_id, notes)
  VALUES (
    p_agency_id,
    'purchase',
    p_quantity,
    v_new_balance,
    p_package_id,
    'Added via Xendit payment'
  );
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- Enable seat_license_packages payment_status index if not exists
-- (adds on top of 010 - idempotent)
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_slp_agency_created
  ON seat_license_packages(agency_id, created_at DESC);

-- Index for payments lookup
CREATE INDEX IF NOT EXISTS idx_pay_reference_id
  ON payments(reference_id);

-- Index for pilgrim_lifecycle user lookup
CREATE INDEX IF NOT EXISTS idx_pl_user_created
  ON pilgrim_lifecycle(user_id, created_at DESC);
