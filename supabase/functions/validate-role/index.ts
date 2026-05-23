// Edge Function: validate-role
// Server-side role validation — the source of truth for user roles.
// Clients MUST NOT trust local state alone.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface RoleResponse {
  role: string
  default_route: string
}

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Create Supabase client with user's JWT
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

    // Validate the JWT and get the user
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Query the profiles table for the authoritative role
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('role, name')
      .eq('id', user.id)
      .single()

    if (profileError || !profile) {
      // Fallback: try to get from user metadata if profile not found
      const metaRole = user.user_metadata?.role as string | undefined
      if (!metaRole) {
        return new Response(
          JSON.stringify({ error: 'Profile not found and no role in metadata' }),
          { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
      // Use metadata role as fallback
      const response: RoleResponse = {
        role: mapLegacyRole(metaRole),
        default_route: getDefaultRouteForRole(mapLegacyRole(metaRole)),
      }
      return new Response(JSON.stringify(response), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const response: RoleResponse = {
      role: profile.role,
      default_route: getDefaultRouteForRole(profile.role),
    }

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    return new Response(
      JSON.stringify({ error: 'Internal server error', details: String(err) }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

function getDefaultRouteForRole(role: string): string {
  switch (role) {
    case 'super_admin':
    case 'admin_haramain_pro':
      return '/admin'
    case 'travel_admin':
    case 'team_support':
    case 'muthawif':
      return '/travel-admin'
    case 'jamaah':
    case 'jamaah_mandiri':
      return '/jamaah'
    default:
      return '/'
  }
}

function mapLegacyRole(role: string): string {
  // Map old schema roles to new UserRole format
  const map: Record<string, string> = {
    admin: 'admin_haramain_pro',
    agency: 'travel_admin',
    pilgrim: 'jamaah',
  }
  return map[role] ?? role
}
