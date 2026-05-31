# Payment Webhook Flow — Haramain Pro

Version: 1.0
Status: PRODUCTION-GRADE CONTROL DOCUMENT

---

## 1. PURPOSE

Define a secure, idempotent, and fraud-resistant payment processing system using Midtrans webhook.

System MUST guarantee:
- no double processing
- no fake webhook acceptance
- consistent subscription activation

---

## 2. SOURCE OF TRUTH

| Data | Source |
|------|--------|
| transaction | transactions table |
| webhook payload | Midtrans |
| signature | Midtrans server key |
| subscription update | profiles |

---

## 3. ENTRY POINT

ONLY entry:

Edge Function:
→ midtrans-webhook

NO direct client access allowed

---

## 4. SIGNATURE VALIDATION (MANDATORY)

```
IF signature != expected_sha512
    → REJECT (INVALID_SIGNATURE)
    → LOG security event
```

RULE:
- MUST use server_key from secure vault
- MUST NOT use client-side key

---

## 5. IDEMPOTENCY (CRITICAL)

```
IF transaction.status == 'settlement'
    → RETURN (ALREADY_PROCESSED)
```

RULE:
- order_id MUST be unique
- processing MUST be safe to repeat

---

## 6. PROCESSING FLOW

### Step 1 — Validate Signature
### Step 2 — Fetch transaction by order_id
### Step 3 — Check idempotency
### Step 4 — Process based on status

---

## 7. STATUS HANDLING

### settlement

```
→ UPDATE transactions.status = settlement
→ UPDATE profiles.subscription_tier = active
→ LOG success
```

---

### pending

```
→ UPDATE transactions.status = pending
→ NO subscription change
```

---

### expire / cancel

```
→ UPDATE transactions.status
→ DO NOT activate subscription
```

---

## 8. RACE CONDITION PROTECTION

```
USE DB transaction + row lock

SELECT ... FOR UPDATE
```

RULE:
- MUST prevent double update
- MUST be atomic

---

## 9. FAILURE SCENARIOS

| Case | Result |
|------|--------|
| invalid signature | reject |
| duplicate webhook | ignore |
| DB failure | retry |
| unknown order_id | log + reject |

---

## 10. ERROR MAPPING

| Scenario | Code |
|---------|------|
| invalid signature | INVALID_SIGNATURE |
| already processed | ALREADY_PROCESSED |
| payment failed | PAYMENT_FAILED |

---

## 11. AUDIT

Log:

- order_id
- status
- actor (system)
- timestamp

---

## 12. OBSERVABILITY

Track:

- webhook_success_rate
- duplicate_rate
- processing_latency

Alert:

```
IF webhook_failure_rate > 5%
    → ALERT
```

---

## 13. SECURITY RULES

- NEVER trust incoming payload without signature validation
- NEVER update subscription without settlement
- NEVER expose webhook endpoint publicly without validation

---

## 14. TEST SCENARIOS

- duplicate webhook
- invalid signature
- delayed webhook
- concurrent webhook

---

## FINAL RULE

Webhook processing MUST be:

- idempotent
- atomic
- secure

Any double charge or missed activation = CRITICAL DEFECT
