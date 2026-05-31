-- Migration: Add rombongan_id to alumni_reviews for romongan-scoped reviews
-- List reviews by romongan, and submit reviews attached to a romongan

-- Add rombongan_id column
ALTER TABLE alumni_reviews
  ADD COLUMN IF NOT EXISTS rombongan_id UUID REFERENCES rombangans(id) ON DELETE CASCADE;

-- Index for efficient listing by romongan
CREATE INDEX IF NOT EXISTS idx_ar_rombongan_id ON alumni_reviews(rombongan_id);

-- Allow pilgrims/jamaah to insert their own reviews for their romongan
-- (RLS will still enforce: they can only insert if their profile's rombongan_id matches)
-- No new RLS policy needed for INSERT since the column FK enforces referential integrity,
-- but we update the travel_admin policy to also allow reading by rombongan if needed.

-- Update ar_travel_admin_all policy to also allow travel_admin to manage
-- reviews belonging to any rombongan under their agency (via FK chain).
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

-- Allow users to insert reviews for their own romongan
DROP POLICY IF EXISTS "ar_user_insert_own" ON alumni_reviews;
CREATE POLICY "ar_user_insert_own" ON alumni_reviews
  FOR INSERT WITH CHECK (
    auth.uid() = user_id
    AND (
      -- Must provide matching rombongan_id that matches user's profile rombongan_id
      rombongan_id IS NOT NULL
      AND EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid() AND rombongan_id = alumni_reviews.rombongan_id
      )
    )
  );

-- Allow users to read their own reviews
DROP POLICY IF EXISTS "ar_user_read_own" ON alumni_reviews;
CREATE POLICY "ar_user_read_own" ON alumni_reviews
  FOR SELECT USING (
    auth.uid() = user_id
    OR is_published = true
  );
