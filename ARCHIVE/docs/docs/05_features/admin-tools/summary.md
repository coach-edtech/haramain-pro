# Admin Tools — Summary

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Feature Summary

| Aspect | Detail |
|--------|--------|
| Feature | Admin Tools |
| Owner | OpenClaw (starter), Onyx (refinement) |
| Priority | P1 |
| Status | Implementation pending |

## What It Does
Dashboard and tools for Antigravity staff to manage the platform, support users, and maintain compliance.

## Tools

### Metrics Dashboard
- Daily/weekly/monthly active users
- Subscription conversions
- Panic alerts triggered
- Consent compliance rates
- Agency sign-ups

### Trial Override
- Extend trial period for specific users
- Reset trial (if user accidentally expired)
- Reason required for audit

### Global Test Mode
- Toggle test mode (banner in UI)
- Affects all users or specific cohort
- Used for staging validation

### Watermark Preview
- Preview how photos will look with watermark
- Verify watermark positioning

### Data Management
- View user consent records
- Process deletion requests
- Audit log viewer

## Access Control
- Sys Admin role only
- Audit trail for all actions
- No access to payment data (PCI scope)

## Related
- `docs/02_product/personas/system-admin.md`
- `docs/05_features/dx-tools/`
