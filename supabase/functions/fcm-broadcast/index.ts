// Edge Function: fcm-broadcast
// Handles group broadcast messages with FCM push

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface BroadcastPayload {
  groupId: string
  message: string
}

const FCM_SERVER_KEY = Deno.env.get('FCM_SERVER_KEY') || ''

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

    // Get user from JWT
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser()
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Get user's profile
    const { data: profile } = await supabaseClient
      .from('profiles')
      .select('name')
      .eq('id', user.id)
      .single()

    // Verify user is a member of the group
    const { data: membership } = await supabaseClient
      .from('group_members')
      .select('id')
      .eq('group_id', (await req.clone().json()).groupId)
      .eq('user_id', user.id)
      .single()

    if (!membership) {
      return new Response(JSON.stringify({ error: 'Not a member of this group' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const payload: BroadcastPayload = await req.json()

    if (!payload.groupId || !payload.message) {
      return new Response(JSON.stringify({ error: 'Malformed payload' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Validate message length
    if (payload.message.length > 500) {
      return new Response(JSON.stringify({ error: 'Message too long (max 500 chars)' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Insert broadcast log
    const { data: broadcast, error: insertError } = await supabaseClient
      .from('broadcast_logs')
      .insert({
        group_id: payload.groupId,
        sender_id: user.id,
        message: payload.message
      })
      .select()
      .single()

    if (insertError) {
      console.error('Broadcast insert error:', insertError)
      return new Response(JSON.stringify({ error: 'Internal error' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Get all group members' FCM tokens (except sender)
    const { data: memberTokens } = await supabaseClient
      .from('fcm_tokens')
      .select('token, user_id')
      .neq('user_id', user.id)
      .eq('is_active', true)

    // Get all members in the group
    const { data: groupMembers } = await supabaseClient
      .from('group_members')
      .select('user_id')
      .eq('group_id', payload.groupId)
      .neq('user_id', user.id)

    if (groupMembers && groupMembers.length > 0) {
      const memberIds = groupMembers.map(m => m.user_id)
      
      // Get tokens for all members except sender
      const { data: tokens } = await supabaseClient
        .from('fcm_tokens')
        .select('token, user_id')
        .in('user_id', memberIds)
        .eq('is_active', true)

      // Send FCM to each device
      const fcmPromises = tokens?.map(async (tokenRecord) => {
        try {
          await sendFCMNotification(tokenRecord.token, {
            title: `📢 ${profile?.name || 'Group'}:`,
            body: payload.message,
            data: {
              type: 'broadcast',
              broadcast_id: broadcast.id,
              sender_id: user.id,
              group_id: payload.groupId,
            }
          })
        } catch (fcmError) {
          console.error('FCM send error:', fcmError)
        }
      }) || []

      await Promise.allSettled(fcmPromises)
    }

    return new Response(JSON.stringify({ 
      status: 'success', 
      broadcastId: broadcast.id,
      notifiedCount: memberTokens?.length || 0
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  } catch (error) {
    console.error('Broadcast function error:', error)
    return new Response(JSON.stringify({ error: 'Internal error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
