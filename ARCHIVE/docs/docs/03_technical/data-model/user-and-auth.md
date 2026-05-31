# User and Auth

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
User authentication and profile data model.

## Supabase Auth

### Method: Phone OTP
- User enters phone number (+62 format)
- OTP sent via SMS
- 6-digit code verification
- Session persisted in app

### Tables

#### `public.profiles`
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | FK → auth.users |
| `phone` | TEXT | E.164 format |
| `full_name` | TEXT | Display name |
| `role` | ENUM | 'jamaah', 'muthawif', 'travel_admin', 'sys_admin' |
| `agency_id` | UUID | FK → agencies (nullable) |
| `created_at` | TIMESTAMPTZ | |
| `updated_at` | TIMESTAMPTZ | |

#### `public.consents`
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | PK |
| `user_id` | UUID | FK → profiles |
| `consent_location` | BOOLEAN | GPS tracking |
| `consent_media` | BOOLEAN | Photo logging |
| `consent_notification` | BOOLEAN | Push notifications |
| `consent_marketing` | BOOLEAN | Alumni broadcast |
| `consented_at` | TIMESTAMPTZ | |
| `revoked_at` | TIMESTAMPTZ | Nullable |

## RLS Policies
- Users can SELECT/UPDATE their own profile
- No cross-user data access
- Consent records: only own

## Related
- `docs/03_technical/data-model/consent-and-deletion.md`
- `docs/05_features/pdpl-consent/`
