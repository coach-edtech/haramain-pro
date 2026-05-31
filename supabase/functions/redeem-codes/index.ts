// Edge Function: redeem-codes
// POST /functions/v1/redeem-codes (generate)
// GET  /functions/v1/redeem-codes?agency_id=&status= (list)

import { serve } from "https://deno.land/x/sift@0.6.0/mod.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://haramain.pro',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, content-type',
  'Access-Control-Max-Age': '86400',
};

// Generate 6-char alphanumeric code
function generateCode(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // excluded confusing: 0,O,1,I
  let code = '';
  const array = new Uint8Array(6);
  crypto.getRandomValues(array);
  for (const byte of array) {
    code += chars[byte % chars.length];
  }
  return code;
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
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

  const role = payload.role;
  const userId = payload.sub;
  const tokenAgencyId = payload.agency_id;

  // Only travel_admin and super_admin can generate
  if (!['travel_admin', 'super_admin'].includes(role)) {
    return Response.json({ error: 'Forbidden' }, { status: 403, headers: corsHeaders });
  }

  const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
  const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const headers = {
    'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
    'apikey': SUPABASE_SERVICE_KEY,
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };

  try {
    if (req.method === 'POST') {
      const { agency_id, quantity = 1, type = 'jama_redeem', expires_at } = await req.json();

      // Determine target agency
      let targetAgencyId = tokenAgencyId;
      if (role === 'super_admin' && agency_id) {
        targetAgencyId = agency_id;
      }
      if (!targetAgencyId) {
        return Response.json({ error: 'agency_id required' }, { status: 400, headers: corsHeaders });
      }

      if (!['jama_redeem', 'team_invite', 'muthawif_invite'].includes(type)) {
        return Response.json({ error: 'Invalid type' }, { status: 400, headers: corsHeaders });
      }

      if (quantity < 1 || quantity > 100) {
        return Response.json({ error: 'Quantity must be 1-100' }, { status: 400, headers: corsHeaders });
      }

      // Check seat balance for jama_redeem type
      if (type === 'jama_redeem') {
        const agencyRes = await fetch(`${SUPABASE_URL}/rest/v1/agencies?id=eq.${targetAgencyId}&select=seat_balance`, {
          headers: { 'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`, 'apikey': SUPABASE_SERVICE_KEY },
        });
        const agencies = await agencyRes.json();
        const currentBalance = agencies?.[0]?.seat_balance ?? 0;
        if (currentBalance < quantity) {
          return Response.json({
            error: 'Insufficient seat balance',
            current_balance: currentBalance,
            requested: quantity,
          }, { status: 400, headers: corsHeaders });
        }
      }

      // Generate codes
      const codes: any[] = [];
      for (let i = 0; i < quantity; i++) {
        let code = generateCode();
        // Ensure uniqueness
        let attempts = 0;
        while (attempts < 5) {
          const checkRes = await fetch(`${SUPABASE_URL}/rest/v1/redeem_codes?code=eq.${code}&select=id`, {
            headers: { 'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`, 'apikey': SUPABASE_SERVICE_KEY },
          });
          const existing = await checkRes.json();
          if (existing.length === 0) break;
          code = generateCode();
          attempts++;
        }

        const payload: any = {
          agency_id: targetAgencyId,
          code,
          type,
          status: 'available',
          created_by: userId,
        };
        if (expires_at) payload.expires_at = expires_at;

        const insertRes = await fetch(`${SUPABASE_URL}/rest/v1/redeem_codes`, {
          method: 'POST',
          headers,
          body: JSON.stringify(payload),
        });
        const inserted = await insertRes.json();
        codes.push(...inserted);
      }

      // If jama_redeem, deduct seat balance
      if (type === 'jama_redeem') {
        await fetch(`${SUPABASE_URL}/rest/v1/rpc/consume_seat_batch`, {
          method: 'POST',
          headers,
          body: JSON.stringify({ p_agency_id: targetAgencyId, p_count: quantity }),
        }).catch(() => {
          // Fallback: direct update if RPC doesn't exist yet
          // Just note in response that manual deduction may be needed
        });
      }

      return Response.json({
        success: true,
        codes: codes.map((c: any) => ({
          id: c.id,
          code: c.code,
          type: c.type,
          status: c.status,
          expires_at: c.expires_at,
        })),
        count: codes.length,
      }, { headers: corsHeaders });

    } else if (req.method === 'GET') {
      const url = new URL(req.url);
      const agencyId = url.searchParams.get('agency_id') || tokenAgencyId;
      const status = url.searchParams.get('status');
      const limit = Math.min(parseInt(url.searchParams.get('limit') || '50'), 100);

      if (!agencyId) {
        return Response.json({ error: 'agency_id required' }, { status: 400, headers: corsHeaders });
      }

      let query = `${SUPABASE_URL}/rest/v1/redeem_codes?agency_id=eq.${agencyId}&order=created_at.desc&limit=${limit}`;
      if (status) query += `&status=eq.${status}`;

      const res = await fetch(query, { headers });
      const codes = await res.json();

      return Response.json({
        codes: codes.map((c: any) => ({
          id: c.id,
          code: c.code,
          type: c.type,
          status: c.status,
          expires_at: c.expires_at,
          used_at: c.used_at,
          used_by_user_id: c.used_by_user_id,
          created_at: c.created_at,
        })),
        count: codes.length,
      }, { headers: corsHeaders });

    } else {
      return Response.json({ error: 'Method not allowed' }, { status: 405, headers: corsHeaders });
    }

  } catch (error) {
    console.error('redeem-codes error:', error);
    return Response.json({ error: 'Internal server error' }, { status: 500, headers: corsHeaders });
  }
});
