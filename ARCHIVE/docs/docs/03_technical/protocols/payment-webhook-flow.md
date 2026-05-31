# Payment Webhook Flow

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Flow for Midtrans payment webhook → subscription activation.

## B2C Payment Flow (Safety Pass)

### Happy Path
```
User → taps "Buy Safety Pass" (Rp 120,000)
    → Midtrans Snap opens (in-app browser)
    → User completes payment
    → Midtrans POST /webhook to Supabase Edge
    │
    ▼
Edge Function: payment-webhook
    1. Verify Midtrans signature
    2. Parse transaction_status
    3. If "settlement" or "capture":
       → Insert/Update subscriptions record
       → status='active', type='b2c_lifetime'
       → Supabase Realtime broadcast
    4. Return 200 to Midtrans
    │
    ▼
Flutter App
    → Realtime subscription update received
    → Unlock premium features immediately
```

### Signature Verification
```typescript
// Edge function
import crypto from 'crypto';

function verifyMidtransSignature(
  orderId: string,
  statusCode: string,
  grossAmount: string,
  serverKey: string,
  signatureKey: string
): boolean {
  const hash = crypto
    .createHash('sha512')
    .update(orderId + statusCode + grossAmount + serverKey)
    .digest('hex');
  return hash === signatureKey;
}
```

### Idempotency
- Midtrans may retry webhook 3x
- Edge function checks if subscription already created for order_id
- Duplicate settlement: ignore (idempotent)

### Error Handling
| Scenario | Action |
|----------|--------|
| Invalid signature | Return 403 |
| Duplicate order_id | Skip (idempotent) |
| Wrong amount | Log, return 200, flag for review |
| Supabase error | Return 500 (Midtrans will retry) |

## Related
- `docs/05_features/subscription-paywall/`
- `docs/03_technical/architecture/edge-functions.md`
