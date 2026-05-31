# Consent Matrix — Haramain Pro

Version: 1.0
Status: PRODUCTION-GRADE CONTROL DOCUMENT

---

## 1. PURPOSE

Define deterministic, enforceable consent system for:
- PDPL compliance
- Feature access control
- Data processing permissions
- Consent lifecycle & revocation

---

## 2. CONSENT TYPES

### 2.1 Core PDPL Consent (MANDATORY)

| Consent | Column | Required |
|--------|--------|---------|
| PDPL General | pdpl_consent_granted | YES |
| Location | location_consent_granted | YES |
| Photo | photo_consent_granted | YES |
| Notification | notification_consent_granted | YES |

---

### 2.2 Marketing Consent (SEPARATE)

| Consent | Column | Required |
|--------|--------|---------|
| Marketing | marketing_consent_granted | OPTIONAL |

RULE:
- MUST be stored separately
- MUST NOT affect core system access

---

## 3. SOURCE OF TRUTH

| Data | Source |
|------|--------|
| Core consent | user_consents table |
| Marketing | marketing_preferences table |

---

## 4. ENFORCEMENT RULES

### 4.1 Global Rule

IF pdpl_consent_granted != true
    → REJECT ALL FEATURES
    → REDIRECT onboarding

---

### 4.2 Feature Mapping

IF feature == 'gps' AND location_consent_granted != true
    → REJECT (CONSENT_REQUIRED)

IF feature == 'camera' AND photo_consent_granted != true
    → REJECT (CONSENT_REQUIRED)

IF feature == 'notification' AND notification_consent_granted != true
    → REJECT (CONSENT_REQUIRED)

---

## 5. CONSENT WITHDRAWAL

IF user withdraws consent
    → SET all flags = false
    → TRIGGER data purge
    → LOG audit

---

## 6. EDGE ENFORCEMENT

ALL Edge Functions MUST validate consent BEFORE processing.

---

## 7. DATABASE RULES (RLS)

Users:
    CAN update own consent ONLY

MUST NOT:
    set consent true without flow

---

## 8. FAILURE SCENARIOS

| Condition | Result |
|----------|--------|
| Missing consent | 403 |
| Revoked consent | feature disabled |
| Version mismatch | 403 |

---

## 9. AUDIT

Every change MUST log:
- actor_id
- consent_type
- previous
- new
- timestamp

---

## 10. FINAL RULE

Consent is a HARD GATE.

ANY bypass = CRITICAL DEFECT
