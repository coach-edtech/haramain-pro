# B2C Safety Pass

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
B2C subscription product — lifetime Safety Pass for individual pilgrims.

## Product Details

| Attribute | Value |
|-----------|-------|
| Name | Safety Pass |
| Price | Rp 120,000 (lifetime) |
| Trial | 7 days free, non-renewable |
| Access | All B2C premium features |

## Included Features
- Panic Alert (with fallback)
- Offline Maps (Mecca + Medina)
- Virtual Muthawif (geofence prayers)
- Jejak Ibadah (spiritual activity log)
- Group Join (PIN-based)

## Paywall Logic

### Before Purchase
| Feature | Access |
|---------|--------|
| Onboarding + Consent | ✅ Allowed |
| Join Group | ✅ Allowed |
| Trial Features | ✅ 7 days |
| Panic Alert | ❌ Trial only |
| Offline Maps | ❌ Trial only |
| Jejak Ibadah | ❌ Trial only |

### After Purchase
All B2C features unlocked permanently for the user.

### After Trial Expires
- Panic Alert: ❌ Disabled
- Offline Maps: ❌ Disabled
- Jejak Ibadah: ❌ Disabled
- Group View: ✅ Read-only
- Account Settings: ✅ Allowed

## Conversion Flow
1. User completes onboarding + consents
2. 7-day trial auto-starts
3. Trial banner visible in app
4. User taps "Get Safety Pass" (Rp 120,000)
5. Midtrans payment flow
6. Webhook confirms → RLS updated in real-time
7. Features unlocked immediately

## Related
- `docs/05_features/subscription-paywall/`
- `docs/03_technical/protocols/trial-and-unlock-flow.md`
