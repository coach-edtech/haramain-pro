# Trial and Unlock Flow

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Trial activation and subscription unlock protocol.

## Trial Activation
Triggered automatically after user completes consent flow.

```
Consents submitted
    │
    ▼
Supabase: Create subscription record
    → type='trial'
    → status='active'
    → trial_started_at=NOW()
    → trial_expires_at=NOW() + 7 days
    │
    ▼
Realtime: Broadcast to app
    → Trial activated message
    → Show trial banner in UI
```

## Trial Expiry Detection
Two mechanisms:

### 1. App-side (optimistic)
```dart
// Check on app launch and periodically
if (subscription.type == 'trial' &&
    DateTime.now().isAfter(subscription.trialExpiresAt)) {
  // Disable premium features
  // Show paywall
}
```

### 2. Server-side (authoritative)
```sql
-- RLS policy on features
CREATE POLICY "premium_features"
ON subscriptions
FOR SELECT
USING (
  status = 'active'
  AND (
    type = 'b2c_lifetime'
    OR (type = 'trial' AND trial_expires_at > NOW())
    OR (type = 'b2b_assigned' AND ...)
  )
);
```

## Unlock After Payment
```
Midtrans webhook: settlement
    │
    ▼
Edge function: Update subscription
    → type='b2c_lifetime'
    → status='active'
    → purchased_at=NOW()
    │
    ▼
Realtime broadcast
    → App receives update
    → Immediate unlock (no app restart needed)
```

## Related
- `docs/05_features/subscription-paywall/`
- `docs/03_technical/data-model/subscription.md`
