# Feature Brief: Onboarding + PDPL Consent

_Feature ID: F-01_
_Status: Draft_
_Date: 2026-04-04_
_Author: OpenClaw (extracted from PRD)_

---

## 1. Problem Statement

Saudi PDPL (Saudi Data Protection Law) requires explicit opt-in consent for location tracking and sensitive biometric/passport data. Users must also have a clear mechanism to withdraw consent and request data deletion at any time. Without this, the app cannot legally operate in Saudi Arabia.

---

## 2. Goal

Force all new B2C users through a mandatory onboarding flow that:
- Captures explicit PDPL consent before any premium feature access
- Provides a clear, accessible way to withdraw consent and delete data
- Complies with Saudi SDAIA regulations

---

## 3. User Flow

```
New User opens app
       ↓
Splash / Welcome Screen
       ↓
Explain why location & data is needed (PDPL notice)
       ↓
[ ] Consent for location tracking (required)
       ↓
[ ] Consent for passport/biometric data processing (optional)
       ↓
[ ] Accept Terms & Conditions
       ↓
Register / Login
       ↓
Home Screen
```

**PDPL Withdrawal Flow:**
```
Settings → Privacy & Data → Withdraw Consent
       ↓
Confirmation modal (impact explanation)
       ↓
User confirms → Local data purge → Server data purge
       ↓
App restarts → Shows PDPL consent onboarding again
```

---

## 4. Scope

### In Scope
- PDPL consent modal (mandatory, cannot be skipped)
- Location tracking consent toggle
- Passport/biometric data consent (optional)
- Data deletion request flow (local + server)
- Settings menu PDPL management interface
- 7-day free trial trigger

### Out of Scope
- Full GDPR-style data export (PDF report)
- Manual data deletion by admin (covered in separate admin feature)
- Multi-language consent UI (Phase 1: Indonesian only)

---

## 5. Acceptance Criteria

- [ ] User cannot access any screen beyond consent modal on first launch
- [ ] Location tracking consent is REQUIRED to proceed
- [ ] Passport/biometric consent is OPTIONAL
- [ ] "Withdraw Consent" immediately purges local data
- [ ] Server-side deletion request is triggered within 24 hours
- [ ] After withdrawal, app forces user back to consent screen on next launch
- [ ] Trial countdown starts AFTER consent is granted
- [ ] Withdrawal flow is accessible from Settings without requiring support ticket

---

## 6. Edge Cases

| Case | Handling |
|------|----------|
| User denies location consent | Block access, show explanation, allow retry |
| User partially completes consent, exits | Resume from last incomplete step |
| Network unavailable during server deletion request | Queue request, retry on next connectivity |
| Admin manually extends trial after consent withdrawal | Re-prompt consent flow on next session |

---

## 7. Dependencies

- Supabase Auth (registration, JWT)
- Supabase Database (profile.pdplConsentGranted, pdplConsentTimestamp)
- Local storage purge mechanism (Flutter SecureStorage / SharedPreferences)
- Edge function for server-side deletion (future)

---

## 8. Technical Notes

- `profile.pdplConsentGranted: boolean` must be `true` before any feature access
- `profile.pdplConsentTimestamp: timestamp` records when consent was given
- Local SQLite / SecureStorage must be wiped on withdrawal
- Backend must support "delete on request" for PDPL compliance

---

## 9. Related PRD References

- PRD-16: Mandatory onboarding opt-in consent
- PRD-17: Settings menu consent withdrawal
- PRD-25: Auto-purge GPS history 30 days post-trip
- PRD-76-80: PDPL Consent Reset (Verify feature for testing)

---

## 10. Questions Open

1. Should passport/biometric data collection happen during onboarding or later (when needed)?
2. Is there a specific SDAIA-required wording for the consent notice?
3. Should the deletion flow also revoke FCM tokens?

