import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://haramain.pro',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function validateUUID(id: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id)
}

interface PanicResponsePayload {
  alert_id: string
  responder_id: string
  action: string // 'stay_jemput' | 'saya_di_sini' | 'telepon'
}

const VALID_ACTIONS = ['stay_jemput', 'saya_di_sini', 'telepon']

async function sendFCMNotification(token: string, payload: {
  title: string
  body: string
  data: Record<string, string>
}) {
  const FCM_SERVER_KEY = Deno.env.get('FCM_SERVER_KEY') || ''
  
  try {
    const response = await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `key=${FCM_SERVER_KEY}`,
      },
      body: JSON.stringify({
        to: token,
        notification: {
          title: payload.title,
          body: payload.body,
          sound: 'default',
        },
        data: payload.data,
        android: {
          priority: 'high',
          notification: {
            channel_id: 'panic_responses',
            sound: 'default',
          },
        },
        apns: {
          headers: {
            'apns-priority': '5',
          },
          payload: {
            aps: {
              alert: {
                title: payload.title,
                body: payload.body,
              },
              sound: 'default',
            },
          },
        },
      }),
    })

    if (!response.ok) {
      throw new Error(`FCM error: ${response.status}`)
    }

    return await response.json()
  } catch (error) {
    console.error('FCM send error:', error)
    throw error
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader ?? '' } } }
    )

    // Verify user is authenticated
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser()
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const payload: PanicResponsePayload = await req.json()

    // Validate required fields
    if (!payload.alert_id || !payload.responder_id || !payload.action) {
      return new Response(JSON.stringify({ error: 'Missing required fields: alert_id, responder_id, action' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Validate UUIDs
    if (!validateUUID(payload.alert_id)) {
      return new Response(JSON.stringify({ error: 'Invalid alert_id format' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (!validateUUID(payload.responder_id)) {
      return new Response(JSON.stringify({ error: 'Invalid responder_id format' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Validate action
    if (!VALID_ACTIONS.includes(payload.action)) {
      return new Response(JSON.stringify({ error: `Invalid action. Must be one of: ${VALID_ACTIONS.join(', ')}` }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Verify responder is Muthawif or Admin
    const { data: responderProfile, error: profileError } = await supabaseClient
      .from('profiles')
      .select('id, role, name')
      .eq('id', payload.responder_id)
      .single()

    if (profileError || !responderProfile) {
      return new Response(JSON.stringify({ error: 'Responder profile not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const responderRole = responderProfile.role
    if (responderRole !== 'muthawif' && responderRole !== 'admin') {
      return new Response(JSON.stringify({ error: 'Only Muthawif or Admin can respond to panic alerts' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Fetch the panic alert
    const { data: panicAlert, error: alertError } = await supabaseClient
      .from('panic_alerts')
      .select('*')
      .eq('id', payload.alert_id)
      .single()

    if (alertError || !panicAlert) {
      return new Response(JSON.stringify({ error: 'Panic alert not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Check if alert is still pending
    if (panicAlert.status !== 'pending') {
      return new Response(JSON.stringify({ 
        error: 'Alert has already been responded to or resolved',
        current_status: panicAlert.status 
      }), {
        status: 409,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const respondedAt = new Date().toISOString()

    // Update panic_alerts with response
    const { error: updateError } = await supabaseClient
      .from('panic_alerts')
      .update({
        responded_by: payload.responder_id,
        responded_at: respondedAt,
        status: 'responded',
        response_type: payload.action,
      })
      .eq('id', payload.alert_id)

    if (updateError) {
      console.error('Failed to update panic alert:', updateError)
      return new Response(JSON.stringify({ error: 'Failed to update panic alert' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Send FCM to Jamaah
    let fcmNotified = false
    if (panicAlert.jamaah_id) {
      // Get Jamaah FCM token
      const { data: fcmToken } = await supabaseClient
        .from('fcm_tokens')
        .select('token')
        .eq('user_id', panicAlert.jamaah_id)
        .single()

      if (fcmToken?.token) {
        const actionMessages: Record<string, { title: string; body: string }> = {
          stay_jemput: {
            title: '✅ Muthawif sedang dalam perjalanan',
            body: `${responderProfile.name || 'Muthawif'} akan menjemput Anda. Stay di tempat!`,
          },
          saya_di_sini: {
            title: '📍 Muthawif menemukan Anda',
            body: `${responderProfile.name || 'Muthawif'} sudah mengetahui lokasi Anda.`,
          },
          telepon: {
            title: '📞 Muthawif akan menelepon',
            body: `${responderProfile.name || 'Muthawif'} akan menghubungi Anda.`,
          },
        }

        const msg = actionMessages[payload.action]
        try {
          await sendFCMNotification(fcmToken.token, {
            title: msg.title,
            body: msg.body,
            data: {
              type: 'panic_responded',
              alert_id: payload.alert_id,
              responder_id: payload.responder_id,
              responder_name: responderProfile.name || '',
              action: payload.action,
              responded_at: respondedAt,
            },
          })
          fcmNotified = true
        } catch (fcmError) {
          console.error('Failed to send FCM to Jamaah:', fcmError)
          // Don't fail the whole response if FCM fails
        }
      }
    }

    return new Response(JSON.stringify({
      status: 'success',
      alert_id: payload.alert_id,
      responded_by: payload.responder_id,
      responded_at: respondedAt,
      action: payload.action,
      fcm_notified: fcmNotified,
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  } catch (error) {
    console.error('Panic response function error:', error)
    return new Response(JSON.stringify({ error: 'Internal error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
