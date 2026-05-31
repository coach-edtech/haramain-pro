# Feature Brief: B2C Paywall + Midtrans Integration

_Feature ID: F-05_
_Status: Draft_
_Date: 2026-04-04_
_Author: OpenClaw (extracted from PRD)_

---

## 1. Problem Statement

The app needs a sustainable revenue model. Pilgrims must be able to purchase lifetime premium access ("Haramain Safety Pass") to unlock premium features. Payment must be frictionless, trustworthy, and trigger instant access activation.

---

## 2. Goal

- Offer 7-day free trial for premium features (Offline Maps, Panic Button)
- Display persistent countdown of remaining trial days
- Enforce strict paywall when trial expires
- Process Rp 120,000 lifetime purchase via Midtrans Snap
- Unlock premium instantly upon successful payment webhook
- Display conversion hooks: "100% Peace of Mind or Money Back Guarantee" + "Lifetime Access"

---

## 3. User Flow

### Trial Flow
```
User completes PDPL consent + registration
       ↓
7-day free trial STARTS automatically
       ↓
Premium features unlocked: Offline Maps, Panic Button
       ↓
Persistent banner: "X days remaining in free trial"
       ↓
Trial expires at 00:00 on day 7
       ↓
PAYWALL triggered
```

### Paywall + Purchase Flow
```
Trial expires OR user taps premium feature
       ↓
PAYWALL SCREEN displayed
       ↓
Show: "Haramain Safety Pass — Rp 120,000 Lifetime"
       ↓
"100% Peace of Mind or Money Back Guarantee"
       ↓
"Lifetime Access — Never pay again"
       ↓
[Buy Now] button → Opens Midtrans Snap
       ↓
User completes payment in Midtrans UI
       ↓
Midtrans sends webhook → backend verifies SHA512
       ↓
Backend unlocks premium: subscriptionTier = "active"
       ↓
App receives Realtime update OR polls → shows "Premium Active!"
       ↓
All premium features unlocked permanently
```

---

## 4. Scope

### In Scope
- 7-day free trial trigger on registration
- Persistent trial countdown banner/indicator
- Strict paywall blocking premium features on expiration
- Midtrans Snap integration (redirect to Midtrans webview)
- SHA512 webhook verification
- Instant premium unlock on webhook confirmation
- "Haramain Safety Pass" branding
- Conversion psychological hooks (guarantee, lifetime)

### Out of Scope
- Refund flow (handled by Midtrans directly)
- Subscription management (lifetime, no recurring)
- Promo codes / discounts
- Alternative payment methods (OVO, Dana, etc. — Midtrans handles this)
- Invoice generation

---

## 5. Pricing

| Product | Price | Type |
|---------|-------|------|
| Haramain Safety Pass | Rp 120,000 | Lifetime (one-time) |

---

## 6. Premium Features (Unlocked by Purchase)

1. Offline Maps (Makkah + Madinah)
2. Panic Button (GPS + Muthawif alert)
3. Virtual Muthawif (prayer surfacing)
4. Jejak Ibadah photo gallery sync

---

## 7. Acceptance Criteria

- [ ] Trial starts IMMEDIATELY after registration (not after first login)
- [ ] Trial countdown shows in persistent banner/header on all screens
- [ ] When trial expires, premium features show paywall overlay
- [ ] Map tiles already downloaded remain accessible but re-download blocked
- [ ] Panic button shows paywall but still allows GPS tracking (safety exception?)
- [ ] Midtrans Snap opens in secure webview
- [ ] Payment via Midtrans Snap succeeds and returns to app
- [ ] Webhook from Midtrans received within 60 seconds
- [ ] SHA512 signature verified server-side
- [ ] subscriptionTier updated to "active" in database
- [ ] App reflects premium state within 5 seconds of webhook
- [ ] Premium state persists across app reinstall (server-side, not local)
- [ ] "Money Back Guarantee" claim process documented

---

## 8. Midtrans Integration

### Snap API Flow
```
Client:
1. Request order_id + snap_token from backend
2. Open Midtrans Snap with token

Backend:
1. Generate unique order_id
2. Call Midtrans API: POST /snap/v1/transactions
3. Return { token, redirect_url }

Midtrans:
- User completes payment
- Server sends webhook to backend: POST /webhook/midtrans
- Webhook verified with SHA512

Backend webhook handler:
1. Verify signature_key
2. Check transaction_status == "settlement"
3. Update user subscriptionTier = "active"
```

### Security
- All Midtrans API calls server-side (backend never exposes client_key)
- Signature verification: `SHA512(order_id + status_code + gross_amount + ServerKey)`
- Backend must reject any unverified webhook

---

## 9. State Machine

```
[NEW USER]
    ↓ (registers)
[FREE_TRIAL] ← 7 days
    ↓ (expires OR user buys)
[PAYWALL] ← blocked from premium
    OR [ACTIVE] ← payment confirmed
    ↓
Lifetime
```

---

## 10. Edge Cases

| Case | Handling |
|------|----------|
| User buys but webhook fails | Retry logic; user sees "Processing" until confirmed |
| Midtrans returns "pending" | Show "Payment pending — we'll notify you" |
| User tries to bypass paywall via VPN | Server-side enforcement, client UI is cosmetic |
| Payment via compromised card | Midtrans handles fraud detection |
| User requests refund | Midtrans refund flow; revert subscriptionTier on success |

---

## 11. Dependencies

- Midtrans Snap API (server-side + client SDK)
- Supabase: `subscriptions` table
- Supabase Edge Function: `midtrans-webhook`
- Supabase Realtime (for instant UI update on unlock)

---

## 12. Related PRD References

- PRD-18: 7-day free trial upon registration
- PRD-19: Persistent countdown indicator
- PRD-20: Strict paywall on expiration
- PRD-21: Rp 120,000 lifetime "Haramain Safety Pass"
- PRD-22: Conversion hooks (guarantee, lifetime)
- PRD-23: Midtrans Snap integration
- PRD-24: Instant unlock on webhook success
- PRD-52-57: Monetization Sandbox Loop (DX test feature)

---

## 13. Questions Open

1. When trial expires, should Panic Button be fully blocked or show limited functionality? (Safety consideration)
2. Should the countdown banner be dismissible or persistent?
3. What happens if user downloads app fresh on day 6 of trial? (Trial should be tied to account, not device)
4. Is there a "restore purchase" option for reinstalls? (Yes, server-side subscription persists)
5. Should there be a "trial expired" notification push before blocking?

