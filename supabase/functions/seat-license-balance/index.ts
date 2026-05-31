// Edge Function: seat-license-balance
// GET /functions/v1/seat-license-balance
// Returns seat license balance for the authenticated travel admin's agency

import { serve } from "https://deno.land/x/sift@0.6.0/mod.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://haramain.pro',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, content-type',
  'Access-Control-Max-Age': '86400',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  if (req.method !== 'GET') {
    return Response.json({ error: 'Method not allowed' }, { status: 405, headers: corsHeaders });
  }

  // Verify JWT
  const authHeader = req.headers.get('Authorization');
  if (!authHeader?.startsWith('Bearer ')) {
    return Response.json({ error: 'Unauthorized' }, { status: 401, headers: corsHeaders });
  }

  try {
    // Decode JWT to get user info
    const token = authHeader.replace('Bearer ', '');
    const payload = JSON.parse(atob(token.split('.')[1]));
    const userId = payload.sub;
    const role = payload.role;
    const agencyId = payload.agency_id;

    if (!['travel_admin', 'super_admin', 'admin_haramain_pro'].includes(role)) {
      return Response.json({ error: 'Forbidden' }, { status: 403, headers: corsHeaders });
    }

    // For super_admin / admin_haramain_pro, require agency_id query param
    let targetAgencyId = agencyId;
    if (role === 'super_admin' || role === 'admin_haramain_pro') {
      const url = new URL(req.url);
      targetAgencyId = url.searchParams.get('agency_id');
      if (!targetAgencyId) {
        return Response.json({ error: 'agency_id query param required for this role' }, { status: 400, headers: corsHeaders });
      }
    }

    if (!targetAgencyId) {
      return Response.json({ error: 'No agency_id found in token' }, { status: 400, headers: corsHeaders });
    }

    // Fetch agency seat_balance
    const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
    const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

    const agencyRes = await fetch(`${SUPABASE_URL}/rest/v1/agencies?id=eq.${targetAgencyId}&select=id,name,seat_balance,wl_status`, {
      headers: {
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        'apikey': SUPABASE_SERVICE_KEY,
        'Content-Type': 'application/json',
      },
    });

    const agencies = await agencyRes.json();
    if (!agencies || agencies.length === 0) {
      return Response.json({ error: 'Agency not found' }, { status: 404, headers: corsHeaders });
    }

    const agency = agencies[0];

    // Fetch summary stats
    const [packagesRes, transactionsRes, alertsRes] = await Promise.all([
      fetch(`${SUPABASE_URL}/rest/v1/seat_license_packages?agency_id=eq.${targetAgencyId}&select=id,quantity,total_price,payment_status,created_at`, {
        headers: { 'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`, 'apikey': SUPABASE_SERVICE_KEY },
      }),
      fetch(`${SUPABASE_URL}/rest/v1/seat_license_transactions?agency_id=eq.${targetAgencyId}&order=created_at.desc&limit=20&select=id,type,quantity,balance_after,created_at`, {
        headers: { 'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`, 'apikey': SUPABASE_SERVICE_KEY },
      }),
      fetch(`${SUPABASE_URL}/rest/v1/seat_license_alerts?agency_id=eq.${targetAgencyId}&is_active=eq.true&select=id,threshold,triggered_at`, {
        headers: { 'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`, 'apikey': SUPABASE_SERVICE_KEY },
      }),
    ]);

    const packages = await packagesRes.json();
    const transactions = await transactionsRes.json();
    const alerts = await alertsRes.json();

    const totalPurchased = packages
      .filter((p: any) => p.payment_status === 'paid')
      .reduce((sum: number, p: any) => sum + p.quantity, 0);

    const totalConsumed = transactions
      .filter((t: any) => t.type === 'consumed')
      .reduce((sum: number, t: any) => sum + t.quantity, 0);

    const totalRefunded = transactions
      .filter((t: any) => t.type === 'refunded')
      .reduce((sum: number, t: any) => sum + t.quantity, 0);

    const activeAlert = alerts.find((a: any) => !a.triggered_at);

    return Response.json({
      agency_id: targetAgencyId,
      agency_name: agency.name,
      seat_balance: agency.seat_balance ?? 0,
      total_purchased: totalPurchased,
      total_consumed: totalConsumed,
      total_refunded: totalRefunded,
      wl_status: agency.wl_status,
      alert: activeAlert ? {
        threshold: activeAlert.threshold,
        is_active: true,
        triggered: false,
      } : null,
      recent_transactions: transactions.slice(0, 10).map((t: any) => ({
        id: t.id,
        type: t.type,
        quantity: t.quantity,
        balance_after: t.balance_after,
        created_at: t.created_at,
      })),
    }, { headers: corsHeaders });

  } catch (error) {
    console.error('seat-license-balance error:', error);
    return Response.json({ error: 'Internal server error' }, { status: 500, headers: corsHeaders });
  }
});
