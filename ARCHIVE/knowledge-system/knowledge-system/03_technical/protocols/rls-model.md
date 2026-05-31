# RLS Model — Haramain Pro

Version: 1.0
Status: PRODUCTION-GRADE CONTROL DOCUMENT

---

## 1. PURPOSE

Define deterministic Row Level Security (RLS) enforcement for:
- Multi-tenant isolation
- User data protection
- Cross-role access control

RLS is the FINAL enforcement layer. Application code is NOT trusted.

---

## 2. CORE PRINCIPLES

1. ALL tables MUST enable RLS
2. ALL access MUST be validated using JWT claims
3. NO cross-tenant access unless sys_admin
4. DENY by default

---

## 3. JWT DEPENDENCY

RLS uses:

- auth.uid()
- auth.jwt()->>'role'
- auth.jwt()->>'agency_id'
- auth.jwt()->>'is_admin'

---

## 4. TENANT ISOLATION

RULE:

IF resource.agency_id != jwt.agency_id
    AND is_admin != true
        → REJECT

---

## 5. TABLE POLICIES

### profiles

SELECT:
    auth.uid() = id
    OR is_admin = true

UPDATE:
    auth.uid() = id

---

### rombongan

SELECT:
    user IN rombongan_members
    OR agency match
    OR is_admin

---

### rombongan_members

SELECT:
    self OR same agency

INSERT:
    travel_admin OR muthawif

---

### user_consents

SELECT:
    self only

UPDATE:
    self only

---

### transactions

ALL access:
    Edge Function only

---

### gps_tracks

SELECT:
    self OR muthawif of same group

INSERT:
    service role only

DELETE:
    pg_cron only

---

## 6. ENFORCEMENT RULES

IF no matching policy
    → DENY (default)

---

## 7. FAILURE SCENARIOS

| Case | Result |
|------|--------|
| Cross tenant access | blocked |
| Unauthorized update | blocked |
| Missing JWT | blocked |

---

## 8. SECURITY RULES

- NEVER bypass RLS except service role
- Service role ONLY in Edge Functions
- All policies MUST be tested

---

## 9. VALIDATION

System valid ONLY if:

- No cross-tenant leak
- All queries filtered
- Unauthorized access returns empty

---

## FINAL RULE

RLS is NON-NEGOTIABLE.

Any bypass = CRITICAL SECURITY FAILURE
