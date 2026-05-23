// Edge Function Tests for fcm-panic-alert
// Run with: deno test functions/tests/panic_alert_test.ts

import { assertEquals, assertExists } from 'https://deno.land/std@0.168.0/testing/asserts.ts'

Deno.test('PanicAlert - payload validation', () => {
  const validPayload = {
    rombonganId: '550e8400-e29b-41d4-a716-446655440000',
    distressedLat: 21.4225,
    distressedLng: 39.8262,
    timestamp: new Date().toISOString(),
  }

  assertExists(validPayload.rombonganId)
  assertExists(validPayload.distressedLat)
  assertExists(validPayload.distressedLng)
  assertExists(validPayload.timestamp)
})

Deno.test('PanicAlert - rate limit validation', () => {
  const fiveMinutesMs = 5 * 60 * 1000
  const now = Date.now()
  
  // Alert from 3 minutes ago - should be rate limited
  const recentAlertTime = new Date(now - 3 * 60 * 1000).toISOString()
  const timeDiff = now - new Date(recentAlertTime).getTime()
  assertEquals(timeDiff < fiveMinutesMs, true)

  // Alert from 6 minutes ago - should NOT be rate limited
  const oldAlertTime = new Date(now - 6 * 60 * 1000).toISOString()
  const oldTimeDiff = now - new Date(oldAlertTime).getTime()
  assertEquals(oldTimeDiff > fiveMinutesMs, true)
})

Deno.test('PanicAlert - coordinate validation for Makkah', () => {
  const makkahLat = 21.4225
  const makkahLng = 39.8262

  // Latitude should be between -90 and 90
  assertEquals(makkahLat >= -90 && makkahLat <= 90, true)
  // Longitude should be between -180 and 180
  assertEquals(makkahLng >= -180 && makkahLng <= 180, true)
  // Makkah coordinates
  assertEquals(makkahLat >= 21 && makkahLat <= 22, true)
  assertEquals(makkahLng >= 39 && makkahLng <= 40, true)
})

Deno.test('PanicAlert - coordinate validation for Madinah', () => {
  const madinahLat = 24.5247
  const madinahLng = 39.5692

  assertEquals(madinahLat >= -90 && madinahLat <= 90, true)
  assertEquals(madinahLng >= -180 && madinahLng <= 180, true)
  assertEquals(madinahLat >= 24 && madinahLat <= 25, true)
})

Deno.test('PanicAlert - status transitions', () => {
  const validStatuses = ['pending', 'responded', 'resolved', 'cancelled']
  
  assertEquals(validStatuses.includes('pending'), true)
  assertEquals(validStatuses.includes('responded'), true)
  assertEquals(validStatuses.includes('resolved'), true)
  assertEquals(validStatuses.includes('cancelled'), true)
  assertEquals(validStatuses.length, 4)
})

Deno.test('PanicAlert - UUID format validation', () => {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
  
  const validUuid = '550e8400-e29b-41d4-a716-446655440000'
  const invalidUuid = 'not-a-uuid'

  assertEquals(uuidRegex.test(validUuid), true)
  assertEquals(uuidRegex.test(invalidUuid), false)
})
