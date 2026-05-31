// Edge Function: fraud-alert-webhook
// POST /functions/v1/fraud-alert-webhook
// Flags suspicious redeem patterns and blocks offending accounts

import { serve } from "https://deno.land/x/sift@0.6.0/mod.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://haramain.pro',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, content-type',
  'Access-Control-Max-Age': '86400',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return Response.json({ error: 'Method not allowed' }, { status: 405, headers: corsHeaders });
  }

  // Internal endpoint - verify shared secret
  const authHeader = req.headers.get('Authorization');
  const expectedSecret = Deno.env.get('INTERNAL_WEBHOOK_SECRET');
  if (!expectedSecret || authHeader !== `Bearer ${expectedSecret}`) {
    return Response.json({ error: 'Unauthorized' }, { status: 401, headers: corsHeaders });
  }

  try {
    const { user_id, agency_id, alert_type, details } = await req.json();

    if (!user_id || !alert_type) {
      return Response.json({ error: 'user_id and alert_type required' }, { status: 400, headers: corsHeaders });
    }

    const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
    const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const headers = {
      'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
      'apikey': SUPABASE_SERVICE_KEY,
      'Content-Type': 'application/json',
    };

    // Insert fraud alert
    const alertRes = await fetch(`${SUPABASE_URL}/rest/v1/fraud_alerts`, {
      method: 'POST',
      headers,
      body: JSON.stringify({
        user_id,
        agency_id: agency_id || null,
        alert_type: alert_type,
        details: details || {},
        status: 'pending',
      }),
    });
    const alerts = await alertRes.json();
    const alert = alerts[0];

    // Auto-action based on alert type
    let autoAction = null;
    if (alert_type === 'bulk_redeem' || alert_type === 'impossible_location') {
      // Auto-suspend user account
      await fetch(`${SUPABASE_URL}/rest/v1/profiles?id=eq.${user_id}`, {
        method: 'PATCH',
        headers,
        body: JSON.stringify({ wl_status: 'suspended' }),
      });
      autoAction = 'user_suspended';

      // Create notification for agency admin
      if (agency_id) {
        const adminsRes = await fetch(
          `${SUPABASE_URL}/rest/v1/profiles?agency_id=eq.${agency_id}&role=eq.travel_admin&select=id`,
          { headers }
        );
        const admins: any[] = await adminsRes.json();
        for (const admin of admins) {
          await fetch(`${SUPABASE_URL}/rest/v1/notifications`, {
            method: 'POST',
            headers,
            body: JSON.stringify({
              user_id: admin.id,
              title: 'Peringatan Keamanan',
              body: `Akun ${user_id.slice(0, 8)}.. terdeteksi aktivitas mencurigakan. Akun telah ditangguhkan sementara.`,
              type: 'security_alert',
              priority: 'high',
            }),
          });
        }
      }
    } else if (alert_type === 'rapid_redeem') {
      autoAction = 'flagged_only';
    }

    return Response.json({
      received: true,
      fraud_alert_id: alert.id,
      auto_action: autoAction,
    }, { headers: corsHeaders });

  } catch (error) {
    console.error('fraud-alert-webhook error:', error);
    return Response.json({ error: 'Internal server error' }, { status: 500, headers: corsHeaders });
  }
});
