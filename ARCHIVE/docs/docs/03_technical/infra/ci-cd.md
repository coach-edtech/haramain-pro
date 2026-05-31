# CI/CD

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Continuous integration and deployment pipeline.

## Pipeline Overview

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   Lint/Test  │───▶│   Build      │───▶│   Deploy     │
│   (PR)       │    │   (Main)     │    │   Staging    │
└──────────────┘    └──────────────┘    └──────────────┘
                                                │
                     ┌──────────────┐            │
                     │   Deploy     │◀───────────┘
                     │   Production │  (manual gate)
                     └──────────────┘
```

## Tools
- **CI/CD**: GitHub Actions (primary)
- **Mobile CI**: Codemagic (optional for advanced features)
- **Supabase**: Supabase CLI + GitHub Actions

## Related
- `docs/03_technical/infra/github-actions.md`
- `docs/03_technical/infra/codemagic.md`
