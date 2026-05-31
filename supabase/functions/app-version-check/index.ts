// Edge Function: app-version-check
// GET /functions/v1/app-version-check?platform=ios|android&current_version=1.0.0
// PUBLIC endpoint — no auth required.
// Returns whether an app update is available for the given platform and version.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
}

/**
 * Compare two semantic versions.
 * Returns negative if a < b, zero if a == b, positive if a > b.
 */
function compareVersions(a: string, b: string): number {
  const parse = (v: string) => v.split('.').map(n => parseInt(n, 10) || 0)
  const [aMaj, aMin, aPat] = parse(a)
  const [bMaj, bMin, bPat] = parse(b)
  if (aMaj !== bMaj) return aMaj - bMaj
  if (aMin !== bMin) return aMin - bMin
  return aPat - bPat
}

interface AppVersionRecord {
  id: string
  version: string
  version_code: number
  platform: string
  release_type: string
  release_notes: string | null
  is_mandatory: boolean
  is_active: boolean
  published_at: string
  min_version: string | null
  download_url: string | null
}

serve(async (req: Request) => {
  // ── CORS preflight ──────────────────────────────────────────────
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  if (req.method !== 'GET') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed' }),
      { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }

  // ── Parse query params ───────────────────────────────────────────
  const url = new URL(req.url)
  const platform = url.searchParams.get('platform')
  const currentVersion = url.searchParams.get('current_version')

  // Validate platform
  if (!platform || (platform !== 'ios' && platform !== 'android')) {
    return new Response(
      JSON.stringify({
        error: 'Missing or invalid "platform" param. Must be "ios" or "android".',
      }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }

  // Validate current_version
  if (!currentVersion || typeof currentVersion !== 'string' || currentVersion.trim() === '') {
    return new Response(
      JSON.stringify({ error: 'Missing or invalid "current_version" param.' }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }

  const safeVersion = currentVersion.trim()

  // ── Query latest active version for this platform ────────────────
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  const { data: record, error: dbError } = await supabase
    .from('app_versions')
    .select('id, version, version_code, platform, release_type, release_notes, is_mandatory, min_version, download_url')
    .eq('platform', platform)
    .eq('is_active', true)
    .order('version_code', { ascending: false })
    .limit(1)
    .single()

  if (dbError || !record) {
    console.error('app-version-check DB error:', dbError)
    return new Response(
      JSON.stringify({ error: 'No version information found for this platform.' }),
      { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }

  const versionRec = record as AppVersionRecord
  const latestVer = versionRec.version
  const minVer = versionRec.min_version ?? '0.0.0'

  // update_available = latest > current
  const updateAvailable = compareVersions(safeVersion, latestVer) < 0

  // mandatory = user is below min_version OR the release is flagged mandatory
  const belowMinVersion = compareVersions(safeVersion, minVer) < 0
  const isMandatory = belowMinVersion || (versionRec.is_mandatory && updateAvailable)

  return new Response(
    JSON.stringify({
      update_available: updateAvailable,
      latest_version: latestVer,
      min_version: minVer,
      download_url: versionRec.download_url ?? '',
      is_mandatory: isMandatory,
      release_notes: versionRec.release_notes ?? '',
    }),
    { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  )
})
