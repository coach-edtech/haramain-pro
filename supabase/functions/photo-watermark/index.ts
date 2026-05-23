// Edge Function: photo-watermark
// Adds agency watermark to jejak ibadah photos

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing authorization' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    const { data: { user }, error: authError } = await supabaseClient.auth.getUser()
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Get user's profile to find their agency
    const { data: profile } = await supabaseClient
      .from('profiles')
      .select('rombongan_id, role')
      .eq('id', user.id)
      .single()

    if (!profile?.rombongan_id) {
      return new Response(JSON.stringify({ error: 'User not in a group' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Get the rombongan to find agency
    const { data: rombongan } = await supabaseClient
      .from('rombangans')
      .select('agency_id')
      .eq('id', profile.rombongan_id)
      .single()

    if (!rombongan?.agency_id) {
      return new Response(JSON.stringify({ error: 'No agency found' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Get form data
    const formData = await req.formData()
    const file = formData.get('file') as File | null
    
    if (!file) {
      return new Response(JSON.stringify({ error: 'No file provided' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Read file as array buffer
    const arrayBuffer = await file.arrayBuffer()
    const uint8Array = new Uint8Array(arrayBuffer)

    // TODO: In production, use a library like sharp or jimp to:
    // 1. Download agency logo from agency_logos bucket
    // 2. Composite logo onto the photo (bottom-right corner)
    // 3. Return watermarked image
    // For now, return the original as this requires image processing library

    // Upload original (watermarking would be done in production)
    const fileName = `${user.id}/${Date.now()}.webp`
    const { data: uploadData, error: uploadError } = await supabaseClient
      .storage
      .from('jejak_ibadah_media')
      .upload(fileName, uint8Array, {
        contentType: 'image/webp',
        upsert: false,
      })

    if (uploadError) {
      console.error('Upload error:', uploadError)
      return new Response(JSON.stringify({ error: 'Upload failed' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Get public URL
    const { data: urlData } = supabaseClient
      .storage
      .from('jejak_ibadah_media')
      .getPublicUrl(fileName)

    return new Response(JSON.stringify({
      status: 'success',
      url: urlData.publicUrl,
      fileName,
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  } catch (error) {
    console.error('Watermark function error:', error)
    return new Response(JSON.stringify({ error: 'Internal error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
