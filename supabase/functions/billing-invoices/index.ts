// Edge Function: billing-invoices
// GET  /functions/v1/billing-invoices
// POST /functions/v1/billing-invoices (generate)
// PATCH /functions/v1/billing-invoices?id= (update status)

import { serve } from "https://deno.land/x/sift@0.6.0/mod.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://haramain.pro',
  'Access-Control-Allow-Methods': 'GET, POST, PATCH, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, content-type',
  'Access-Control-Max-Age': '86400',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

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

  const role = jwtPayload.role;
  const tokenAgencyId = jwtPayload.agency_id;

  if (!['travel_admin', 'super_admin', 'admin_haramain_pro'].includes(role)) {
    return Response.json({ error: 'Forbidden' }, { status: 403, headers: corsHeaders });
  }

  const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
  const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const headers = {
    'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
    'apikey': SUPABASE_SERVICE_KEY,
    'Content-Type': 'application/json',
  };

  try {
    const url = new URL(req.url);

    // GET: list invoices
    if (req.method === 'GET') {
      let targetAgencyId = tokenAgencyId;
      if (role === 'super_admin' || role === 'admin_haramain_pro') {
        targetAgencyId = url.searchParams.get('agency_id') || tokenAgencyId;
      }

      const status = url.searchParams.get('status');
      const limit = Math.min(parseInt(url.searchParams.get('limit') || '50'), 100);

      let query = `${SUPABASE_URL}/rest/v1/invoices?agency_id=eq.${targetAgencyId}&order=created_at.desc&limit=${limit}`;
      if (status) query += `&status=eq.${status}`;

      const invRes = await fetch(query, { headers });
      const invoices: any[] = await invRes.json();

      return Response.json({
        invoices: invoices.map(inv => ({
          id: inv.id,
          invoice_number: inv.invoice_number,
          billing_period_start: inv.billing_period_start,
          billing_period_end: inv.billing_period_end,
          active_pax_count: inv.active_pax_count,
          price_per_seat: inv.price_per_seat,
          subtotal: inv.subtotal,
          adjustments: inv.adjustments,
          total_due: inv.total_due,
          status: inv.status,
          due_date: inv.due_date,
          paid_at: inv.paid_at,
          pdf_url: inv.pdf_url,
          created_at: inv.created_at,
        })),
        count: invoices.length,
      }, { headers: corsHeaders });

    // POST: generate invoice
    } else if (req.method === 'POST') {
      if (role !== 'super_admin') {
        return Response.json({ error: 'Only super_admin can generate invoices' }, { status: 403, headers: corsHeaders });
      }

      const { agency_id, period_start, period_end, price_per_seat = 50000 } = await req.json();

      if (!agency_id || !period_start || !period_end) {
        return Response.json({ error: 'agency_id, period_start, period_end required' }, { status: 400, headers: corsHeaders });
      }

      // Count active pax in billing period
      const startDate = new Date(period_start).toISOString().split('T')[0];
      const endDate = new Date(period_end).toISOString().split('T')[0];

      const activePaxRes = await fetch(
        `${SUPABASE_URL}/rest/v1/seat_license_transactions?agency_id=eq.${agency_id}&type=eq.consumed&created_at=gte.${startDate}&created_at=lte.${endDate}&select=id`,
        { headers }
      );
      const activePaxData: any[] = await activePaxRes.json();
      const activePaxCount = activePaxData.length;

      const subtotal = activePaxCount * price_per_seat;

      // Generate invoice number: INV-{AGENCY_SHORT}-{YYYYMM}-{SEQ}
      const yearMonth = new Date(period_start).toISOString().slice(0, 7).replace('-', '');
      const shortId = agency_id.replace(/-/g, '').slice(0, 6).toUpperCase();

      // Get sequence number for this agency+month
      const seqRes = await fetch(
        `${SUPABASE_URL}/rest/v1/invoices?invoice_number=ilike.INV-${shortId}-${yearMonth}%&order=invoice_number.desc&limit=1&select=invoice_number`,
        { headers }
      );
      const existingInvoices: any[] = await seqRes.json();
      let seq = 1;
      if (existingInvoices.length > 0) {
        const lastNum = existingInvoices[0].invoice_number;
        const match = lastNum.match(/-(\d{3})$/);
        if (match) seq = parseInt(match[1]) + 1;
      }

      const invoiceNumber = `INV-${shortId}-${yearMonth}-${String(seq).padStart(3, '0')}`;
      const dueDate = new Date(Date.now() + 14 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];

      // Create invoice
      const invoicePayload = {
        invoice_number: invoiceNumber,
        agency_id,
        billing_period_start: period_start,
        billing_period_end: period_end,
        active_pax_count: activePaxCount,
        price_per_seat,
        subtotal,
        adjustments: 0,
        total_due: subtotal,
        status: 'draft',
        due_date: dueDate,
      };

      const invRes = await fetch(`${SUPABASE_URL}/rest/v1/invoices`, {
        method: 'POST',
        headers,
        body: JSON.stringify(invoicePayload),
      });
      const invoices = await invRes.json();

      return Response.json({
        success: true,
        invoice: invoices[0],
        active_pax_count: activePaxCount,
      }, { headers: corsHeaders });

    // PATCH: update invoice (mark paid, etc)
    } else if (req.method === 'PATCH') {
      const invoiceId = url.searchParams.get('id');
      if (!invoiceId) {
        return Response.json({ error: 'Invoice id required' }, { status: 400, headers: corsHeaders });
      }

      const body = await req.json();
      const { status, payment_method, payment_proof_url } = body;

      if (!status) {
        return Response.json({ error: 'status required' }, { status: 400, headers: corsHeaders });
      }

      const updatePayload: any = { status };
      if (status === 'paid') {
        updatePayload.paid_at = new Date().toISOString();
        if (payment_method) updatePayload.payment_method = payment_method;
        if (payment_proof_url) updatePayload.payment_proof_url = payment_proof_url;
      }

      await fetch(`${SUPABASE_URL}/rest/v1/invoices?id=eq.${invoiceId}`, {
        method: 'PATCH',
        headers,
        body: JSON.stringify(updatePayload),
      });

      return Response.json({ success: true, status }, { headers: corsHeaders });

    } else {
      return Response.json({ error: 'Method not allowed' }, { status: 405, headers: corsHeaders });
    }

  } catch (error) {
    console.error('billing-invoices error:', error);
    return Response.json({ error: 'Internal server error' }, { status: 500, headers: corsHeaders });
  }
});
