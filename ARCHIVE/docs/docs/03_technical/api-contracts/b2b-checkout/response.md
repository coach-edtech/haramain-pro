# B2B Checkout API — Response Contracts

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Response formats for B2B volume license purchase endpoints.

---

## POST /b2b/checkout

### Success Response (201 Created)
```json
{
  "success": true,
  "order": {
    "id": "uuid",
    "agency_id": "uuid",
    "pax_count": 75,
    "unit_price": 90000,
    "discount_percent": 10,
    "discounted_price": 81000,
    "total": 6075000,
    "currency": "IDR",
    "status": "pending_payment",
    "created_at": "2026-04-04T22:10:00Z"
  },
  "payment": {
    "midtrans_order_id": "HARAMAIN-ORDER-uuid",
    "midtrans_redirect_url": "https://app.midtrans.com/...",
    "expires_at": "2026-04-05T22:10:00Z"
  }
}
```

### Price Tier Reference
| Passengers | Discount | Effective Price |
|------------|----------|-----------------|
| 1–50 | 0% | Rp 90,000 |
| 51–200 | 10% | Rp 81,000 |
| 201–500 | 20% | Rp 72,000 |
| 500+ | 30% | Rp 63,000 |

---

## POST /b2b/checkout/confirm

### Success Response (200)
```json
{
  "success": true,
  "order_id": "uuid",
  "status": "payment_received",
  "credits_added": 75,
  "credits_remaining": 75,
  "confirmed_at": "2026-04-04T22:20:00Z"
}
```

### Notes
- **settlement update concept**: Midtrans webhook confirms payment → credits added to agency account
- Agency can immediately assign licenses to Jamaah after payment confirmed

## Related
- `docs/03_technical/api-contracts/b2b-checkout/request.md`
- `docs/03_technical/api-contracts/b2b-checkout/error.md`
