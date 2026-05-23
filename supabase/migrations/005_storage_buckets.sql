-- Storage Buckets Migration
-- Creates buckets for offline maps, agency logos, and jejak ibadah photos

-- Enable storage
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
  ('offline_maps', 'offline_maps', true, 524288000, NULL),  -- 500MB max, any file type
  ('agency_logos', 'agency_logos', false, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp']),  -- 10MB max, images only
  ('jejak_ibadah_media', 'jejak_ibadah_media', false, 5242880, ARRAY['image/webp', 'image/jpeg']);  -- 5MB max, images only

-- RLS Policies for storage.buckets
ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read public maps
CREATE POLICY "maps_public_read" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'offline_maps'
  );

-- Allow agencies to upload their logos
CREATE POLICY "agency_logo_upload" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'agency_logos' AND
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'agency'
    )
  );

-- Allow agencies to update their own logos
CREATE POLICY "agency_logo_update" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'agency_logos' AND
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'agency'
    )
  );

-- Allow pilgrims to upload their jejak ibadah photos
CREATE POLICY "jejak_ibadah_upload" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'jejak_ibadah_media' AND
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'pilgrim'
    )
  );

-- Allow pilgrims to read their own photos
CREATE POLICY "jejak_ibadah_read" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'jejak_ibadah_media' AND
    (
      auth.uid() = (storage.foldername(name))[1]::uuid
      OR EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = auth.uid() AND role IN ('muthawif', 'agency', 'admin')
      )
    )
  );

-- Allow agencies to read photos of their pilgrims
CREATE POLICY "jejak_ibadah_agency_read" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'jejak_ibadah_media' AND
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN rombangans r ON r.agency_id = p.id
      WHERE p.id = auth.uid() 
      AND p.role = 'agency'
      AND storage.foldername(name)[1]::uuid = ANY(
        SELECT id FROM profiles WHERE rombongan_id = ANY(
          SELECT id FROM rombangans WHERE agency_id = p.id
        )
      )
    )
  );

-- Allow pilgrims to delete their own photos
CREATE POLICY "jejak_ibadah_delete" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'jejak_ibadah_media' AND
    auth.uid() = (storage.foldername(name))[1]::uuid
  );
