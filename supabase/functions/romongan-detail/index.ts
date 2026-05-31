// Edge Function: romongan-detail
// GET /functions/v1/romongan-detail?id=UUID
// Returns romongan + emi_plans + enrolled profiles
// Auth: travel_admin, super_admin, admin_haramain_pro, muthawif (own romongan only)

import { serve } from "https://deno.land/x/sift@0.6.0/mod.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://haramain.pro',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, content-type',
  'Access-Control-Max-Age': '86400',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  if (req.method !== 'GET') {
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

  const role = payload.role;
  const userId = payload.sub;
  const tokenAgencyId = payload.agency_id;

  const allowedRoles = ['super_admin', 'admin_haramain_pro', 'travel_admin', 'muthawif'];
  if (!allowedRoles.includes(role)) {
    return Response.json({ error: 'Forbidden' }, { status: 403, headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const romonganId = url.searchParams.get('id');

    if (!romonganId) {
      return Response.json({ error: 'Romongan id (UUID) required' }, { status: 400, headers: corsHeaders });
    }

    const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
    const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const headers = {
      'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
      'apikey': SUPABASE_SERVICE_KEY,
      'Content-Type': 'application/json',
    };

    // Fetch romongan
    const romonganRes = await fetch(
      `${SUPABASE_URL}/rest/v1/rombongans?id=eq.${romonganId}&select=*`,
      { headers }
    );
    const rombangans: any[] = await romonganRes.json();

    if (!rombangans || rombangans.length === 0) {
      return Response.json({ error: 'Romongan not found' }, { status: 404, headers: corsHeaders });
    }

    const romongan = rombangans[0];

    // Access control: muthawif can only view their own romongan
    if (role === 'muthawif' && romongan.muthawif_id !== userId) {
      return Response.json({ error: 'Forbidden' }, { status: 403, headers: corsHeaders });
    }

    // Access control: non-super-admin must belong to same agency
    if (!['super_admin', 'admin_haramain_pro'].includes(role) && romongan.agency_id !== tokenAgencyId) {
      return Response.json({ error: 'Forbidden' }, { status: 403, headers: corsHeaders });
    }

    // Parallel fetches: enrolled profiles, emi_plans
    const [
      enrolledProfilesRes,
      emiPlansRes,
    ] = await Promise.all([
      // Profiles enrolled in this romongan (via profiles.rombongan_id)
      fetch(
        `${SUPABASE_URL}/rest/v1/profiles?rombongan_id=eq.${romonganId}&select=id,name,email,role,subscription_tier,created_at`,
        { headers }
      ),
      // EMI plans for this romongan (if emi_plans table exists)
      fetch(
        `${SUPABASE_URL}/rest/v1/emi_plans?rombongan_id=eq.${romonganId}&select=*`,
        { headers }
      ),
    ]);

    const enrolledProfiles: any[] = await enrolledProfilesRes.json();
    const emiPlansData: any[] = await emiPlansRes.json();
    // Gracefully handle 404 from emi_plans table not existing
    const emiPlans = Array.isArray(emiPlansData) ? emiPlansData : [];

    // Build enrolled profiles summary
    const profileStats = {
      total: enrolledProfiles.length,
      by_role: {
        pilgrim: enrolledProfiles.filter(p => p.role === 'pilgrim').length,
        jamaah: enrolledProfiles.filter(p => p.role === 'jamaah').length,
        muthawif: enrolledProfiles.filter(p => p.role === 'muthawif').length,
      },
      by_tier: {
        active: enrolledProfiles.filter(p => p.subscription_tier === 'active').length,
        trial: enrolledProfiles.filter(p => p.subscription_tier === 'trial').length,
        expired: enrolledProfiles.filter(p => p.subscription_tier === 'expired').length,
      },
    };

    return Response.json({
      romongan: {
        id: romongan.id,
        agency_id: romongan.agency_id,
        name: romongan.name,
        departure_date: romongan.departure_date,
        return_date: romongan.return_date,
        muthawif_id: romongan.muthawif_id,
        status: romongan.status,
        invite_code: romongan.invite_code,
        created_at: romongan.created_at,
      },
      profile_stats: profileStats,
      enrolled_profiles: enrolledProfiles.map(p => ({
        id: p.id,
        name: p.name,
        email: p.email,
        role: p.role,
        subscription_tier: p.subscription_tier,
        created_at: p.created_at,
      })),
      emi_plans: emiPlans,
    }, { headers: corsHeaders });

  } catch (error) {
    console.error('romongan-detail error:', error);
    return Response.json({ error: 'Internal server error' }, { status: 500, headers: corsHeaders });
  }
});
