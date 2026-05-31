# Dependency Map

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Cross-reference of feature dependencies — what each feature needs from other services/components.

## Feature → Dependencies

### Panic Alert
- **FCM** — push notification (primary)
- **Twilio** — SMS/WhatsApp fallback
- **Rombongan** — group membership for alert routing
- **Device Token** — FCM token registration
- **User Profiles** — recipient contact info

### Subscription Paywall
- **Midtrans** — payment gateway
- **User Profiles** — subscription status
- **Realtime** — instant unlock after payment
- **RLS** — access control based on subscription

### Jejak Ibadah
- **Isar** — local queue storage
- **File System** — photo/media storage
- **Watermark Function** — image watermarking
- **Rombongan** — trip context
- **Sync Engine** — upload queue management

### Offline Maps
- **Mapbox** — offline tile storage
- **Isar** — tile metadata cache
- **File System** — tile storage (max 300MB)
- **Storage Circuit Breaker** — auto-cleanup

### Virtual Muthawif
- **Geofence** — location boundary detection
- **GPS Background** — continuous awareness
- **Local Doa Repository** — offline duas
- **Rombongan** — prayer context

### B2B Volume Licensing
- **Agency Profiles** — tenant context
- **Rombongan** — passenger list
- **Invoice Engine** — discount calculation
- **RLS** — org-scoped data

### Alumni Broadcast
- **FCM** — push broadcast
- **Marketing Consent** — permission check
- **Cohort Selection** — audience filtering
- **Alumni Table** — past pilgrims

### Admin Tools
- **Metrics Dashboard** — usage stats
- **Trial Override** — extend/reset trial
- **Global Test Mode** — simulate scenarios
- **Watermark Preview** — media preview

### DX Tools
- **GPS Spoofer** — location simulation
- **Alert Loopback** — self-test panic
- **Consent Reset** — clear consent state
- **Non-Production Only** — safety guardrails

## Related Decisions
- `016-local-storage-strategy-isar.md` — Isar as primary local DB
- `015-panic-alert-fallback-with-twilio.md` — fallback layering
- `004-payment-gateway-midtrans.md` — Midtrans integration
