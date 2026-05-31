// Xendit Invoice Edge Function
// POST /functions/v1/xendit-invoice
// Creates a Xendit invoice for Safety Pass purchase

import { serve } from "https://deno.land/x/sift@0.6.0/mod.ts";

const XENDIT_API_KEY = Deno.env.get('XENDIT_API_KEY');
const XENDIT_CALLBACK_SECRET = Deno.env.get('XENDIT_CALLBACK_SECRET');

// CORS headers - no wildcard, specific origins only
const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://haramain.pro',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, content-type',
  'Access-Control-Max-Age': '86400',
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  // Verify JWT authorization
  const authHeader = req.headers.get('Authorization');
  if (!authHeader?.startsWith('Bearer ')) {
    return Response.json(
      { error: 'Unauthorized - Missing or invalid Bearer token' },
      { status: 401, headers: corsHeaders }
    );
  }

  // Only allow POST
  if (req.method !== 'POST') {
    return Response.json(
      { error: 'Method not allowed' },
      { status: 405, headers: corsHeaders }
    );
  }

  try {
    const { amount, description } = await req.json();

    // Validate input
    if (!amount || typeof amount !== 'number' || amount <= 0) {
      return Response.json(
        { error: 'Invalid amount - must be a positive number' },
        { status: 400, headers: corsHeaders }
      );
    }

    if (!description || typeof description !== 'string') {
      return Response.json(
        { error: 'Invalid description - must be a non-empty string' },
        { status: 400, headers: corsHeaders }
      );
    }

    // Check API key is configured
    if (!XENDIT_API_KEY) {
      console.error('XENDIT_API_KEY not configured');
      return Response.json(
        { error: 'Payment service not configured' },
        { status: 500, headers: corsHeaders }
      );
    }

    // Create Xendit invoice via REST API
    const externalId = `HP-${Date.now()}-${crypto.randomUUID().split('-')[0]}`;
    
    const response = await fetch('https://api.xendit.co/v2/invoices', {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${btoa(XENDIT_API_KEY + ':')}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        external_id: externalId,
        amount: amount,
        description: description,
        invoice_duration: 86400, // 24 hours in seconds
        currency: 'IDR',
        reminder_time: 86000, // ~23.9 hours
        // customer not required for invoice - uses default
        // success_url and failure_url optional - Xendit handles defaults
      }),
    });

    const invoice = await response.json();

    if (!response.ok) {
      console.error('Xendit API error:', invoice);
      return Response.json(
        { error: invoice.message || 'Failed to create invoice' },
        { status: response.status, headers: corsHeaders }
      );
    }

    // Return invoice data to client
    return Response.json(
      {
        invoice_id: invoice.id,
        invoice_url: invoice.invoice_url,
        expiry_date: invoice.expiry_date,
        external_id: externalId,
      },
      { headers: corsHeaders }
    );

  } catch (error) {
    console.error('Error creating Xendit invoice:', error);
    return Response.json(
      { error: 'Internal server error' },
      { status: 500, headers: corsHeaders }
    );
  }
});
