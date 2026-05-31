# Secret Management

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Management of API keys, secrets, and credentials.

## Secrets Inventory

| Secret | Where Used | Storage |
|--------|-----------|---------|
| Supabase URL | Flutter app, Edge functions | Env / .env |
| Supabase anon key | Flutter app | Env, public (RLS-protected) |
| Supabase service role | Edge functions | Env (never client-side) |
| Midtrans Server Key | Edge functions | Env |
| Midtrans Client Key | Flutter app | Env, public |
| Twilio Account SID | Edge functions | Env |
| Twilio Auth Token | Edge functions | Env |
| Twilio Phone Number | Edge functions | Env |
| Mapbox Token | Flutter app | Env |

## Environment Variables

### Development (.env)
```
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ...
MIDTRANS_SERVER_KEY=sb-...
MIDTRANS_CLIENT_KEY=sb-...
TWILIO_ACCOUNT_SID=AC...
TWILIO_AUTH_TOKEN=...
MAPBOX_TOKEN=pk.eyJ...
```

### Production
Same variables in production environment (Supabase dashboard or CI secrets).

## Secret Rotation
- Rotate every 90 days
- Immediate rotation on suspected compromise
- Zero-downtime rotation: new secret → deploy → revoke old

## Client-Side Secrets
- Anon key: Safe to expose (RLS protects data)
- Mapbox token: Limited to mapbox scope
- Never expose: Service role key, server-side secrets

## Related
- `docs/03_technical/security/rls-model.md`
- `docs/03_technical/infra/deployment.md`
