# Photo Sync Flow — Haramain Pro

Version: 1.0
Status: PRODUCTION-GRADE CONTROL DOCUMENT

---

## 1. PURPOSE

Define a deterministic, offline-first photo synchronization system with:

- guaranteed eventual upload
- idempotent processing (no duplicates)
- retry with backoff
- watermark processing with circuit breaker
- strict membership & consent enforcement

---

## 2. SOURCE OF TRUTH

| Data | Source |
|------|--------|
| local queue | Isar (mobile) |
| upload state | local + server ack |
| membership | rombongan_members |
| consent | user_consents |
| storage | Supabase Storage |
| processing | Edge Function (photo-watermark) |

---

## 3. STATES (LOCAL QUEUE)

| State | Description |
|------|-------------|
| QUEUED | captured offline, pending upload |
| UPLOADING | in-flight |
| PROCESSING | server-side watermark |
| COMPLETED | uploaded + confirmed |
| FAILED | retryable error |
| PERMANENT_FAILED | non-retryable |

---

## 4. IDENTITY & IDEMPOTENCY

Each photo MUST have:

- `client_photo_id` (UUID v4)
- `hash_sha256` (content hash)
- `rombongan_id`
- `user_id`

### RULES

```
IF server receives same client_photo_id
    → MUST return existing record (idempotent)

IF hash_sha256 duplicate within same rombongan
    → ALLOW (different moments) BUT MUST NOT overwrite
```

---

## 5. PRECONDITIONS (EDGE)

```
IF pdpl_consent != true OR photo_consent != true
    → REJECT (CONSENT_REQUIRED)

IF user NOT IN rombongan_members
    → REJECT (GROUP_ACCESS_DENIED)

IF trip state NOT IN [ACTIVE, GRACE]
    → REJECT (GROUP_EXPIRED)
```

---

## 6. CLIENT FLOW (OFFLINE-FIRST)

### Capture

```
ON capture:
    → generate client_photo_id
    → compute hash_sha256
    → store in Isar as QUEUED
```

### Sync Trigger

- app foreground
- network becomes available
- periodic background job

### Upload Loop

```
FOR each photo WHERE state IN [QUEUED, FAILED]:

    → set state = UPLOADING
    → POST /photo/upload (multipart + metadata)

    IF success
        → set state = PROCESSING (await webhook/ack)
    ELSE
        → set state = FAILED
        → schedule retry (backoff)
```

---

## 7. RETRY STRATEGY

### Exponential Backoff

```
attempt 1 → retry in 5s
attempt 2 → 30s
attempt 3 → 2m
attempt 4 → 10m
attempt 5 → 1h
>5 attempts → PERMANENT_FAILED
```

### Rules

- MUST persist attempt count locally
- MUST stop retry on 4xx (except 429)
- MUST respect `Retry-After` for 429

---

## 8. EDGE UPLOAD ENDPOINT

### Request

- multipart file
- headers: Authorization (JWT)
- body:
  - client_photo_id
  - hash_sha256
  - rombongan_id
  - captured_at (client; informational only)

### Validation

```
IF JWT invalid → 401
IF consent invalid → 403
IF membership invalid → 403
IF rate limit exceeded → 429
```

### Idempotency

```
IF client_photo_id exists
    → RETURN existing object (200)
```

### Storage

- upload original to temporary bucket `photos_raw/`
- enqueue processing job

---

## 9. WATERMARK PROCESSING (EDGE)

### Pipeline

1. fetch agency logo
2. compose watermark
3. compress to target size
4. store to `photos/`

### Circuit Breaker

```
IF processing_latency_ms > 3000 OR error_rate > 10%
    → OPEN CIRCUIT
    → SKIP watermark
    → MOVE original to final bucket
```

### Recovery

```
IF stable 5 min
    → HALF-OPEN
IF stable 10 min
    → CLOSE
```

---

## 10. SERVER ACK

After processing:

```
INSERT/UPSERT photo record:
- id
- client_photo_id
- user_id
- rombongan_id
- storage_path
- processed = true
- created_at
```

Client polling / realtime:

```
IF server confirms processed
    → set local state = COMPLETED
```

---

## 11. DUPLICATE PREVENTION

- Primary key: `client_photo_id`
- Unique index recommended on (`client_photo_id`)
- Optional secondary check: (`user_id`, `hash_sha256`, day)

---

## 12. RLS ENFORCEMENT

### SELECT

```
ALLOW IF:
    user IN rombongan_members
    OR same agency (admin/muthawif)
    OR sys_admin
```

### INSERT

```
ALLOW IF:
    auth.uid() = user_id
    AND membership valid
```

### UPDATE/DELETE

- restricted to uploader (limited) OR agency admin OR sys_admin

---

## 13. ERROR MAPPING

| Scenario | Code |
|---------|------|
| no consent | CONSENT_REQUIRED |
| not member | GROUP_ACCESS_DENIED |
| rate limit | RATE_LIMIT_EXCEEDED |
| upload fail | UPLOAD_FAILED |
| processing fail | WATERMARK_FAILED |

---

## 14. OBSERVABILITY

Track:

- photo_upload_success_rate
- upload_latency_ms
- processing_latency_ms
- queue_size
- retry_rate

Alert:

```
IF upload_success_rate < 98%
    → ALERT
```

---

## 15. AUDIT

Log:

- upload attempt
- processing result
- failures (with reason)

---

## 16. TEST SCENARIOS

- offline capture then sync
- duplicate upload (same client_photo_id)
- network drop mid-upload
- watermark failure → fallback
- rate limit handling

---

## FINAL RULE

Photo sync MUST be:

- idempotent
- retry-safe
- offline-first

Any duplicate or lost photo = DEFECT
