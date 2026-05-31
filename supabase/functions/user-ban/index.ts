// Edge Function: user-ban
// POST /functions/v1/user-ban
// SuperAdmin only — bans a user and invalidates all their sessions.
//
// Body: { user_id: string, reason: string }
//
// What it does:
// 1. Validates the calling user is SuperAdmin
// 2. Checks the target user exists and is not already banned
// 3. Updates profiles: sets is_banned=true, banned_at, ban_reason, banned_by
// 4. Invalidates all active sessions for the banned user via Supabase Auth Admin API
// 5. Logs the ban action to audit_logs
// 6. Returns the ban record

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://haramain.pro',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

interface BanRequest {
  user_id: string
  reason: string
}

serve(async (req: Request) => {
  // ── CORS preflight ──────────────────────────────────────────────
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed' }),
      { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }

  // ── Authenticate caller ──────────────────────────────────────────
  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return new Response(
      JSON.stringify({ error: 'Missing Authorization header' }),
      { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false },
    }
  )

  const { data: { user: caller }, error: authError } = await supabase.auth.getUser()
  if (authError || !caller) {
    return new Response(
      JSON.stringify({ error: 'Unauthorized' }),
      { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }

  // ── Verify caller is SuperAdmin ──────────────────────────────────
  const { data: callerProfile, error: profileError } = await supabase
    .from('profiles')
    .select('id, role')
    .eq('id', caller.id)
    .single()

  if (profileError || !callerProfile) {
    return new Response(
      JSON.stringify({ error: 'Forbidden' }),
      { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }

  if (callerProfile.role !== 'super_admin') {
    return new Response(
      JSON.stringify({ error: 'Forbidden: SuperAdmin required' }),
      { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }

  // ── Parse & validate body ────────────────────────────────────────
  let body: BanRequest
  try {
    body = await req.json()
  } catch {
    return new Response(
      JSON.stringify({ error: 'Invalid JSON body' }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }

  const { user_id, reason } = body

  if (!user_id || typeof user_id !== 'string') {
    return new Response(
      JSON.stringify({ error: 'user_id is required and must be a string' }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }

  if (!reason || typeof reason !== 'string' || reason.trim().length === 0) {
    return new Response(
      JSON.stringify({ error: 'reason is required and must be a non-empty string' }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }

  // Prevent self-ban
  if (user_id === caller.id) {
    return new Response(
      JSON.stringify({ error: 'Cannot ban yourself' }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }

  // ── Service-role client for admin operations ────────────────────
  const serviceSupabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  // ── Check target user exists ─────────────────────────────────────
  const { data: targetProfile, error: targetError } = await serviceSupabase
    .from('profiles')
    .select('id, email, name, role, is_banned')
    .eq('id', user_id)
    .single()

  if (targetError || !targetProfile) {
    return new Response(
      JSON.stringify({ error: 'Target user not found' }),
      { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }

  // Cannot ban another SuperAdmin
  if (targetProfile.role === 'super_admin') {
    return new Response(
      JSON.stringify({ error: 'Cannot ban a SuperAdmin' }),
      { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }

  // Already banned
  if (targetProfile.is_banned === true) {
    return new Response(
      JSON.stringify({ error: 'User is already banned', user_id }),
      { status: 409, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }

  // ── Ban the user ────────────────────────────────────────────────
  const banTimestamp = new Date().toISOString()

  const { error: banError } = await serviceSupabase
    .from('profiles')
    .update({
      is_banned: true,
      banned_at: banTimestamp,
      ban_reason: reason.trim(),
      banned_by: caller.id,
    })
    .eq('id', user_id)

  if (banError) {
    return new Response(
      JSON.stringify({ error: 'Failed to ban user', details: banError.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }

  // ── Invalidate all sessions via Auth Admin API ───────────────────
  // List all sessions for the user, then revoke them.
  // Supabase Auth admin API: GET /auth/v1/admin/users/{id}/sessions → revoke
  const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
  const SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

  let sessionsRevoked = 0
  try {
    // Step 1: Get all sessions for the user
    const listRes = await fetch(
      `${SUPABASE_URL}/auth/v1/admin/users/${user_id}/sessions`,
      {
        headers: {
          Authorization: `Bearer ${SERVICE_KEY}`,
          apikey: SERVICE_KEY,
          'Content-Type': 'application/json',
        },
      }
    )

    if (listRes.ok) {
      const sessionsData = await listRes.json()
      const sessions: Array<{ id: string }> = sessionsData.sessions ?? []

      // Step 2: Revoke each session individually
      for (const session of sessions) {
        const revokeRes = await fetch(
          `${SUPABASE_URL}/auth/v1/admin/users/${user_id}/sessions/${session.id}`,
          {
            method: 'DELETE',
            headers: {
              Authorization: `Bearer ${SERVICE_KEY}`,
              apikey: SERVICE_KEY,
            },
          }
        )
        if (revokeRes.ok) {
          sessionsRevoked++
        }
      }
    } else {
      // Fallback: attempt global session revoke for the user
      // Some Supabase setups use a simpler revoke-all endpoint
      const revokeRes = await fetch(
        `${SUPABASE_URL}/auth/v1/admin/users/${user_id}/sessions`,
        {
          method: 'DELETE',
          headers: {
            Authorization: `Bearer ${SERVICE_KEY}`,
            apikey: SERVICE_KEY,
          },
        }
      )
      if (revokeRes.ok) {
        sessionsRevoked = -1 // indicates bulk revoke was used
      }
    }
  } catch (err) {
    // Session invalidation failure should not fail the whole ban operation
    console.error('Session invalidation error:', err)
  }

  // ── Log to audit_logs ───────────────────────────────────────────
  await serviceSupabase.from('audit_logs').insert({
    user_id: caller.id,
    user_email: caller.email,
    user_role: callerProfile.role,
    action: `Banned user ${targetProfile.email} — ${reason.trim()}`,
    action_type: 'SUSPEND',
    resource_type: 'profile',
    resource_id: user_id,
    metadata: {
      target_email: targetProfile.email,
      target_role: targetProfile.role,
      reason: reason.trim(),
      sessions_revoked: sessionsRevoked,
      banned_by: caller.id,
      banned_at: banTimestamp,
    },
  })

  // ── Return success ──────────────────────────────────────────────
  return new Response(
    JSON.stringify({
      success: true,
      user_id,
      banned_at: banTimestamp,
      reason: reason.trim(),
      banned_by: caller.id,
      sessions_revoked: sessionsRevoked,
      profile: {
        id: targetProfile.id,
        email: targetProfile.email,
        name: targetProfile.name,
        role: targetProfile.role,
        is_banned: true,
        banned_at: banTimestamp,
        ban_reason: reason.trim(),
      },
    }),
    { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  )
})
