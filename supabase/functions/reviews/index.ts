// Edge Function: reviews
// GET /functions/v1/reviews?rombongan_id=<uuid>  — list reviews by romongan
// POST /functions/v1/reviews                     — submit a review
// Auth: GET → travel_admin / super_admin / admin_haramain_pro (own agency)
//       POST → authenticated user with matching profile.rombongan_id

import { serve } from "https://deno.land/x/sift@0.6.0/mod.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://haramain.pro',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, content-type',
  'Access-Control-Max-Age': '86400',
};

interface Review {
  id: string;
  user_id: string;
  agency_id: string;
  rombongan_id: string;
  rating: number;
  review_text: string | null;
  is_published: boolean;
  admin_response: string | null;
  created_at: string;
  // joined
  user_name?: string;
  user_email?: string;
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

  const userId = payload.sub;
  const role = payload.role;
  const tokenAgencyId = payload.agency_id;

  const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
  const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const supabaseHeaders = {
    'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
    'apikey': SUPABASE_SERVICE_KEY,
    'Content-Type': 'application/json',
  };

  // ─── GET: List reviews by romongan_id ─────────────────────────────────────────
  if (req.method === 'GET') {
    const allowedRoles = ['travel_admin', 'super_admin', 'admin_haramain_pro'];
    if (!allowedRoles.includes(role)) {
      return Response.json({ error: 'Forbidden' }, { status: 403, headers: corsHeaders });
    }

    const url = new URL(req.url);
    const romonganId = url.searchParams.get('rombongan_id');

    if (!romonganId) {
      return Response.json({ error: 'rombongan_id query param is required' }, { status: 400, headers: corsHeaders });
    }

    // Verify romongan belongs to agency
    if (!['super_admin', 'admin_haramain_pro'].includes(role)) {
      const romonganRes = await fetch(
        `${SUPABASE_URL}/rest/v1/rombongans?id=eq.${romonganId}&agency_id=eq.${tokenAgencyId}&select=id`,
        { headers: supabaseHeaders }
      );
      const rombongans: any[] = await romonganRes.json();
      if (!rombongans || rombongans.length === 0) {
        return Response.json({ error: 'Romongan not found or not accessible' }, { status: 404, headers: corsHeaders });
      }
    }

    // Fetch reviews for romongan
    const reviewsRes = await fetch(
      `${SUPABASE_URL}/rest/v1/alumni_reviews?rombongan_id=eq.${romonganId}&order=created_at.desc`,
      { headers: supabaseHeaders }
    );
    const reviews: Review[] = await reviewsRes.json();

    // Fetch user names for the reviewers
    const userIds = [...new Set(reviews.map(r => r.user_id))];
    let userMap: Record<string, { name: string; email: string }> = {};

    if (userIds.length > 0) {
      const usersRes = await fetch(
        `${SUPABASE_URL}/rest/v1/users?id=in.(${userIds.join(',')})&select=id,name,email`,
        { headers: supabaseHeaders }
      );
      const users: any[] = await usersRes.json();
      userMap = Object.fromEntries(users.map(u => [u.id, { name: u.name || 'Unknown', email: u.email || '' }]));
    }

    const enrichedReviews = reviews.map(r => ({
      ...r,
      user_name: userMap[r.user_id]?.name || 'Unknown',
      user_email: userMap[r.user_id]?.email || '',
    }));

    // Compute average rating
    const publishedReviews = enrichedReviews.filter(r => r.is_published);
    const average_rating = publishedReviews.length > 0
      ? publishedReviews.reduce((sum, r) => sum + r.rating, 0) / publishedReviews.length
      : null;

    return Response.json({
      reviews: enrichedReviews,
      average_rating: average_rating ? Math.round(average_rating * 10) / 10 : null,
      total_count: enrichedReviews.length,
      published_count: publishedReviews.length,
    }, { headers: corsHeaders });
  }

  // ─── POST: Submit a review ────────────────────────────────────────────────────
  if (req.method === 'POST') {
    let body: any;
    try {
      body = await req.json();
    } catch {
      return Response.json({ error: 'Invalid JSON body' }, { status: 400, headers: corsHeaders });
    }

    const { rombongan_id, rating, review_text } = body;

    // Validation
    if (!rombongan_id || !rating) {
      return Response.json({ error: 'rombongan_id and rating are required' }, { status: 400, headers: corsHeaders });
    }

    if (typeof rating !== 'number' || rating < 1 || rating > 5) {
      return Response.json({ error: 'rating must be a number between 1 and 5' }, { status: 400, headers: corsHeaders });
    }

    if (!Number.isInteger(rating)) {
      return Response.json({ error: 'rating must be an integer between 1 and 5' }, { status: 400, headers: corsHeaders });
    }

    if (review_text && review_text.length > 2000) {
      return Response.json({ error: 'review_text must be 2000 characters or less' }, { status: 400, headers: corsHeaders });
    }

    // Verify user's profile has matching romongan_id
    const profileRes = await fetch(
      `${SUPABASE_URL}/rest/v1/profiles?id=eq.${userId}&rombongan_id=eq.${rombongan_id}&select=id,rombongan_id,agency_id,name,email`,
      { headers: supabaseHeaders }
    );
    const profiles: any[] = await profileRes.json();

    if (!profiles || profiles.length === 0) {
      return Response.json({ error: 'You are not enrolled in this romongan' }, { status: 403, headers: corsHeaders });
    }

    const profile = profiles[0];

    // Check if user already submitted a review for this romongan
    const existingRes = await fetch(
      `${SUPABASE_URL}/rest/v1/alumni_reviews?user_id=eq.${userId}&rombongan_id=eq.${rombongan_id}&select=id`,
      { headers: supabaseHeaders }
    );
    const existing: any[] = await existingRes.json();
    if (existing && existing.length > 0) {
      return Response.json({ error: 'You have already submitted a review for this romongan' }, { status: 409, headers: corsHeaders });
    }

    // Insert review
    const insertPayload = {
      user_id: userId,
      agency_id: profile.agency_id,
      rombongan_id,
      rating,
      review_text: review_text || null,
      is_published: true, // auto-publish; travel_admin can unpublish via direct DB access
    };

    const insertRes = await fetch(`${SUPABASE_URL}/rest/v1/alumni_reviews`, {
      method: 'POST',
      headers: supabaseHeaders,
      body: JSON.stringify(insertPayload),
    });
    const result: any[] = await insertRes.json();

    if (!result || result.length === 0 || !result[0]?.id) {
      return Response.json({ error: 'Failed to insert review' }, { status: 500, headers: corsHeaders });
    }

    const created: Review = result[0];

    return Response.json({
      id: created.id,
      user_id: created.user_id,
      rombongan_id: created.rombongan_id,
      rating: created.rating,
      review_text: created.review_text,
      is_published: created.is_published,
      created_at: created.created_at,
      user_name: profile.name || 'Unknown',
      user_email: profile.email || '',
    }, { status: 201, headers: corsHeaders });
  }

  return Response.json({ error: 'Method not allowed' }, { status: 405, headers: corsHeaders });
});
