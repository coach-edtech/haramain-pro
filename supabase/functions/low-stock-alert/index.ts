// Edge Function: low-stock-alert
// GET /functions/v1/low-stock-alert
// PATCH /functions/v1/low-stock-alert?id= (acknowledge/dismiss)

import { serve } from "https://deno.land/x/sift@0.6.0/mod.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://haramain.pro',
  'Access-Control-Allow-Methods': 'GET, PATCH, OPTIONS',
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
  let payload: any;
  try {
    payload = JSON.parse(atob(token.split('.')[1]));
  } catch {
    return Response.json({ error: 'Invalid token' }, { status: 401, headers: corsHeaders });
  }

  const role = payload.role;
  const tokenAgencyId = payload.agency_id;

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

    // GET: list alerts
    if (req.method === 'GET') {
      let targetAgencyId = tokenAgencyId;
      if (role === 'super_admin' || role === 'admin_haramain_pro') {
        targetAgencyId = url.searchParams.get('agency_id') || tokenAgencyId;
      }

      const status = url.searchParams.get('status'); // active | acknowledged | dismissed

      let query = `${SUPABASE_URL}/rest/v1/seat_license_alerts?agency_id=eq.${targetAgencyId}&order=created_at.desc`;
      if (status) query += `&status=eq.${status}`;

      const alertRes = await fetch(query, { headers });
      const alerts: any[] = await alertRes.json();

      return Response.json({
        alerts: alerts.map(a => ({
          id: a.id,
          threshold: a.threshold,
          current_balance: a.current_balance,
          status: a.status,
          triggered_at: a.triggered_at,
          acknowledged_at: a.acknowledged_at,
          acknowledged_by: a.acknowledged_by,
          created_at: a.created_at,
        })),
        count: alerts.length,
      }, { headers: corsHeaders });

    // PATCH: acknowledge or dismiss
    } else if (req.method === 'PATCH') {
      const alertId = url.searchParams.get('id');
      if (!alertId) {
        return Response.json({ error: 'Alert id required' }, { status: 400, headers: corsHeaders });
      }

      const { status } = await req.json();
      if (!status || !['acknowledged', 'dismissed'].includes(status)) {
        return Response.json({ error: 'status must be acknowledged or dismissed' }, { status: 400, headers: corsHeaders });
      }

      const updatePayload: any = { status };
      if (status === 'acknowledged') {
        updatePayload.acknowledged_at = new Date().toISOString();
        updatePayload.acknowledged_by = payload.sub;
      }

      await fetch(`${SUPABASE_URL}/rest/v1/seat_license_alerts?id=eq.${alertId}`, {
        method: 'PATCH',
        headers,
        body: JSON.stringify(updatePayload),
      });

      return Response.json({ success: true, status }, { headers: corsHeaders });

    } else {
      return Response.json({ error: 'Method not allowed' }, { status: 405, headers: corsHeaders });
    }

  } catch (error) {
    console.error('low-stock-alert error:', error);
    return Response.json({ error: 'Internal server error' }, { status: 500, headers: corsHeaders });
  }
});
