-- Migration 017: Extend app_versions table
-- Adds min_version and download_url columns needed by app-version-check edge function.

ALTER TABLE app_versions
  ADD COLUMN IF NOT EXISTS min_version TEXT DEFAULT '0.0.0',
  ADD COLUMN IF NOT EXISTS download_url TEXT DEFAULT '';
