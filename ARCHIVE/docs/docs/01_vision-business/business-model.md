# Business Model

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
B2B2C revenue model for Haramain Pro.

## Revenue Streams

### B2C — Safety Pass (Primary)
- **Price**: Rp 120,000 lifetime
- **Trial**: 7 days free, non-renewable
- **Access**: Panic alert, offline maps, virtual muthawif, jejak ibadah
- **Acquisition**: Direct app download, agency referrals

### B2B — Volume Licensing (Secondary)
- **Base Price**: Rp 90,000 per passenger
- **Volume Discount Tiers**:
  | Passengers | Discount | Effective Price |
  |------------|----------|-----------------|
  | 1–50       | 0%       | Rp 90,000       |
  | 51–200     | 10%      | Rp 81,000       |
  | 201–500    | 20%      | Rp 72,000       |
  | 500+       | 30%      | Rp 63,000       |
- **Billing**: Agency receives invoice, manages passenger allocation
- **Access**: Agencies assign passes to registered Jamaah

### B2B — Agency Onboarding
- Registration via PPIU license verification
- Logo and branding customization
- Dedicated tenant context

## B2B2C Flow
```
Travel Agency (PPIU)
    ├── Buys volume license (Rp 90k/pax)
    ├── Creates rombongans
    ├── Invites Jamaah (PIN or B2B bypass)
    └── Jamaah redeems → Safety Pass activated
```

## Cost Structure
- Supabase (hosting + egress)
- Mapbox (offline tile storage)
- Midtrans (payment gateway fees)
- FCM + Twilio (notification costs)
- Infrastructure (CI/CD, monitoring)

## Related
- `docs/05_features/subscription-paywall/`
- `docs/05_features/b2b-volume-licensing/`
- `docs/05_features/agency-onboarding/`
