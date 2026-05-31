# GitHub Actions

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
GitHub Actions CI/CD workflow configuration.

## Workflows

### 1. Flutter CI (PR)
```yaml
name: Flutter CI
on: [pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
```

### 2. Deploy Staging (main branch)
```yaml
name: Deploy Staging
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter build apk --release
      - run: flutter build ipa --release
      # Upload to Firebase App Distribution or similar
```

### 3. Supabase Deploy
```yaml
name: Deploy Supabase
on:
  push:
    paths:
      - 'supabase/**'
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: supabase/setup-cli@v1
      - run: supabase db push
      - run: supabase functions deploy --project-ref ${{ secrets.PROJECT_REF }}
```

## Secrets
- `SUPABASE_PROJECT_REF`
- `SUPABASE_ACCESS_TOKEN`
- `MIDTRANS_SERVER_KEY`
- `TWILIO_AUTH_TOKEN`
- `MAPBOX_TOKEN`

## Related
- `docs/03_technical/infra/ci-cd.md`
- `docs/03_technical/infra/codemagic.md`
