# Deployment

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Deployment architecture and strategy.

## Environments

| Environment | Purpose | URL |
|-------------|---------|-----|
| Development | Local dev | localhost |
| Staging | Pre-production testing | staging.haramain.app |
| Production | Live users | app.haramain.app |

## Flutter App Deployment

### iOS
- **Build**: Flutter build ipa
- **Sign**: Development + Distribution certificates
- **Beta**: TestFlight (internal testing)
- **Release**: App Store Connect (App Store)

### Android
- **Build**: Flutter build apk --release
- **Sign**: Keystore (Antigravity)
- **Beta**: Internal testing track (Play Console)
- **Release**: Production track (Play Store)

## Supabase Deployment

### Database Migrations
- Stored in `supabase/migrations/`
- Applied via Supabase CLI: `supabase db push`
- CI/CD: Applied automatically on main branch

### Edge Functions
- Written in TypeScript
- Deploy via: `supabase functions deploy <function-name>`
- Secrets set via: `supabase secrets set <key=value>`

### Storage
- Bucket: `jejak_ibadah` (public read, authenticated write)
- RLS on storage objects

## Monitoring
- Supabase Analytics: Built-in dashboard
- Crashlytics: Flutter integration
- Error tracking: Sentry (optional)

## Related
- `docs/03_technical/infra/codemagic.md`
- `docs/03_technical/infra/github-actions.md`
