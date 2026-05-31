// Edge Function: system-alerts
// GET  /functions/v1/system-alerts     - List alerts (SuperAdmin only)
// POST /functions/v1/system-alerts     - Create alert (SuperAdmin only)
// PATCH /functions/v1/system-alerts?id= - Acknowledge/dismiss alert (SuperAdmin only)

import { serve } from "https://deno.land/x/sift@0.6.0/mod.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://haramain.pro',
  'Access-Control-Allow-Methods': 'GET, POST, PATCH, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, content-type',
  'Access-Control-Max-Age': '86400',
};

const ALERT_TYPES = ['low_license_stock', 'payment_failed', 'suspicious_activity', 'service_down'] as const;
type AlertType = typeof ALERT_TYPES[number];

interface SystemAlert {
  id: string;
  alert_type: AlertType;
  severity: 'info' | 'warning' | 'critical';
  title: string;
  message: string;
  metadata: Record<string, unknown>;
  status: 'active' | 'acknowledged' | 'dismissed';
  acknowledged_at: string | null;
  acknowledged_by: string | null;
  created_at: string;
}

function isAlertType(v: string): v is AlertType {
  return ALERT_TYPES.includes(v as AlertType);
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  // Auth
  const authHeader = req.headers.get('Authorization');
  if (!authHeader?.startsWith('Bearer ')) {
    return Response.json({ error: 'Unauthorized' }, { status: 401, headers: corsHeaders });
  }

  const token = authHeader.replace('Bearer ', '');
  let payload: Record<string, unknown>;
  try {
    payload = JSON.parse(atob(token.split('.')[1]));
  } catch {
    return Response.json({ error: 'Invalid token' }, { status: 401, headers: corsHeaders });
  }

  const role = payload.role as string;
  if (role !== 'super_admin') {
    return Response.json({ error: 'Forbidden: SuperAdmin only' }, { status: 403, headers: corsHeaders });
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

    // GET — list alerts
    if (req.method === 'GET') {
      const status = url.searchParams.get('status');
      const alertType = url.searchParams.get('alert_type');
      const limit = Math.min(parseInt(url.searchParams.get('limit') || '50'), 100);
      const offset = parseInt(url.searchParams.get('offset') || '0');

      let query = `${SUPABASE_URL}/rest/v1/system_alerts?order=created_at.desc&limit=${limit}&offset=${offset}`;
      if (status) query += `&status=eq.${status}`;
      if (alertType && isAlertType(alertType)) query += `&alert_type=eq.${alertType}`;

      const res = await fetch(query, { headers });
      const alerts: SystemAlert[] = await res.json();

      // Count total
      let countQuery = `${SUPABASE_URL}/rest/v1/system_alerts?select=id`;
      if (status) countQuery += `&status=eq.${status}`;
      if (alertType && isAlertType(alertType)) countQuery += `&alert_type=eq.${alertType}`;
      const countRes = await fetch(countQuery, { headers });
      const countData: unknown[] = await countRes.json();

      return Response.json({
        alerts,
        count: countData.length,
        limit,
        offset,
      }, { headers: corsHeaders });
    }

    // POST — create alert
    if (req.method === 'POST') {
      const body = await req.json();
      const { alert_type, severity, title, message, metadata } = body;

      if (!alert_type || !isAlertType(alert_type)) {
        return Response.json({ error: `alert_type must be one of: ${ALERT_TYPES.join(', ')}` }, { status: 400, headers: corsHeaders });
      }
      if (!title || typeof title !== 'string') {
        return Response.json({ error: 'title is required' }, { status: 400, headers: corsHeaders });
      }
      if (!message || typeof message !== 'string') {
        return Response.json({ error: 'message is required' }, { status: 400, headers: corsHeaders });
      }
      if (severity && !['info', 'warning', 'critical'].includes(severity)) {
        return Response.json({ error: 'severity must be info, warning, or critical' }, { status: 400, headers: corsHeaders });
      }

      const insertRes = await fetch(`${SUPABASE_URL}/rest/v1/system_alerts`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          alert_type,
          severity: severity || 'info',
          title,
          message,
          metadata: metadata || {},
          status: 'active',
          created_at: new Date().toISOString(),
        }),
      });

      const inserted: SystemAlert[] = await insertRes.json();
      return Response.json({ alert: inserted[0] }, { status: 201, headers: corsHeaders });
    }

    // PATCH — acknowledge / dismiss
    if (req.method === 'PATCH') {
      const alertId = url.searchParams.get('id');
      if (!alertId) {
        return Response.json({ error: 'Alert id (query param ?id=) is required' }, { status: 400, headers: corsHeaders });
      }

      const { status } = await req.json();
      if (!status || !['acknowledged', 'dismissed'].includes(status)) {
        return Response.json({ error: 'status must be acknowledged or dismissed' }, { status: 400, headers: corsHeaders });
      }

      const updatePayload: Record<string, unknown> = { status };
      if (status === 'acknowledged') {
        updatePayload.acknowledged_at = new Date().toISOString();
        updatePayload.acknowledged_by = payload.sub as string;
      }

      await fetch(`${SUPABASE_URL}/rest/v1/system_alerts?id=eq.${alertId}`, {
        method: 'PATCH',
        headers,
        body: JSON.stringify(updatePayload),
      });

      return Response.json({ success: true, id: alertId, status }, { headers: corsHeaders });
    }

    return Response.json({ error: 'Method not allowed' }, { status: 405, headers: corsHeaders });

  } catch (error) {
    console.error('system-alerts error:', error);
    return Response.json({ error: 'Internal server error' }, { status: 500, headers: corsHeaders });
  }
});
