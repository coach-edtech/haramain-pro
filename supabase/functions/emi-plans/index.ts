// Edge Function: emi-plans
// GET/POST /functions/v1/emi-plans
// GET  - List EMI installment plans by romongan_id
// POST - Create a new EMI installment plan for a romongan

import { serve } from "https://deno.land/x/sift@0.6.0/mod.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://haramain.pro',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, content-type',
  'Access-Control-Max-Age': '86400',
};

interface EmiPlan {
  id: string;
  romongan_id: string;
  total_amount: number;
  tenure_months: number | null;
  tenure_weeks: number | null;
  status: 'pending' | 'active' | 'completed' | 'cancelled';
  created_at: string;
}

interface EmiPayment {
  id: string;
  plan_id: string;
  installment_number: number;
  amount: number;
  due_date: string;
  paid_date: string | null;
  status: 'pending' | 'paid' | 'overdue';
  created_at: string;
}

// GET /functions/v1/emi-plans?romongan_id=<uuid>
// Lists EMI plans for a romongan (travel_admin sees own agency's, super_admin sees all)
serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  // Authenticate JWT
  const authHeader = req.headers.get('Authorization');
  if (!authHeader?.startsWith('Bearer ')) {
    return Response.json({ error: 'Unauthorized' }, { status: 401, headers: corsHeaders });
  }

  const token = authHeader.replace('Bearer ', '');
  let jwtPayload: any;
  try {
    jwtPayload = JSON.parse(atob(token.split('.')[1]));
  } catch {
    return Response.json({ error: 'Invalid token' }, { status: 401, headers: corsHeaders });
  }

  const userId = jwtPayload.sub;
  const role = jwtPayload.role;
  const agencyId = jwtPayload.agency_id;

  if (!['travel_admin', 'super_admin', 'admin_haramain_pro', 'agency'].includes(role)) {
    return Response.json({ error: 'Forbidden' }, { status: 403, headers: corsHeaders });
  }

  const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
  const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const supabaseHeaders = {
    'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
    'apikey': SUPABASE_SERVICE_KEY,
    'Content-Type': 'application/json',
  };

  // ─── GET ────────────────────────────────────────────────────────────────────
  if (req.method === 'GET') {
    const url = new URL(req.url);
    const romonganId = url.searchParams.get('romongan_id');

    if (!romonganId) {
      return Response.json({ error: 'romongan_id query param is required' }, { status: 400, headers: corsHeaders });
    }

    // Travel admin / agency can only see plans for their own agency's rombongans
    if (role === 'travel_admin' || role === 'agency') {
      if (!agencyId) {
        return Response.json({ error: 'No agency_id in token' }, { status: 400, headers: corsHeaders });
      }
      // Verify romongan belongs to agency
      const romonganRes = await fetch(
        `${SUPABASE_URL}/rest/v1/rombongans?id=eq.${romonganId}&agency_id=eq.${agencyId}&select=id`,
        { headers: supabaseHeaders }
      );
      const rombongans = await romonganRes.json();
      if (!rombongans || rombongans.length === 0) {
        return Response.json({ error: 'Rombongan not found or not accessible' }, { status: 404, headers: corsHeaders });
      }
    }

    // Fetch EMI plans
    const plansRes = await fetch(
      `${SUPABASE_URL}/rest/v1/emi_plans?romongan_id=eq.${romonganId}&order=created_at.desc`,
      { headers: supabaseHeaders }
    );
    const plans: EmiPlan[] = await plansRes.json();

    if (plans.length === 0) {
      return Response.json({ plans: [], payments: {} }, { headers: corsHeaders });
    }

    // Fetch all payments for these plans
    const planIds = plans.map(p => p.id);
    const paymentsRes = await fetch(
      `${SUPABASE_URL}/rest/v1/emi_payments?plan_id=in.(${planIds.join(',')})&order=installment_number.asc`,
      { headers: supabaseHeaders }
    );
    const payments: EmiPayment[] = await paymentsRes.json();

    // Group payments by plan_id
    const paymentsByPlan: Record<string, EmiPayment[]> = {};
    for (const payment of payments) {
      if (!paymentsByPlan[payment.plan_id]) {
        paymentsByPlan[payment.plan_id] = [];
      }
      paymentsByPlan[payment.plan_id].push(payment);
    }

    return Response.json({
      plans,
      payments: paymentsByPlan,
    }, { headers: corsHeaders });
  }

  // ─── POST ───────────────────────────────────────────────────────────────────
  if (req.method === 'POST') {
    let body: any;
    try {
      body = await req.json();
    } catch {
      return Response.json({ error: 'Invalid JSON body' }, { status: 400, headers: corsHeaders });
    }

    const {
      romongan_id,
      total_amount,
      tenure_months,
      tenure_weeks,
      payment_schedule, // Array of { due_date, amount } for each installment
    } = body;

    // Validation
    if (!romongan_id || !total_amount || (!tenure_months && !tenure_weeks)) {
      return Response.json({
        error: 'romongan_id, total_amount, and either tenure_months or tenure_weeks are required',
      }, { status: 400, headers: corsHeaders });
    }

    if (total_amount <= 0) {
      return Response.json({ error: 'total_amount must be greater than 0' }, { status: 400, headers: corsHeaders });
    }

    if (tenure_months && tenure_months <= 0) {
      return Response.json({ error: 'tenure_months must be greater than 0' }, { status: 400, headers: corsHeaders });
    }

    if (tenure_weeks && tenure_weeks <= 0) {
      return Response.json({ error: 'tenure_weeks must be greater than 0' }, { status: 400, headers: corsHeaders });
    }

    // Travel admin / agency can only create plans for their own agency's rombongans
    if (role === 'travel_admin' || role === 'agency') {
      if (!agencyId) {
        return Response.json({ error: 'No agency_id in token' }, { status: 400, headers: corsHeaders });
      }
      const romonganRes = await fetch(
        `${SUPABASE_URL}/rest/v1/rombongans?id=eq.${romongan_id}&agency_id=eq.${agencyId}&select=id`,
        { headers: supabaseHeaders }
      );
      const rombongans = await romonganRes.json();
      if (!rombongans || rombongans.length === 0) {
        return Response.json({ error: 'Rombongan not found or not accessible' }, { status: 404, headers: corsHeaders });
      }
    } else if (role === 'super_admin' || role === 'admin_haramain_pro') {
      // Verify romongan exists
      const romonganRes = await fetch(
        `${SUPABASE_URL}/rest/v1/rombongans?id=eq.${romongan_id}&select=id`,
        { headers: supabaseHeaders }
      );
      const rombongans = await romonganRes.json();
      if (!rombongans || rombongans.length === 0) {
        return Response.json({ error: 'Rombongan not found' }, { status: 404, headers: corsHeaders });
      }
    }

    try {
      // Create the EMI plan
      const planPayload = {
        romongan_id,
        total_amount,
        tenure_months: tenure_months || null,
        tenure_weeks: tenure_weeks || null,
        status: 'active',
      };

      const planRes = await fetch(`${SUPABASE_URL}/rest/v1/emi_plans`, {
        method: 'POST',
        headers: supabaseHeaders,
        body: JSON.stringify(planPayload),
      });
      const planResult = await planRes.json();
      if (!planResult || planResult.length === 0 || !planResult[0]?.id) {
        return Response.json({ error: 'Failed to create EMI plan' }, { status: 500, headers: corsHeaders });
      }
      const plan: EmiPlan = planResult[0];

      // Create EMI payment records
      if (payment_schedule && Array.isArray(payment_schedule) && payment_schedule.length > 0) {
        const paymentPayloads = payment_schedule.map((item: any, index: number) => ({
          plan_id: plan.id,
          installment_number: index + 1,
          amount: item.amount,
          due_date: item.due_date,
          status: 'pending',
        }));

        const paymentsRes = await fetch(`${SUPABASE_URL}/rest/v1/emi_payments`, {
          method: 'POST',
          headers: supabaseHeaders,
          body: JSON.stringify(paymentPayloads),
        });
        const paymentsResult = await paymentsRes.json();

        if (!paymentsResult || paymentsResult.length === 0) {
          // Rollback plan creation on payment failure
          await fetch(`${SUPABASE_URL}/rest/v1/emi_plans?id=eq.${plan.id}`, {
            method: 'DELETE',
            headers: supabaseHeaders,
          });
          return Response.json({ error: 'Failed to create EMI payment records' }, { status: 500, headers: corsHeaders });
        }

        return Response.json({
          plan,
          payments: paymentsResult,
        }, { status: 201, headers: corsHeaders });
      }

      return Response.json({ plan }, { status: 201, headers: corsHeaders });

    } catch (error) {
      console.error('emi-plans POST error:', error);
      return Response.json({ error: 'Internal server error' }, { status: 500, headers: corsHeaders });
    }
  }

  return Response.json({ error: 'Method not allowed' }, { status: 405, headers: corsHeaders });
});
