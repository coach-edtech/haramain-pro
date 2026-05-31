# Decision Log

_Keputusan penting project. Di-update oleh Hermes (CTO) setelah setiap sprint._

---

## 2026-05-02 — PRD v1.10-FINAL Decisions

| Item | Decision | Reason |
|------|----------|--------|
| Enterprise = White Label only | Enterprise tier (>100 pax) ONLY untuk Travel yang beli White Label | Coach Chaidir confirmation |
| White Label Dasbor Web ✅ | White Label Travel HARUS punya Travel Admin Dashboard | Fix typo di PRD — was ❌ (for Admin only) |
| Revenue Share Sales Agent | DIHAPUS — Sales Agent TIDAK membeli Safety Pass | Coach Chaidir: lisensi dari Travel, biaya sudah include dalam paket Umrah |
| Sales Agent commission | Haramain Pro TIDAK bayar komisi ke Sales Agent | Coach Chaidir confirmation |
| Jejak Ibadah REMOVED from Mandiri | Album foto dihapus dari scope Mandiri | Coach Chaidir decision —各族自己保存照片 |
| Panic Button dual responder | Panic Alert diterima Muthawif DAN Team-Support | Both can respond "Stay, saya jemput" or "Saya di sini" |
| Panic Button auto-deactivate | Panic Button auto-deactivate H+1, re-activate via new trip/payment | Anti-abuse design |
| Invitation Approval Flow | Jamaah Travel bisa Accept/Decline invitation, 7-day expiry | Admin can resend/cancel |
| UX Accessibility Tooltip | First-time popup guide untuk setiap fitur | Multi-language (ID/AR), "Tampilkan lagi" option |
| Informasi Umrah (NEW) | Content library (video/audio/teks) by SuperAdmin, free for all | Sales Agent tool untuk prospek |
| OSM over Mapbox | Self-hosted OSM tiles — no licensing fee | OQ-02 Resolved |
| SDAIA NRC = HARD | Operating in Saudi requires NRC registration | 4-8 week timeline, legal risk |
| Audio doa via earphone | Diperbolehkan di dalam masjid | OQ-06 Resolved |
| Kemenag endorsement | Tidak perlu endorsement pemerintah | OQ-07 Resolved |

---

## 2026-04-04 — Initial Setup

| Item | Decision | Reason |
|------|----------|--------|
| Brain Repo structure | Using `/brain/` folder dengan 8 subfolder | Follows Onyx recommendation — separates knowledge by concern |
| Curator role | OpenClaw sebagai curator, bukan auto-write | Agents don't auto-write; manual curation lebih stabil |
| Onyx | Ditunda | Context+ already provides code intelligence; brain repo sufficient untuk awal |
| Nautex | Sudah integrated sebagai task management | Codex pulls tasks dari Nautex MCP |

## 2026-04-04 — MVP Feature Briefs Created

Extracted 8 MVP feature briefs from PRD:

| ID | Feature | File |
|----|---------|------|
| F-01 | Onboarding + PDPL Consent | `02_features/F01-onboarding-pdpl-consent.md` |
| F-02 | Panic Button | `02_features/F02-panic-button.md` |
| F-03 | Offline Maps | `02_features/F03-offline-maps.md` |
| F-04 | Virtual Muthawif | `02_features/F04-virtual-muthawif.md` |
| F-05 | B2C Paywall + Midtrans | `02_features/F05-b2c-paywall-midtrans.md` |
| F-06 | B2B Group System | `02_features/F06-b2b-group-system.md` |
| F-07 | Jejak Ibadah Photo | `02_features/F07-jejak-ibadah-photo.md` |
| F-08 | B2B Agency Dashboard | `02_features/F08-b2b-agency-dashboard.md` |

Each brief includes: Problem Statement, Goal, User Flow, Scope, Acceptance Criteria, Edge Cases, Dependencies, Technical Notes, PRD References, Open Questions.

---

## 2026-04-04 — Codex Technical Plans Complete

Codex telah generate 8 technical plans di `04_cto_codex/`:

| File | Feature |
|------|---------|
| F01-ctechnical-plan.md | Onboarding + PDPL Consent |
| F02-ctechnical-plan.md | Panic Button |
| F03-ctechnical-plan.md | Offline Maps |
| F04-ctechnical-plan.md | Virtual Muthawif |
| F05-ctechnical-plan.md | B2C Paywall + Midtrans |
| F06-ctechnical-plan.md | B2B Group System |
| F07-ctechnical-plan.md | Jejak Ibadah Photo |
| F08-ctechnical-plan.md | B2B Agency Dashboard |

Total: 772 lines. Each includes: Database Schema, API Endpoints, Task Breakdown, Risks.

---

## 2026-04-04 — T-01 Migration Review

Codex membuat: `supabase/migrations/2026040417_consent_schema.sql`

Issues found + fixed:
| Issue | Fix | File |
|-------|-----|------|
| Missing admin RLS policies | Added admin policies for sys_admin | `2026040418_consent_rls_admin_trigger.sql` |
| No auto-update updated_at | Added trigger function | `2026040418_consent_rls_admin_trigger.sql` |

---

_Log dimaintain oleh OpenClaw. Setiap keputusan baru ditambahkan di atas._
