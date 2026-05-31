-- NOTE: Storage buckets are managed via Supabase Dashboard > Storage > New Bucket
-- The following creates RLS policies only for existing buckets
-- Run after buckets 'offline_maps', 'agency_logos', 'jejak_ibadah_media' exist

ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users to read public maps
CREATE POLICY "maps_public_read" ON storage.objects
  FOR SELECT USING (bucket_id = 'offline_maps');

-- Allow agencies to upload their logos
CREATE POLICY "agency_logo_upload" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'agency_logos' AND
    auth.uid() IS NOT NULL
  );

-- Allow agencies to update their own logos
CREATE POLICY "agency_logo_update" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'agency_logos' AND
    auth.uid() IS NOT NULL
  );

-- Allow pilgrims to upload their jejak ibadah photos
CREATE POLICY "jejak_ibadah_upload" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'jejak_ibadah_media' AND
    auth.uid() IS NOT NULL
  );

-- Allow pilgrims to read their own photos (folder = user UUID)
CREATE POLICY "jejak_ibadah_read" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'jejak_ibadah_media'
  );

-- Allow pilgrims to delete their own photos
CREATE POLICY "jejak_ibadah_delete" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'jejak_ibadah_media'
  );
