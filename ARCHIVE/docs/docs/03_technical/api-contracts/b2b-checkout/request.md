# B2B Checkout API — Request Contracts

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Request formats for B2B volume license purchase endpoints.

---

## POST /b2b/checkout

Create a volume license purchase order (agency).

### Request
```json
{
  "pax_count": 75,
  "notes": "Umrah Ramadan batch"
}
```

### Fields
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `pax_count` | integer | Yes | Number of passenger licenses (min: 1) |
| `notes` | string | No | Internal notes for this order |

### Notes
- **Backend pricing formula**: price calculated server-side based on tier
- **Discount tiers**: calculated on total credits purchased, not assigned
- Midtrans invoice generated server-side

---

## GET /b2b/quote

Get pricing quote without creating order.

### Request
```json
{
  "pax_count": 75
}
```

### Response
```json
{
  "pax_count": 75,
  "unit_price": 90000,
  "discount_percent": 10,
  "discounted_price": 81000,
  "total": 6075000,
  "currency": "IDR",
  "tier": "51-200 pax"
}
```

---

## POST /b2b/checkout/confirm

Confirm and initiate payment (after Midtrans payment completes).

### Request
```json
{
  "order_id": "uuid",
  "midtrans_transaction_id": "string"
}
```

## Related
- `docs/03_technical/api-contracts/b2b-checkout/response.md`
- `docs/03_technical/api-contracts/b2b-checkout/error.md`
