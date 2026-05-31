# Alumni Broadcast — Summary

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Feature Summary

| Aspect | Detail |
|--------|--------|
| Feature | Alumni Broadcast |
| Owner | OpenClaw (starter), Onyx (refinement) |
| Priority | P2 |
| Status | Implementation pending |

## What It Does
Allows agencies to send push notifications (FCM) to past pilgrims who have opted into marketing communications.

## Prerequisites
- Pilgrim completed trip (trip_end_at passed)
- Pilgrim granted `consent_marketing = true`
- Agency has pilgrim in their alumni list

## Use Cases
- "Umrah season starting — book now!"
- "Special Hajj packages for returning pilgrims"
- "Share your feedback and get a discount"

## Audience Selection
- Filter by: trip date range, demographics, past group
- Exclude: already converted, unsubscribed

## Compliance
- Marketing consent required (separate from core)
- One-tap unsubscribe in all broadcasts
- PDPL compliant

## Implementation Notes
- Uses FCM for push delivery
- Admin UI for audience selection
- Delivery receipts + opt-out tracking

## Related
- `docs/05_features/marketing-consent/`
- `docs/02_product/personas/travel-agency.md`
