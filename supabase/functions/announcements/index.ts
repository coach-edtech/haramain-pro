// Edge Function: announcements
// GET  /functions/v1/announcements - List active announcements (PUBLIC, no auth)
// POST /functions/v1/announcements - Create announcement (SuperAdmin only)
// DELETE /functions/v1/announcements?id= - Delete announcement (SuperAdmin only)

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
}

const ANNOUNCEMENT_TYPES = ['info', 'warning', 'promotion', 'maintenance'] as const
const PRIORITIES = ['low', 'normal', 'high', 'urgent'] as const
const TARGET_AUDIENCES = ['all', 'travel', 'agency', 'muthawif'] as const

type AnnouncementType = typeof ANNOUNCEMENT_TYPES[number]
type Priority = typeof PRIORITIES[number]
type TargetAudience = typeof TARGET_AUDIENCES[number]

interface Announcement {
  id: string
  title: string
  content: string
  announcement_type: AnnouncementType
  priority: Priority
  target_audience: TargetAudience
  is_active: boolean
  is_pinned: boolean
  starts_at: string | null
  ends_at: string | null
  created_at: string
  updated_at: string
  created_by: string | null
}

function isAnnouncementType(v: string): v is AnnouncementType {
  return ANNOUNCEMENT_TYPES.includes(v as AnnouncementType)
}

function isPriority(v: string): v is Priority {
  return PRIORITIES.includes(v as Priority)
}

function isTargetAudience(v: string): v is TargetAudience {
  return TARGET_AUDIENCES.includes(v as TargetAudience)
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  const url = new URL(req.url)

  // ── Auth helper ─────────────────────────────────────────────────────
  const getAuthPayload = (req: Request): Record<string, unknown> | null => {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader?.startsWith('Bearer ')) return null
    const token = authHeader.replace('Bearer ', '')
    try {
      return JSON.parse(atob(token.split('.')[1]))
    } catch {
      return null
    }
  }

  // ── SuperAdmin check ─────────────────────────────────────────────────
  const requireSuperAdmin = (req: Request): Response | null => {
    const payload = getAuthPayload(req)
    if (!payload) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }
    const role = payload.role as string
    if (role !== 'super_admin' && role !== 'admin_haramain_pro') {
      return new Response(JSON.stringify({ error: 'Forbidden: SuperAdmin only' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }
    return null
  }

  // ── GET — Public list of active announcements ───────────────────────
  if (req.method === 'GET') {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const targetAudience = url.searchParams.get('target_audience')
    const type = url.searchParams.get('type')
    const limit = Math.min(parseInt(url.searchParams.get('limit') || '20'), 100)

    let query = supabase
      .from('announcements')
      .select('id, title, content, announcement_type, priority, target_audience, is_pinned, starts_at, ends_at, created_at')
      .eq('is_active', true)
      .order('is_pinned', { ascending: false })
      .order('priority', { ascending: false })
      .order('created_at', { ascending: false })
      .limit(limit)

    // Date range filter — only show announcements within their active window
    query = query
      .or(`starts_at.is.null,starts_at.lte.now()`)
      .or(`ends_at.is.null,ends_at.gte.now()`)

    if (targetAudience && isTargetAudience(targetAudience)) {
      query = query.or(`target_audience.eq.${targetAudience},target_audience.eq.all`)
    }

    if (type && isAnnouncementType(type)) {
      query = query.eq('announcement_type', type)
    }

    const { data, error } = await query

    if (error) {
      console.error('announcements GET error:', error)
      return new Response(JSON.stringify({ error: 'Failed to fetch announcements' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    return new Response(JSON.stringify({ announcements: data ?? [] }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // ── POST — Create announcement (SuperAdmin only) ────────────────────
  if (req.method === 'POST') {
    const forbidden = requireSuperAdmin(req)
    if (forbidden) return forbidden

    let body: Record<string, unknown>
    try {
      body = await req.json()
    } catch {
      return new Response(JSON.stringify({ error: 'Invalid JSON body' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const { title, content, announcement_type, priority, target_audience, is_active, is_pinned, starts_at, ends_at } = body

    if (!title || typeof title !== 'string' || title.trim() === '') {
      return new Response(JSON.stringify({ error: 'title is required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (!content || typeof content !== 'string' || content.trim() === '') {
      return new Response(JSON.stringify({ error: 'content is required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (!announcement_type || !isAnnouncementType(announcement_type as string)) {
      return new Response(
        JSON.stringify({ error: `announcement_type must be one of: ${ANNOUNCEMENT_TYPES.join(', ')}` }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (priority && !isPriority(priority as string)) {
      return new Response(
        JSON.stringify({ error: `priority must be one of: ${PRIORITIES.join(', ')}` }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (target_audience && !isTargetAudience(target_audience as string)) {
      return new Response(
        JSON.stringify({ error: `target_audience must be one of: ${TARGET_AUDIENCES.join(', ')}` }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const payload = getAuthPayload(req)!
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const insertData: Record<string, unknown> = {
      title: (title as string).trim(),
      content: (content as string).trim(),
      announcement_type,
      priority: priority || 'normal',
      target_audience: target_audience || 'all',
      is_active: is_active !== undefined ? Boolean(is_active) : true,
      is_pinned: Boolean(is_pinned),
      starts_at: starts_at || null,
      ends_at: ends_at || null,
      created_by: payload.sub as string,
    }

    const { data, error: insertError } = await supabase
      .from('announcements')
      .insert(insertData)
      .select()
      .single()

    if (insertError) {
      console.error('announcements POST error:', insertError)
      return new Response(JSON.stringify({ error: 'Failed to create announcement' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    return new Response(JSON.stringify({ announcement: data }), {
      status: 201,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // ── DELETE — Delete announcement (SuperAdmin only) ──────────────────
  if (req.method === 'DELETE') {
    const forbidden = requireSuperAdmin(req)
    if (forbidden) return forbidden

    const id = url.searchParams.get('id')
    if (!id) {
      return new Response(JSON.stringify({ error: 'Announcement id (?id=) is required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { error: deleteError } = await supabase
      .from('announcements')
      .delete()
      .eq('id', id)

    if (deleteError) {
      console.error('announcements DELETE error:', deleteError)
      return new Response(JSON.stringify({ error: 'Failed to delete announcement' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    return new Response(JSON.stringify({ success: true, id }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  return new Response(JSON.stringify({ error: 'Method not allowed' }), {
    status: 405,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
})
