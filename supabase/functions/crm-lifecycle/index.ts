// Edge Function: crm-lifecycle
// GET  /functions/v1/crm-lifecycle
// GET  /functions/v1/crm-lifecycle?user_id= (detail)
// PATCH /functions/v1/crm-lifecycle (update stage)

import { serve } from "https://deno.land/x/sift@0.6.0/mod.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://haramain.pro',
  'Access-Control-Allow-Methods': 'GET, PATCH, POST, OPTIONS',
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

  if (!['travel_admin', 'team_support', 'muthawif', 'super_admin', 'admin_haramain_pro'].includes(role)) {
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
    const userIdParam = url.searchParams.get('user_id');

    // GET: lifecycle dashboard summary
    if (req.method === 'GET' && !userIdParam) {
      // Determine target agency
      let targetAgencyId = tokenAgencyId;
      if (role === 'super_admin' || role === 'admin_haramain_pro') {
        targetAgencyId = url.searchParams.get('agency_id') || tokenAgencyId;
      }

      const filterStage = url.searchParams.get('stage');

      let query = `${SUPABASE_URL}/rest/v1/pilgrim_lifecycle?agency_id=eq.${targetAgencyId}&select=*`;
      if (filterStage) query += `&stage=eq.${filterStage}`;

      const lcRes = await fetch(query, { headers });
      const lifecycles: any[] = await lcRes.json();

      // Count by stage
      const counts: Record<string, number> = {
        prospect: 0, booked: 0, active: 0, alumni: 0, churned: 0,
      };
      for (const lc of lifecycles) {
        counts[lc.stage] = (counts[lc.stage] || 0) + 1;
      }

      // Conversion rates
      const total = lifecycles.length;
      const conversionFunnel = [
        { stage: 'prospect', count: counts.prospect, rate: total > 0 ? (counts.prospect / total) * 100 : 0 },
        { stage: 'booked', count: counts.booked, rate: total > 0 ? (counts.booked / total) * 100 : 0 },
        { stage: 'active', count: counts.active, rate: total > 0 ? (counts.active / total) * 100 : 0 },
        { stage: 'alumni', count: counts.alumni, rate: total > 0 ? (counts.alumni / total) * 100 : 0 },
      ];

      // Get pilgrims list with profile info
      const pilgrimIds = lifecycles.map(lc => lc.user_id);
      let pilgrims: any[] = [];
      if (pilgrimIds.length > 0) {
        const pilgrimIdsParam = pilgrimIds.join(',');
        const profilesRes = await fetch(
          `${SUPABASE_URL}/rest/v1/profiles?id=in.(${pilgrimIdsParam})&select=id,name,email,subscription_tier`,
          { headers }
        );
        pilgrims = await profilesRes.json();
      }

      const pilgrimMap: Record<string, any> = {};
      for (const p of pilgrims) pilgrimMap[p.id] = p;

      const pilgrimsWithLifecycle = lifecycles.map(lc => ({
        id: lc.id,
        user_id: lc.user_id,
        stage: lc.stage,
        stage_changed_at: lc.stage_changed_at,
        booking_date: lc.booking_date,
        departure_date: lc.departure_date,
        return_date: lc.return_date,
        notes: lc.notes,
        pilgrim: pilgrimMap[lc.user_id] || null,
      }));

      return Response.json({
        stages: ['prospect', 'booked', 'active', 'alumni', 'churned'],
        counts,
        conversion_funnel: conversionFunnel,
        pilgrims: pilgrimsWithLifecycle,
      }, { headers: corsHeaders });

    // GET: pilgrim detail
    } else if (req.method === 'GET' && userIdParam) {
      const [lcRes, commRes, profileRes] = await Promise.all([
        fetch(`${SUPABASE_URL}/rest/v1/pilgrim_lifecycle?user_id=eq.${userIdParam}&select=*`, { headers }),
        fetch(`${SUPABASE_URL}/rest/v1/communication_logs?user_id=eq.${userIdParam}&order=created_at.desc&limit=50&select=*`, { headers }),
        fetch(`${SUPABASE_URL}/rest/v1/profiles?id=eq.${userIdParam}&select=*`, { headers }),
      ]);

      const lifecycles: any[] = await lcRes.json();
      const communications: any[] = await commRes.json();
      const profiles: any[] = await profileRes.json();

      return Response.json({
        pilgrim_detail: profiles[0] || null,
        lifecycle: lifecycles[0] || null,
        communications,
      }, { headers: corsHeaders });

    // PATCH: update stage
    } else if (req.method === 'PATCH') {
      const { user_id, stage, notes } = await req.json();

      if (!user_id || !stage) {
        return Response.json({ error: 'user_id and stage required' }, { status: 400, headers: corsHeaders });
      }

      const validStages = ['prospect', 'booked', 'active', 'alumni', 'churned'];
      if (!validStages.includes(stage)) {
        return Response.json({ error: 'Invalid stage' }, { status: 400, headers: corsHeaders });
      }

      // Update or insert lifecycle record
      const existingRes = await fetch(
        `${SUPABASE_URL}/rest/v1/pilgrim_lifecycle?user_id=eq.${user_id}&select=id,stage`,
        { headers }
      );
      const existing: any[] = await existingRes.json();

      if (existing.length > 0) {
        await fetch(`${SUPABASE_URL}/rest/v1/pilgrim_lifecycle?id=eq.${existing[0].id}`, {
          method: 'PATCH',
          headers,
          body: JSON.stringify({
            stage,
            stage_changed_at: new Date().toISOString(),
            ...(notes !== undefined ? { notes } : {}),
          }),
        });
      } else {
        await fetch(`${SUPABASE_URL}/rest/v1/pilgrim_lifecycle`, {
          method: 'POST',
          headers,
          body: JSON.stringify({
            user_id,
            agency_id: tokenAgencyId,
            stage,
          }),
        });
      }

      return Response.json({ success: true, stage }, { headers: corsHeaders });

    } else {
      return Response.json({ error: 'Method not allowed' }, { status: 405, headers: corsHeaders });
    }

  } catch (error) {
    console.error('crm-lifecycle error:', error);
    return Response.json({ error: 'Internal server error' }, { status: 500, headers: corsHeaders });
  }
});
