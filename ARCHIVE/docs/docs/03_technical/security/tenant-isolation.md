# Tenant Isolation

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Multi-tenant isolation strategy for agencies (B2B).

## Isolation Layers

### Layer 1: Database (RLS)
Each agency's data isolated via RLS policies on `rombongans`, `rombongan_members`, `profiles`.

```sql
-- Agency A cannot see Agency B's groups
CREATE POLICY "agency_isolation"
ON rombongans
FOR ALL
USING (agency_id IN (
  SELECT agency_id FROM profiles
  WHERE id = auth.uid()
  AND role IN ('travel_admin', 'sys_admin')
));
```

### Layer 2: Application
Supabase Edge Functions validate tenant context:
```typescript
// Edge function: get-group-members
const user = await getUserFromToken(token);
const group = await getGroup(groupId);

// Validate user belongs to group's agency
if (group.agencyId !== user.agencyId) {
  throw new Error('TENANT_FORBIDDEN');
}
```

### Layer 3: API Keys
- Each agency does NOT get separate API keys
- Users authenticate via Supabase Auth
- RLS enforced on all queries

## Data Isolation Matrix

| Data Type | Isolation Scope |
|-----------|---------------|
| Agency profile | agency_id |
| Rombongan | agency_id |
| Jamaah membership | rombongan_id |
| Panic alerts | rombongan_id |
| Jejak ibadah | user_id (personal) |
| Subscriptions | user_id (personal) |

## Anti-Patterns Prevented
- ❌ Agency A accessing Agency B'srombongan
- ❌ Jamaah from Group A viewing Group B's pilgrims
- ❌ Panic alerts leaking to unauthorized parties

## Related
- `docs/03_technical/security/rls-model.md`
- `docs/03_technical/security/secret-management.md`
