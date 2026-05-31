# B2B Volume Licensing — Summary

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Feature Summary

| Aspect | Detail |
|--------|--------|
| Feature | B2B Volume Licensing |
| Owner | OpenClaw (starter), Onyx (refinement) |
| Priority | P0 (core B2B) |
| Status | Implementation pending |

## What It Does
Allows travel agencies to purchase Safety Passes in bulk at volume discounts, then assign them to their pilgrims.

## Pricing Tiers
| Passengers | Discount | Effective Price |
|------------|----------|----------------|
| 1–50 | 0% | Rp 90,000 |
| 51–200 | 10% | Rp 81,000 |
| 201–500 | 20% | Rp 72,000 |
| 500+ | 30% | Rp 63,000 |

## Flow
1. Agency purchases volume credits via Midtrans
2. Agency uploads/assigns passenger list
3. Pilgrims receive assigned Safety Pass
4. Pilgrims activate without payment

## Implementation Notes
- Discount calculated on credits purchased (not assigned)
- Retroactive tier adjustment when volume threshold hit
- Credits never expire (use-it-or-lose-it? TBD)

## Dependencies
- Agency onboarding
- Midtrans invoice API
- Passenger management UI

## Related
- `docs/02_product/monetization/b2b-volume-licensing.md`
- `docs/05_features/agency-onboarding/`
