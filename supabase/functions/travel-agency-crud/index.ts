// Edge Function: travel-agency-crud
// GET  /functions/v1/travel-agency-crud (list/search agencies)
// POST /functions/v1/travel-agency-crud (create agency)
// PATCH /functions/v1/travel-agency-crud?id= (update agency)

import { serve } from "https://deno.land/x/sift@0.6.0/mod.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://haramain.pro',
  'Access-Control-Allow-Methods': 'GET, POST, PATCH, OPTIONS',
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
  const tokenAgencyId = jwtPayload.agency_id;

  if (!['travel_admin', 'super_admin', 'admin_haramain_pro'].includes(role)) {
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

    // GET: list/search agencies
    if (req.method === 'GET') {
      const search = url.searchParams.get('search') || '';
      const wlStatus = url.searchParams.get('wl_status');
      const limit = Math.min(parseInt(url.searchParams.get('limit') || '50'), 100);

      let query = `${SUPABASE_URL}/rest/v1/agencies?order=created_at.desc&limit=${limit}`;
      if (search) query += `&name=ilike.*${search}*`;
      if (wlStatus) query += `&wl_status=eq.${wlStatus}`;

      // Non-super-admin can only see own agency
      if (role !== 'super_admin' && role !== 'admin_haramain_pro') {
        query = `${SUPABASE_URL}/rest/v1/agencies?id=eq.${tokenAgencyId}&select=*`;
      }

      const res = await fetch(query, { headers });
      const agencies: any[] = await res.json();

      return Response.json({
        agencies: agencies.map(a => ({
          id: a.id,
          name: a.name,
          address: a.address,
          phone: a.phone,
          wl_status: a.wl_status,
          seat_balance: a.seat_balance,
          low_stock_threshold: a.low_stock_threshold,
          created_at: a.created_at,
        })),
        count: agencies.length,
      }, { headers: corsHeaders });

    // POST: create agency
    } else if (req.method === 'POST') {
      if (role !== 'super_admin' && role !== 'admin_haramain_pro') {
        return Response.json({ error: 'Only super_admin can create agencies' }, { status: 403, headers: corsHeaders });
      }

      const { name, address, phone, email, initial_seat_balance = 0, low_stock_threshold = 20 } = await req.json();

      if (!name) {
        return Response.json({ error: 'name required' }, { status: 400, headers: corsHeaders });
      }

      const agencyRes = await fetch(`${SUPABASE_URL}/rest/v1/agencies`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          name,
          address: address || null,
          phone: phone || null,
          email: email || null,
          seat_balance: initial_seat_balance,
          low_stock_threshold,
          wl_status: 'trial',
        }),
      });
      const agencies = await agencyRes.json();

      return Response.json({ success: true, agency: agencies[0] }, { headers: corsHeaders });

    // PATCH: update agency
    } else if (req.method === 'PATCH') {
      const agencyId = url.searchParams.get('id');
      if (!agencyId) {
        return Response.json({ error: 'Agency id required' }, { status: 400, headers: corsHeaders });
      }

      // Non-super-admin can only update own agency
      if (role !== 'super_admin' && role !== 'admin_haramain_pro' && agencyId !== tokenAgencyId) {
        return Response.json({ error: 'Forbidden' }, { status: 403, headers: corsHeaders });
      }

      const body = await req.json();
      const { name, address, phone, email, wl_status, low_stock_threshold } = body;

      const updatePayload: any = {};
      if (name !== undefined) updatePayload.name = name;
      if (address !== undefined) updatePayload.address = address;
      if (phone !== undefined) updatePayload.phone = phone;
      if (email !== undefined) updatePayload.email = email;
      if (low_stock_threshold !== undefined) updatePayload.low_stock_threshold = low_stock_threshold;
      // Only super_admin can change wl_status
      if (wl_status !== undefined && (role === 'super_admin' || role === 'admin_haramain_pro')) {
        updatePayload.wl_status = wl_status;
      }

      if (Object.keys(updatePayload).length === 0) {
        return Response.json({ error: 'No valid fields to update' }, { status: 400, headers: corsHeaders });
      }

      await fetch(`${SUPABASE_URL}/rest/v1/agencies?id=eq.${agencyId}`, {
        method: 'PATCH',
        headers,
        body: JSON.stringify(updatePayload),
      });

      return Response.json({ success: true }, { headers: corsHeaders });

    } else {
      return Response.json({ error: 'Method not allowed' }, { status: 405, headers: corsHeaders });
    }

  } catch (error) {
    console.error('travel-agency-crud error:', error);
    return Response.json({ error: 'Internal server error' }, { status: 500, headers: corsHeaders });
  }
});
