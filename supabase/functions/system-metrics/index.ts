// Edge Function: system-metrics
// GET /functions/v1/system-metrics
// SuperAdmin only: health metrics — active users, seat license usage, revenue, error rates

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

  // SuperAdmin only
  const role = payload.role;
  if (role !== 'super_admin') {
    return Response.json({ error: 'Forbidden: SuperAdmin only' }, { status: 403, headers: corsHeaders });
  }

  try {
    const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
    const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const headers = {
      'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
      'apikey': SUPABASE_SERVICE_KEY,
      'Content-Type': 'application/json',
    };

    // Parallel data fetches
    const [
      profilesRes,
      agenciesRes,
      paymentsRes,
      seatTxRes,
      panicAlertsRes,
      invoicesRes,
    ] = await Promise.all([
      // Profiles: active users, trials, churned
      fetch(`${SUPABASE_URL}/rest/v1/profiles?select=id,subscription_tier,status,last_seen,created_at`, { headers }),
      // Agencies: count by wl_status
      fetch(`${SUPABASE_URL}/rest/v1/agencies?select=id,wl_status,created_at`, { headers }),
      // Payments: for revenue and failure rate
      fetch(`${SUPABASE_URL}/rest/v1/payments?select=id,type,amount,payment_status,created_at`, { headers }),
      // Seat transactions: purchased vs consumed
      fetch(`${SUPABASE_URL}/rest/v1/seat_license_transactions?select=id,type,quantity,created_at`, { headers }),
      // Panic alerts: for error/alert rate
      fetch(`${SUPABASE_URL}/rest/v1/panic_alerts?select=id,status,created_at,resolved_at`, { headers }),
      // Invoices: for billing error rates
      fetch(`${SUPABASE_URL}/rest/v1/invoices?select=id,status,total_due,created_at`, { headers }),
    ]);

    const profiles: any[] = await profilesRes.json();
    const agencies: any[] = await agenciesRes.json();
    const payments: any[] = await paymentsRes.json();
    const seatTx: any[] = await seatTxRes.json();
    const panicAlerts: any[] = await panicAlertsRes.json();
    const invoices: any[] = await invoicesRes.json();

    // ─── 1. Active Users ─────────────────────────────────────────────────────
    const now = new Date();
    const twentyFourHoursAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000).toISOString();

    const totalProfiles = profiles.length;
    const activeSubscriptionProfiles = profiles.filter(p => p.subscription_tier === 'active');
    const trialProfiles = profiles.filter(p => p.subscription_tier === 'trial');
    const expiredProfiles = profiles.filter(p => p.subscription_tier === 'expired');

    // "Currently active" = active subscription AND seen in last 24h
    const recentlyActive = activeSubscriptionProfiles.filter(p => {
      if (!p.last_seen) return false;
      return p.last_seen >= twentyFourHoursAgo;
    });

    const activeUsers = {
      total: totalProfiles,
      active_subscription: activeSubscriptionProfiles.length,
      trial: trialProfiles.length,
      expired: expiredProfiles.length,
      online_24h: recentlyActive.length,
    };

    // ─── 2. Seat License Usage ────────────────────────────────────────────────
    const purchasedTx = seatTx.filter(t => t.type === 'purchase');
    const consumedTx = seatTx.filter(t => t.type === 'consumed');
    const totalSeatsPurchased = purchasedTx.reduce((sum, t) => sum + (t.quantity || 0), 0);
    const totalSeatsConsumed = consumedTx.reduce((sum, t) => sum + (t.quantity || 0), 0);
    const totalSeatsBalance = totalSeatsPurchased - totalSeatsConsumed;

    // Low-stock agencies: seat_balance < 20
    const lowStockAgencies = agencies.filter(a => {
      const bal = a.seat_balance ?? 0;
      return bal > 0 && bal < 20;
    }).length;
    const depletedAgencies = agencies.filter(a => (a.seat_balance ?? 0) === 0).length;

    const seatLicense = {
      total_purchased: totalSeatsPurchased,
      total_consumed: totalSeatsConsumed,
      total_balance: totalSeatsBalance,
      utilization_pct: totalSeatsPurchased > 0
        ? Math.round((totalSeatsConsumed / totalSeatsPurchased) * 100)
        : 0,
      low_stock_agencies: lowStockAgencies,
      depleted_agencies: depletedAgencies,
    };

    // ─── 3. Revenue ──────────────────────────────────────────────────────────
    const paidPayments = payments.filter(p => p.payment_status === 'paid');
    const failedPayments = payments.filter(p => p.payment_status === 'failed');
    const pendingPayments = payments.filter(p => p.payment_status === 'pending');

    const totalRevenue = paidPayments.reduce((sum, p) => sum + (p.amount || 0), 0);

    // Revenue by type
    const revenueByType: Record<string, number> = {};
    for (const p of paidPayments) {
      revenueByType[p.type] = (revenueByType[p.type] || 0) + p.amount;
    }

    // Monthly revenue — last 6 months
    const monthlyRevenue: { month: string; amount: number }[] = [];
    for (let i = 5; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const monthStart = d.toISOString().slice(0, 7);
      const monthPayments = paidPayments.filter(p =>
        p.created_at && p.created_at.startsWith(monthStart)
      );
      const monthAmount = monthPayments.reduce((sum: number, p) => sum + (p.amount || 0), 0);
      monthlyRevenue.push({ month: monthStart, amount: monthAmount });
    }

    // Revenue from invoices (platform fees)
    const paidInvoices = invoices.filter(inv => inv.status === 'paid');
    const overdueInvoices = invoices.filter(inv => inv.status === 'overdue');
    const invoiceRevenue = paidInvoices.reduce((sum, inv) => sum + (inv.total_due || 0), 0);

    const revenue = {
      total_revenue_idr: totalRevenue,
      invoice_revenue_idr: invoiceRevenue,
      by_type: revenueByType,
      monthly_6mo: monthlyRevenue,
      paid_transactions: paidPayments.length,
      failed_transactions: failedPayments.length,
      pending_transactions: pendingPayments.length,
    };

    // ─── 4. Error Rates ──────────────────────────────────────────────────────

    // Payment failure rate
    const totalPaymentAttempts = payments.length;
    const paymentFailureRate = totalPaymentAttempts > 0
      ? Math.round((failedPayments.length / totalPaymentAttempts) * 10000) / 100
      : 0;

    // Invoice overdue rate
    const totalInvoices = invoices.length;
    const invoiceOverdueRate = totalInvoices > 0
      ? Math.round((overdueInvoices.length / totalInvoices) * 10000) / 100
      : 0;

    // Panic alert stats
    const openPanics = panicAlerts.filter(p => p.status === 'open' || p.status === 'pending');
    const resolvedPanics = panicAlerts.filter(p => p.status === 'resolved');
    const cancelledPanics = panicAlerts.filter(p => p.status === 'cancelled');
    const totalPanics = panicAlerts.length;

    // Panic resolution time (avg minutes from created_at to resolved_at)
    let avgPanicResolutionMinutes: number | null = null;
    const resolvedWithTime = panicAlerts.filter(p =>
      p.status === 'resolved' && p.resolved_at && p.created_at
    );
    if (resolvedWithTime.length > 0) {
      const totalResolutionMs = resolvedWithTime.reduce((sum, p) => {
        return sum + (new Date(p.resolved_at).getTime() - new Date(p.created_at).getTime());
      }, 0);
      avgPanicResolutionMinutes = Math.round(totalResolutionMs / resolvedWithTime.length / 60000);
    }

    // Panic error rate (% of panics that are open/pending out of total)
    const panicErrorRate = totalPanics > 0
      ? Math.round((openPanics.length / totalPanics) * 10000) / 100
      : 0;

    // SLA health: open panic alerts older than 30 minutes
    const thirtyMinutesAgo = new Date(now.getTime() - 30 * 60 * 60 * 1000).toISOString();
    const staleOpenPanics = panicAlerts.filter(p =>
      (p.status === 'open' || p.status === 'pending') &&
      p.created_at &&
      p.created_at < thirtyMinutesAgo
    ).length;

    // Agency error rate (suspended vs total)
    const suspendedAgencies = agencies.filter(a => a.wl_status === 'suspended').length;
    const agencyErrorRate = agencies.length > 0
      ? Math.round((suspendedAgencies / agencies.length) * 10000) / 100
      : 0;

    const errorRates = {
      payment_failure_pct: paymentFailureRate,
      invoice_overdue_pct: invoiceOverdueRate,
      panic_error_pct: panicErrorRate,
      agency_suspension_pct: agencyErrorRate,
      panic_resolution_avg_minutes: avgPanicResolutionMinutes,
      stale_open_panics_30m: staleOpenPanics,
      counts: {
        open_panics: openPanics.length,
        resolved_panics: resolvedPanics.length,
        cancelled_panics: cancelledPanics.length,
        total_panics: totalPanics,
        failed_payments: failedPayments.length,
        overdue_invoices: overdueInvoices.length,
        suspended_agencies: suspendedAgencies,
      },
    };

    // ─── Overall Health Score (0-100) ─────────────────────────────────────────
    const healthScore = Math.max(0, Math.min(100,
      100
      - paymentFailureRate
      - panicErrorRate
      - agencyErrorRate
      - invoiceOverdueRate
    ));

    const health = {
      score: Math.round(healthScore * 10) / 10,
      status: healthScore >= 90 ? 'healthy' : healthScore >= 70 ? 'degraded' : 'critical',
      timestamp: now.toISOString(),
    };

    return Response.json({
      active_users: activeUsers,
      seat_license: seatLicense,
      revenue,
      error_rates: errorRates,
      health,
    }, { headers: corsHeaders });

  } catch (error) {
    console.error('system-metrics error:', error);
    return Response.json({ error: 'Internal server error' }, { status: 500, headers: corsHeaders });
  }
});
