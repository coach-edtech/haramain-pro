# Production Gates

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Go/no-go criteria for production deployment.

## Gate Criteria

### 1. Security
- [ ] No critical security findings in code review
- [ ] RLS tested and verified in staging
- [ ] Webhook signature verification tested
- [ ] No secrets in code or client-side
- [ ] PDPL consent flow verified

### 2. Functionality
- [ ] Panic alert tested end-to-end
- [ ] Payment flow tested with real cards (test mode)
- [ ] Offline mode verified
- [ ] All features from `staging-checklist.md` pass

### 3. Performance
- [ ] App cold start <3s on target devices
- [ ] API response P95 <500ms
- [ ] No memory leaks in stress test

### 4. Compliance
- [ ] PDPL consent documented
- [ ] Data deletion SLA verified
- [ ] Audit trail functional

### 5. Monitoring
- [ ] Crashlytics configured
- [ ] Error tracking active
- [ ] Health probes deployed

## Sign-off
Requires sign-off from:
1. Tech Lead
2. Product Owner
3. Compliance (if applicable)

## Related
- `docs/03_technical/verification/staging-checklist.md`
- `docs/04_execution/release/go-no-go.md`
