// Edge Function: fraud-detection
// GET /functions/v1/fraud-detection?user_id=UUID  - Get fraud risk for a specific user
// GET /functions/v1/fraud-detection               - List all flagged users
// Access: SuperAdmin only

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://haramain.pro',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
}

// Risk score mapping: qualitative -> 0-100
const RISK_SCORE_MAP: Record<string, number> = {
  low: 25,
  medium: 50,
  high: 75,
  critical: 100,
}

// Flag types for fraud detection
const FLAG_TYPES = [
  'multiple_accounts',
  'suspicious_payment',
  'unusual_location',
  'velocity_check',
  'chargeback',
  'fake_identity',
  'abuse_promo',
  'session_anomaly',
  'api_abuse',
  'payment_declined_repeated',
]

// Compute overall risk score (0-100) from flags
function computeRiskScore(flags: any[]): number {
  if (!flags || flags.length === 0) return 0

  // Weight by severity
  const weightedSum = flags.reduce((sum, flag) => {
    const score = RISK_SCORE_MAP[flag.risk_score] ?? 50
    return sum + score
  }, 0)

  // Average weighted by count, boosted for multiple flags
  const baseScore = weightedSum / flags.length

  // Multi-flag boost: if user has 3+ flags, increase risk
  const multiFlagBoost = flags.length >= 3 ? Math.min(flags.length * 3, 20) : 0

  // Unreviewed flags boost risk (pending = more suspicious)
  const pendingFlags = flags.filter(f => f.status === 'pending').length
  const pendingBoost = pendingFlags > 0 ? Math.min(pendingFlags * 5, 15) : 0

  return Math.min(100, Math.round(baseScore + multiFlagBoost + pendingBoost))
}

// Determine risk level label from score
function getRiskLevel(score: number): string {
  if (score >= 80) return 'critical'
  if (score >= 60) return 'high'
  if (score >= 35) return 'medium'
  if (score > 0) return 'low'
  return 'none'
}

// GET /functions/v1/fraud-detection?user_id=UUID
async function handleGetByUser(supabase: any, userId: string) {
  // Fetch all fraud flags for this user
  const { data: flags, error } = await supabase
    .from('fraud_flags')
    .select('*')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })

  if (error) {
    return Response.json({ error: error.message }, { status: 500, headers: corsHeaders })
  }

  // Fetch user profile info
  const { data: profile, error: profileError } = await supabase
    .from('profiles')
    .select('id, email, full_name, role, is_fraud_flagged, fraud_flag_reason, fraud_review_notes, created_at')
    .eq('id', userId)
    .single()

  if (profileError && profileError.code !== 'PGRST116') {
    return Response.json({ error: profileError.message }, { status: 500, headers: corsHeaders })
  }

  const riskScore = computeRiskScore(flags ?? [])
  const riskLevel = getRiskLevel(riskScore)

  // Aggregate flags by type
  const flagsByType: Record<string, number> = {}
  for (const flag of (flags ?? [])) {
    flagsByType[flag.flag_type] = (flagsByType[flag.flag_type] ?? 0) + 1
  }

  // Count by status
  const statusCounts = {
    pending: flags?.filter(f => f.status === 'pending').length ?? 0,
    reviewed: flags?.filter(f => f.status === 'reviewed').length ?? 0,
    false_positive: flags?.filter(f => f.status === 'false_positive').length ?? 0,
    confirmed: flags?.filter(f => f.status === 'confirmed').length ?? 0,
  }

  return Response.json({
    user_id: userId,
    profile: profile ? {
      id: profile.id,
      email: profile.email,
      full_name: profile.full_name,
      role: profile.role,
      is_fraud_flagged: profile.is_fraud_flagged,
      fraud_flag_reason: profile.fraud_flag_reason,
      fraud_review_notes: profile.fraud_review_notes,
      created_at: profile.created_at,
    } : null,
    fraud_flags: flags ?? [],
    flags_count: flags?.length ?? 0,
    flags_by_type: flagsByType,
    status_counts: statusCounts,
    risk_score: riskScore,
    risk_level: riskLevel,
  }, { headers: corsHeaders })
}

