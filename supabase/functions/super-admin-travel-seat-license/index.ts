// Edge Function: super-admin-travel-seat-license
// GET /functions/v1/super-admin-travel-seat-license?travel_id=UUID
// SuperAdmin only: returns seat license summary for a specific travel agency

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
  if (!['super_admin', 'admin_haramain_pro'].includes(role)) {
    return Response.json({ error: 'Forbidden' }, { status: 403, headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const travelId = url.searchParams.get('travel_id');

    if (!travelId) {
      return Response.json({ error: 'travel_id query param required' }, { status: 400, headers: corsHeaders });
    }

    const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
    const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const headers = {
      'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
      'apikey': SUPABASE_SERVICE_KEY,
      'Content-Type': 'application/json',
    };

    // Fetch agency info
    const agencyRes = await fetch(
      `${SUPABASE_URL}/rest/v1/agencies?id=eq.${travelId}&select=id,name,address,phone,email,seat_balance,wl_status,low_stock_threshold,created_at`,
      { headers }
    );
    const agencies: any[] = await agencyRes.json();
    if (!agencies || agencies.length === 0) {
      return Response.json({ error: 'Travel agency not found' }, { status: 404, headers: corsHeaders });
    }
    const agency = agencies[0];

    // Fetch packages, transactions, alerts, and recent codes in parallel
    const [packagesRes, transactionsRes, alertsRes, codesRes] = await Promise.all([
      // Seat license packages (paid purchases)
      fetch(
        `${SUPABASE_URL}/rest/v1/seat_license_packages?agency_id=eq.${travelId}&payment_status=eq.paid&order=created_at.desc&select=id,quantity,total_price,created_at`,
        { headers }
      ),
      // Seat license transactions
      fetch(
        `${SUPABASE_URL}/rest/v1/seat_license_transactions?agency_id=eq.${travelId}&order=created_at.desc&limit=50&select=id,type,quantity,balance_after,created_at`,
        { headers }
      ),
      // Seat license alerts
      fetch(
        `${SUPABASE_URL}/rest/v1/seat_license_alerts?agency_id=eq.${travelId}&order=created_at.desc&select=id,threshold,current_balance,status,triggered_at,acknowledged_at,acknowledged_by,created_at`,
        { headers }
      ),
      // Recent redeem codes (last 20)
      fetch(
        `${SUPABASE_URL}/rest/v1/redeem_codes?agency_id=eq.${travelId}&order=created_at.desc&limit=20&select=id,code,type,status,expires_at,used_at,used_by_user_id,created_at`,
        { headers }
      ),
    ]);

    const [packages, transactions, alerts, codes] = await Promise.all([
      packagesRes.json(),
      transactionsRes.json(),
      alertsRes.json(),
      codesRes.json(),
    ]);

    // Compute summary stats
    const totalPurchased = packages.reduce((sum: number, p: any) => sum + p.quantity, 0);
    const totalConsumed = transactions
      .filter((t: any) => t.type === 'consumed')
      .reduce((sum: number, t: any) => sum + t.quantity, 0);
    const totalRefunded = transactions
      .filter((t: any) => t.type === 'refunded')
      .reduce((sum: number, t: any) => sum + t.quantity, 0);

    const activeAlerts = alerts.filter((a: any) => a.status === 'active' || a.status === 'triggered');

    return Response.json({
      agency: {
        id: agency.id,
        name: agency.name,
        address: agency.address,
        phone: agency.phone,
        email: agency.email,
        seat_balance: agency.seat_balance ?? 0,
        wl_status: agency.wl_status,
        low_stock_threshold: agency.low_stock_threshold,
        created_at: agency.created_at,
      },
      summary: {
        total_purchased: totalPurchased,
        total_consumed: totalConsumed,
        total_refunded: totalRefunded,
        current_balance: agency.seat_balance ?? 0,
      },
      packages: packages.map((p: any) => ({
        id: p.id,
        quantity: p.quantity,
        total_price: p.total_price,
        created_at: p.created_at,
      })),
      transactions: transactions.map((t: any) => ({
        id: t.id,
        type: t.type,
        quantity: t.quantity,
        balance_after: t.balance_after,
        created_at: t.created_at,
      })),
      alerts: alerts.map((a: any) => ({
        id: a.id,
        threshold: a.threshold,
        current_balance: a.current_balance,
        status: a.status,
        triggered_at: a.triggered_at,
        acknowledged_at: a.acknowledged_at,
        acknowledged_by: a.acknowledged_by,
        created_at: a.created_at,
      })),
      recent_codes: codes.map((c: any) => ({
        id: c.id,
        code: c.code,
        type: c.type,
        status: c.status,
        expires_at: c.expires_at,
        used_at: c.used_at,
        used_by_user_id: c.used_by_user_id,
        created_at: c.created_at,
      })),
      alert_summary: {
        total: alerts.length,
        active: activeAlerts.length,
        acknowledged: alerts.filter((a: any) => a.status === 'acknowledged').length,
        dismissed: alerts.filter((a: any) => a.status === 'dismissed').length,
      },
    }, { headers: corsHeaders });

  } catch (error) {
    console.error('super-admin-travel-seat-license error:', error);
    return Response.json({ error: 'Internal server error' }, { status: 500, headers: corsHeaders });
  }
});
