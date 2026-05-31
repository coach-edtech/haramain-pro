# Assumptions

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Key assumptions underlying the Haramain Pro product and business model.

## Market Assumptions
1. Indonesian pilgrims want safety and spiritual guidance in a single app
2. Travel agencies (PPIU) will pay for volume licensing to differentiate services
3. Offline functionality is critical — connectivity in Mecca/Medina is unreliable
4. Rp 120,000 lifetime pass is acceptable for target demographic
5. B2B referral (agency → Jamaah) will drive B2C adoption

## Technical Assumptions
1. Supabase can handle RLS + realtime requirements for MVP scale
2. Mapbox offline tiles can be cached within 300MB per region limit
3. FCM reliability is sufficient for panic alert primary path
4. Twilio fallback provides adequate SMS coverage in Saudi Arabia
5. Isar can reliably queue writes for sync-on-reconnect

## Operational Assumptions
1. Travel agencies will complete onboarding with minimal support
2. Jamaah can joinrombongan via 6-digit PIN without confusion
3. Muthawif will use field ops tools if UI is simple enough
4. PDPL consent checkboxes will not significantly impact conversion
5. Marketing consent will be declined by majority (handled gracefully)

## Security Assumptions
1. RLS enforced at database level prevents cross-tenant access
2. Admin tools accessible only to Antigravity internal team
3. DX tools (GPS spoofer, alert loopback) restricted to test environments
4. No sensitive data (passport, biometrics) stored in MVP

## Risks & Open Questions
- Will Midtrans handle Indonesian payment methods adequately?
- Is Twilio WhatsApp API reliable in Saudi Arabia?
- Will Isar sync handle concurrent writes from multiple devices?
- Can we maintain <24h deletion SLA with current infra?

## Related
- `docs/06_decisions/` — key technical decisions
- `docs/04_execution/backlog/open-questions.md`
