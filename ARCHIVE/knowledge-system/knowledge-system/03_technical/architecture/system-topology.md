# System Topology — Haramain Pro

Version: 1.0
Status: PRODUCTION-GRADE ARCHITECTURE DOCUMENT

---

## 1. PURPOSE

Define end-to-end topology across:
- Client (Flutter)
- Edge Functions (Supabase)
- Database (PostgreSQL + RLS)
- Storage (Supabase Storage)
- External Services (FCM, Twilio, Midtrans, Mapbox)

All data paths MUST be explicit and enforceable.

---

## 2. HIGH-LEVEL FLOW

Client → Edge Functions → Database (RLS) → Storage
                         ↘ External Services

RULE:
- Client NEVER talks directly to DB (except PostgREST with RLS)
- All critical logic MUST pass through Edge

---

## 3. COMPONENTS

### 3.1 Client (Flutter)

Responsibilities:
- UI rendering
- Local state (Isar)
- Offline queue (photos)
- JWT storage

MUST:
- enforce route guards
- NOT trust local role/consent without refresh

---

### 3.2 Edge Functions (Supabase)

Core services:
- refresh-claims
- panic-dispatch
- photo-watermark
- midtrans-webhook
- consent-withdraw

Responsibilities:
- validation (auth, consent, access)
- orchestration
- external API calls

MUST:
- be stateless
- be idempotent where required
- log all critical actions

---

### 3.3 Database (PostgreSQL)

Core:
- profiles
- rombongan
- rombongan_members
- user_consents
- transactions
- panic_alerts
- gps_tracks
- photos

MUST:
- enforce RLS on ALL tables
- act as source of truth
- store UTC timestamps only

---

### 3.4 Storage (Supabase Storage)

Buckets:
- photos_raw/
- photos/

Rules:
- raw uploads temporary
- processed images final
- access controlled via signed URLs

---

### 3.5 External Services

| Service | Purpose |
|--------|--------|
| FCM | push notifications (panic) |
| Twilio | fallback voice alert |
| Midtrans | payments |
| Mapbox | maps & geolocation |

---

## 4. DATA FLOW BY FEATURE

### 4.1 Auth

Client → Edge (refresh-claims) → DB → JWT → Client

---

### 4.2 Panic

Client → Edge (panic) → DB validate → FCM → Twilio fallback → DB log

---

### 4.3 Photo Sync

Client (offline queue) → Edge upload → Storage raw → Edge processing → Storage final → DB record → Client sync

---

### 4.4 Payment

Midtrans → Webhook (Edge) → Validate → DB update → Profile subscription update

---

### 4.5 GPS

Client → DB (service role) → pg_cron purge

---

## 5. SECURITY LAYERS

1. Client guards
2. Edge validation
3. RLS enforcement (FINAL)

RULE:
- No single layer is trusted alone

---

## 6. FAILURE ISOLATION

- Edge failure → retry / fallback
- External failure → circuit breaker
- DB failure → reject request

---

## 7. OBSERVABILITY INTEGRATION

Each layer MUST emit logs:
- Client: errors, retries
- Edge: structured logs
- DB: query + RLS failures

---

## 8. SCALING MODEL

- Client: horizontal (users)
- Edge: serverless auto-scale
- DB: vertical + read replicas
- Storage: CDN-backed

---

## 9. DEPLOYMENT BOUNDARY

| Layer | Deployment |
|------|-----------|
| Client | Mobile (App Store / Play Store) |
| Edge | Supabase Functions |
| DB | Supabase Postgres |
| Storage | Supabase |
| External | Managed services |

---

## 10. FINAL RULE

All system interactions MUST follow this topology.

Any bypass (direct DB, skipped Edge, ignored RLS) = CRITICAL DEFECT
