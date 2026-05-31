# 006 — Emergency Alert: Fallback Layering

> Owner: OpenClaw
> Status: Approved
> Note: Starter content — based on master doc direction.

## Decision
Implement panic alert with **layered fallback** — primary push notification with SMS/WhatsApp and local escalation if delivery fails.

## Fallback Layers

### Layer 1: FCM Push (Primary)
- Fast, free, works when app is open/background
- Requires internet connection
- Target: all devices in same rombongan + muthawif

### Layer 2: Twilio SMS (Secondary)
- Triggered if FCM delivery fails or user requests SMS
- Works on any phone with cellular signal
- Cost: ~Rp 150–500 per SMS (Saudi Arabia rates)

### Layer 3: Twilio WhatsApp (Tertiary)
- If SMS fails or as alternative
- Requires WhatsApp installed on sender device
- Better delivery in some regions

### Layer 4: Local Loopback Signal (Last Resort)
- Device makes loud noise/vibration even if no network
- Intended for: user is in immediate danger but no connectivity
- **Non-production test only** (not for actual emergency)

## Escalation Logic
```
Panic triggered
  → Try FCM (5s timeout)
  → If fail → Try Twilio SMS
  → If fail → Try Twilio WhatsApp
  → If all fail → Local alarm (test mode only)
```

## Trigger Conditions
- Manual: User taps panic button
- Automatic: GPS fence breach (future milestone)
- Test mode: DX tools loopback

## Related
- `docs/05_features/panic-alert/`
- `docs/03_technical/protocols/panic-flow.md`
- `015-panic-alert-fallback-with-twilio.md`
