// Edge Function: user-unban
// POST /functions/v1/user-unban/{user_id}  — removes ban on a user (SuperAdmin only)
// Removes the banned_by, banned_at, and ban_reason fields from profiles.

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
  let jwtPayload: any;
  try {
    jwtPayload = JSON.parse(atob(token.split('.')[1]));
  } catch {
    return Response.json({ error: 'Invalid token' }, { status: 401, headers: corsHeaders });
  }

  const role = jwtPayload.role;
  const requesterId = jwtPayload.sub;

  // SuperAdmin only
  if (role !== 'super_admin') {
    return Response.json({ error: 'Forbidden — SuperAdmin only' }, { status: 403, headers: corsHeaders });
  }

  // Extract user_id from path: /functions/v1/user-unban/{user_id}
  const url = new URL(req.url);
  const pathParts = url.pathname.split('/').filter(Boolean);
  const userId = pathParts[pathParts.length - 1];

  if (!userId) {
    return Response.json({ error: 'user_id is required (path parameter)' }, { status: 400, headers: corsHeaders });
  }

  // Validate UUID format
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  if (!uuidRegex.test(userId)) {
    return Response.json({ error: 'Invalid user_id format' }, { status: 400, headers: corsHeaders });
  }

  // Cannot unban yourself
  if (userId === requesterId) {
    return Response.json({ error: 'Cannot unban yourself' }, { status: 400, headers: corsHeaders });
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
    // Verify target user exists and is actually banned
    const profileRes = await fetch(
      `${SUPABASE_URL}/rest/v1/profiles?id=eq.${userId}&select=id,name,email,role,banned_at,banned_by,ban_reason`,
      { headers }
    );
    const profiles: any[] = await profileRes.json();

    if (!profiles || profiles.length === 0) {
      return Response.json({ error: 'User not found' }, { status: 404, headers: corsHeaders });
    }

    const profile = profiles[0];

    if (!profile.banned_at) {
      return Response.json({ error: 'User is not banned' }, { status: 409, headers: corsHeaders });
    }

    // Remove ban fields: set banned_at, banned_by, ban_reason to null
    const unbanRes = await fetch(
      `${SUPABASE_URL}/rest/v1/profiles?id=eq.${userId}`,
      {
        method: 'PATCH',
        headers: { ...headers, 'Prefer': 'return=representation' },
        body: JSON.stringify({
          banned_at: null,
          banned_by: null,
          ban_reason: null,
          updated_at: new Date().toISOString(),
        }),
      }
    );
    const updated: any[] = await unbanRes.json();

    if (!unbanRes.ok || !updated || updated.length === 0) {
      return Response.json({ error: 'Failed to unban user' }, { status: 500, headers: corsHeaders });
    }

    return Response.json({
      success: true,
      message: 'User unbanned successfully',
      user: {
        id: updated[0].id,
        name: updated[0].name,
        email: updated[0].email,
        role: updated[0].role,
        banned_at: updated[0].banned_at,
        banned_by: updated[0].banned_by,
        ban_reason: updated[0].ban_reason,
      },
    }, { headers: corsHeaders });

  } catch (error) {
    console.error('user-unban error:', error);
    return Response.json({ error: 'Internal server error' }, { status: 500, headers: corsHeaders });
  }
});
