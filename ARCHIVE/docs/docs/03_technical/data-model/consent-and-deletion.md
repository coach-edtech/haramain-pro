# Consent and Deletion

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
PDPL consent records and data deletion handling.

## Tables

#### `public.consents`
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | PK |
| `user_id` | UUID | FK → profiles (UNIQUE) |
| `consent_location` | BOOLEAN | GPS tracking |
| `consent_media` | BOOLEAN | Photo logging |
| `consent_notification` | BOOLEAN | Push notifications |
| `consent_marketing` | BOOLEAN | Alumni broadcast |
| `consented_at` | TIMESTAMPTZ | Initial consent time |
| `revoked_at` | TIMESTAMPTZ | Nullable (null = active) |
| `ip_address` | TEXT | Consent captured from IP |
| `user_agent` | TEXT | Device info |

#### `public.deletion_requests`
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | PK |
| `user_id` | UUID | FK → profiles |
| `status` | ENUM | 'pending', 'processing', 'completed', 'failed' |
| `requested_at` | TIMESTAMPTZ | |
| `completed_at` | TIMESTAMPTZ | Nullable |
| `notes` | TEXT | Internal notes |

## Deletion Flow
1. User submits deletion request (in-app or email)
2. Request created with status='pending'
3. Background job processes:
   - Delete from all tables (CASCADE via FK)
   - Purge Isar data on next app launch
   - Remove from backups (per retention policy)
4. Status → 'completed'
5. Confirmation sent to user

## Consent Audit
- All consent changes logged with timestamp
- Immutable records (no UPDATE, only INSERT new record)
- Audit trail for PDPL compliance

## Related
- `docs/02_product/compliance/pdpl-requirements.md`
- `docs/05_features/pdpl-consent/`
