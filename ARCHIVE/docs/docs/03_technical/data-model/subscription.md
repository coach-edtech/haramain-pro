# Subscription

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Safety Pass subscription data model.

## Tables

#### `public.subscriptions`
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | PK |
| `user_id` | UUID | FK → profiles |
| `type` | ENUM | 'trial', 'b2c_lifetime', 'b2b_assigned' |
| `status` | ENUM | 'active', 'expired', 'revoked' |
| `trial_started_at` | TIMESTAMPTZ | |
| `trial_expires_at` | TIMESTAMPTZ | trial_start + 7 days |
| `purchased_at` | TIMESTAMPTZ | Payment timestamp |
| `midtrans_order_id` | TEXT | For B2C receipts |
| `source` | ENUM | 'direct_purchase', 'agency_assigned' |
| `agency_id` | UUID | FK → agencies (for B2B) |
| `created_at` | TIMESTAMPTZ | |

## State Machine

```
┌─────────────┐   trial starts   ┌─────────────────┐
│   (none)    │─────────────────▶│     trial       │
└─────────────┘                   │  (7 days)       │
       ▲                          └────────┬────────┘
       │                                   │
       │ expires                    purchase
       │                                   │
       │                    ┌──────────────▼──────────┐
       └─────────────────────│      b2c_lifetime       │
                             └─────────────────────────┘
```

## Access Logic
```sql
-- User has active subscription if:
-- 1. type='b2c_lifetime' AND status='active'
-- 2. type='b2b_assigned' AND status='active' AND trip active
-- 3. type='trial' AND trial_expires_at > NOW()
```

## Related
- `docs/05_features/subscription-paywall/`
- `docs/03_technical/protocols/subscription-access-state-machine.md`
