// Edge Function: broadcast-notification
// POST /functions/v1/broadcast-notification
// SuperAdmin only: sends push notification to all / android / ios users
// Payload: { title: string, body: string, target: 'all' | 'android' | 'ios' }

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://haramain.pro',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface BroadcastPayload {
  title: string
  body: string
  target: 'all' | 'android' | 'ios'
}

const FCM_SERVER_KEY = Deno.env.get('FCM_SERVER_KEY') || ''

function validateUUID(id: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id)
}

async function sendFCMNotification(token: string, payload: {
  title: string
  body: string
  data: Record<string, string>
}) {
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
      },
      data: payload.data,
      android: {
        priority: 'high',
        notification: {
          channel_id: 'broadcast',
        },
      },
      apns: {
        headers: {
          'apns-priority': '10',
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
  return response.json()
}

async function sendToTopic(topic: string, payload: {
  title: string
  body: string
  data: Record<string, string>
}) {
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
      },
      data: payload.data,
      android: {
        priority: 'high',
        notification: {
          channel_id: 'broadcast',
        },
      },
      apns: {
        headers: {
          'apns-priority': '10',
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
  return response.json()
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing authorization' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Verify SuperAdmin role from JWT
    const token = authHeader.replace('Bearer ', '')
    let jwtPayload: any
    try {
      jwtPayload = JSON.parse(atob(token.split('.')[1]))
    } catch {
      return new Response(JSON.stringify({ error: 'Invalid token' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const role = jwtPayload.role
    if (!['super_admin', 'admin_haramain_pro'].includes(role)) {
      return new Response(JSON.stringify({ error: 'Forbidden: SuperAdmin only' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    const payload: BroadcastPayload = await req.json()

    // Validate required fields
    if (!payload.title || typeof payload.title !== 'string' || payload.title.trim().length === 0) {
      return new Response(JSON.stringify({ error: 'title is required and must be a non-empty string' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (!payload.body || typeof payload.body !== 'string' || payload.body.trim().length === 0) {
      return new Response(JSON.stringify({ error: 'body is required and must be a non-empty string' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (!payload.target || !['all', 'android', 'ios'].includes(payload.target)) {
      return new Response(JSON.stringify({ error: 'target must be one of: all, android, ios' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Validate title/body length
    if (payload.title.length > 200) {
      return new Response(JSON.stringify({ error: 'title too long (max 200 chars)' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (payload.body.length > 500) {
      return new Response(JSON.stringify({ error: 'body too long (max 500 chars)' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Log broadcast
    const { data: broadcastLog, error: logError } = await supabaseClient
      .from('broadcast_notification_logs')
      .insert({
        title: payload.title.trim(),
        body: payload.body.trim(),
        target: payload.target,
        sent_by: jwtPayload.sub || jwtPayload.user_id || 'unknown',
        status: 'processing',
      })
      .select()
      .single()

    if (logError) {
      console.error('Broadcast log insert error:', logError)
    }

    const dataPayload = {
      type: 'broadcast_notification',
      broadcast_log_id: broadcastLog?.id || 'unknown',
      timestamp: new Date().toISOString(),
    }

    let notifiedCount = 0
    let fcmSuccessCount = 0
    let fcmFailureCount = 0
    let fcmNotConfigured = false

    // Check if FCM is configured
    if (!FCM_SERVER_KEY) {
      console.log('[broadcast-notification] FCM not configured - logging only')
      fcmNotConfigured = true

      // Update log status to skipped
      if (broadcastLog?.id) {
        await supabaseClient
          .from('broadcast_notification_logs')
          .update({ 
            status: 'skipped',
            notified_count: 0,
            fcm_success_count: 0,
            fcm_failure_count: 0,
          })
          .eq('id', broadcastLog.id)
      }

      return new Response(JSON.stringify({
        status: 'skipped',
        message: 'FCM not configured, notification logged only',
        broadcastLogId: broadcastLog?.id || null,
        notifiedCount: 0,
        fcmSuccessCount: 0,
        fcmFailureCount: 0,
      }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    try {
      // Use topic-based messaging for better performance
      const topic = payload.target === 'all' 
        ? 'broadcast_all' 
        : payload.target === 'android' 
          ? 'broadcast_android' 
          : 'broadcast_ios'

      const fcmResult = await sendToTopic(topic, {
        title: payload.title.trim(),
        body: payload.body.trim(),
        data: dataPayload,
      })

      console.log(`[broadcast-notification] FCM topic send result:`, JSON.stringify(fcmResult))

      if (fcmResult.success_count > 0) {
        fcmSuccessCount = fcmResult.success_count
        notifiedCount = fcmResult.success_count
      }

      if (fcmResult.failure_count > 0) {
        fcmFailureCount = fcmResult.failure_count
      }

      // Also try to send to all active tokens as fallback/enhancement
      const { data: tokens } = await supabaseClient
        .from('fcm_tokens')
        .select('token, platform')
        .eq('is_active', true)

      if (tokens && tokens.length > 0) {
        // Filter tokens by platform if target is not 'all'
        const filteredTokens = payload.target === 'all' 
          ? tokens 
          : tokens.filter(t => {
              if (payload.target === 'android') return t.platform === 'android'
              if (payload.target === 'ios') return t.platform === 'ios'
              return true
            })

        // Send to each token for more reliable delivery
        const sendPromises = filteredTokens.map(async (tokenRecord) => {
          try {
            await sendFCMNotification(tokenRecord.token, {
              title: payload.title.trim(),
              body: payload.body.trim(),
              data: dataPayload,
            })
            fcmSuccessCount++
            notifiedCount++
          } catch (err) {
            console.error('FCM token send error:', err)
            fcmFailureCount++
          }
        })

        await Promise.allSettled(sendPromises)
      }

    } catch (fcmError) {
      console.error('[broadcast-notification] FCM send error:', fcmError)
      fcmFailureCount++
    }

    // Update log with results
    if (broadcastLog?.id) {
      await supabaseClient
        .from('broadcast_notification_logs')
        .update({ 
          status: fcmNotConfigured ? 'skipped' : (fcmFailureCount === 0 ? 'completed' : 'partial'),
          notified_count: notifiedCount,
          fcm_success_count: fcmSuccessCount,
          fcm_failure_count: fcmFailureCount,
        })
        .eq('id', broadcastLog.id)
    }

    return new Response(JSON.stringify({
      status: fcmNotConfigured ? 'skipped' : (fcmFailureCount === 0 ? 'success' : 'partial'),
      broadcastLogId: broadcastLog?.id || null,
      notifiedCount,
      fcmSuccessCount,
      fcmFailureCount,
      target: payload.target,
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  } catch (error) {
    console.error('broadcast-notification function error:', error)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
