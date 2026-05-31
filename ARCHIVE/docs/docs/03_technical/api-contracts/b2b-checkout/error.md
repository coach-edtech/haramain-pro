# B2B Checkout API — Error Contracts

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Error codes and responses for B2B volume license purchase endpoints.

## Error Codes

| Code | HTTP Status | Meaning | Handling |
|------|-------------|---------|----------|
| `B2B_INVALID_PAX_COUNT` | 400 | Pax count must be positive integer | Provide valid count |
| `B2B_QUOTE_EXPIRED` | 400 | Quote no longer valid | Request new quote |
| `B2B_PAYMENT_PENDING` | 409 | Order already has pending payment | Wait or cancel existing |
| `B2B_PAYMENT_EXPIRED` | 410 | Payment window expired | Create new order |
| `B2B_PAYMENT_FAILED` | 402 | Payment was declined/failed | Try different payment method |
| `B2B_INSUFFICIENT_CREDITS` | 400 | Not enough credits to assign | Purchase more licenses |
| `B2B_NOT_AGENCY` | 403 | User is not an agency admin | Check user role |
| `AUTH_REQUIRED` | 401 | Not authenticated | Authenticate first |

## Notes on Backend Pricing Formula
- Calculated server-side to prevent manipulation
- Discount tier based on **total credits purchased** (not assigned)
- Retroactive: if agency crosses tier threshold, all prior purchases get new discount rate

## Error Response Shape
```json
{
  "error": {
    "code": "B2B_INVALID_PAX_COUNT",
    "message": "Passenger count must be a positive integer",
    "details": {
      "provided": -5
    }
  }
}
```

## Related
- `docs/03_technical/api-contracts/b2b-checkout/request.md`
- `docs/03_technical/api-contracts/b2b-checkout/response.md`
