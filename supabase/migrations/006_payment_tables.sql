-- Payment/Subscription Tables for B2C Monetization

-- Subscriptions table
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  tier TEXT NOT NULL CHECK (tier IN ('trial', 'basic', 'premium')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired', 'cancelled')),
  start_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  end_date TIMESTAMPTZ,
  midtrans_order_id TEXT,
  midtrans_transaction_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Payment history table
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  subscription_id UUID REFERENCES subscriptions(id) ON DELETE SET NULL,
  amount NUMERIC(10, 2) NOT NULL,
  currency TEXT DEFAULT 'SAR',
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'settlement', 'expire', 'deny', 'cancel', 'refund')),
  midtrans_order_id TEXT UNIQUE,
  midtrans_transaction_id TEXT,
  payment_type TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);
CREATE INDEX idx_payments_user_id ON payments(user_id);
CREATE INDEX idx_payments_midtrans_order_id ON payments(midtrans_order_id);

-- RLS
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- Users can read their own subscriptions
CREATE POLICY "subscription_self_read" ON subscriptions
  FOR SELECT USING (user_id = auth.uid());

-- Users can insert their own subscriptions
CREATE POLICY "subscription_self_insert" ON subscriptions
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- Users can update their own subscriptions
CREATE POLICY "subscription_self_update" ON subscriptions
  FOR UPDATE USING (user_id = auth.uid());

-- Users can read their own payments
CREATE POLICY "payment_self_read" ON payments
  FOR SELECT USING (user_id = auth.uid());

-- Payments insert via webhook only (service role)
CREATE POLICY "payment_webhook_insert" ON payments
  FOR INSERT WITH CHECK (
    midtrans_order_id IS NOT NULL  -- Only via webhook
  );

-- Agency can read payments of their pilgrims
CREATE POLICY "payment_agency_read" ON payments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN rombangans r ON r.agency_id = p.id
      WHERE p.id = auth.uid() 
      AND p.role = 'agency'
      AND payments.user_id = ANY(
        SELECT id FROM profiles WHERE rombongan_id = ANY(
          SELECT id FROM rombangans WHERE agency_id = p.id
        )
      )
    )
  );
