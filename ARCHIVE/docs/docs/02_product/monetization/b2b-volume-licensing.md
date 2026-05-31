# B2B Volume Licensing

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
B2B pricing model for travel agencies purchasing Safety Passes in bulk for pilgrims.

## Pricing Structure

### Base Price
| Passengers | Price/Pax | Total (10 pax example) |
|------------|-----------|------------------------|
| Base | Rp 90,000 | Rp 900,000 |

### Volume Discount Tiers
| Passengers | Discount | Effective Price | Total (example) |
|------------|----------|-----------------|------------------|
| 1–50       | 0%       | Rp 90,000       | —                |
| 51–200     | 10%      | Rp 81,000       | Rp 4.05M (50 pax)|
| 201–500    | 20%      | Rp 72,000       | Rp 14.4K (200 pax)|
| 500+       | 30%      | Rp 63,000       | Rp 31.5K (500 pax)|

## How It Works

### 1. Agency Purchases Credits
- Agency selects passenger count
- Discount calculated automatically
- Midtrans payment (invoice or direct)
- Credits loaded to agency account

### 2. Agency Assigns Passes
- Upload passenger list (CSV or manual)
- System generates Safety Pass for each
- Passes appear in agency dashboard
- Agency can assign/revoke passes

### 3. Pilgrim Activates
- Pilgrim downloads app
- Agency sends invite (B2B bypass or PIN)
- Pilgrim joins group → Safety Pass auto-applied
- No payment required for pilgrim

## Purpose for Agencies
- **Value-add**: Offer premium safety features to pilgrims
- **Differentiation**: Stand out from competitors
- **Efficiency**: Bulk pricing vs individual purchases
- **Control**: Agency manages pass lifecycle

## Backend Calculation
Discount tier calculated based on **credits purchased** (not passengers assigned at time of purchase). Example:
1. Agency buys 100 credits @ Rp 90k/pax = Rp 9,000,000 (no discount tier yet)
2. Assigns 60 pilgrims → credits remaining: 40
3. Buys 50 more credits → total 150 → 10% discount applied retroactively to ALL 150
4. Refund/invoice adjustment applied

## Related
- `docs/05_features/b2b-volume-licensing/`
- `docs/05_features/agency-onboarding/`
- `docs/04_execution/milestones/milestone-2-foundation.md`
