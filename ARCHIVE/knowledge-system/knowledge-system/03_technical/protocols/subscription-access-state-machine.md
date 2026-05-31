# Subscription Access State Machine — Haramain Pro

Version: 1.0
Status: PRODUCTION-GRADE CONTROL DOCUMENT

---

## 1. PURPOSE

Define deterministic access control for:
- B2C (lifetime purchase)
- B2B (rombongan-based access)
- Free trial

This system MUST prevent:
- access leakage
- bypass scenarios
- inconsistent state

---

## 2. SOURCE OF TRUTH

| Data | Source |
|------|--------|
| subscription_tier | profiles |
| trial_ends_at | profiles |
| rombongan membership | rombongan_members |
| trip_end_at | rombongan |

---

## 3. STATES

| State | Condition | Access |
|------|----------|--------|
| FREE_TRIAL | trial active | LIMITED |
| B2C_ACTIVE | subscription_tier == active | FULL |
| B2B_ACTIVE | in active rombongan | FULL |
| EXPIRED | none valid | BLOCKED |

---

## 4. PRIORITY RULES

```text
IF B2C_ACTIVE
    → FULL ACCESS

ELSE IF B2B_ACTIVE
    → FULL ACCESS (until trip_end_at)

ELSE IF FREE_TRIAL
    → LIMITED ACCESS

ELSE
    → BLOCKED
```

---

## 5. ENFORCEMENT RULES

### 5.1 Core Access Check

```ts
function getAccessState(profile, memberships):

  IF profile.subscription_tier == 'active'
      RETURN FULL (B2C)

  activeGroup = memberships.find(
      trip_end_at > NOW()
  )

  IF activeGroup exists
      RETURN FULL (B2B)

  IF profile.trial_ends_at > NOW()
      RETURN LIMITED

  RETURN BLOCKED
```

---

## 6. PAYWALL RULE

IF state == BLOCKED
    → MUST show paywall
    → MUST reject API (403 TRIAL_EXPIRED)

---

## 7. PANIC OVERRIDE

```text
IF user in active rombongan
    → panic ALWAYS ALLOWED
```

---

## 8. EDGE ENFORCEMENT

ALL premium endpoints:

IF access != FULL
    → REJECT (403)

---

## 9. RLS RULE

RLS MUST NOT depend on subscription.

ONLY:
- membership
- ownership

---

## 10. FAILURE SCENARIOS

| Case | Result |
|------|--------|
| expired trial | blocked |
| expired group | blocked |
| invalid membership | blocked |

---

## 11. TEST CASES

- B2C overrides B2B
- B2B ends exactly at trip_end_at
- trial cannot extend access
- no dual-state conflict

---

## FINAL RULE

Access state MUST be derived, NEVER stored.

Any stored state = defect
