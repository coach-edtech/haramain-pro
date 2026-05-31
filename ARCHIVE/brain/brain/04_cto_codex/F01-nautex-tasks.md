# F-01: Onboarding + PDPL Consent — Nautex Tasks

_Based on Codex Technical Plan F01_
_Status: Ready for Nautex_
_Date: 2026-04-04_

---

## Task List (in order)

### T-01: Database Schema Setup
- **Name:** Setup database schema for PDPL consent
- **Type:** Code
- **Description:** Create/update `profiles`, `consent_events`, and `data_deletion_requests` tables in Supabase. Add columns: pdpl_consent_granted, pdpl_consent_timestamp, location_consent_granted, passport_biometric_consent_granted, trial_started_at, consent_version, consent_withdrawn_at
- **Files:** `supabase/migrations/`
- **Requirements:** PRD-16, PRD-17

### T-02: Mobile Route Guard
- **Name:** Implement consent route guard in Flutter
- **Type:** Code
- **Description:** Implement route guard that blocks access to home/premium features if mandatory consent not granted. Check both local storage and server state.
- **Files:** `lib/auth/`
- **Requirements:** PRD-16

### T-03: Onboarding UI Flow
- **Name:** Build multi-step onboarding UI
- **Type:** Code
- **Description:** Build multi-step consent flow: (1) Welcome/PDPL notice, (2) Location consent (required), (3) Passport/biometric consent (optional), (4) Terms acceptance. Support resume from local state.
- **Files:** `lib/onboarding/`, `lib/widgets/consent_*.dart`
- **Requirements:** PRD-16

### T-04: Consent API Endpoints
- **Name:** Implement consent submission API
- **Type:** Code
- **Description:** Create `POST /v1/onboarding/consent` endpoint. Save consent event, start 7-day trial, return updated profile. Create audit trail in consent_events.
- **Files:** `supabase/functions/consent-handler/`
- **Requirements:** PRD-16, PRD-18

### T-05: Settings Privacy Page
- **Name:** Build Settings > Privacy & Data page
- **Type:** Code
- **Description:** UI for users to view consent status, withdraw consent, request data deletion. Show clear explanation of impact.
- **Files:** `lib/settings/privacy_page.dart`
- **Requirements:** PRD-17

### T-06: Local Purge Service
- **Name:** Implement local data purge service
- **Type:** Code
- **Description:** Create PurgeService that clears: SQLite, SecureStorage, SharedPreferences, cached maps, photo queue, session tokens. Trigger on consent withdrawal.
- **Files:** `lib/services/purge_service.dart`
- **Requirements:** PRD-17

### T-07: Consent Withdrawal Endpoint
- **Name:** Implement consent withdrawal API
- **Type:** Code
- **Description:** Create `POST /v1/privacy/withdraw-consent` endpoint. Mark consent withdrawn, enqueue deletion request, revoke premium eligibility.
- **Files:** `supabase/functions/withdraw-consent/`
- **Requirements:** PRD-17

### T-08: Offline Deletion Queue
- **Name:** Implement offline deletion request queue
- **Type:** Code
- **Description:** If offline when withdrawal triggered, queue request locally. Retry with exponential backoff when connectivity restored. Show status in Settings.
- **Files:** `lib/services/deletion_queue.dart`
- **Requirements:** PRD-17

### T-09: Integration Tests
- **Name:** Write integration tests for consent flows
- **Type:** Test
- **Description:** Test: first launch flow, partial onboarding resume, withdrawal when offline, relaunch after withdrawal, trial starts only after consent granted.
- **Files:** `test/consent/`
- **Requirements:** PRD-16, PRD-17, PRD-76-80

### T-10: Observability
- **Name:** Add consent analytics/observability
- **Type:** Code
- **Description:** Track consent completion rate, withdrawal rate, deletion request backlog. Add metrics for dashboard.
- **Files:** `supabase/functions/`
- **Requirements:** PRD-76

---

## Nautex Designator Mapping

| Nautex Task | Feature | Type |
|-------------|---------|------|
| T-01 | F-01: Database Schema | Code |
| T-02 | F-01: Route Guard | Code |
| T-03 | F-01: Onboarding UI | Code |
| T-04 | F-01: Consent API | Code |
| T-05 | F-01: Settings Privacy | Code |
| T-06 | F-01: Purge Service | Code |
| T-07 | F-01: Withdrawal API | Code |
| T-08 | F-01: Offline Queue | Code |
| T-09 | F-01: Integration Tests | Test |
| T-10 | F-01: Observability | Code |

---

## How to Submit to Nautex

1. Copy each task above
2. Go to Nautex UI or invoke via Codex/Trae
3. Create tasks with the format from `.nautex/AGENTS.md`
4. Set appropriate `workflow_info.in_focus` flags

---

_Next: After F-01 tasks are in Nautex, Codex pulls and implements_
