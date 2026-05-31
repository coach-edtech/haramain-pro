# PDPL Data Lifecycle

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Detailed specification for PDPL (Indonesian Personal Data Protection Law) compliance — data lifecycle management.

## Consent Categories (MVP)

### Core Service Consents
Required for basic app functionality.

| Category | Data Type | Purpose | Default |
|----------|-----------|---------|---------|
| Location | GPS coordinates | Panic alert, GPS tracking | ❌ Off |
| Media | Photos/Videos | Jejak ibadah documentation | ❌ Off |
| Notification | Device token | Push alerts | ❌ Off |

### Separate Consent
Not required for core service.

| Category | Data Type | Purpose | Default |
|----------|-----------|---------|---------|
| Marketing | Contact info | Alumni broadcast | ❌ Off |

### Key Rule
**No passport or biometric data collected in MVP.**

## Consent Flow

```
1. User installs app
2. Onboarding → consent screen
3. Each category explained individually
4. User toggles each ON/OFF
5. User confirms → consent recorded
6. If any core consent OFF → features using that data disabled
7. Trial starts automatically
```

## Withdrawal Flow

### User-Initiated
1. User opens Settings → Privacy
2. Taps category to withdraw
3. Confirmation dialog
4. Server records `withdrawn_at`
5. Features immediately affected

### SLA
- Withdrawal processed: **immediately**
- Effect on data: anonymized within **24 hours**

## Deletion Request Flow

### User-Initiated
1. User submits deletion request (Settings → Privacy → Delete Account)
2. Server creates `deletion_request` record
3. Background job processes within **24 hours**
4. All personal data hard deleted
5. Backup purge (per retention schedule)
6. Confirmation email sent

### Data Deleted
- User profile
- Location history
- Jejak ibadah entries
- Consent records
- All related data

### Data Retained (Post-Deletion)
- Anonymized analytics
- Audit logs (no PII)

## GPS Data Retention

### During Trip
- Collected continuously when `consent_location = true`
- Stored in `location_history` table
- Visible to muthawif (same group only)

### Post-Trip (0–7 days)
- All location data retained
- Available for recovery

### Post-Trip (7–30 days)
- Location data aggregated (hourly resolution)
- Full resolution deleted

### Post-Trip (30+ days)
- All location history **purged**
- If user withdraws location consent: immediate anonymization

## Retention Summary Table

| Data Type | During Trip | 0–7 Days Post | 7–30 Days | 30+ Days |
|-----------|------------|---------------|-----------|----------|
| Location | ✅ Full | ✅ Full | ⚠️ Aggregated | ❌ Purged |
| Photos | ✅ Stored | ✅ Stored | ✅ Stored | User choice |
| Consent records | ✅ Lifetime | ✅ Lifetime | ✅ Lifetime | ❌ Anonymized |
| Account data | ✅ Active | ✅ Active | ✅ Active | ❌ Deleted |

## Audit Trail

### Logged Events
- Consent granted (timestamp, IP, user agent)
- Consent withdrawn (timestamp)
- Deletion requested (timestamp)
- Deletion completed (timestamp)

### Retention
- Audit logs: **permanent** (regulatory requirement)
- Stored separately from user data

## Related
- `docs/02_product/compliance/pdpl-requirements.md`
- `docs/03_technical/data-model/consent-and-deletion.md`
- `docs/05_features/pdpl-consent/`
