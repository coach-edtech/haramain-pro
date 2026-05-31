// Edge Function: seat-license-checkout
// POST /functions/v1/seat-license-checkout
// Creates seat license package + Xendit invoice for Travel Admin purchase

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
    const { package_id } = await req.json();

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
    const headers = {
      'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
      'apikey': SUPABASE_SERVICE_KEY,
      'Content-Type': 'application/json',
    };

    // Get agency name
    const agencyRes = await fetch(`${SUPABASE_URL}/rest/v1/agencies?id=eq.${agencyId}&select=name`, {
      headers,
    });
    const agencies = await agencyRes.json();
    const agencyName = agencies?.[0]?.name || 'Unknown';

    // Create payment record first (status: pending)
    const paymentPayload = {
      agency_id: agencyId,
      type: 'seat_license_purchase',
      reference_id: `SLP-${Date.now()}`,
      amount: totalPrice,
      currency: 'IDR',
      payment_status: 'pending',
    };

    const paymentRes = await fetch(`${SUPABASE_URL}/rest/v1/payments`, {
      method: 'POST',
      headers,
      body: JSON.stringify(paymentPayload),
    });
    const payments = await paymentRes.json();
    const payment = payments[0];

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
      headers,
      body: JSON.stringify(slpPayload),
    });
    const slPackages = await slpRes.json();
    const slPackage = slPackages[0];

    // Create Xendit invoice
    const externalId = `SL-${agencyId?.slice(0, 8)}-${Date.now()}`;
    const description = `Haramain Pro Seat License - ${pkg.label} (${pkg.quantity} seats × Rp ${pkg.price_per_seat.toLocaleString('id-ID')})`;

    const xenditRes = await fetch('https://api.xendit.co/v2/invoices', {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${btoa(XENDIT_API_KEY + ':')}`,
        'Content-Type': 'application/json',
      },
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

    const xenditInvoice = await xenditRes.json();

    if (!xenditRes.ok) {
      // Rollback: delete payment and package records
      await fetch(`${SUPABASE_URL}/rest/v1/payments?id=eq.${payment.id}`, {
        method: 'DELETE', headers,
      });
      await fetch(`${SUPABASE_URL}/rest/v1/seat_license_packages?id=eq.${slPackage.id}`, {
        method: 'DELETE', headers,
      });
      return Response.json({ error: xenditInvoice.message || 'Xendit error' }, { status: 502, headers: corsHeaders });
    }

    // Update payment with Xendit ID and checkout URL
    await fetch(`${SUPABASE_URL}/rest/v1/payments?id=eq.${payment.id}`, {
      method: 'PATCH',
      headers,
      body: JSON.stringify({
        xendit_payment_id: xenditInvoice.id,
        xendit_checkout_url: xenditInvoice.invoice_url,
        reference_id: externalId,
      }),
    });

    // Update package with invoice URL
    await fetch(`${SUPABASE_URL}/rest/v1/seat_license_packages?id=eq.${slPackage.id}`, {
      method: 'PATCH',
      headers,
      body: JSON.stringify({ invoice_url: xenditInvoice.invoice_url }),
    });

    return Response.json({
      success: true,
      package_id: slPackage.id,
      payment_id: payment.id,
      xendit_invoice_id: xenditInvoice.id,
      xendit_checkout_url: xenditInvoice.invoice_url,
      amount: totalPrice,
      quantity: pkg.quantity,
      description,
    }, { headers: corsHeaders });

  } catch (error) {
    console.error('seat-license-checkout error:', error);
    return Response.json({ error: 'Internal server error' }, { status: 500, headers: corsHeaders });
  }
});
