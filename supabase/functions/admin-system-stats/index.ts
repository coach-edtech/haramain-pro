// Edge Function: admin-system-stats
// GET /functions/v1/admin-system-stats
// SuperAdmin: platform-wide health, usage, and revenue stats

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
    const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
    const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const headers = {
      'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
      'apikey': SUPABASE_SERVICE_KEY,
      'Content-Type': 'application/json',
    };

    const [
      agenciesRes,
      profilesRes,
      paymentsRes,
      panicAlertsRes,
      seatTxRes,
    ] = await Promise.all([
      fetch(`${SUPABASE_URL}/rest/v1/agencies?select=id,name,wl_status,seat_balance,created_at`, { headers }),
      fetch(`${SUPABASE_URL}/rest/v1/profiles?select=id,subscription_tier,created_at`, { headers }),
      fetch(`${SUPABASE_URL}/rest/v1/payments?select=id,type,amount,payment_status,created_at`, { headers }),
      fetch(`${SUPABASE_URL}/rest/v1/panic_alerts?select=id,status,created_at`, { headers }),
      fetch(`${SUPABASE_URL}/rest/v1/seat_license_transactions?select=id,type,quantity,created_at`, { headers }),
    ]);

    const agencies: any[] = await agenciesRes.json();
    const profiles: any[] = await profilesRes.json();
    const payments: any[] = await paymentsRes.json();
    const panicAlerts: any[] = await panicAlertsRes.json();
    const seatTx: any[] = await seatTxRes.json();

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

    // === User Stats ===
    const activeUsers = profiles.filter(p => p.subscription_tier === 'active').length;
    const trialUsers = profiles.filter(p => p.subscription_tier === 'trial').length;
    const churnedUsers = profiles.filter(p => p.subscription_tier === 'churned').length;

    // === Agency Stats ===
    const activeAgencies = agencies.filter(a => a.wl_status === 'active').length;
    const suspendedAgencies = agencies.filter(a => a.wl_status === 'suspended').length;

    // Total seats platform-wide
    const totalSeatsPurchased = seatTx
      .filter(t => t.type === 'purchase')
      .reduce((sum: number, t: any) => sum + t.quantity, 0);
    const totalSeatsConsumed = seatTx
      .filter(t => t.type === 'consumed')
      .reduce((sum: number, t: any) => sum + t.quantity, 0);

    // === Panic Stats ===
    const openPanics = panicAlerts.filter(p => p.status === 'open').length;
    const resolvedPanics = panicAlerts.filter(p => p.status === 'resolved').length;

    // === SLA Metrics ===
    // Calculate avg response time from panic_alerts if resolved_at exists
    // For now, estimate based on alert age
    const openPanicList = panicAlerts.filter(p => p.status === 'open');
    let avgResponseMinutes = null;
    if (openPanicList.length > 0) {
      const nowMs = Date.now();
      const oldestOpen = Math.min(...openPanicList.map((p: any) =>
        new Date(p.created_at).getTime()
      ));
      avgResponseMinutes = Math.round((nowMs - oldestOpen) / 60000);
    }

    return Response.json({
      revenue: {
        total_revenue_idr: totalRevenue,
        by_type: revenueByType,
        monthly_6mo: monthlyRevenue,
      },
      users: {
        total: profiles.length,
        active: activeUsers,
        trial: trialUsers,
        churned: churnedUsers,
      },
      agencies: {
        total: agencies.length,
        active: activeAgencies,
        suspended: suspendedAgencies,
      },
      seats: {
        total_purchased: totalSeatsPurchased,
        total_consumed: totalSeatsConsumed,
        total_balance: totalSeatsPurchased - totalSeatsConsumed,
      },
      panic: {
        open: openPanics,
        resolved: resolvedPanics,
        total: panicAlerts.length,
      },
      sla: {
        avg_response_minutes: avgResponseMinutes,
        open_alert_count: openPanics,
      },
    }, { headers: corsHeaders });

  } catch (error) {
    console.error('admin-system-stats error:', error);
    return Response.json({ error: 'Internal server error' }, { status: 500, headers: corsHeaders });
  }
});
