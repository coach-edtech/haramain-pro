# PDPL Requirements

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Personal Data Protection Law (Indonesia) compliance requirements for Haramain Pro.

## Consent Categories (MVP)

### Required Consents (Core Service)
| Category | Purpose | Data Type |
|----------|---------|-----------|
| Location | GPS tracking, safety features | Coordinates, timestamps |
| Push Notification | Panic alerts, group updates | Device token |
| Media (Photos) | Jejak ibadah photo logging | Image files |

### Optional Consent (Separate)
| Category | Purpose | Data Type |
|----------|---------|-----------|
| Marketing | Alumni broadcast, promotions | Contact info |

## Key Principles

### 1. Explicit Consent Required
- No data processing before consent
- Consent dialogs separate per category
- Users can decline optional consents
- Declining core consents limits functionality (not error)

### 2. No Sensitive Data in MVP
- ❌ Passport data
- ❌ Biometric data
- ❌ Financial data (beyond payment receipt)
- Only: phone, name, location during trip

### 3. Consent Withdrawal
- Users can revoke consent at any time
- Revocation processed within 24 hours
- Partial withdrawal allowed (e.g., revoke location but keep notification)

### 4. Data Deletion
- Deletion request triggers full account deletion
- All personal data removed within 24 hours
- Backups purged per retention schedule
- Deletion confirmation sent to user

### 5. Data Retention
| Data Type | Retention | After trip_end_at |
|-----------|-----------|-------------------|
| Location history | Duration of trip | Deleted after 30 days |
| Photos (Jejak) | Until user deletes | User-controlled |
| Consent records | Lifetime | Audit requirement |
| Account data | Until deletion | On-demand |

## Consent Capture Flow
1. Onboarding → consent screen
2. Each category explained with purpose
3. Toggle ON/OFF per category
4. Confirm selection
5. Stored in `consents` table with timestamp
6. Realtime sync to RLS

## Related
- `docs/05_features/pdpl-consent/`
- `docs/03_technical/data-model/consent-and-deletion.md`
