# Trip Lifecycle — Haramain Pro

Version: 1.0
Status: PRODUCTION-GRADE CONTROL DOCUMENT

---

## 1. PURPOSE

Define deterministic lifecycle for a rombongan (trip) that governs:
- access window (B2B)
- GPS collection & TTL
- panic eligibility
- feature activation/deactivation

All states MUST be explicit and time-bound.

---

## 2. SOURCE OF TRUTH

| Data | Source |
|------|--------|
| rombongan_id | rombongan.id |
| trip_start_at | rombongan.trip_start_at |
| trip_end_at | rombongan.trip_end_at |
| is_active (derived) | NOW() between start & end |
| members | rombongan_members |
| agency | rombongan.agency_id |

---

## 3. STATES (EXPLICIT)

| State | Condition | Description |
|------|-----------|-------------|
| DRAFT | created, start null | Not published |
| SCHEDULED | NOW() < start | Prepared, not started |
| ACTIVE | start <= NOW() < end | Trip running |
| GRACE | NOW() >= end AND < end + 24h | Post-trip limited window |
| ENDED | NOW() >= end + 24h | Fully ended |

---

## 4. STATE TRANSITIONS

```
DRAFT → SCHEDULED → ACTIVE → GRACE → ENDED
```

### RULES

- MUST NOT skip states
- MUST be time-driven (server time only)
- is_active MUST be derived, NOT stored

---

## 5. ENFORCEMENT RULES

### 5.1 Active Check

```
IF NOW() >= trip_start_at
  AND NOW() < trip_end_at
    → ACTIVE
```

### 5.2 Grace Window

```
IF NOW() >= trip_end_at
  AND NOW() < trip_end_at + 24h
    → GRACE
```

### 5.3 Ended

```
IF NOW() >= trip_end_at + 24h
    → ENDED
```

---

## 6. ACCESS CONTROL BY STATE

| Feature | ACTIVE | GRACE | ENDED |
|--------|--------|-------|-------|
| Premium access (B2B) | FULL | LIMITED | BLOCKED |
| Panic | ALLOWED | BLOCKED | BLOCKED |
| GPS tracking | ON | OFF | OFF |
| Photo upload | ALLOWED | ALLOWED (read-only sync) | BLOCKED |
| Group broadcast | ALLOWED | BLOCKED | BLOCKED |

---

## 7. SUBSCRIPTION INTEGRATION

```
IF ACTIVE AND member == true
    → B2B_ACTIVE

IF GRACE
    → DO NOT extend subscription
```

RULE:
- Trip MUST NOT extend beyond end time
- No implicit extension

---

## 8. GPS & DATA POLICY

### GPS Tracking

```
IF state != ACTIVE
    → STOP GPS collection
```

### TTL

- gps_tracks: 30 days
- enforced via pg_cron

---

## 9. PANIC INTEGRATION

```
IF state == ACTIVE
    → ALLOW panic

ELSE
    → REJECT (GROUP_EXPIRED)
```

---

## 10. EDGE ENFORCEMENT

All Edge Functions MUST validate:

- trip state
- membership
- time window

```
IF state != ACTIVE
    → REJECT
```

---

## 11. RLS INTEGRATION

RLS MUST enforce:

- access only if member
- rombongan_id match

RLS MUST NOT rely on state directly
(state is enforced at Edge)

---

## 12. FAILURE SCENARIOS

| Case | Result |
|------|--------|
| trip_end_at in past | BLOCKED |
| user not member | REJECT |
| invalid dates | REJECT (CONSTRAINT_VIOLATION) |

---

## 13. CONSTRAINTS

Database MUST enforce:

- trip_start_at < trip_end_at
- duration reasonable (e.g., < 60 days)

---

## 14. AUDIT

Log:

- trip created
- trip updated
- state transitions (derived logs)

---

## 15. TEST CASES

- transition at exact boundary time
- GPS stops immediately at end
- panic blocked after end
- grace window does not extend access

---

## FINAL RULE

Trip lifecycle is TIME-DRIVEN and IMMUTABLE in behavior.

Any manual override = DEFECT unless via sys_admin audit path.
