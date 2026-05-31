// Edge Function: validate-redeem
// POST /functions/v1/validate-redeem
// Validates + consumes a redeem code for Jamaah activation

import { serve } from "https://deno.land/x/sift@0.6.0/mod.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://haramain.pro',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, content-type',
  'Access-Control-Max-Age': '86400',
};

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
  let payload: any;
  try {
    payload = JSON.parse(atob(token.split('.')[1]));
  } catch {
    return Response.json({ error: 'Invalid token' }, { status: 401, headers: corsHeaders });
  }

  const userId = payload.sub;

  try {
    const { code } = await req.json();

    if (!code || typeof code !== 'string') {
      return Response.json({ error: 'Code is required' }, { status: 400, headers: corsHeaders });
    }

    const normalCode = code.trim().toUpperCase();

    const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
    const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const headers = {
      'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
      'apikey': SUPABASE_SERVICE_KEY,
      'Content-Type': 'application/json',
    };

    // Look up the code
    const lookupRes = await fetch(
      `${SUPABASE_URL}/rest/v1/redeem_codes?code=eq.${normalCode}&select=*`,
      { headers }
    );
    const results = await lookupRes.json();

    if (!results || results.length === 0) {
      return Response.json({ valid: false, error: 'Invalid code' }, { status: 404, headers: corsHeaders });
    }

    const redeemCode = results[0];

    // Check status
    if (redeemCode.status !== 'available') {
      return Response.json({
        valid: false,
        error: `Code is ${redeemCode.status}`,
        status: redeemCode.status,
      }, { status: 400, headers: corsHeaders });
    }

    // Check expiry
    if (redeemCode.expires_at && new Date(redeemCode.expires_at) < new Date()) {
      // Mark as expired
      await fetch(`${SUPABASE_URL}/rest/v1/redeem_codes?id=eq.${redeemCode.id}`, {
        method: 'PATCH',
        headers,
        body: JSON.stringify({ status: 'expired' }),
      });
      return Response.json({ valid: false, error: 'Code has expired' }, { status: 400, headers: corsHeaders });
    }

    const agencyId = redeemCode.agency_id;

    // Get agency info + seat balance
    const agencyRes = await fetch(
      `${SUPABASE_URL}/rest/v1/agencies?id=eq.${agencyId}&select=id,name,seat_balance`,
      { headers }
    );
    const agencies = await agencyRes.json();
    if (!agencies || agencies.length === 0) {
      return Response.json({ valid: false, error: 'Agency not found' }, { status: 404, headers: corsHeaders });
    }
    const agency = agencies[0];

    // Get or create user profile
    let profileRes = await fetch(
      `${SUPABASE_URL}/rest/v1/profiles?id=eq.${userId}&select=id,agency_id,subscription_tier`,
      { headers }
    );
    let profiles = await profileRes.json();

    if (!profiles || profiles.length === 0) {
      // Auto-create profile
      const createRes = await fetch(`${SUPABASE_URL}/rest/v1/profiles`, {
        method: 'POST',
        headers,
        body: JSON.stringify({ id: userId, agency_id: agencyId }),
      });
      profiles = await createRes.json();
    } else {
      // Update agency_id if not set
      if (!profiles[0].agency_id) {
        await fetch(`${SUPABASE_URL}/rest/v1/profiles?id=eq.${userId}`, {
          method: 'PATCH',
          headers,
          body: JSON.stringify({ agency_id: agencyId }),
        });
      }
    }

    // Consume seat via RPC
    const consumeRes = await fetch(`${SUPABASE_URL}/rest/v1/rpc/consume_seat`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ p_agency_id: agencyId }),
    });

    if (!consumeRes.ok) {
      const errData = await consumeRes.text();
      console.error('consume_seat error:', errData);
      // If consume fails (no balance), still mark code as used but flag it
      return Response.json({
        valid: true,
        warning: 'Seat consumption failed - contact support',
        code_id: redeemCode.id,
        code_type: redeemCode.type,
      }, { headers: corsHeaders });
    }

    // Mark code as used
    await fetch(`${SUPABASE_URL}/rest/v1/redeem_codes?id=eq.${redeemCode.id}`, {
      method: 'PATCH',
      headers,
      body: JSON.stringify({
        status: 'used',
        used_at: new Date().toISOString(),
        used_by_user_id: userId,
      }),
    });

    // Update profile to active/premium
    await fetch(`${SUPABASE_URL}/rest/v1/profiles?id=eq.${userId}`, {
      method: 'PATCH',
      headers,
      body: JSON.stringify({ subscription_tier: 'active' }),
    });

    // Handle lifecycle based on type
    if (redeemCode.type === 'jama_redeem') {
      // Insert pilgrim_lifecycle if not exists
      await fetch(`${SUPABASE_URL}/rest/v1/pilgrim_lifecycle`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          user_id: userId,
          agency_id: agencyId,
          stage: 'active',
        }),
      }).catch(() => {}); // ignore if already exists
    }

    return Response.json({
      valid: true,
      code_id: redeemCode.id,
      code_type: redeemCode.type,
      agency: {
        id: agency.id,
        name: agency.name,
      },
      new_balance: agency.seat_balance ? agency.seat_balance - 1 : null,
    }, { headers: corsHeaders });

  } catch (error) {
    console.error('validate-redeem error:', error);
    return Response.json({ valid: false, error: 'Internal server error' }, { status: 500, headers: corsHeaders });
  }
});
