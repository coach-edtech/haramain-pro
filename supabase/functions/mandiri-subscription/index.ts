// Edge Function: mandiri-subscription
// POST /functions/v1/mandiri-subscription
// Creates Xendit invoice for Umrah Mandiri self-purchase (Rp 120.000/lifetime)

import { serve } from "https://deno.land/x/sift@0.6.0/mod.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://haramain.pro',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, content-type',
  'Access-Control-Max-Age': '86400',
};

const MANDIRI_PRICE = 120000; // Rp 120,000 lifetime

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return Response.json({ error: 'Method not allowed' }, { status: 405, headers: corsHeaders });
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

  const userId = jwtPayload.sub;
  const XENDIT_API_KEY = Deno.env.get('XENDIT_API_KEY');
  if (!XENDIT_API_KEY) {
    return Response.json({ error: 'Xendit not configured' }, { status: 500, headers: corsHeaders });
  }

  try {
    const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
    const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const headers = {
      'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
      'apikey': SUPABASE_SERVICE_KEY,
      'Content-Type': 'application/json',
    };

    // Check if user already has active subscription
    const profileRes = await fetch(
      `${SUPABASE_URL}/rest/v1/profiles?id=eq.${userId}&select=id,subscription_tier,agency_id`,
      { headers }
    );
    const profiles = await profileRes.json();
    const profile = profiles?.[0];

    if (!profile) {
      return Response.json({ error: 'Profile not found' }, { status: 404, headers: corsHeaders });
    }

    if (profile.subscription_tier === 'active') {
      return Response.json({ error: 'Already subscribed' }, { status: 400, headers: corsHeaders });
    }

    // Check for existing pending mandiri payment
    const existingPayRes = await fetch(
      `${SUPABASE_URL}/rest/v1/payments?user_id=eq.${userId}&type=eq.mandiri_subscription&payment_status=eq.pending&select=id`,
      { headers }
    );
    const existingPayments = await existingPayRes.json();

    if (existingPayments && existingPayments.length > 0) {
      // Return existing payment URL
      const paymentId = existingPayments[0].id;
      const paymentDetailRes = await fetch(
        `${SUPABASE_URL}/rest/v1/payments?id=eq.${paymentId}&select=xendit_checkout_url`,
        { headers }
      );
      const paymentDetails = await paymentDetailRes.json();
      if (paymentDetails?.[0]?.xendit_checkout_url) {
        return Response.json({
          existing: true,
          checkout_url: paymentDetails[0].xendit_checkout_url,
          message: 'You have a pending payment',
        }, { headers: corsHeaders });
      }
    }

    // Create payment record
    const paymentRes = await fetch(`${SUPABASE_URL}/rest/v1/payments`, {
      method: 'POST',
      headers,
      body: JSON.stringify({
        type: 'mandiri_subscription',
        reference_id: userId, // for mandiri, reference_id = user_id
        amount: MANDIRI_PRICE,
        currency: 'IDR',
        payment_status: 'pending',
      }),
    });
    const payments = await paymentRes.json();
    const payment = payments[0];

    // Create Xendit invoice
    const externalId = `MANDIRI-${userId}-${Date.now()}`;
    const description = 'Umrah Mandiri -langganan Lifetime (Rp 120.000)';

    const xenditRes = await fetch('https://api.xendit.co/v2/invoices', {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${btoa(XENDIT_API_KEY + ':')}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        external_id: externalId,
        amount: MANDIRI_PRICE,
        description,
        invoice_duration: 86400,
        currency: 'IDR',
        reminder_time: 86000,
        client_type: 'customer',
        payment_methods: ['OVO', 'DANA', 'BANK_TRANSFER', 'CREDIT_CARD'],
      }),
    });

    const xenditInvoice = await xenditRes.json();

    if (!xenditRes.ok) {
      // Rollback payment record
      await fetch(`${SUPABASE_URL}/rest/v1/payments?id=eq.${payment.id}`, {
        method: 'DELETE', headers,
      });
      return Response.json({ error: xenditInvoice.message || 'Xendit error' }, { status: 502, headers: corsHeaders });
    }

    // Update payment with Xendit details
    await fetch(`${SUPABASE_URL}/rest/v1/payments?id=eq.${payment.id}`, {
      method: 'PATCH',
      headers,
      body: JSON.stringify({
        xendit_payment_id: xenditInvoice.id,
        xendit_checkout_url: xenditInvoice.invoice_url,
      }),
    });

    return Response.json({
      success: true,
      payment_id: payment.id,
      xendit_invoice_id: xenditInvoice.id,
      checkout_url: xenditInvoice.invoice_url,
      amount: MANDIRI_PRICE,
      description,
    }, { headers: corsHeaders });

  } catch (error) {
    console.error('mandiri-subscription error:', error);
    return Response.json({ error: 'Internal server error' }, { status: 500, headers: corsHeaders });
  }
});
