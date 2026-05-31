// Edge Function: audit-logs
// GET /functions/v1/audit-logs  - List/query audit events
// POST /functions/v1/audit-logs - Create a new audit event
// Access: SuperAdmin + admin_haramain_pro only

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://haramain.pro',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
}

const VALID_ACTION_TYPES = [
  'CREATE', 'READ', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT',
  'APPROVE', 'REJECT', 'SUSPEND', 'ACTIVATE', 'EXPORT', 'IMPORT',
  'PAYMENT', 'REFUND', 'TRANSFER', 'ASSIGN', 'UNASSIGN',
  'PANIC', 'EMERGENCY', 'SYSTEM', 'OTHER',
]

// ─── GET /functions/v1/audit-logs ───────────────────────────────────────────
async function handleGet(req: Request, supabase: any, userId: string) {
  const url = new URL(req.url)
  const limit = Math.min(parseInt(url.searchParams.get('limit') ?? '50'), 200)
  const offset = parseInt(url.searchParams.get('offset') ?? '0')
  const userIdFilter = url.searchParams.get('user_id')
  const actionType = url.searchParams.get('action_type')
  const action = url.searchParams.get('action')
  const resourceType = url.searchParams.get('resource_type')
  const resourceId = url.searchParams.get('resource_id')
  const startDate = url.searchParams.get('start_date')
  const endDate = url.searchParams.get('end_date')

  let query = supabase
    .from('audit_logs')
    .select('*', { count: 'exact' })
    .order('created_at', { ascending: false })
    .range(offset, offset + limit - 1)

  if (userIdFilter) query = query.eq('user_id', userIdFilter)
  if (actionType) query = query.eq('action_type', actionType)
  if (action) query = query.ilike('action', `%${action}%`)
  if (resourceType) query = query.eq('resource_type', resourceType)
  if (resourceId) query = query.eq('resource_id', resourceId)
  if (startDate) query = query.gte('created_at', startDate)
  if (endDate) query = query.lte('created_at', endDate)

  const { data, error, count } = await query

  if (error) {
    return Response.json({ error: error.message }, { status: 500, headers: corsHeaders })
  }

  return Response.json({
    data,
    count,
    limit,
    offset,
  }, { headers: corsHeaders })
}

// ─── POST /functions/v1/audit-logs ──────────────────────────────────────────
async function handlePost(req: Request, supabase: any, userId: string) {
  const body = await req.json()
  const {
    action,
    action_type,
    resource_type,
    resource_id,
    metadata = {},
    user_email,
    user_role,
    ip_address,
    user_agent,
    request_id,
  } = body

  // Validation
  if (!action || !action_type || !resource_type) {
    return Response.json({
      error: 'Missing required fields: action, action_type, resource_type',
    }, { status: 400, headers: corsHeaders })
  }

  if (!VALID_ACTION_TYPES.includes(action_type)) {
    return Response.json({
      error: `Invalid action_type. Must be one of: ${VALID_ACTION_TYPES.join(', ')}`,
    }, { status: 400, headers: corsHeaders })
  }

  if (metadata && typeof metadata !== 'object') {
    return Response.json({
      error: 'metadata must be an object',
    }, { status: 400, headers: corsHeaders })
  }

  const { data, error } = await supabase
    .from('audit_logs')
    .insert({
      user_id: userId,
      user_email: user_email ?? null,
      user_role: user_role ?? null,
      action,
      action_type,
      resource_type,
      resource_id: resource_id ?? null,
      metadata,
      ip_address: ip_address ?? null,
      user_agent: user_agent ?? null,
      request_id: request_id ?? null,
    })
    .select()
    .single()

  if (error) {
    return Response.json({ error: error.message }, { status: 500, headers: corsHeaders })
  }

  return Response.json({ data }, { status: 201, headers: corsHeaders })
}

// ─── Main handler ────────────────────────────────────────────────────────────
serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
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

  // Verify role from profiles table
  const { data: profile, error: profileError } = await supabase
    .from('profiles')
    .select('id, role')
    .eq('id', user.id)
    .single()

  if (profileError || !profile) {
    return Response.json({ error: 'Forbidden' }, { status: 403, headers: corsHeaders })
  }

  if (!['super_admin', 'admin_haramain_pro'].includes(profile.role)) {
    return Response.json({ error: 'Forbidden' }, { status: 403, headers: corsHeaders })
  }

  // Route
  if (req.method === 'GET') {
    return handleGet(req, supabase, user.id)
  } else if (req.method === 'POST') {
    return handlePost(req, supabase, user.id)
  } else {
    return Response.json({ error: 'Method not allowed' }, { status: 405, headers: corsHeaders })
  }
})
