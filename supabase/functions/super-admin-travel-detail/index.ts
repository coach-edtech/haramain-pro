// Edge Function: super-admin-travel-detail
// GET /functions/v1/super-admin-travel-detail?id=UUID
// SuperAdmin only — returns full travel agency profile + stats

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
    const agencyId = url.searchParams.get('id');

    if (!agencyId) {
      return Response.json({ error: 'Agency id (UUID) required' }, { status: 400, headers: corsHeaders });
    }

    const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
    const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const headers = {
      'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
      'apikey': SUPABASE_SERVICE_KEY,
      'Content-Type': 'application/json',
    };

    // Fetch agency profile
    const agencyRes = await fetch(
      `${SUPABASE_URL}/rest/v1/agencies?id=eq.${agencyId}&select=*`,
      { headers }
    );
    const agencies: any[] = await agencyRes.json();

    if (!agencies || agencies.length === 0) {
      return Response.json({ error: 'Agency not found' }, { status: 404, headers: corsHeaders });
    }

    const agency = agencies[0];

    // Parallel stat fetches
    const [
      profilesRes,
      groupsRes,
      paymentsRes,
      seatTxRes,
      seatPackagesRes,
      salesAgentsRes,
      recentGroupsRes,
      recentPaymentsRes,
    ] = await Promise.all([
      // All profiles under this agency (jamaah/pilgrim count)
      fetch(
        `${SUPABASE_URL}/rest/v1/profiles?agency_id=eq.${agencyId}&select=id,role,subscription_tier,created_at`,
        { headers }
      ),
      // All groups under this agency
      fetch(
        `${SUPABASE_URL}/rest/v1/groups?agency_id=eq.${agencyId}&select=id,status,created_at`,
        { headers }
      ),
      // All payments under this agency
      fetch(
        `${SUPABASE_URL}/rest/v1/payments?agency_id=eq.${agencyId}&select=id,type,amount,payment_status,created_at`,
        { headers }
      ),
      // Seat license transactions under this agency
      fetch(
        `${SUPABASE_URL}/rest/v1/seat_license_transactions?agency_id=eq.${agencyId}&select=id,type,quantity,created_at`,
        { headers }
      ),
      // Seat license packages under this agency
      fetch(
        `${SUPABASE_URL}/rest/v1/seat_license_packages?agency_id=eq.${agencyId}&select=id,package_name,quantity,total_price,payment_status,created_at`,
        { headers }
      ),
      // Sales agents under this agency
      fetch(
        `${SUPABASE_URL}/rest/v1/sales_agents?agency_id=eq.${agencyId}&select=id,name,agent_code,commission_rate,status,created_at`,
        { headers }
      ),
      // Recent groups (last 5)
      fetch(
        `${SUPABASE_URL}/rest/v1/groups?agency_id=eq.${agencyId}&order=created_at.desc&limit=5&select=id,name,status,created_at`,
        { headers }
      ),
      // Recent payments (last 5)
      fetch(
        `${SUPABASE_URL}/rest/v1/payments?agency_id=eq.${agencyId}&order=created_at.desc&limit=5&select=id,type,amount,payment_status,created_at`,
        { headers }
      ),
    ]);

    const profiles: any[] = await profilesRes.json();
    const groups: any[] = await groupsRes.json();
    const payments: any[] = await paymentsRes.json();
    const seatTx: any[] = await seatTxRes.json();
    const seatPackages: any[] = await seatPackagesRes.json();
    const salesAgents: any[] = await salesAgentsRes.json();
    const recentGroups: any[] = await recentGroupsRes.json();
    const recentPayments: any[] = await recentPaymentsRes.json();

    // === Jamaah Count ===
    // role = 'pilgrim' or 'jamaah' = actual pilgrims
    const jamaahProfiles = profiles.filter(p =>
      ['pilgrim', 'jamaah'].includes(p.role)
    );
    const jamaahCount = jamaahProfiles.length;

    // All users under agency
    const totalUsers = profiles.length;

    // User breakdown
    const activeUsers = profiles.filter(p => p.subscription_tier === 'active').length;
    const trialUsers = profiles.filter(p => p.subscription_tier === 'trial').length;
    const expiredUsers = profiles.filter(p => p.subscription_tier === 'expired').length;

    // === Groups Stats ===
    const totalGroups = groups.length;
    const activeGroups = groups.filter(g => g.status === 'active').length;
    const plannedGroups = groups.filter(g => g.status === 'planned').length;
    const completedGroups = groups.filter(g => g.status === 'completed').length;

    // === Revenue Stats ===
    const paidPayments = payments.filter(p => p.payment_status === 'paid');
    const totalRevenue = paidPayments.reduce((sum: number, p: any) => sum + (p.amount || 0), 0);

    // Revenue by type
    const revenueByType: Record<string, number> = {};
    for (const p of paidPayments) {
      revenueByType[p.type] = (revenueByType[p.type] || 0) + p.amount;
    }

    // Revenue by month (last 6 months)
    const now = new Date();
    const monthlyRevenue: { month: string; amount: number }[] = [];
    for (let i = 5; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const monthStart = d.toISOString().slice(0, 7);
      const monthPayments = paidPayments.filter((p: any) =>
        p.created_at && p.created_at.startsWith(monthStart)
      );
      const monthAmount = monthPayments.reduce((sum: number, p: any) => sum + (p.amount || 0), 0);
      monthlyRevenue.push({ month: monthStart, amount: monthAmount });
    }

    // === Seat License Stats ===
    const seatsPurchased = seatTx
      .filter(t => t.type === 'purchase')
      .reduce((sum: number, t: any) => sum + t.quantity, 0);
    const seatsConsumed = seatTx
      .filter(t => t.type === 'consumed')
      .reduce((sum: number, t: any) => sum + t.quantity, 0);
    const seatsRefunded = seatTx
      .filter(t => t.type === 'refunded')
      .reduce((sum: number, t: any) => sum + t.quantity, 0);

    // Total spent on seat license packages (paid ones)
    const paidPackages = seatPackages.filter(p => p.payment_status === 'paid');
    const totalSeatsSpent = paidPackages.reduce((sum: number, p: any) => sum + (p.total_price || 0), 0);

    // === Sales Agents Stats ===
    const totalAgents = salesAgents.length;
    const activeAgents = salesAgents.filter(a => a.status === 'active').length;
    const inactiveAgents = salesAgents.filter(a => a.status === 'inactive').length;

    // === Build response ===
    return Response.json({
      agency: {
        id: agency.id,
        name: agency.name,
        address: agency.address,
        phone: agency.phone,
        email: agency.email,
        wl_status: agency.wl_status,
        seat_balance: agency.seat_balance,
        low_stock_threshold: agency.low_stock_threshold,
        created_at: agency.created_at,
      },
      stats: {
        jamaah_count: jamaahCount,
        total_users: totalUsers,
        active_users: activeUsers,
        trial_users: trialUsers,
        expired_users: expiredUsers,
        total_groups: totalGroups,
        active_groups: activeGroups,
        planned_groups: plannedGroups,
        completed_groups: completedGroups,
        total_agents: totalAgents,
        active_agents: activeAgents,
        inactive_agents: inactiveAgents,
      },
      revenue: {
        total_revenue_idr: totalRevenue,
        by_type: revenueByType,
        monthly_6mo: monthlyRevenue,
        total_seats_spent_idr: totalSeatsSpent,
      },
      seats: {
        balance: agency.seat_balance,
        total_purchased: seatsPurchased,
        total_consumed: seatsConsumed,
        total_refunded: seatsRefunded,
        total_packages: seatPackages.length,
        pending_packages: seatPackages.filter(p => p.payment_status === 'pending').length,
        paid_packages: paidPackages.length,
      },
      recent_groups: recentGroups.map(g => ({
        id: g.id,
        name: g.name,
        status: g.status,
        created_at: g.created_at,
      })),
      recent_payments: recentPayments.map(p => ({
        id: p.id,
        type: p.type,
        amount: p.amount,
        status: p.payment_status,
        created_at: p.created_at,
      })),
    }, { headers: corsHeaders });

  } catch (error) {
    console.error('super-admin-travel-detail error:', error);
    return Response.json({ error: 'Internal server error' }, { status: 500, headers: corsHeaders });
  }
});
