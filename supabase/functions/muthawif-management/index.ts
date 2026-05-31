// Edge Function: muthawif-management
// GET    /functions/v1/muthawif-management          - list muthawifs by agency (query: agency_id, search)
// POST   /functions/v1/muthawif-management          - create muthawif
// PATCH  /functions/v1/muthawif-management?id=      - update muthawif
// DELETE /functions/v1/muthawif-management?id=      - delete (soft: is_active=false) muthawif
// POST   /functions/v1/muthawif-management/assign   - assign muthawif to romongan
// DELETE /functions/v1/muthawif-management/assign?id= - remove muthawif from romongan

import { serve } from "https://deno.land/x/sift@0.6.0/mod.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://haramain.pro',
  'Access-Control-Allow-Methods': 'GET, POST, PATCH, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, content-type',
  'Access-Control-Max-Age': '86400',
};

const ALLOWED_ROLES = ['super_admin', 'admin_haramain_pro', 'travel_admin'];

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

  if (!ALLOWED_ROLES.includes(role)) {
    return Response.json({ error: 'Forbidden' }, { status: 403, headers: corsHeaders });
  }

  const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
  const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const headers = {
    'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
    'apikey': SUPABASE_SERVICE_KEY,
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };

  try {
    const url = new URL(req.url);
    const pathParts = url.pathname.split('/').filter(Boolean);
    const lastPart = pathParts[pathParts.length - 1];
    const isAssignEndpoint = lastPart === 'assign';
    const isDeleteAssign = req.method === 'DELETE' && isAssignEndpoint;

    // ── POST /assign ──────────────────────────────────────────────
    if (req.method === 'POST' && isAssignEndpoint) {
      const { muthawif_id, romongan_id, role_in_rombongan = 'muthawif' } = await req.json();

      if (!muthawif_id || !romongan_id) {
        return Response.json({ error: 'muthawif_id and romongan_id required' }, { status: 400, headers: corsHeaders });
      }

      // Verify muthawif belongs to agency (or super)
      const mRes = await fetch(`${SUPABASE_URL}/rest/v1/muthawifs?id=eq.${muthawif_id}&agency_id=eq.${tokenAgencyId}&select=id,agency_id`, { headers });
      const muthawifs: any[] = await mRes.json();
      if (muthawifs.length === 0 && role !== 'super_admin' && role !== 'admin_haramain_pro') {
        return Response.json({ error: 'Muthawif not found or not in your agency' }, { status: 404, headers: corsHeaders });
      }

      // Verify romongan belongs to agency
      const rRes = await fetch(`${SUPABASE_URL}/rest/v1/rombongans?id=eq.${romongan_id}&agency_id=eq.${tokenAgencyId}&select=id`, { headers });
      const roms: any[] = await rRes.json();
      if (roms.length === 0 && role !== 'super_admin' && role !== 'admin_haramain_pro') {
        return Response.json({ error: 'Romongan not found or not in your agency' }, { status: 404, headers: corsHeaders });
      }

      const assignRes = await fetch(`${SUPABASE_URL}/rest/v1/muthawif_rombongan`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          muthawif_id,
          romongan_id,
          role_in_rombongan,
        }),
      });
      const created = await assignRes.json();

      if (assignRes.status === 409) {
        return Response.json({ error: 'Muthawif already assigned to this romongan' }, { status: 409, headers: corsHeaders });
      }

      return Response.json({ success: true, assignment: created[0] ?? created }, { status: 201, headers: corsHeaders });
    }

    // ── DELETE /assign ────────────────────────────────────────────
    if (isDeleteAssign) {
      const mrId = url.searchParams.get('id');
      if (!mrId) return Response.json({ error: 'Assignment id required' }, { status: 400, headers: corsHeaders });

      const delRes = await fetch(`${SUPABASE_URL}/rest/v1/muthawif_rombongan?id=eq.${mrId}`, {
        method: 'DELETE',
        headers,
      });

      if (delRes.status === 204 || delRes.status === 200) {
        return Response.json({ success: true }, { headers: corsHeaders });
      }
      return Response.json({ error: 'Failed to remove assignment' }, { status: 500, headers: corsHeaders });
    }

    // ── GET /muthawif-management ─────────────────────────────────
    if (req.method === 'GET') {
      const agencyIdParam = url.searchParams.get('agency_id');
      const search = url.searchParams.get('search') || '';
      const limit = Math.min(parseInt(url.searchParams.get('limit') || '50'), 100);

      // Determine target agency_id
      let targetAgencyId = agencyIdParam;
      if (!targetAgencyId) {
        // Default to token's agency for non-super
        targetAgencyId = tokenAgencyId;
      } else if (role !== 'super_admin' && role !== 'admin_haramain_pro') {
        // Non-super cannot query arbitrary agencies
        targetAgencyId = tokenAgencyId;
      }

      if (!targetAgencyId) {
        return Response.json({ error: 'agency_id required (query param or token)' }, { status: 400, headers: corsHeaders });
      }

      let query = `${SUPABASE_URL}/rest/v1/muthawifs?agency_id=eq.${targetAgencyId}&is_active=eq.true&order=created_at.desc&limit=${limit}`;
      if (search) {
        query += `&or=(name.ilike.*${search}*,phone.ilike.*${search}*,email.ilike.*${search}*)`;
      }

      const res = await fetch(query, { headers });
      const muthawifs: any[] = await res.json();

      // Fetch romongan assignments for these muthawifs
      if (muthawifs.length === 0) {
        return Response.json({ muthawifs: [], count: 0 }, { headers: corsHeaders });
      }

      const muthawifIds = muthawifs.map(m => m.id);
      const mrRes = await fetch(
        `${SUPABASE_URL}/rest/v1/muthawif_rombongan?muthawif_id=in.(${muthawifIds.join(',')})&select=*`,
        { headers }
      );
      const assignments: any[] = await mrRes.json();

      const romonganIds = [...new Set(assignments.map(a => a.rombongan_id))];
      let romonganMap: Record<string, any> = {};
      if (romonganIds.length > 0) {
        const romRes = await fetch(
          `${SUPABASE_URL}/rest/v1/rombongans?id=in.(${romonganIds.join(',')})&select=id,name,status`,
          { headers }
        );
        const roms: any[] = await romRes.json();
        romonganMap = Object.fromEntries(roms.map(r => [r.id, r]));
      }

      return Response.json({
        muthawifs: muthawifs.map(m => ({
          id: m.id,
          profile_id: m.profile_id,
          agency_id: m.agency_id,
          name: m.name,
          phone: m.phone,
          email: m.email,
          specialization: m.specialization,
          license_number: m.license_number,
          is_active: m.is_active,
          created_at: m.created_at,
          assignments: assignments
            .filter(a => a.muthawif_id === m.id)
            .map(a => ({
              id: a.id,
              romongan_id: a.rombongan_id,
              romongan_name: romonganMap[a.rombongan_id]?.name ?? null,
              romongan_status: romonganMap[a.rombongan_id]?.status ?? null,
              role_in_rombongan: a.role_in_rombongan,
              assigned_at: a.assigned_at,
            })),
        })),
        count: muthawifs.length,
      }, { headers: corsHeaders });
    }

    // ── POST ─────────────────────────────────────────────────────
    if (req.method === 'POST') {
      const { profile_id, name, phone, email, specialization, license_number } = await req.json();

      if (!profile_id || !name) {
        return Response.json({ error: 'profile_id and name required' }, { status: 400, headers: corsHeaders });
      }

      // Use token agency if not super
      let agencyId = tokenAgencyId;
      if (role === 'super_admin' || role === 'admin_haramain_pro') {
        agencyId = url.searchParams.get('agency_id') || tokenAgencyId;
      }

      if (!agencyId) {
        return Response.json({ error: 'agency_id required' }, { status: 400, headers: corsHeaders });
      }

      // Check profile_id already has a muthawif record
      const existing = await fetch(`${SUPABASE_URL}/rest/v1/muthawifs?profile_id=eq.${profile_id}&select=id`, { headers });
      const existingData: any[] = await existing.json();
      if (existingData.length > 0) {
        return Response.json({ error: 'Profile already registered as muthawif' }, { status: 409, headers: corsHeaders });
      }

      const createRes = await fetch(`${SUPABASE_URL}/rest/v1/muthawifs`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          profile_id,
          agency_id: agencyId,
          name,
          phone: phone || null,
          email: email || null,
          specialization: specialization || null,
          license_number: license_number || null,
        }),
      });
      const created: any[] = await createRes.json();

      if (!createRes.ok) {
        const errMsg = Array.isArray(created) ? (created[0]?.message || 'Failed to create muthawif') : 'Failed to create muthawif';
        return Response.json({ error: errMsg }, { status: 400, headers: corsHeaders });
      }

      return Response.json({ success: true, muthawif: created[0] }, { status: 201, headers: corsHeaders });
    }

    // ── PATCH ─────────────────────────────────────────────────────
    if (req.method === 'PATCH') {
      const muthawifId = url.searchParams.get('id');
      if (!muthawifId) {
        return Response.json({ error: 'Muthawif id required' }, { status: 400, headers: corsHeaders });
      }

      // Verify ownership / agency
      const checkRes = await fetch(`${SUPABASE_URL}/rest/v1/muthawifs?id=eq.${muthawifId}&select=id,agency_id`, { headers });
      const check: any[] = await checkRes.json();
      if (check.length === 0) {
        return Response.json({ error: 'Muthawif not found' }, { status: 404, headers: corsHeaders });
      }
      if (role !== 'super_admin' && role !== 'admin_haramain_pro' && check[0].agency_id !== tokenAgencyId) {
        return Response.json({ error: 'Forbidden' }, { status: 403, headers: corsHeaders });
      }

      const body = await req.json();
      const { name, phone, email, specialization, license_number, is_active } = body;

      const updatePayload: any = {};
      if (name !== undefined) updatePayload.name = name;
      if (phone !== undefined) updatePayload.phone = phone;
      if (email !== undefined) updatePayload.email = email;
      if (specialization !== undefined) updatePayload.specialization = specialization;
      if (license_number !== undefined) updatePayload.license_number = license_number;
      if (is_active !== undefined) updatePayload.is_active = is_active;

      if (Object.keys(updatePayload).length === 0) {
        return Response.json({ error: 'No valid fields to update' }, { status: 400, headers: corsHeaders });
      }

      updatePayload.updated_at = new Date().toISOString();

      await fetch(`${SUPABASE_URL}/rest/v1/muthawifs?id=eq.${muthawifId}`, {
        method: 'PATCH',
        headers: { ...headers, 'Prefer': 'return=minimal' },
        body: JSON.stringify(updatePayload),
      });

      return Response.json({ success: true }, { headers: corsHeaders });
    }

    // ── DELETE ─────────────────────────────────────────────────────
    if (req.method === 'DELETE') {
      const muthawifId = url.searchParams.get('id');
      if (!muthawifId) {
        return Response.json({ error: 'Muthawif id required' }, { status: 400, headers: corsHeaders });
      }

      const checkRes = await fetch(`${SUPABASE_URL}/rest/v1/muthawifs?id=eq.${muthawifId}&select=id,agency_id`, { headers });
      const check: any[] = await checkRes.json();
      if (check.length === 0) {
        return Response.json({ error: 'Muthawif not found' }, { status: 404, headers: corsHeaders });
      }
      if (role !== 'super_admin' && role !== 'admin_haramain_pro' && check[0].agency_id !== tokenAgencyId) {
        return Response.json({ error: 'Forbidden' }, { status: 403, headers: corsHeaders });
      }

      // Soft-delete: set is_active = false
      await fetch(`${SUPABASE_URL}/rest/v1/muthawifs?id=eq.${muthawifId}`, {
        method: 'PATCH',
        headers: { ...headers, 'Prefer': 'return=minimal' },
        body: JSON.stringify({ is_active: false, updated_at: new Date().toISOString() }),
      });

      return Response.json({ success: true }, { headers: corsHeaders });
    }

    return Response.json({ error: 'Method not allowed' }, { status: 405, headers: corsHeaders });

  } catch (error) {
    console.error('muthawif-management error:', error);
    return Response.json({ error: 'Internal server error' }, { status: 500, headers: corsHeaders });
  }
});
