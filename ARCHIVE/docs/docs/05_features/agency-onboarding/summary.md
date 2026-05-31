# Agency Onboarding — Summary

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Feature Summary

| Aspect | Detail |
|--------|--------|
| Feature | Agency Onboarding (B2B) |
| Owner | OpenClaw (starter), Onyx (refinement) |
| Priority | P0 (B2B entry) |
| Status | Implementation pending |

## What It Does
Registers travel agencies (PPIU) to the platform, verifies their license, and creates their tenant context.

## Onboarding Steps
1. **Registration**: Company name, phone, email
2. **License Verification**: Upload PPIU license document
3. **Admin Review**: Antigravity staff approves
4. **Account Created**: Agency tenant context established
5. **Dashboard Access**: Agency admin can log in

## Required Data
- Company name (PT XXX)
- NPWP / Tax ID
- PPIU License number
- License document (PDF/image)
- Logo (optional)

## Roles Created
- **Agency Admin**: Full agency management
- **Agency Staff**: Passenger management (no billing)

## Implementation Notes
- License verification is manual (admin reviews uploaded doc)
- Future: API integration withKemenag PPIU database

## Dependencies
- Supabase Auth (agency accounts)
- Admin review workflow
- File upload for license docs

## Related
- `docs/02_product/personas/travel-agency.md`
- `docs/05_features/b2b-volume-licensing/`
