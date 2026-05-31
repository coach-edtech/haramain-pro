# Panic Flow — Haramain Pro

Version: 1.0
Status: PRODUCTION-GRADE CONTROL DOCUMENT

---

## 1. PURPOSE

Define a deterministic, multi-layer panic alert system with:
- guaranteed dispatch attempt
- fallback mechanisms
- abuse protection (throttle)
- observability & audit

This flow is SAFETY-CRITICAL.

---

## 2. SOURCE OF TRUTH

| Data | Source |
|------|--------|
| membership | rombongan_members |
| trip window | rombongan.trip_end_at |
| throttle | panic_alerts.created_at |
| muthawif target | profiles (device_fcm_token) |

---

## 3. PRECONDITIONS

```
IF user NOT IN rombongan_members
    → REJECT (MEMBER_NOT_FOUND)

IF rombongan.trip_end_at <= NOW()
    → REJECT (GROUP_EXPIRED)
```

---

## 4. THROTTLE (CLIENT + SERVER)

WINDOW: 5 minutes

### Client

```
IF now - last_triggered < 5min
    → REJECT (PANIC_THROTTLED)
```

### Server (authoritative)

```
IF last_panic.created_at within 5min
    → REJECT (PANIC_THROTTLED)
```

---

## 5. DISPATCH PIPELINE

### Step 1 — Validate

- membership valid
- trip active
- throttle passed

### Step 2 — Resolve Target

Fetch muthawif:
- id
- device_fcm_token
- phone_number

---

## 6. LAYERED DELIVERY

### LAYER 1 — FCM (PRIMARY)

```
SEND FCM Critical Alert

IF success
    → RECORD (layer = FCM)
    → RETURN success
```

---

### LAYER 2 — TWILIO (FALLBACK)

Triggered IF:
- no FCM token
- FCM failure
- timeout

```
CALL Twilio voice alert

→ RECORD (layer = TWILIO)
→ RETURN success
```

---

### LAYER 3 — FAILURE

```
IF FCM AND TWILIO fail
    → RECORD failure
    → RETURN (PANIC_DISPATCH_FAILED)
```

---

## 7. CIRCUIT BREAKER

### FCM

```
IF failure_rate > 20% (1 min)
    → OPEN circuit
    → ROUTE all to Twilio
```

### Recovery

```
IF success_rate > 98% (5 min)
    → HALF-OPEN
```

---

## 8. DATA RECORD

Insert into panic_alerts:

- user_id
- rombongan_id
- lat
- lng
- dispatched_at
- delivery_layer
- fallback_used
- failure_reason

---

## 9. EDGE ENFORCEMENT

ALL panic requests MUST pass:

- auth validation
- membership validation
- throttle validation

---

## 10. RLS RULE

Users:
    CAN insert own panic only

Admin:
    CAN read all

---

## 11. ERROR MAPPING

| Case | Code |
|------|------|
| not member | MEMBER_NOT_FOUND |
| group expired | GROUP_EXPIRED |
| throttle | PANIC_THROTTLED |
| full failure | PANIC_DISPATCH_FAILED |

---

## 12. OBSERVABILITY

Track:

- panic_trigger_count
- panic_success_rate
- panic_fallback_rate
- dispatch_latency_ms

ALERT:

```
IF panic_success_rate < 95%
    → CRITICAL
```

---

## 13. AUDIT

Every trigger MUST log:

- actor_id
- rombongan_id
- timestamp
- result

---

## 14. TEST SCENARIOS

- no membership → reject
- expired trip → reject
- FCM fail → Twilio used
- both fail → error
- throttle enforced

---

## FINAL RULE

Panic MUST attempt delivery at least once.

Failure to dispatch = CRITICAL INCIDENT.
