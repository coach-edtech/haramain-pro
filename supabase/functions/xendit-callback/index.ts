// Edge Function: xendit-callback
// POST /functions/v1/xendit-callback
// Handles Xendit payment webhook callbacks - verifies via XENDIT_CALLBACK_TOKEN

import { serve } from "https://deno.land/x/sift@0.6.0/mod.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://haramain.pro',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, content-type, x-callback-token',
  'Access-Control-Max-Age': '86400',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return Response.json({ error: 'Method not allowed' }, { status: 405, headers: corsHeaders });
  }

  // Verify callback token
  const callbackToken = req.headers.get('x-callback-token');
  const expectedToken = Deno.env.get('XENDIT_CALLBACK_TOKEN');
  
  if (!expectedToken) {
    console.error('XENDIT_CALLBACK_TOKEN environment variable not configured');
    return Response.json({ error: 'Server misconfiguration' }, { status: 500, headers: corsHeaders });
  }
  
  if (!callbackToken || callbackToken !== expectedToken) {
    return Response.json({ error: 'Unauthorized callback' }, { status: 401, headers: corsHeaders });
  }

  const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
  const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const headers = {
    'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
    'apikey': SUPABASE_SERVICE_KEY,
    'Content-Type': 'application/json',
  };

  try {
    const event = await req.json();
    
    // Log all events for debugging
    console.log('Xendit callback event:', JSON.stringify(event));

    // Handle different Xendit event types
    const eventType = event.event;
    const data = event.data;

    if (!data) {
      return Response.json({ error: 'Invalid payload - missing data' }, { status: 400, headers: corsHeaders });
    }

    const xenditPaymentId = data.id;
    const externalId = data.external_id;

    switch (eventType) {
      case 'invoice.payment_completed':
        return await handlePaymentCompleted(data, xenditPaymentId, externalId, SUPABASE_URL, headers, corsHeaders);
      
      case 'invoice.payment_failed':
        return await handlePaymentFailed(data, xenditPaymentId, externalId, SUPABASE_URL, headers, corsHeaders);
      
      case 'invoice.expired':
        return await handlePaymentExpired(data, externalId, SUPABASE_URL, headers, corsHeaders);
      
      case 'payment.success':
        return await handlePaymentSuccess(data, SUPABASE_URL, headers, corsHeaders);
      
      case 'payment.failed':
        return await handlePaymentFailedGeneric(data, SUPABASE_URL, headers, corsHeaders);
      
      default:
        // Acknowledge unknown events without error (Xendit may add new event types)
        console.log(`Ignoring unhandled event type: ${eventType}`);
        return Response.json({ received: true, ignored: true }, { headers: corsHeaders });
    }

  } catch (error) {
    console.error('xendit-callback error:', error);
    return Response.json({ error: 'Internal server error' }, { status: 500, headers: corsHeaders });
  }
});

async function handlePaymentCompleted(
  data: any,
  xenditPaymentId: string,
  externalId: string,
  supabaseUrl: string,
  headers: Record<string, string>,
  corsHeaders: Record<string, string>
) {
  // Find payment by Xendit ID or external_id
  let payments = await findPayment(supabaseUrl, headers, { xendit_payment_id: xenditPaymentId });
  
  if (!payments || payments.length === 0) {
    payments = await findPayment(supabaseUrl, headers, { reference_id: externalId });
  }

  if (!payments || payments.length === 0) {
    console.error('Payment not found for xendit_payment_id:', xenditPaymentId, 'or external_id:', externalId);
    return Response.json({ error: 'Payment not found' }, { status: 404, headers: corsHeaders });
  }

  const payment = payments[0];

  // Idempotency: skip if already paid
  if (payment.payment_status === 'paid') {
    return Response.json({ received: true, idempotent: true }, { headers: corsHeaders });
  }

  const agencyId = payment.agency_id;
  const paymentType = payment.type;

  // Process based on payment type
  switch (paymentType) {
    case 'seat_license_purchase':
      await processSeatLicensePurchase(supabaseUrl, headers, payment, agencyId, data, xenditPaymentId);
      break;
    
    case 'mandiri_subscription':
      await processMandiriSubscription(supabaseUrl, headers, payment, externalId, data);
      break;
    
    case 'safety_pass':
      await processSafetyPassPurchase(supabaseUrl, headers, payment, data, xenditPaymentId);
      break;
    
    default:
      // Generic payment update
      await updatePaymentStatus(supabaseUrl, headers, payment.id, 'paid', data.payment_method);
  }

  return Response.json({ received: true, processed: true }, { headers: corsHeaders });
}

