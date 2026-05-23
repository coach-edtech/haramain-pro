-- Panic alerts table
CREATE TABLE panic_alerts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  jamaaah_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  grup_id UUID NOT NULL,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'responded', 'resolved', 'cancelled')),
  responded_by UUID REFERENCES profiles(id),
  responded_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for panic alerts
CREATE INDEX idx_panic_alerts_jamaaah_id ON panic_alerts(jamaaah_id);
CREATE INDEX idx_panic_alerts_timestamp ON panic_alerts(timestamp DESC);
CREATE INDEX idx_panic_alerts_status ON panic_alerts(status);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE rombangans ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE photo_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE panic_alerts ENABLE ROW LEVEL SECURITY;

-- RLS Policies for profiles
CREATE POLICY "profile_self_read" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "profile_self_update" ON profiles FOR UPDATE USING (auth.uid() = id);

-- RLS Policies for rombangans
CREATE POLICY "rombongan_self_read" ON rombangans FOR SELECT USING (
  EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.rombongan_id = rombangans.id)
);
CREATE POLICY "rombongan_agency_crud" ON rombangans FOR ALL USING (agency_id = auth.uid());

-- RLS Policies for transactions
CREATE POLICY "transaction_self_read" ON transactions FOR SELECT USING (user_id = auth.uid());

-- RLS Policies for photo_queue
CREATE POLICY "photo_queue_self_read" ON photo_queue FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "photo_queue_self_insert" ON photo_queue FOR INSERT WITH CHECK (user_id = auth.uid());

-- RLS Policies for panic_alerts
CREATE POLICY "panic_alert_jamaah_insert" ON panic_alerts FOR INSERT WITH CHECK (
  jamaaah_id = auth.uid()
);
CREATE POLICY "panic_alert_muthawif_read" ON panic_alerts FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM profiles p 
    WHERE p.id = auth.uid() 
    AND p.role IN ('muthawif', 'admin')
  )
);
CREATE POLICY "panic_alert_muthawif_update" ON panic_alerts FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM profiles p 
    WHERE p.id = auth.uid() 
    AND p.role IN ('muthawif', 'admin')
  )
);
