# Release Criteria

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Criteria for releasing each milestone.

## General Criteria (All Releases)
- [ ] All P0 bugs resolved
- [ ] Staging checklist passed
- [ ] Security review passed
- [ ] No regression in existing features
- [ ] Monitoring and alerting active
- [ ] Rollback plan documented

## Milestone-Specific

### M0 (Onboarding + PDPL)
- [ ] Consent flow verified with legal
- [ ] Audit trail functional
- [ ] No data processed before consent

### M1 (Foundation)
- [ ] RLS isolation tested
- [ ] No cross-tenant data leakage

### M2 (Edge + Middleware)
- [ ] Payment webhook tested end-to-end
- [ ] Panic alert delivery confirmed
- [ ] Twilio fallback verified

### M3 (Offline Engine)
- [ ] Offline launch verified
- [ ] Sync success >95%
- [ ] Storage circuit breaker tested

### M4 (User Journeys)
- [ ] Full E2E journey tested
- [ ] All personas verified

### M5 (DX + Validation)
- [ ] All probes passing
- [ ] Performance benchmarks met
- [ ] Production ready

## Related
- `docs/04_execution/release/go-no-go.md`
- `docs/03_technical/verification/production-gates.md`
