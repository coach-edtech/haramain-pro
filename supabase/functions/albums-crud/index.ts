// Edge Function: albums-crud
// GET  /functions/v1/albums-crud            → list albums (filter by travel_id)
// POST /functions/v1/albums-crud            → create album
// GET  /functions/v1/albums-crud?id=        → get album detail + items
// PATCH /functions/v1/albums-crud?id=        → update album
// DELETE /functions/v1/albums-crud?id=       → delete album
// POST /functions/v1/albums-crud/add-item    → add photo item to album
// DELETE /functions/v1/albums-crud/remove-item?id= → remove item

import { serve } from "https://deno.land/x/sift@0.6.0/mod.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://haramain.pro',
  'Access-Control-Allow-Methods': 'GET, POST, PATCH, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, content-type',
  'Access-Control-Max-Age': '86400',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
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
  const tokenAgencyId = jwtPayload.agency_id;

  if (!['travel_admin', 'super_admin', 'admin_haramain_pro', 'agent'].includes(role)) {
    return Response.json({ error: 'Forbidden' }, { status: 403, headers: corsHeaders });
  }

  const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
  const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const headers = {
    'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
    'apikey': SUPABASE_SERVICE_KEY,
    'Content-Type': 'application/json',
  };

  try {
    const url = new URL(req.url);
    const id = url.searchParams.get('id');
    const path = url.pathname.split('/').pop();

    // ---------- helpers ----------
    async function getAlbumWithItems(albumId: string) {
      const albumRes = await fetch(
        `${SUPABASE_URL}/rest/v1/albums?id=eq.${albumId}&select=*`,
        { headers }
      );
      const albums: any[] = await albumRes.json();
      if (!albums.length) return null;

      const itemsRes = await fetch(
        `${SUPABASE_URL}/rest/v1/album_items?album_id=eq.${albumId}&order=created_at.asc&select=*`,
        { headers }
      );
      const items: any[] = await itemsRes.json();

      return { ...albums[0], items };
    }

    // ---------- add-item ----------
    if (path === 'add-item' && req.method === 'POST') {
      const { album_id, storage_url, thumbnail_url, caption } = await req.json();

      if (!album_id || !storage_url) {
        return Response.json({ error: 'album_id and storage_url required' }, { status: 400, headers: corsHeaders });
      }

      // Verify album exists and user has access
      const albumRes = await fetch(`${SUPABASE_URL}/rest/v1/albums?id=eq.${album_id}&select=agency_id,travel_id`, { headers });
      const albums: any[] = await albumRes.json();
      if (!albums.length) {
        return Response.json({ error: 'Album not found' }, { status: 404, headers: corsHeaders });
      }

      // Check ownership
      if (role !== 'super_admin' && role !== 'admin_haramain_pro' && albums[0].agency_id !== tokenAgencyId) {
        return Response.json({ error: 'Forbidden' }, { status: 403, headers: corsHeaders });
      }

      const itemRes = await fetch(`${SUPABASE_URL}/rest/v1/album_items`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          album_id,
          storage_url,
          thumbnail_url: thumbnail_url || null,
          caption: caption || null,
        }),
      });
      const items: any[] = await itemRes.json();
      return Response.json({ success: true, item: items[0] }, { headers: corsHeaders });
    }

    // ---------- remove-item ----------
    if (path === 'remove-item' && req.method === 'DELETE') {
      const itemId = url.searchParams.get('id');
      if (!itemId) {
        return Response.json({ error: 'Item id required' }, { status: 400, headers: corsHeaders });
      }

      // Get item + album ownership
      const itemRes = await fetch(
        `${SUPABASE_URL}/rest/v1/album_items?id=eq.${itemId}&select=*,albums:album_id(agency_id)`,
        { headers }
      );
      const items: any[] = await itemRes.json();
      if (!items.length) {
        return Response.json({ error: 'Item not found' }, { status: 404, headers: corsHeaders });
      }

      if (role !== 'super_admin' && role !== 'admin_haramain_pro' && items[0].albums?.agency_id !== tokenAgencyId) {
        return Response.json({ error: 'Forbidden' }, { status: 403, headers: corsHeaders });
      }

      await fetch(`${SUPABASE_URL}/rest/v1/album_items?id=eq.${itemId}`, {
        method: 'DELETE',
        headers,
      });

      return Response.json({ success: true }, { headers: corsHeaders });
    }

    // ---------- GET list ----------
    if (req.method === 'GET' && !id) {
      const travelId = url.searchParams.get('travel_id');
      const search = url.searchParams.get('search') || '';
      const limit = Math.min(parseInt(url.searchParams.get('limit') || '50'), 100);

      let query = `${SUPABASE_URL}/rest/v1/albums?order=created_at.desc&limit=${limit}&select=*`;

      // Non-super/haramain-pro must filter by agency
      if (role !== 'super_admin' && role !== 'admin_haramain_pro') {
        query += `&agency_id=eq.${tokenAgencyId}`;
      }

      if (travelId) query += `&travel_id=eq.${travelId}`;
      if (search) query += `&name=ilike.*${search}*`;

      const res = await fetch(query, { headers });
      const albums: any[] = await res.json();

      return Response.json({ albums, count: albums.length }, { headers: corsHeaders });
    }

    // ---------- GET detail ----------
    if (req.method === 'GET' && id) {
      const album = await getAlbumWithItems(id);
      if (!album) {
        return Response.json({ error: 'Album not found' }, { status: 404, headers: corsHeaders });
      }

      if (role !== 'super_admin' && role !== 'admin_haramain_pro' && album.agency_id !== tokenAgencyId) {
        return Response.json({ error: 'Forbidden' }, { status: 403, headers: corsHeaders });
      }

      return Response.json({ album }, { headers: corsHeaders });
    }

    // ---------- POST create ----------
    if (req.method === 'POST') {
      const { name, travel_id, description } = await req.json();

      if (!name) {
        return Response.json({ error: 'name required' }, { status: 400, headers: corsHeaders });
      }

      const agencyId = role === 'super_admin' || role === 'admin_haramain_pro'
        ? (url.searchParams.get('agency_id') || tokenAgencyId)
        : tokenAgencyId;

      const albumRes = await fetch(`${SUPABASE_URL}/rest/v1/albums`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          name,
          agency_id: agencyId,
          travel_id: travel_id || null,
          description: description || null,
        }),
      });
      const albums: any[] = await albumRes.json();

      return Response.json({ success: true, album: albums[0] }, { headers: corsHeaders });
    }

    // ---------- PATCH update ----------
    if (req.method === 'PATCH' && id) {
      const existing = await getAlbumWithItems(id);
      if (!existing) {
        return Response.json({ error: 'Album not found' }, { status: 404, headers: corsHeaders });
      }

      if (role !== 'super_admin' && role !== 'admin_haramain_pro' && existing.agency_id !== tokenAgencyId) {
        return Response.json({ error: 'Forbidden' }, { status: 403, headers: corsHeaders });
      }

      const { name, description, travel_id } = await req.json();
      const updatePayload: any = {};
      if (name !== undefined) updatePayload.name = name;
      if (description !== undefined) updatePayload.description = description;
      if (travel_id !== undefined) updatePayload.travel_id = travel_id;

      if (Object.keys(updatePayload).length === 0) {
        return Response.json({ error: 'No valid fields to update' }, { status: 400, headers: corsHeaders });
      }

      await fetch(`${SUPABASE_URL}/rest/v1/albums?id=eq.${id}`, {
        method: 'PATCH',
        headers,
        body: JSON.stringify(updatePayload),
      });

      return Response.json({ success: true }, { headers: corsHeaders });
    }

    // ---------- DELETE ----------
    if (req.method === 'DELETE' && id) {
      const albumRes = await fetch(`${SUPABASE_URL}/rest/v1/albums?id=eq.${id}&select=agency_id`, { headers });
      const albums: any[] = await albumRes.json();
      if (!albums.length) {
        return Response.json({ error: 'Album not found' }, { status: 404, headers: corsHeaders });
      }

      if (role !== 'super_admin' && role !== 'admin_haramain_pro' && albums[0].agency_id !== tokenAgencyId) {
        return Response.json({ error: 'Forbidden' }, { status: 403, headers: corsHeaders });
      }

      // Delete items first (FK cascade should handle this, but be explicit)
      await fetch(`${SUPABASE_URL}/rest/v1/album_items?album_id=eq.${id}`, {
        method: 'DELETE',
        headers,
      });
      await fetch(`${SUPABASE_URL}/rest/v1/albums?id=eq.${id}`, {
        method: 'DELETE',
        headers,
      });

      return Response.json({ success: true }, { headers: corsHeaders });
    }

    return Response.json({ error: 'Method not allowed' }, { status: 405, headers: corsHeaders });

  } catch (error) {
    console.error('albums-crud error:', error);
    return Response.json({ error: 'Internal server error' }, { status: 500, headers: corsHeaders });
  }
});
