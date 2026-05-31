# 004 — Payment Gateway: Midtrans

> Owner: OpenClaw
> Status: Approved
> Note: Starter content — based on master doc direction.

## Decision
Use **Midtrans** as the payment gateway for Haramain Pro B2C and B2B transactions.

## Rationale
- **Indonesian market leader** — supports local payment methods (GoPay, OVO, Dana, Bank Transfer, credit card)
- Proven reliability for Rp-denominated transactions
- **Snap** integration for seamless in-app checkout
- Webhook support for real-time payment verification
- Established fraud detection

## Implementation

### B2C Flow (Safety Pass)
```
User taps "Buy Safety Pass" (Rp 120,000)
  → Midtrans Snap opens
  → User completes payment
  → Midtrans webhook → Supabase Edge Function
  → Subscription record updated (realtime)
  → User unlocks premium features
```

### B2B Flow (Volume License)
```
Agency purchases N pax @ Rp 90,000/pax
  → Midtrans invoice generated
  → Agency pays via bank transfer or virtual account
  → Payment confirmed → credits added to agency account
  → Agency assigns passes to Jamaah
```

## Configuration
- **Environment**: Sandbox for dev, Production for release
- **Payment Methods**: Credit card, GoPay, OVO, Dana, Bank Transfer (BNI, Mandiri, BRI, BCA)
- **Notification**: HTTP webhook to Supabase Edge Function

## Alternatives Considered
- **Xendit**: Good but smaller Indonesian market share
- **Doku**: More complex integration
- **Stripe**: Limited Indonesian payment method coverage

## Related
- `docs/05_features/subscription-paywall/`
- `docs/05_features/b2b-volume-licensing/`
- `docs/03_technical/protocols/payment-webhook-flow.md`
