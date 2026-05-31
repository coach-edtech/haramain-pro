# Edge Functions

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Serverless functions running in Supabase Edge for backend logic.

## Function Inventory

### 1. `payment-webhook`
**Trigger**: Midtrans payment notification
**Purpose**: Update subscription status after B2C payment
```
Midtrans → webhook → verify signature → update subscriptions table → return 200
```

### 2. `sync-jejak-ibadah`
**Trigger**: Mobile app sync request
**Purpose**: Process queued jejak ibadah entries from offline
```
Mobile → auth check → validate data → insert to jejak_ibadah → update sync status
```

### 3. `panic-escalate`
**Trigger**: FCM delivery failure callback
**Purpose**: Escalate panic to Twilio fallback
```
FCM fail → trigger Twilio SMS → log escalation → confirm delivery
```

### 4. `group-expiry-check`
**Trigger**: Cron (daily)
**Purpose**: Expire groups past trip_end_at, revoke access
```
Query active groups WHERE trip_end_at < NOW()
→ Mark as expired
→ Revoke Jamaah access
→ Send notification
```

### 5. `marketing-broadcast`
**Trigger**: Admin action
**Purpose**: Send FCM broadcast to alumni with marketing consent
```
Admin → validate audience → filter marketing_consent=true → FCM batch send
```

## Runtime
- **Deno** or **Node.js** (Supabase Edge runtime)
- **Region**: Singapore (ap-southeast-1) for Indonesian latency

## Security
- Webhook functions verify signature (Midtrans/FCM)
- All functions verify JWT from Supabase Auth
- Rate limiting on broadcast function

## Related
- `docs/03_technical/protocols/payment-webhook-flow.md`
- `docs/03_technical/protocols/panic-flow.md`
