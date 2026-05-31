# 002 — Backend: Supabase

> Owner: OpenClaw
> Status: Approved
> Note: Starter content — based on master doc direction.

## Decision
Use **Supabase** as the backend-as-a-service platform for Haramain Pro.

## Rationale
- PostgreSQL with **Row Level Security (RLS)** for multi-tenant isolation
- Built-in **Authentication** (email, phone, OTP)
- **Realtime** subscriptions for live updates (subscription unlock, group changes)
- **Edge Functions** for serverless backend logic
- Indonesian data residency available
- Lower operational overhead vs self-hosted

## Key Supabase Features Used
| Feature | Purpose |
|---------|---------|
| Auth | User registration/login (phone OTP) |
| Database | All structured data (users, subscriptions, rombongans) |
| RLS | Multi-tenant isolation (agency, group, user level) |
| Realtime | Subscription state sync, push triggers |
| Edge Functions | Payment webhook handling, sync logic |
| Storage | Media uploads (watermarked photos) |

## Alternatives Considered
- **Firebase**: Less flexible RLS, Google-centric
- **Custom Node.js + Postgres**: Higher operational cost
- **Appwrite**: Smaller ecosystem, less mature realtime

## Related
- `docs/03_technical/architecture/system-topology.md`
- `docs/03_technical/security/rls-model.md`
