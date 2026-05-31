# DX Tools — Summary

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Feature Summary

| Aspect | Detail |
|--------|--------|
| Feature | DX (Developer Experience) Tools |
| Owner | OpenClaw (starter), Onyx (refinement) |
| Priority | P1 |
| Status | Implementation pending |

## What It Does
Internal tools for development, testing, and debugging — **non-production only**.

## Tools

### GPS Spoofer
- Inject fake GPS location into app
- Test geofence triggers without being physically present
- Use case: test Virtual Muthawif triggers

### Alert Loopback
- Trigger panic alert that sends to self only
- Full escalation path tested (FCM → Twilio)
- No actual emergency services called
- Visible "TEST MODE" indicator

### Consent Reset
- Clear consent state for specific user
- Retrigger consent flow without deleting account
- Use case: test consent UI multiple times

### Sync Debugger
- View sync queue contents
- Force sync attempt
- View last sync timestamp
- Clear sync queue

### Non-Production Guard
- GPS spoofer disabled in production builds
- Alert loopback limited to test users
- Guards prevent accidental misuse

## Security
- DX tools require authenticated dev/test account
- Actions logged in audit table
- Cannot access production user data

## Related
- `docs/02_product/personas/system-admin.md`
- `docs/05_features/admin-tools/`
