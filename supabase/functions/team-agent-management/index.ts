// Edge Function: team-agent-management
// GET  /functions/v1/team-agent-management
// POST /functions/v1/team-agent-management (invite agent)
// PATCH /functions/v1/team-agent-management?id= (update agent role/status)
// DELETE /functions/v1/team-agent-management?id= (remove agent)

import { serve } from "https://deno.land/x/sift@0.6.0/mod.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://haramain.pro',
  'Access-Control-Allow-Methods': 'GET, POST, PATCH, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, content-type',
  'Access-Control-Max-Age': '86400',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  const authHeader = req.headers.get('Authorization');
  if (!authHeader?.startsWith('Bearer ')) {
    return Response.json({ error: 'Unauthorized' }, { status: 401, headers: corsHeaders });
  }

  const token = authHeader.replace('Bearer ', '');
  let jwtPayload: any;
  try {
    jwtPayload = JSON.parse(atob(token.split('.')[1]));
  } catch {
    return Response.json({ error: 'Invalid token' }, { status: 401, headers: corsHeaders });
  }

  const role = jwtPayload.role;
  const userId = jwtPayload.sub;
  const tokenAgencyId = jwtPayload.agency_id;

  if (!['travel_admin', 'team_support', 'super_admin', 'admin_haramain_pro'].includes(role)) {
    return Response.json({ error: 'Forbidden' }, { status: 403, headers: corsHeaders });
  }

  const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
  const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const headers = {
    'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
    'apikey': SUPABASE_SERVICE_KEY,
    'Content-Type': 'application/json',
  };

  try {
    const url = new URL(req.url);

    // GET: list team members
    if (req.method === 'GET') {
      let targetAgencyId = tokenAgencyId;
      if (role === 'super_admin' || role === 'admin_haramain_pro') {
        targetAgencyId = url.searchParams.get('agency_id') || tokenAgencyId;
      }

      const profilesRes = await fetch(
        `${SUPABASE_URL}/rest/v1/profiles?agency_id=eq.${targetAgencyId}&select=id,name,email,role,wl_status,created_at`,
        { headers }
      );
      const profiles: any[] = await profilesRes.json();

      return Response.json({
        members: profiles.map(p => ({
          id: p.id,
          name: p.name,
          email: p.email,
          role: p.role,
          wl_status: p.wl_status,
          created_at: p.created_at,
        })),
        count: profiles.length,
      }, { headers: corsHeaders });

    // POST: invite agent
    } else if (req.method === 'POST') {
      const { email, name, role = 'team_support', invite_code } = await req.json();

      if (!email || !name) {
        return Response.json({ error: 'email and name required' }, { status: 400, headers: corsHeaders });
      }

      const validRoles = ['team_support', 'muthawif'];
      if (!validRoles.includes(role)) {
        return Response.json({ error: `role must be one of: ${validRoles.join(', ')}` }, { status: 400, headers: corsHeaders });
      }

      // Check if user already exists
      const existingRes = await fetch(
        `${SUPABASE_URL}/rest/v1/profiles?email=eq.${encodeURIComponent(email)}&select=id`,
        { headers }
      );
      const existing: any[] = await existingRes.json();

      if (existing.length > 0) {
        return Response.json({ error: 'User with this email already exists' }, { status: 409, headers: corsHeaders });
      }

      // If invite_code provided, use it to assign agency
      let targetAgencyId = tokenAgencyId;
      if (invite_code && (role === 'super_admin' || role === 'admin_haramain_pro')) {
        // Look up agency by invite code
        const codeRes = await fetch(
          `${SUPABASE_URL}/rest/v1/redeem_codes?code=eq.${invite_code}&status=eq.available&type=eq.team_invite&select=agency_id`,
          { headers }
        );
        const codes: any[] = await codeRes.json();
        if (codes.length > 0) {
          targetAgencyId = codes[0].agency_id;
        }
      }

      // Create profile (user will be linked via auth later)
      const profileRes = await fetch(`${SUPABASE_URL}/rest/v1/profiles`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          email,
          name,
          role,
          agency_id: targetAgencyId,
          wl_status: 'pending',
          subscription_tier: 'pending',
        }),
      });
      const profiles = await profileRes.json();

      // Mark invite code as used if provided
      if (invite_code) {
        await fetch(
          `${SUPABASE_URL}/rest/v1/redeem_codes?code=eq.${invite_code}`,
          {
            method: 'PATCH',
            headers,
            body: JSON.stringify({ status: 'used' }),
          }
        );
      }

      return Response.json({
        success: true,
        profile: profiles[0],
        invite_code: invite_code || null,
      }, { headers: corsHeaders });

    // PATCH: update agent
    } else if (req.method === 'PATCH') {
      const memberId = url.searchParams.get('id');
      if (!memberId) {
        return Response.json({ error: 'Member id required' }, { status: 400, headers: corsHeaders });
      }

      const { role, wl_status, name } = await req.json();

      const updatePayload: any = {};
      if (role !== undefined) updatePayload.role = role;
      if (wl_status !== undefined) updatePayload.wl_status = wl_status;
      if (name !== undefined) updatePayload.name = name;

      if (Object.keys(updatePayload).length === 0) {
        return Response.json({ error: 'No fields to update' }, { status: 400, headers: corsHeaders });
      }

      await fetch(`${SUPABASE_URL}/rest/v1/profiles?id=eq.${memberId}`, {
        method: 'PATCH',
        headers,
        body: JSON.stringify(updatePayload),
      });

      return Response.json({ success: true }, { headers: corsHeaders });

    // DELETE: remove agent
    } else if (req.method === 'DELETE') {
      const memberId = url.searchParams.get('id');
      if (!memberId) {
        return Response.json({ error: 'Member id required' }, { status: 400, headers: corsHeaders });
      }

      // Can't remove self
      if (memberId === userId) {
        return Response.json({ error: 'Cannot remove yourself' }, { status: 400, headers: corsHeaders });
      }

      // Remove from agency (set agency_id to null, role to null)
      await fetch(`${SUPABASE_URL}/rest/v1/profiles?id=eq.${memberId}`, {
        method: 'PATCH',
        headers,
        body: JSON.stringify({
          agency_id: null,
          role: null,
          wl_status: 'removed',
        }),
      });

      return Response.json({ success: true }, { headers: corsHeaders });

    } else {
      return Response.json({ error: 'Method not allowed' }, { status: 405, headers: corsHeaders });
    }

  } catch (error) {
    console.error('team-agent-management error:', error);
    return Response.json({ error: 'Internal server error' }, { status: 500, headers: corsHeaders });
  }
});
