// Edge Function: xendit-webhook
// POST /functions/v1/xendit-webhook
// Handles Xendit payment callbacks - updates payment + seat license status

import { serve } from "https://deno.land/x/sift@0.6.0/mod.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://haramain.pro',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, content-type, x-webhook-key',
  'Access-Control-Max-Age': '86400',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return Response.json({ error: 'Method not allowed' }, { status: 405, headers: corsHeaders });
  }

  // Verify webhook key
  const webhookKey = req.headers.get('x-webhook-key');
  const expectedKey = Deno.env.get('XENDIT_WEBHOOK_KEY');
  if (!webhookKey || webhookKey !== expectedKey) {
    return Response.json({ error: 'Unauthorized webhook' }, { status: 401, headers: corsHeaders });
  }

  try {
    const event = await req.json();

    if (event.event !== 'invoice.payment_completed') {
      return Response.json({ received: true, ignored: true }, { headers: corsHeaders });
    }

    const xenditInvoice = event.data;
    const xenditPaymentId = xenditInvoice.id;
    const externalId = xenditInvoice.external_id;

    const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
    const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const headers = {
      'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
      'apikey': SUPABASE_SERVICE_KEY,
      'Content-Type': 'application/json',
    };

    // Find payment by Xendit ID or external_id
    let paymentQuery = `${SUPABASE_URL}/rest/v1/payments?xendit_payment_id=eq.${xenditPaymentId}&select=*`;
    let paymentRes = await fetch(paymentQuery, { headers });
    let payments = await paymentRes.json();

    // Also try by reference_id
    if (!payments || payments.length === 0) {
      paymentQuery = `${SUPABASE_URL}/rest/v1/payments?reference_id=eq.${externalId}&select=*`;
      paymentRes = await fetch(paymentQuery, { headers });
      payments = await paymentRes.json();
    }

    if (!payments || payments.length === 0) {
      console.error('Payment not found for xendit_payment_id:', xenditPaymentId);
      return Response.json({ error: 'Payment not found' }, { status: 404, headers: corsHeaders });
    }

    const payment = payments[0];

    // Idempotency: skip if already paid
    if (payment.payment_status === 'paid') {
      return Response.json({ received: true, idempotent: true }, { headers: corsHeaders });
    }

    const agencyId = payment.agency_id;

    // Determine payment type and process accordingly
    if (payment.type === 'seat_license_purchase') {
      // Find the seat_license_package for this payment
      const slpRes = await fetch(
        `${SUPABASE_URL}/rest/v1/seat_license_packages?payment_id=eq.${payment.id}&select=*`,
        { headers }
      );
      const slPackages = await slpRes.json();
      const slPackage = slPackages?.[0];

      if (slPackage) {
        // Update package to paid
        await fetch(`${SUPABASE_URL}/rest/v1/seat_license_packages?id=eq.${slPackage.id}`, {
          method: 'PATCH',
          headers,
          body: JSON.stringify({
            payment_status: 'paid',
            paid_at: new Date().toISOString(),
          }),
        });

        // Add seat balance to agency via RPC
        await fetch(`${SUPABASE_URL}/rest/v1/rpc/add_seat_balance`, {
          method: 'POST',
          headers,
          body: JSON.stringify({
            p_agency_id: agencyId,
            p_quantity: slPackage.quantity,
            p_package_id: slPackage.id,
          }),
        });

        // Log transaction
        await fetch(`${SUPABASE_URL}/rest/v1/seat_license_transactions`, {
          method: 'POST',
          headers,
          body: JSON.stringify({
            agency_id: agencyId,
            type: 'purchase',
            quantity: slPackage.quantity,
            balance_after: slPackage.quantity + (await fetchAgencyBalance(agencyId, SUPABASE_URL, SUPABASE_SERVICE_KEY)),
            related_package_id: slPackage.id,
            notes: `Purchased via Xendit invoice ${xenditPaymentId}`,
          }),
        });
      }

      // Update payment status
      await fetch(`${SUPABASE_URL}/rest/v1/payments?id=eq.${payment.id}`, {
        method: 'PATCH',
        headers,
        body: JSON.stringify({
          payment_status: 'paid',
          paid_at: new Date().toISOString(),
          payment_method: xenditInvoice.payment_method || 'unknown',
        }),
      });

    } else if (payment.type === 'mandiri_subscription') {
      // Mandiri subscription - activate premium for user
      const userId = externalId; // for mandiri, external_id is user_id
      if (userId) {
        await fetch(`${SUPABASE_URL}/rest/v1/profiles?id=eq.${userId}`, {
          method: 'PATCH',
          headers,
          body: JSON.stringify({ subscription_tier: 'active' }),
        });
      }

      await fetch(`${SUPABASE_URL}/rest/v1/payments?id=eq.${payment.id}`, {
        method: 'PATCH',
        headers,
        body: JSON.stringify({
          payment_status: 'paid',
          paid_at: new Date().toISOString(),
        }),
      });

    } else {
      // Generic payment status update
      await fetch(`${SUPABASE_URL}/rest/v1/payments?id=eq.${payment.id}`, {
        method: 'PATCH',
        headers,
        body: JSON.stringify({
          payment_status: 'paid',
          paid_at: new Date().toISOString(),
        }),
      });
    }

    return Response.json({ received: true, processed: true }, { headers: corsHeaders });

  } catch (error) {
    console.error('xendit-webhook error:', error);
    return Response.json({ error: 'Internal server error' }, { status: 500, headers: corsHeaders });
  }
});

// Helper to get current agency seat balance
async function fetchAgencyBalance(agencyId: string, supabaseUrl: string, serviceKey: string): Promise<number> {
  try {
    const res = await fetch(`${supabaseUrl}/rest/v1/agencies?id=eq.${agencyId}&select=seat_balance`, {
      headers: { 'Authorization': `Bearer ${serviceKey}`, 'apikey': serviceKey },
    });
    const agencies = await res.json();
    return agencies?.[0]?.seat_balance ?? 0;
  } catch {
    return 0;
  }
}
