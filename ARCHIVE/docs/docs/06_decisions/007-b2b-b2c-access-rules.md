# 007 — B2B/B2C Access Rules

> Owner: OpenClaw
> Status: Approved
> Note: Starter content — based on master doc direction.

## Decision
Separate access rules for B2C (individual Jamaah) and B2B (agency-managed groups) with clear RLS boundaries.

## Access Matrix

### B2C (Direct Jamaah)
| Action | Requires |
|--------|---------|
| Create account | Phone OTP |
| Joinrombongan | PIN code |
| Buy Safety Pass | Midtrans payment |
| Trigger panic | Safety Pass active |
| View offline maps | Safety Pass active |
| Submit jejak ibadah | Safety Pass active |

### B2B (Agency/PPIU)
| Action | Requires |
|--------|---------|
| Register agency | PPIU license verification |
| Createrombongan | Agency subscription |
| Invite Jamaah | Agency license |
| B2B bypass invite | Agency + no PIN needed |
| Manage passenger list | Agency access |
| Volume license purchase | B2B pricing |

## RLS Enforcement

### Tenant Isolation (Agency Level)
- Agencies can only see their ownrombongans
- Jamaah assigned to agency'srombongan only
- Cross-agency data invisible

### Group Isolation (Rombongan Level)
- Jamaah in Rombongan A cannot see Rombongan B data
- Panic alerts scoped to same rombongan
- Jejak ibadah scoped to own account

### User Isolation (Individual Level)
- Personal data visible only to self
- Marketing consent per-user (RLS enforced)
- Deletion request scoped to own data

## Related
- `docs/03_technical/security/rls-model.md`
- `docs/03_technical/security/tenant-isolation.md`
- `docs/05_features/b2b-volume-licensing/`
- `docs/05_features/rombongan-group-management/`