async function handlePaymentFailed(
  data: any,
  xenditPaymentId: string,
  externalId: string,
  supabaseUrl: string,
  headers: Record<string, string>,
  corsHeaders: Record<string, string>
) {
  let payments = await findPayment(supabaseUrl, headers, { xendit_payment_id: xenditPaymentId });
  
  if (!payments || payments.length === 0) {
    payments = await findPayment(supabaseUrl, headers, { reference_id: externalId });
  }

  if (!payments || payments.length === 0) {
    console.error('Payment not found for failed callback:', xenditPaymentId);
    return Response.json({ error: 'Payment not found' }, { status: 404, headers: corsHeaders });
  }

  const payment = payments[0];

  // Only update if not already paid
  if (payment.payment_status !== 'paid') {
    const failureReason = data.failure_reason || 'Payment failed';
    await updatePaymentStatus(supabaseUrl, headers, payment.id, 'failed', undefined, failureReason);
    
    // Cancel related seat license packages if any
    if (payment.type === 'seat_license_purchase') {
      await cancelRelatedSeatLicensePackage(supabaseUrl, headers, payment.id);
    }
  }

  return Response.json({ received: true, processed: true }, { headers: corsHeaders });
}

async function handlePaymentExpired(
  data: any,
  externalId: string,
  supabaseUrl: string,
  headers: Record<string, string>,
  corsHeaders: Record<string, string>
) {
  const payments = await findPayment(supabaseUrl, headers, { reference_id: externalId });

  if (!payments || payments.length === 0) {
    console.error('Payment not found for expired callback:', externalId);
    return Response.json({ error: 'Payment not found' }, { status: 404, headers: corsHeaders });
  }

  const payment = payments[0];

  // Only update if not already paid
  if (payment.payment_status !== 'paid') {
    await updatePaymentStatus(supabaseUrl, headers, payment.id, 'expired');
    
    // Cancel related seat license packages if any
    if (payment.type === 'seat_license_purchase') {
      await cancelRelatedSeatLicensePackage(supabaseUrl, headers, payment.id);
    }
  }

  return Response.json({ received: true, processed: true }, { headers: corsHeaders });
}

async function handlePaymentSuccess(
  data: any,
  supabaseUrl: string,
  headers: Record<string, string>,
  corsHeaders: Record<string, string>
) {
  // Generic payment success - try to find by Xendit ID
  const xenditPaymentId = data.id || data.payment_id;
  if (!xenditPaymentId) {
    return Response.json({ error: 'Missing payment ID' }, { status: 400, headers: corsHeaders });
  }

  const payments = await findPayment(supabaseUrl, headers, { xendit_payment_id: xenditPaymentId });

  if (!payments || payments.length === 0) {
    console.error('Payment not found for success callback:', xenditPaymentId);
    return Response.json({ error: 'Payment not found' }, { status: 404, headers: corsHeaders });
  }

  const payment = payments[0];

  if (payment.payment_status !== 'paid') {
    await updatePaymentStatus(supabaseUrl, headers, payment.id, 'paid', data.payment_method);
  }

  return Response.json({ received: true, processed: true }, { headers: corsHeaders });
}

async function handlePaymentFailedGeneric(
  data: any,
  supabaseUrl: string,
  headers: Record<string, string>,
  corsHeaders: Record<string, string>
) {
  const xenditPaymentId = data.id || data.payment_id;
  if (!xenditPaymentId) {
    return Response.json({ error: 'Missing payment ID' }, { status: 400, headers: corsHeaders });
  }

  const payments = await findPayment(supabaseUrl, headers, { xendit_payment_id: xenditPaymentId });

  if (!payments || payments.length === 0) {
    console.error('Payment not found for failed callback:', xenditPaymentId);
    return Response.json({ error: 'Payment not found' }, { status: 404, headers: corsHeaders });
  }

  const payment = payments[0];

  if (payment.payment_status !== 'paid') {
    const failureReason = data.failure_reason || 'Payment failed';
    await updatePaymentStatus(supabaseUrl, headers, payment.id, 'failed', undefined, failureReason);
  }

  return Response.json({ received: true, processed: true }, { headers: corsHeaders });
}

