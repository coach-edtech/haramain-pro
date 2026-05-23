-- NRC Registration Table for SDAIA Compliance
-- Saudi Data & AI Office National Register Compliance

CREATE TABLE IF NOT EXISTS nrc_registrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Passport Information
  passport_number VARCHAR(50) NOT NULL,
  passport_expiry_date DATE NOT NULL,
  passport_country VARCHAR(100) NOT NULL,
  passport_image_url TEXT,
  
  -- Personal Information
  full_name VARCHAR(255) NOT NULL,
  nationality VARCHAR(100) NOT NULL,
  birth_date DATE NOT NULL,
  birth_place VARCHAR(100),
  gender VARCHAR(20) NOT NULL,
  
  -- Visa Information
  visa_number VARCHAR(50),
  visa_type VARCHAR(50),
  visa_expiry_date DATE,
  visa_image_url TEXT,
  
  -- Accommodation in Saudi Arabia
  accommodation_name VARCHAR(255) NOT NULL,
  accommodation_address TEXT,
  accommodation_city VARCHAR(100) NOT NULL,
  accommodation_phone VARCHAR(50),
  
  -- Itinerary
  itinerary_days TEXT[] NOT NULL,
  
  -- Status & Tracking
  status VARCHAR(20) DEFAULT 'draft',
  -- draft | submitted | under_review | approved | rejected
  rejection_reason TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  submitted_at TIMESTAMPTZ,
  reviewed_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_nrc_user_id ON nrc_registrations(user_id);
CREATE INDEX idx_nrc_status ON nrc_registrations(status);
CREATE INDEX idx_nrc_created_at ON nrc_registrations(created_at);

-- RLS Policies
ALTER TABLE nrc_registrations ENABLE ROW LEVEL SECURITY;

-- Users can only see their own NRC
CREATE POLICY "Users can view own NRC" ON nrc_registrations
  FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own NRC
CREATE POLICY "Users can insert own NRC" ON nrc_registrations
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own NRC (only if draft or rejected)
CREATE POLICY "Users can update own NRC" ON nrc_registrations
  FOR UPDATE USING (
    auth.uid() = user_id AND 
    status IN ('draft', 'rejected')
  );

-- Admin/Support can view all NRCs
CREATE POLICY "Admins can view all NRC" ON nrc_registrations
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role IN ('admin', 'agency')
    )
  );

-- Admin/Support can update NRC status
CREATE POLICY "Admins can update NRC status" ON nrc_registrations
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role IN ('admin', 'agency')
    )
  );

-- Storage bucket for NRC documents
INSERT INTO storage.buckets (id, name, public)
VALUES ('nrc_documents', 'nrc_documents', false)
ON CONFLICT (id) DO NOTHING;

-- RLS for storage
CREATE POLICY "Users can upload own NRC documents" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'nrc_documents' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can view own NRC documents" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'nrc_documents' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Admins can view all NRC documents" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'nrc_documents' AND
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role IN ('admin', 'agency')
    )
  );

COMMENT ON TABLE nrc_registrations IS 'SDAIA NRC Registration - Required for Saudi compliance';