// GET /functions/v1/fraud-detection (list all flagged users)
async function handleGetAll(supabase: any, url: URL) {
  const limit = Math.min(parseInt(url.searchParams.get('limit') ?? '50'), 200)
  const offset = parseInt(url.searchParams.get('offset') ?? '0')
  const status = url.searchParams.get('status') // pending, reviewed, false_positive, confirmed
  const riskScore = url.searchParams.get('risk_score') // low, medium, high, critical
  const flaggedOnly = url.searchParams.get('flagged_only') !== 'false' // default true

  // Get distinct user_ids with fraud flags, optionally filtered
  let query = supabase
    .from('fraud_flags')
    .select('*', { count: 'exact' })
    .order('created_at', { ascending: false })

  if (status) query = query.eq('status', status)
  if (riskScore) query = query.eq('risk_score', riskScore)

  const { data: flags, error, count } = await query.range(offset, offset + limit - 1)

  if (error) {
    return Response.json({ error: error.message }, { status: 500, headers: corsHeaders })
  }

  // Group by user_id and compute risk scores
  const userMap = new Map<string, any>()

  for (const flag of (flags ?? [])) {
    if (!userMap.has(flag.user_id)) {
      userMap.set(flag.user_id, {
        user_id: flag.user_id,
        flags: [],
        profile: null,
      })
    }
    userMap.get(flag.user_id).flags.push(flag)
  }

  // Fetch profiles for all flagged users
  const userIds = Array.from(userMap.keys())
  let profiles: any[] = []
  if (userIds.length > 0) {
    const { data: profileData } = await supabase
      .from('profiles')
      .select('id, email, full_name, role, is_fraud_flagged, fraud_flag_reason, created_at')
      .in('id', userIds)
    profiles = profileData ?? []
  }

  const profileMap = new Map(profiles.map(p => [p.id, p]))

  // Build response for each user
  const users: any[] = []
  for (const [userId, entry] of userMap) {
    const profile = profileMap.get(userId) ?? null
    const riskScore = computeRiskScore(entry.flags)
    const riskLevel = getRiskLevel(riskScore)

    // Count by status
    const statusCounts = {
      pending: entry.flags.filter((f: any) => f.status === 'pending').length,
      reviewed: entry.flags.filter((f: any) => f.status === 'reviewed').length,
      false_positive: entry.flags.filter((f: any) => f.status === 'false_positive').length,
      confirmed: entry.flags.filter((f: any) => f.status === 'confirmed').length,
    }

    // Most severe flag
    const severityOrder = ['critical', 'high', 'medium', 'low']
    const mostSevereFlag = entry.flags.reduce((best: any, flag: any) => {
      const bestIdx = severityOrder.indexOf(best.risk_score)
      const flagIdx = severityOrder.indexOf(flag.risk_score)
      return flagIdx < bestIdx ? flag : best
    }, entry.flags[0])

    users.push({
      user_id: userId,
      profile: profile ? {
        id: profile.id,
        email: profile.email,
        full_name: profile.full_name,
        role: profile.role,
        is_fraud_flagged: profile.is_fraud_flagged,
        fraud_flag_reason: profile.fraud_flag_reason,
        created_at: profile.created_at,
      } : null,
      flags_count: entry.flags.length,
      risk_score: riskScore,
      risk_level: riskLevel,
      most_severe_flag: {
        flag_type: mostSevereFlag?.flag_type,
        risk_score: mostSevereFlag?.risk_score,
        status: mostSevereFlag?.status,
        created_at: mostSevereFlag?.created_at,
      },
      status_counts: statusCounts,
      latest_flag_at: entry.flags[0]?.created_at,
      latest_flags: entry.flags.slice(0, 5), // Latest 5 flags
    })
  }

  // Sort by risk score descending
  users.sort((a, b) => b.risk_score - a.risk_score)

  // Summary statistics
  const summary = {
    total_flagged_users: count ?? users.length,
    critical_count: users.filter(u => u.risk_level === 'critical').length,
    high_count: users.filter(u => u.risk_level === 'high').length,
    medium_count: users.filter(u => u.risk_level === 'medium').length,
    low_count: users.filter(u => u.risk_level === 'low').length,
    pending_review_count: users.filter(u => u.status_counts.pending > 0).length,
    confirmed_fraud_count: users.filter(u => u.status_counts.confirmed > 0).length,
  }

  return Response.json({
    users,
    summary,
    count: users.length,
    total: count,
    limit,
    offset,
  }, { headers: corsHeaders })
}

// ─── Main handler ───────────────────────────────────────────────────────────
serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  if (req.method !== 'GET') {
    return Response.json({ error: 'Method not allowed' }, { status: 405, headers: corsHeaders })
  }

  // Auth
  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return Response.json({ error: 'Unauthorized' }, { status: 401, headers: corsHeaders })
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false },
    },
  )

  const { data: { user }, error: authError } = await supabase.auth.getUser()
  if (authError || !user) {
    return Response.json({ error: 'Unauthorized' }, { status: 401, headers: corsHeaders })
  }

  // Verify SuperAdmin role from profiles table
  const { data: profile, error: profileError } = await supabase
    .from('profiles')
    .select('id, role')
    .eq('id', user.id)
    .single()

  if (profileError || !profile) {
    return Response.json({ error: 'Forbidden' }, { status: 403, headers: corsHeaders })
  }

  if (!['super_admin', 'admin_haramain_pro'].includes(profile.role)) {
    return Response.json({ error: 'Forbidden: SuperAdmin only' }, { status: 403, headers: corsHeaders })
  }

  const url = new URL(req.url)
  const userId = url.searchParams.get('user_id')

  if (userId) {
    // Validate UUID format
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
    if (!uuidRegex.test(userId)) {
      return Response.json({ error: 'Invalid user_id format. Must be a valid UUID.' }, { status: 400, headers: corsHeaders })
    }
    return handleGetByUser(supabase, userId)
  } else {
    return handleGetAll(supabase, url)
  }
})
