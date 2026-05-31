// Edge Function: seat-license-checkout
// POST /functions/v1/seat-license-checkout
// Creates seat license package + Xendit invoice for Travel Admin purchase
// Supports idempotent requests via idempotency_key in request body

import { serve } from "https://deno.land/x/sift@0.6.0/mod.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://haramain.pro',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, content-type',
  'Access-Control-Max-Age': '86400',
};

// Package definitions (from PRD)
const PACKAGES = [
  { id: 'pkg_10', quantity: 10, price_per_seat: 90000, label: '10 seats' },
  { id: 'pkg_50', quantity: 50, price_per_seat: 80000, label: '50 seats' },
  { id: 'pkg_100', quantity: 100, price_per_seat: 70000, label: '100 seats' },
];

// Xendit API timeout (10s)
const XENDIT_TIMEOUT_MS = 10000;

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

  const role = jwtPayload.role;
  const userId = jwtPayload.sub;
  const tokenAgencyId = jwtPayload.agency_id;

  if (!['travel_admin', 'super_admin'].includes(role)) {
    return Response.json({ error: 'Forbidden' }, { status: 403, headers: corsHeaders });
  }

  const XENDIT_API_KEY = Deno.env.get('XENDIT_API_KEY');
  if (!XENDIT_API_KEY) {
    return Response.json({ error: 'Xendit not configured' }, { status: 500, headers: corsHeaders });
  }

  try {
    const body = await req.json();
    const { package_id, idempotency_key } = body;

    const pkg = PACKAGES.find(p => p.id === package_id);
    if (!pkg) {
      return Response.json({
        error: 'Invalid package_id',
        valid_packages: PACKAGES.map(p => ({ id: p.id, label: p.label, price_per_seat: p.price_per_seat })),
      }, { status: 400, headers: corsHeaders });
    }

    const totalPrice = pkg.quantity * pkg.price_per_seat;
    const agencyId = tokenAgencyId;

    const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
    const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabaseHeaders = {
      'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
      'apikey': SUPABASE_SERVICE_KEY,
      'Content-Type': 'application/json',
      'Prefer': 'return=representation', // ensure POST returns full object
    };

    // Get agency name
    const agencyRes = await fetch(`${SUPABASE_URL}/rest/v1/agencies?id=eq.${agencyId}&select=name`, {
      headers: supabaseHeaders,
    });
    const agencies = await agencyRes.json();
    const agencyName = agencies?.[0]?.name || 'Unknown';

    // Build external_id - use idempotency_key if provided for deterministic result
    const timestamp = Date.now();
    const externalId = idempotency_key
      ? `SL-${agencyId?.slice(0, 8)}-${idempotency_key}`
      : `SL-${agencyId?.slice(0, 8)}-${timestamp}`;

    // Check if payment already exists for this idempotency key (idempotent replay)
    if (idempotency_key) {
      const existingPaymentRes = await fetch(
        `${SUPABASE_URL}/rest/v1/payments?reference_id=eq.${externalId}&select=*`,
        { headers: supabaseHeaders }
      );
      const existingPayments = await existingPaymentRes.json();
      if (existingPayments && existingPayments.length > 0) {
        const existing = existingPayments[0];
        // Look up the seat_license_package via payment_id (payments table has payment_id -> seat_license_packages)
        const slRes = await fetch(
          `${SUPABASE_URL}/rest/v1/seat_license_packages?payment_id=eq.${existing.id}&select=id,quantity`,
          { headers: supabaseHeaders }
        );
        const slPackages = await slRes.json();
        const slPackage = slPackages?.[0];
        // Return existing record - idempotent success
        return Response.json({
          success: true,
          idempotent: true,
          package_id: slPackage?.id ?? null,
          payment_id: existing.id,
          xendit_invoice_id: existing.xendit_payment_id,
          xendit_checkout_url: existing.xendit_checkout_url,
          amount: existing.amount,
          quantity: slPackage?.quantity ?? pkg.quantity,
          description: `Haramain Pro Seat License - ${pkg.label}`,
        }, { headers: corsHeaders });
      }
    }

    // Create payment record first (status: pending)
    const paymentPayload = {
      agency_id: agencyId,
      type: 'seat_license_purchase',
      reference_id: externalId,
      amount: totalPrice,
      currency: 'IDR',
      payment_status: 'pending',
    };

    const paymentRes = await fetch(`${SUPABASE_URL}/rest/v1/payments`, {
      method: 'POST',
      headers: supabaseHeaders,
      body: JSON.stringify(paymentPayload),
    });
    const paymentResult = await paymentRes.json();
    if (!paymentResult || paymentResult.length === 0 || !paymentResult[0]?.id) {
      return Response.json({ error: 'Failed to create payment record' }, { status: 500, headers: corsHeaders });
    }
    const payment = paymentResult[0];

    // Create seat_license_package record
    const slpPayload = {
      agency_id: agencyId,
      package_name: `${pkg.label} Seat License`,
      quantity: pkg.quantity,
      price_per_seat: pkg.price_per_seat,
      total_price: totalPrice,
      payment_status: 'pending',
      payment_id: payment.id,
    };

    const slpRes = await fetch(`${SUPABASE_URL}/rest/v1/seat_license_packages`, {
      method: 'POST',
      headers: supabaseHeaders,
      body: JSON.stringify(slpPayload),
    });
    const slPackageResult = await slpRes.json();
    if (!slPackageResult || slPackageResult.length === 0 || !slPackageResult[0]?.id) {
      // Rollback payment
      await fetch(`${SUPABASE_URL}/rest/v1/payments?id=eq.${payment.id}`, {
        method: 'DELETE', headers: supabaseHeaders,
      });
      return Response.json({ error: 'Failed to create package record' }, { status: 500, headers: corsHeaders });
    }
    const slPackage = slPackageResult[0];

    // Update payment with seat_license_package reference (webhook resolves via payment_id -> seat_license_packages)
    await fetch(`${SUPABASE_URL}/rest/v1/payments?id=eq.${payment.id}`, {
      method: 'PATCH',
      headers: supabaseHeaders,
      body: JSON.stringify({ seat_license_package_id: slPackage.id }),
    }).catch(e => console.error('Failed to patch payment with package ref:', e));

    // Create Xendit invoice with idempotency key
    const description = `Haramain Pro Seat License - ${pkg.label} (${pkg.quantity} seats × Rp ${pkg.price_per_seat.toLocaleString('id-ID')})`;

    // Build Xendit request with AbortController for timeout
    const xenditController = new AbortController();
    const xenditTimeout = setTimeout(() => xenditController.abort(), XENDIT_TIMEOUT_MS);

    const xenditHeaders: Record<string, string> = {
      'Authorization': `Basic ${btoa(XENDIT_API_KEY + ':')}`,
      'Content-Type': 'application/json',
    };
    // Use idempotency_key as Xendit idempotency key for safe retries
    if (idempotency_key) {
      xenditHeaders['Idempotency-Key'] = idempotency_key;
    }

    const xenditRes = await fetch('https://api.xendit.co/v2/invoices', {
      method: 'POST',
      headers: xenditHeaders,
      signal: xenditController.signal,
      body: JSON.stringify({
        external_id: externalId,
        amount: totalPrice,
        description,
        invoice_duration: 86400,
        currency: 'IDR',
        reminder_time: 86000,
        client_type: 'customer',
        customer: {
          given_names: agencyName,
          corporate_name: agencyName,
        },
        payment_methods: ['OVO', 'DANA', 'BANK_TRANSFER', 'CREDIT_CARD'],
      }),
    });
    clearTimeout(xenditTimeout);

    const xenditInvoice = await xenditRes.json();

    // Handle Xendit specific errors
    if (!xenditRes.ok) {
      // Error code 520 = external_id already exists (idempotent - return existing)
      if (xenditRes.status === 520 || xenditInvoice.error_code === 'DUPLICATE_IDEMPOTENCY_KEY' || xenditInvoice.error_code === 'DUPLICATE_EXTERNAL_ID') {
        // Try to find the existing invoice/payment
        const existingRes = await fetch(
          `${SUPABASE_URL}/rest/v1/payments?reference_id=eq.${externalId}&select=*`,
          { headers: supabaseHeaders }
        );
        const existingPayments = await existingRes.json();
        if (existingPayments && existingPayments.length > 0) {
          const existing = existingPayments[0];
          // Look up the seat_license_package via payment_id
          const slRes = await fetch(
            `${SUPABASE_URL}/rest/v1/seat_license_packages?payment_id=eq.${existing.id}&select=id,quantity`,
            { headers: supabaseHeaders }
          );
          const slPackages = await slRes.json();
          const slPackage = slPackages?.[0];
          // Clean up the records we just created since Xendit already has one
          await fetch(`${SUPABASE_URL}/rest/v1/seat_license_packages?id=eq.${slPackage.id}`, {
            method: 'DELETE', headers: supabaseHeaders,
          });
          await fetch(`${SUPABASE_URL}/rest/v1/payments?id=eq.${payment.id}`, {
            method: 'DELETE', headers: supabaseHeaders,
          });
          return Response.json({
            success: true,
            idempotent: true,
            package_id: slPackage?.id ?? null,
            payment_id: existing.id,
            xendit_invoice_id: existing.xendit_payment_id,
            xendit_checkout_url: existing.xendit_checkout_url,
            amount: existing.amount,
            quantity: slPackage?.quantity ?? pkg.quantity,
            description,
          }, { headers: corsHeaders });
        }
      }
      // Rollback: delete payment and package records
      await fetch(`${SUPABASE_URL}/rest/v1/payments?id=eq.${payment.id}`, {
        method: 'DELETE', headers: supabaseHeaders,
      });
      await fetch(`${SUPABASE_URL}/rest/v1/seat_license_packages?id=eq.${slPackage.id}`, {
        method: 'DELETE', headers: supabaseHeaders,
      });
      return Response.json({
        error: xenditInvoice.message || 'Xendit error',
        xendit_error_code: xenditInvoice.error_code,
      }, { status: 502, headers: corsHeaders });
    }

    // Update payment with Xendit ID and checkout URL
    const patchRes = await fetch(`${SUPABASE_URL}/rest/v1/payments?id=eq.${payment.id}`, {
      method: 'PATCH',
      headers: supabaseHeaders,
      body: JSON.stringify({
        xendit_payment_id: xenditInvoice.id,
        xendit_checkout_url: xenditInvoice.invoice_url,
      }),
    });
    if (!patchRes.ok) {
      // Log but don't fail - invoice was created successfully
      console.error('Failed to patch payment with Xendit data:', await patchRes.text());
    }

    // Update package with invoice URL
    const slPatchRes = await fetch(`${SUPABASE_URL}/rest/v1/seat_license_packages?id=eq.${slPackage.id}`, {
      method: 'PATCH',
      headers: supabaseHeaders,
      body: JSON.stringify({ invoice_url: xenditInvoice.invoice_url }),
    });
    if (!slPatchRes.ok) {
      console.error('Failed to patch package with invoice URL:', await slPatchRes.text());
    }

    return Response.json({
      success: true,
      idempotent: false,
      package_id: slPackage.id,
      payment_id: payment.id,
      xendit_invoice_id: xenditInvoice.id,
      xendit_checkout_url: xenditInvoice.invoice_url,
      amount: totalPrice,
      quantity: pkg.quantity,
      description,
    }, { headers: corsHeaders });

  } catch (error) {
    //区分网络超时和其他错误
    const isTimeout = error instanceof DOMException && error.name === 'AbortError';
    console.error('seat-license-checkout error:', isTimeout ? 'Xendit API timeout' : error);
    if (isTimeout) {
      return Response.json({ error: 'Payment service timeout, please retry' }, { status: 504, headers: corsHeaders });
    }
    return Response.json({ error: 'Internal server error' }, { status: 500, headers: corsHeaders });
  }
});
