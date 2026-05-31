# Milestone 1 — Foundation

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Objective
Core infrastructure: database schema, RLS policies, Supabase Edge Functions skeleton.

## Scope
- Database schema (all tables from data model)
- RLS policies (tenant isolation, group isolation)
- Basic CRUD for all entities
- Agency onboarding (PPIU registration)
- Group (rombongan) creation + PIN

## Deliverables
- [ ] All database tables created
- [ ] RLS policies enforced
- [ ] Basic CRUD API (via Supabase)
- [ ] Agency registration flow
- [ ] Rombongan creation with PIN
- [ ] Member join flow

## Dependencies
- Milestone 0 complete

## Success Criteria
- Agencies can register and verify PPIU license
- Groups can be created with PIN codes
- Jamaah can join group via PIN
- Data isolation verified between agencies

## Related
- `docs/03_technical/data-model/` — schema details
- `docs/03_technical/security/rls-model.md`
- `docs/04_execution/milestones/milestone-2-edge-middleware.md`
