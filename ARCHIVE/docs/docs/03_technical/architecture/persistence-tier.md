# Persistence Tier

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Data persistence architecture — Supabase (cloud) and Isar (local).

## Cloud Persistence (Supabase)

### PostgreSQL
- All structural data: users, subscriptions, rombongans, passengers
- RLS enforced at database level
- Multi-tenant isolation

### Tables (High-Level)
| Table | Purpose |
|-------|---------|
| `users` | Auth + profile |
| `subscriptions` | Safety Pass records |
| `rombongans` | Group entities |
| `rombongan_members` | User-to-group mapping |
| `consents` | PDPL consent records |
| `jejak_ibadah` | Spiritual activity logs |
| `panic_alerts` | Alert history |
| `agency` | B2B tenant records |

### RLS Policies
- Tenant isolation: agencies see only their data
- Group isolation: Jamaah see only theirrombongan
- User isolation: personal data private

## Local Persistence (Isar)

### Isar Collections
| Collection | Purpose |
|-----------|---------|
| `User` | Cached user profile |
| `Subscription` | Local subscription state |
| `Rombongan` | Cached group data |
| `JejakIbadahEntry` | Queued spiritual logs |
| `LocationPoint` | GPS queue |
| `OfflineTile` | Map tile metadata |

### Sync Strategy
- **Read**: Local cache → Supabase (stale-while-revalidate)
- **Write**: Isar queue → Supabase on reconnect
- **Conflict**: Timestamp-based, server-wins for shared data

## Storage Limits
- Isar: No hard limit (managed by circuit breaker)
- Offline tiles: 300MB max
- Queued photos: Compressed to 80% quality, max 2MB each

## Related
- `docs/03_technical/data-model/local-storage.md`
- `docs/03_technical/security/rls-model.md`
