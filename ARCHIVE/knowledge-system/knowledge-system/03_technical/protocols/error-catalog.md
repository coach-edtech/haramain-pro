# Error Catalog — Haramain Pro

Version: 1.0
Status: PRODUCTION-GRADE CONTROL DOCUMENT

---

## 1. PURPOSE

Define a deterministic, centralized error system used across:
- Client (Flutter)
- Edge Functions
- Database (RLS / constraints)

All components MUST use these codes. No custom/adhoc errors allowed.

---

## 2. ERROR STRUCTURE

```json
{
  "code": "ERROR_CODE",
  "http_status": 400,
  "message_id": "localized_key",
  "retryable": false,
  "metadata": {}
}
```

RULES:
- `code` is canonical (UPPER_SNAKE_CASE)
- `http_status` MUST be standard HTTP
- `message_id` maps to i18n (Bahasa Indonesia default)
- `retryable` drives client behavior

---

## 3. GLOBAL ERROR CODES

### 3.1 AUTH & SESSION

| Code | HTTP | Retry | Description |
|---|---|---|---|
| SESSION_EXPIRED | 401 | true | JWT missing/expired/invalid |
| INVALID_TOKEN | 401 | false | Signature invalid |
| ADMIN_REQUIRED | 403 | false | Admin route without privilege |
| UNAUTHORIZED_ROLE_CHANGE | 403 | false | Invalid role upgrade |

---

### 3.2 CONSENT

| Code | HTTP | Retry | Description |
|---|---|---|---|
| CONSENT_REQUIRED | 403 | false | Required consent not granted |
| CONSENT_VERSION_OUTDATED | 403 | false | Consent needs re-approval |
| MARKETING_OPT_OUT | 200 | false | User excluded from marketing |

---

### 3.3 ACCESS / PAYWALL

| Code | HTTP | Retry | Description |
|---|---|---|---|
| TRIAL_EXPIRED | 403 | false | Trial ended |
| GROUP_EXPIRED | 410 | false | Trip/group ended |
| GROUP_ACCESS_DENIED | 403 | false | Not a member |
| TENANT_VIOLATION | 403 | false | Cross-tenant access |

---

### 3.4 RLS / DATABASE

| Code | HTTP | Retry | Description |
|---|---|---|---|
| RLS_FORBIDDEN | 403 | false | Blocked by RLS |
| RECORD_NOT_FOUND | 404 | false | No matching record |
| CONSTRAINT_VIOLATION | 400 | false | DB constraint failed |

---

### 3.5 RATE LIMIT

| Code | HTTP | Retry | Description |
|---|---|---|---|
| RATE_LIMIT_EXCEEDED | 429 | true | Too many requests |
| PANIC_THROTTLED | 429 | true | Panic cooldown active |

Headers:
- Retry-After: seconds

---

### 3.6 PANIC / SAFETY

| Code | HTTP | Retry | Description |
|---|---|---|---|
| MEMBER_NOT_FOUND | 403 | false | User not in group |
| GROUP_NOT_ACTIVE | 410 | false | Group inactive |
| FCM_UNAVAILABLE | 200 | true | Fallback will be used |
| PANIC_DISPATCH_FAILED | 500 | true | Both layers failed |

---

### 3.7 PAYMENT (MIDTRANS)

| Code | HTTP | Retry | Description |
|---|---|---|---|
| INVALID_SIGNATURE | 403 | false | Webhook signature mismatch |
| PAYMENT_FAILED | 402 | true | Transaction failed |
| ALREADY_PROCESSED | 200 | false | Idempotent replay |

---

### 3.8 MEDIA

| Code | HTTP | Retry | Description |
|---|---|---|---|
| UPLOAD_FAILED | 500 | true | Storage/upload error |
| WATERMARK_FAILED | 200 | true | Fallback to original |
| FILE_TOO_LARGE | 400 | false | Exceeds limits |

---

### 3.9 LOCATION

| Code | HTTP | Retry | Description |
|---|---|---|---|
| LOCATION_PERMISSION_DENIED | 403 | false | OS-level denial |
| GPS_UNAVAILABLE | 503 | true | No fix available |

---

## 4. CLIENT BEHAVIOR RULES

```ts
IF http_status == 401
  → redirect('/login')

IF code == 'CONSENT_REQUIRED'
  → redirect('/onboarding')

IF code == 'RATE_LIMIT_EXCEEDED'
  → wait(Retry-After)

IF retryable == true
  → exponential_backoff()
```

---

## 5. EDGE FUNCTION RULES

- MUST return structured error object
- MUST NOT leak internal stack traces
- MUST log `code`, `actor_id`, `ip`

---

## 6. DATABASE MAPPING

- RLS violations → map to RLS_FORBIDDEN
- NOT FOUND → RECORD_NOT_FOUND
- constraint error → CONSTRAINT_VIOLATION

---

## 7. AUDIT

Log all security-relevant errors:
- INVALID_SIGNATURE
- UNAUTHORIZED_ROLE_CHANGE
- TENANT_VIOLATION
- RATE_LIMIT_EXCEEDED (burst)

---

## 8. TEST CRITERIA

System is VALID if:
- All layers return same `code`
- No raw errors exposed
- Retry behavior consistent

---

## FINAL RULE

Error Catalog is the SINGLE SOURCE OF TRUTH for all system errors.

Any deviation = DEFECT
