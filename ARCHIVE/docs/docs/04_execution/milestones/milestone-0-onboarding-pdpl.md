# Milestone 0 — Onboarding + PDPL Consent

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Objective
Implement user onboarding and PDPL-compliant consent capture before any data processing.

## Scope
- Phone OTP authentication
- Onboarding UI/UX
- PDPL consent dialog (location, media, notification, marketing)
- Consent storage and RLS enforcement
- 7-day trial auto-activation

## Deliverables
- [ ] Supabase Auth (phone OTP) configured
- [ ] Flutter onboarding screens
- [ ] Consent dialog (4 categories)
- [ ] `consents` table with RLS
- [ ] Trial subscription auto-creation
- [ ] Consent audit trail

## Dependencies
- Supabase project setup
- Flutter project initialization

## Success Criteria
- User can sign up with phone OTP
- All 4 consent categories displayed
- Marketing consent separated from core
- No data processed before consent
- Trial starts automatically after consent

## Related
- `docs/05_features/pdpl-consent/`
- `docs/05_features/marketing-consent/`
- `docs/04_execution/milestones/milestone-1-foundation.md`
