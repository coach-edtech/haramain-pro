// Edge Function: super-admin-seat-license-detail
// GET /functions/v1/super-admin-seat-license-detail?id=UUID
// SuperAdmin only: returns full seat license record with agency, packages, transactions, alerts

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
    const id = url.searchParams.get('id');

    if (!id) {
      return Response.json({ error: 'id query parameter is required' }, { status: 400, headers: corsHeaders });
    }

    const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
    const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const headers = {
      'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
      'apikey': SUPABASE_SERVICE_KEY,
      'Content-Type': 'application/json',
    };

    // Fetch agency
    const agencyRes = await fetch(
      `${SUPABASE_URL}/rest/v1/agencies?id=eq.${id}&select=*`,
      { headers }
    );
    const agencies: any[] = await agencyRes.json();

    if (!agencies || agencies.length === 0) {
      return Response.json({ error: 'Agency not found' }, { status: 404, headers: corsHeaders });
    }

    const agency = agencies[0];

    // Fetch packages, transactions, alerts in parallel
    const [packagesRes, transactionsRes, alertsRes] = await Promise.all([
      fetch(
        `${SUPABASE_URL}/rest/v1/seat_license_packages?agency_id=eq.${id}&order=created_at.desc&select=*`,
        { headers }
      ),
      fetch(
        `${SUPABASE_URL}/rest/v1/seat_license_transactions?agency_id=eq.${id}&order=created_at.desc&select=*`,
        { headers }
      ),
      fetch(
        `${SUPABASE_URL}/rest/v1/seat_license_alerts?agency_id=eq.${id}&order=created_at.desc&select=*`,
        { headers }
      ),
    ]);

    const packages: any[] = await packagesRes.json();
    const transactions: any[] = await transactionsRes.json();
    const alerts: any[] = await alertsRes.json();

    // Compute summary stats
    const totalPurchased = packages
      .filter((p: any) => p.payment_status === 'paid')
      .reduce((sum: number, p: any) => sum + p.quantity, 0);

    const totalConsumed = transactions
      .filter((t: any) => t.type === 'consumed')
      .reduce((sum: number, t: any) => sum + t.quantity, 0);

    const totalRefunded = transactions
      .filter((t: any) => t.type === 'refunded')
      .reduce((sum: number, t: any) => sum + t.quantity, 0);

    return Response.json({
      agency: {
        id: agency.id,
        name: agency.name,
        seat_balance: agency.seat_balance ?? 0,
        wl_status: agency.wl_status,
        low_stock_threshold: agency.low_stock_threshold ?? 20,
        created_at: agency.created_at,
        updated_at: agency.updated_at,
      },
      summary: {
        total_purchased: totalPurchased,
        total_consumed: totalConsumed,
        total_refunded: totalRefunded,
        balance: agency.seat_balance ?? 0,
        status: (agency.seat_balance ?? 0) === 0
          ? 'depleted'
          : (agency.seat_balance ?? 0) < (agency.low_stock_threshold ?? 20)
            ? 'low_stock'
            : 'active',
      },
      packages,
      transactions,
      alerts,
    }, { headers: corsHeaders });

  } catch (error) {
    console.error('super-admin-seat-license-detail error:', error);
    return Response.json({ error: 'Internal server error' }, { status: 500, headers: corsHeaders });
  }
});
