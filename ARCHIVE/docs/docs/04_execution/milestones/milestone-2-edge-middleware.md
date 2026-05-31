# Milestone 2 — Edge + Middleware

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Objective
Payment gateway integration, push notification infrastructure, and server-side logic.

## Scope
- Midtrans Snap integration (B2C Safety Pass)
- Midtrans invoice integration (B2B Volume License)
- Payment webhook handler
- FCM push notification setup
- Panic alert Edge Function
- Twilio SMS/WhatsApp fallback

## Deliverables
- [ ] Midtrans B2C payment flow
- [ ] Midtrans B2B invoice flow
- [ ] Payment webhook Edge Function
- [ ] Subscription unlock on payment confirmation
- [ ] FCM integration in Flutter
- [ ] Panic alert Edge Function (FCM + Twilio)
- [ ] Fallback escalation logic

## Dependencies
- Milestone 1 complete (subscription table exists)
- Supabase Edge Functions configured
- FCM project created
- Twilio account configured

## Success Criteria
- B2C Safety Pass purchasable via Midtrans
- B2B volume license invoice generatable
- Subscription unlocks immediately after payment
- Panic alert sends FCM push to group members
- Fallback to Twilio SMS on FCM failure

## Related
- `docs/03_technical/architecture/edge-functions.md`
- `docs/05_features/subscription-paywall/`
- `docs/05_features/panic-alert/`
- `docs/04_execution/milestones/milestone-3-mobile-offline-engine.md`
