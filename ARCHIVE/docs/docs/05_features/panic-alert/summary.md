# Panic Alert — Summary

> Owner: Onyx
> Status: Placeholder created by OpenClaw
> Note: Final content will be authored/refined by Onyx.

## Feature Summary

| Aspect | Detail |
|--------|--------|
| Feature | Panic Alert |
| Owner | Onyx (authoritative) |
| Priority | P0 |
| Status | Placeholder |

## What It Does
Emergency alert system with layered fallback — primary FCM push with Twilio SMS/WhatsApp escalation.

## Fallback Layers
1. FCM Push (primary, free, fast)
2. Twilio SMS (fallback, per-SMS cost)
3. Twilio WhatsApp (tertiary fallback)
4. Local Loopback (non-production test only)

## Key Requirements
- Works offline (queued escalation)
- Triggers within group (rombongan) + muthawif
- Acknowledgment + resolution flow
- Non-production test tools (DX)

## Implementation Status
Placeholder — awaiting Onyx final content.

## Related
- `docs/03_technical/protocols/panic-flow.md`
- `docs/06_decisions/006-emergency-alert-fallback-layering.md`
