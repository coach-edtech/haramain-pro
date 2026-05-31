# Staging Checklist

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Pre-release verification checklist for staging environment.

## Pre-deployment
- [ ] All GitHub Actions passing
- [ ] Database migrations applied
- [ ] Environment variables configured
- [ ] Supabase Edge Functions deployed

## Functional Testing
- [ ] User registration + OTP
- [ ] Consent flow (all categories)
- [ ] 7-day trial activation
- [ ] Group join via PIN
- [ ] Safety Pass purchase (Midtrans sandbox)
- [ ] Panic alert trigger (loopback test)
- [ ] Panic alert FCM delivery
- [ ] Panic alert Twilio fallback
- [ ] Offline maps download
- [ ] Jejak ibadah photo + watermark
- [ ] Sync on reconnect
- [ ] Group expiry behavior
- [ ] Marketing consent withdrawal

## Security Testing
- [ ] RLS isolation between agencies
- [ ] RLS isolation between groups
- [ ] No sensitive data in client logs
- [ ] Webhook signature verification
- [ ] Consent audit trail

## Performance Testing
- [ ] App launch <2s on mid-range device
- [ ] Offline map tiles <2s load
- [ ] Payment redirect <5s

## Related
- `docs/03_technical/verification/probes.md`
- `docs/03_technical/verification/production-gates.md`
