// Send Invoice Email Edge Function
// POST /functions/v1/send-invoice-email
// Sends invoice email to agency (placeholder for now)

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://haramain.pro',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

interface SendInvoiceEmailPayload {
  invoice_id: string
  agency_email: string
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  // Only allow POST
  if (req.method !== 'POST') {
    return Response.json(
      { error: 'Method not allowed' },
      { status: 405, headers: corsHeaders }
    )
  }

  // Verify authorization
  const authHeader = req.headers.get('Authorization')
  if (!authHeader?.startsWith('Bearer ')) {
    return Response.json(
      { error: 'Unauthorized - Missing or invalid Bearer token' },
      { status: 401, headers: corsHeaders }
    )
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    // Verify user
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser()
    if (authError || !user) {
      return Response.json(
        { error: 'Unauthorized' },
        { status: 401, headers: corsHeaders }
      )
    }

    const payload: SendInvoiceEmailPayload = await req.json()

    // Validate input
    if (!payload.invoice_id || typeof payload.invoice_id !== 'string') {
      return Response.json(
        { error: 'Invalid invoice_id - must be a non-empty string' },
        { status: 400, headers: corsHeaders }
      )
    }

    if (!payload.agency_email || typeof payload.agency_email !== 'string') {
      return Response.json(
        { error: 'Invalid agency_email - must be a non-empty string' },
        { status: 400, headers: corsHeaders }
      )
    }

    // Basic email format validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    if (!emailRegex.test(payload.agency_email)) {
      return Response.json(
        { error: 'Invalid agency_email - not a valid email format' },
        { status: 400, headers: corsHeaders }
      )
    }

    // TODO: Integrate with email service (Resend, SendGrid, etc.)
    // For now, this is a placeholder that logs and returns success

    console.log(`[send-invoice-email] Sending invoice ${payload.invoice_id} to ${payload.agency_email}`)

    // Fetch invoice details for placeholder email content
    const { data: invoice, error: invoiceError } = await supabaseClient
      .from('invoices')
      .select('*')
      .eq('id', payload.invoice_id)
      .single()

    if (invoiceError) {
      console.error('Invoice not found:', invoiceError)
      // Don't fail - just log and continue with placeholder
    }

    if (invoice) {
      console.log(`[send-invoice-email] Invoice details:`, {
        id: invoice.id,
        amount: invoice.amount,
        status: invoice.status,
        agency_id: invoice.agency_id,
      })
    }

    // Placeholder: Log email content that would be sent
    const emailContent = {
      to: payload.agency_email,
      subject: invoice
        ? `Invoice ${invoice.id} - Rp ${invoice.amount?.toLocaleString('id-ID')}`
        : `Invoice ${payload.invoice_id}`,
      body: invoice
        ? `Dear Customer,\n\nPlease find attached invoice ${invoice.id} for Rp ${invoice.amount?.toLocaleString('id-ID')}.\n\nThank you.`
        : `Dear Customer,\n\nPlease find attached invoice ${payload.invoice_id}.\n\nThank you.`,
    }

    console.log(`[send-invoice-email] Email placeholder:`, JSON.stringify(emailContent))

    // Return success response
    return Response.json(
      {
        success: true,
        message: 'Email queued successfully (placeholder)',
        invoice_id: payload.invoice_id,
        recipient: payload.agency_email,
        email_sent: false, // Placeholder - no actual email sent
        email_preview: emailContent,
      },
      { headers: corsHeaders }
    )

  } catch (error) {
    console.error('Error in send-invoice-email:', error)
    return Response.json(
      { error: 'Internal server error' },
      { status: 500, headers: corsHeaders }
    )
  }
})