async function processSeatLicensePurchase(
  supabaseUrl: string,
  headers: Record<string, string>,
  payment: any,
  agencyId: string,
  data: any,
  xenditPaymentId: string
) {
  // Find the seat_license_package for this payment
  const slpRes = await fetch(
    `${supabaseUrl}/rest/v1/seat_license_packages?payment_id=eq.${payment.id}&select=*`,
    { headers }
  );
  const slPackages = await slpRes.json();
  const slPackage = slPackages?.[0];

  if (slPackage) {
    // Update package to paid
    await fetch(`${supabaseUrl}/rest/v1/seat_license_packages?id=eq.${slPackage.id}`, {
      method: 'PATCH',
      headers,
      body: JSON.stringify({
        payment_status: 'paid',
        paid_at: new Date().toISOString(),
      }),
    });

    // Add seat balance to agency via RPC
    await fetch(`${supabaseUrl}/rest/v1/rpc/add_seat_balance`, {
      method: 'POST',
      headers,
      body: JSON.stringify({
        p_agency_id: agencyId,
        p_quantity: slPackage.quantity,
        p_package_id: slPackage.id,
      }),
    });

    // Get current balance for transaction log
    const balanceAfter = await fetchAgencyBalance(agencyId, supabaseUrl, headers);

    // Log transaction
    await fetch(`${supabaseUrl}/rest/v1/seat_license_transactions`, {
      method: 'POST',
      headers,
      body: JSON.stringify({
        agency_id: agencyId,
        type: 'purchase',
        quantity: slPackage.quantity,
        balance_after: balanceAfter + slPackage.quantity,
        related_package_id: slPackage.id,
        notes: `Purchased via Xendit invoice ${xenditPaymentId}`,
      }),
    });
  }

  // Update payment status
  await updatePaymentStatus(supabaseUrl, headers, payment.id, 'paid', data.payment_method);
}

async function processMandiriSubscription(
  supabaseUrl: string,
  headers: Record<string, string>,
  payment: any,
  externalId: string,
  data: any
) {
  const userId = externalId; // for mandiri, external_id is user_id
  
  if (userId) {
    await fetch(`${supabaseUrl}/rest/v1/profiles?id=eq.${userId}`, {
      method: 'PATCH',
      headers,
      body: JSON.stringify({ subscription_tier: 'active' }),
    });
  }

  await updatePaymentStatus(supabaseUrl, headers, payment.id, 'paid', data.payment_method);
}

async function processSafetyPassPurchase(
  supabaseUrl: string,
  headers: Record<string, string>,
  payment: any,
  data: any,
  xenditPaymentId: string
) {
  // Update payment status
  await updatePaymentStatus(supabaseUrl, headers, payment.id, 'paid', data.payment_method);

  // Safety Pass specific logic could be added here
  // e.g., activate safety pass for user, send confirmation, etc.
  console.log(`Safety pass payment completed: ${payment.id}, Xendit: ${xenditPaymentId}`);
}

async function updatePaymentStatus(
  supabaseUrl: string,
  headers: Record<string, string>,
  paymentId: string,
  status: 'paid' | 'failed' | 'expired',
  paymentMethod?: string,
  failureReason?: string
) {
  const updatePayload: any = {
    payment_status: status,
    updated_at: new Date().toISOString(),
  };

  if (status === 'paid') {
    updatePayload.paid_at = new Date().toISOString();
  }
  
  if (paymentMethod) {
    updatePayload.payment_method = paymentMethod;
  }
  
  if (failureReason) {
    updatePayload.failure_reason = failureReason;
  }

  await fetch(`${supabaseUrl}/rest/v1/payments?id=eq.${paymentId}`, {
    method: 'PATCH',
    headers,
    body: JSON.stringify(updatePayload),
  });
}

async function cancelRelatedSeatLicensePackage(
  supabaseUrl: string,
  headers: Record<string, string>,
  paymentId: string
) {
  await fetch(`${supabaseUrl}/rest/v1/seat_license_packages?payment_id=eq.${paymentId}`, {
    method: 'PATCH',
    headers,
    body: JSON.stringify({
      payment_status: 'cancelled',
      cancelled_at: new Date().toISOString(),
    }),
  });
}

async function findPayment(
  supabaseUrl: string,
  headers: Record<string, string>,
  criteria: { xendit_payment_id?: string; reference_id?: string }
): Promise<any[]> {
  let query: string;
  
  if (criteria.xendit_payment_id) {
    query = `${supabaseUrl}/rest/v1/payments?xendit_payment_id=eq.${criteria.xendit_payment_id}&select=*`;
  } else if (criteria.reference_id) {
    query = `${supabaseUrl}/rest/v1/payments?reference_id=eq.${criteria.reference_id}&select=*`;
  } else {
    return [];
  }

  const res = await fetch(query, { headers });
  return await res.json();
}

async function fetchAgencyBalance(
  agencyId: string,
  supabaseUrl: string,
  headers: Record<string, string>
): Promise<number> {
  try {
    const res = await fetch(`${supabaseUrl}/rest/v1/agencies?id=eq.${agencyId}&select=seat_balance`, {
      headers,
    });
    const agencies = await res.json();
    return agencies?.[0]?.seat_balance ?? 0;
  } catch {
    return 0;
  }
}
