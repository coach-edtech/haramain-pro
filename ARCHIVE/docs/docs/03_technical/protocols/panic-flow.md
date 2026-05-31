# Panic Flow

> Owner: OpenClaw
> Status: Starter content created
> Note: Starter content — not authoritative final. Onyx to refine.

## Purpose
Detailed protocol for panic alert triggering and escalation.

## Trigger
User taps **Panic Button** in app (available only with active Safety Pass).

## Escalation Sequence

```
[T=0] User taps panic
    │
    ▼
[T=0 to T=5s] Layer 1: FCM Push
    → Send to all rombongan members + muthawif
    → Delivery confirmation awaited
    │
    ├─ If FCM delivered → WAIT for acknowledgment
    │
    └─ If timeout/fail (T=5s) → escalate
    │
    ▼
[T=5s to T=15s] Layer 2: Twilio SMS
    → Send SMS to all registered phones
    → Message: "PANIC: [Name] needs help at [location]. Call 112."
    │
    ├─ If SMS delivered → WAIT for acknowledgment
    │
    └─ If fail (T=10s) → escalate
    │
    ▼
[T=15s to T=30s] Layer 3: Twilio WhatsApp
    → Send WhatsApp message with location link
    │
    ├─ If delivered → WAIT for acknowledgment
    │
    └─ If fail → escalate
    │
    ▼
[T=30s+] Layer 4: Local Loopback (TEST ONLY)
    → Device loud alarm + vibration
    → ONLY in non-production environments
    → NOT for real emergencies
```

## Acknowledgment
1. Muthawif or agency admin receives alert
2. Taps "Acknowledge" → status: acknowledged
3. Calls pilgrim directly
4. If resolved → taps "Resolve" → status: resolved
5. If false alarm → marks "False Alarm"

## Non-Production Testing (DX Tools)
- Alert loopback: triggers full flow but skips external APIs
- GPS spoofing: inject fake location into panic trigger
- Test mode: visible banner in UI

## Related
- `docs/05_features/panic-alert/`
- `docs/05_features/dx-tools/`
- `015-panic-alert-fallback-with-twilio.md`
