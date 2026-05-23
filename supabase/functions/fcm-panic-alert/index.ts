import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://haramain.pro',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, X-Webhook-Secret',
}

function validateLatitude(lat: number): boolean {
  return lat >= -90 && lat <= 90;
}

function validateLongitude(lng: number): boolean {
  return lng >= -180 && lng <= 180;
}

function validateUUID(id: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id);
}

interface PanicAlertPayload {
  JamaahId?: string
  rombonganId: string
  latitude: number
  longitude: number
  accuracy?: number
  altitude?: number
  message?: string
  timestamp?: string
}

const FCM_SERVER_KEY = Deno.env.get('FCM_SERVER_KEY') || ''
const WEBHOOK_SECRET = Deno.env.get('PANIC_WEBHOOK_SECRET') || ''

async function sendFCMNotification(token: string, payload: {
  title: string
  body: string
  data: Record<string, string>
}) {
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
          sound: 'critical',
          'interruption-level': 'critical',
        },
        data: payload.data,
        android: {
          priority: 'high',
          notification: {
            channel_id: 'panic_alerts',
            sound: 'critical',
            default_vibrate_timings: true,
          },
        },
        apns: {
          headers: {
            'apns-priority': '10',
            'apns-push-type': 'critical',
          },
          payload: {
            aps: {
              alert: {
                title: payload.title,
                body: payload.body,
              },
              sound: 'critical',
              'interruption-level': 'critical',
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

async function sendToTopic(topic: string, payload: {
  title: string
  body: string
  data: Record<string, string>
}) {
  try {
    const response = await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `key=${FCM_SERVER_KEY}`,
      },
      body: JSON.stringify({
        to: `/topics/${topic}`,
        notification: {
          title: payload.title,
          body: payload.body,
          sound: 'critical',
          'interruption-level': 'critical',
        },
        data: payload.data,
        android: {
          priority: 'high',
          notification: {
            channel_id: 'panic_alerts',
            sound: 'critical',
            default_vibrate_timings: true,
          },
        },
      }),
    })
    
    if (!response.ok) {
      throw new Error(`FCM topic error: ${response.status}`)
    }
    
    return await response.json()
  } catch (error) {
    console.error('FCM topic send error:', error)
    throw error
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // Webhook secret validation
  const providedSecret = req.headers.get('X-Webhook-Secret')
  if (!WEBHOOK_SECRET || providedSecret !== WEBHOOK_SECRET) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader ?? '' } } }
    )

    let userId = ''
    
    if (authHeader) {
      const { data: { user }, error: authError } = await supabaseClient.auth.getUser()
      if (!authError && user) {
        userId = user.id
      }
    }

    const payload: PanicAlertPayload = await req.json()

    if (!payload.latitude || !payload.longitude) {
      return new Response(JSON.stringify({ error: 'Missing coordinates' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (!validateLatitude(payload.latitude)) {
      return new Response(JSON.stringify({ error: 'Invalid latitude' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (!validateLongitude(payload.longitude)) {
      return new Response(JSON.stringify({ error: 'Invalid longitude' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (payload.rombonganId && !validateUUID(payload.rombonganId)) {
      return new Response(JSON.stringify({ error: 'Invalid UUID' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const rateLimitWindow = 5 * 60 * 1000
    const fiveMinutesAgo = new Date(Date.now() - rateLimitWindow).toISOString()
    
    if (userId) {
      const { data: recentAlerts } = await supabaseClient
        .from('panic_alerts')
        .select('id')
        .eq('jamaah_id', userId)
        .gte('created_at', fiveMinutesAgo)
        .limit(1)

      if (recentAlerts && recentAlerts.length > 0) {
        return new Response(JSON.stringify({ error: 'Rate limit exceeded. Please wait 5 minutes.' }), {
          status: 429,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }
    }

    let JamaaahName = 'Jamaah'
    if (userId) {
      const { data: profile } = await supabaseClient
        .from('profiles')
        .select('name')
        .eq('id', userId)
        .single()
      
      if (profile?.name) {
        JamaaahName = profile.name
      }
    }

    const { data: panicAlert, error: insertError } = await supabaseClient
      .from('panic_alerts')
      .insert({
        jamaah_id: userId || null,
        grup_id: payload.rombonganId || null,
        latitude: payload.latitude,
        longitude: payload.longitude,
        accuracy: payload.accuracy,
        altitude: payload.altitude,
        message: payload.message,
        created_at: payload.timestamp || new Date().toISOString(),
        status: 'pending'
      })
      .select()
      .single()

    if (insertError) {
      console.error('Panic alert insert error:', insertError)
    }

    const alertData = {
      type: 'panic_alert',
      alert_id: panicAlert?.id || crypto.randomUUID(),
      jamaah_id: userId || '',
      jamaah_name: JamaaahName,
      latitude: payload.latitude.toString(),
      longitude: payload.longitude.toString(),
      accuracy: (payload.accuracy || 0).toString(),
      altitude: (payload.altitude || 0).toString(),
      message: payload.message || '',
      timestamp: payload.timestamp || new Date().toISOString(),
    }

    let notifiedCount = 0
    let fcmSuccessCount = 0
    let fcmFailureCount = 0
    let topicNotified = false

    const timeoutPromise = new Promise<'timeout'>((resolve) => 
      setTimeout(() => resolve('timeout'), 8000)
    )

    const sendNotifications = async () => {
      const promises: Promise<void>[] = []

      if (payload.rombonganId) {
        promises.push(
          sendToTopic(`travel_${payload.rombonganId}`, {
            title: '🚨 Panic Alert!',
            body: `${JamaaahName} butuh bantuan di lokasi ini`,
            data: alertData,
          }).then(() => {
            notifiedCount++
            fcmSuccessCount++
            topicNotified = true
          }).catch(() => {
            fcmFailureCount++
          })
        )
      }

      promises.push(
        sendToTopic('support', {
          title: '🚨 Panic Alert!',
          body: `${JamaaahName} butuh bantuan - check location`,
          data: alertData,
        }).then(() => {
          notifiedCount++
          fcmSuccessCount++
        }).catch(() => {
          fcmFailureCount++
        })
      )

      await Promise.allSettled(promises)
    }

    await Promise.race([
      sendNotifications(),
      timeoutPromise
    ])

    let fallbackTriggered = false
    
    if (fcmFailureCount > 0 && userId) {
      console.log('Some FCM failed, triggering Twilio fallback')
      fallbackTriggered = true
      
      try {
        await supabaseClient.functions.invoke('twilio-voice-fallback', {
          body: {
            jamaah_id: userId,
            grup_id: payload.rombonganId,
            latitude: payload.latitude,
            longitude: payload.longitude,
            alert_id: panicAlert?.id,
            timestamp: new Date().toISOString(),
            nama_jamaah: JamaaahName,
          }
        })
      } catch (twilioError) {
        console.error('Twilio fallback error:', twilioError)
      }
    }

    return new Response(JSON.stringify({ 
      status: 'success',
      messageId: panicAlert?.id || alertData.alert_id,
      notifiedCount,
      fcmSuccessCount,
      fcmFailureCount,
      fallbackTriggered,
      alert: panicAlert || {
        id: alertData.alert_id,
        latitude: payload.latitude,
        longitude: payload.longitude,
        status: 'pending'
      }
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  } catch (error) {
    console.error('Panic alert function error:', error)
    return new Response(JSON.stringify({ error: 'Internal error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
