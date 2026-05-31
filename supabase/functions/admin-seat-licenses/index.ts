// Edge Function: admin-seat-licenses
// GET /functions/v1/admin-seat-licenses
// SuperAdmin: platform-wide seat license dashboard data

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
    const filter = url.searchParams.get('filter'); // all | low_stock | depleted
    const search = url.searchParams.get('search') || '';

    const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
    const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const headers = {
      'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
      'apikey': SUPABASE_SERVICE_KEY,
      'Content-Type': 'application/json',
    };

    // Get all agencies with seat data
    let agenciesQuery = `${SUPABASE_URL}/rest/v1/agencies?select=id,name,seat_balance,wl_status,low_stock_threshold,created_at`;
    const agenciesRes = await fetch(agenciesQuery, { headers });
    const agencies: any[] = await agenciesRes.json();

    // Get all seat license transactions for consumed count
    const transactionsRes = await fetch(
      `${SUPABASE_URL}/rest/v1/seat_license_transactions?type=eq.consumed&select=agency_id,quantity`,
      { headers }
    );
    const transactions: any[] = await transactionsRes.json();

    // Get seat license packages for last purchase date
    const packagesRes = await fetch(
      `${SUPABASE_URL}/rest/v1/seat_license_packages?payment_status=eq.paid&order=created_at.desc&select=agency_id,created_at,quantity,total_price`,
      { headers }
    );
    const packages: any[] = await packagesRes.json();

    // Build per-agency consumed counts
    const consumedByAgency: Record<string, number> = {};
    for (const t of transactions) {
      consumedByAgency[t.agency_id] = (consumedByAgency[t.agency_id] || 0) + t.quantity;
    }

    // Build per-agency last purchase
    const lastPurchaseByAgency: Record<string, string> = {};
    for (const p of packages) {
      if (!lastPurchaseByAgency[p.agency_id]) {
        lastPurchaseByAgency[p.agency_id] = p.created_at;
      }
    }

    // Build license records
    let licenses = agencies.map((agency) => {
      const totalSeats = agency.seat_balance ?? 0;
      const usedSeats = consumedByAgency[agency.id] || 0;
      const balance = totalSeats; // seat_balance is the remaining balance
      const status = balance === 0 ? 'depleted' : balance < 20 ? 'low_stock' : 'active';

      return {
        id: agency.id,
        agency_name: agency.name,
        total_seats: totalSeats + usedSeats, // total ever purchased
        used_seats: usedSeats,
        balance,
        wl_status: agency.wl_status,
        last_purchase: lastPurchaseByAgency[agency.id] || null,
        status,
      };
    });

    // Filter
    if (filter === 'low_stock') {
      licenses = licenses.filter(l => l.status === 'low_stock');
    } else if (filter === 'depleted') {
      licenses = licenses.filter(l => l.status === 'depleted');
    }

    // Search
    if (search) {
      const q = search.toLowerCase();
      licenses = licenses.filter(l => l.agency_name?.toLowerCase().includes(q));
    }

    // Stats
    const totalPlatformSeats = licenses.reduce((sum, l) => sum + l.total_seats, 0);
    const totalPlatformUsed = licenses.reduce((sum, l) => sum + l.used_seats, 0);
    const totalPlatformBalance = licenses.reduce((sum, l) => sum + l.balance, 0);
    const lowStockCount = licenses.filter(l => l.status === 'low_stock').length;
    const depletedCount = licenses.filter(l => l.status === 'depleted').length;

    return Response.json({
      stats: {
        total_seats_sold: totalPlatformSeats,
        total_used: totalPlatformUsed,
        total_balance: totalPlatformBalance,
        low_stock_count: lowStockCount,
        depleted_count: depletedCount,
      },
      licenses,
    }, { headers: corsHeaders });

  } catch (error) {
    console.error('admin-seat-licenses error:', error);
    return Response.json({ error: 'Internal server error' }, { status: 500, headers: corsHeaders });
  }
});
