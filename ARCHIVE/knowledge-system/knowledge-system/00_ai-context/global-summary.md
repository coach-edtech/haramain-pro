# Global Summary — Haramain Pro

> Quick reference for Trae AI agent. Updated 2026-04-27.

## What Is This Project?

**Haramain Pro** is a Smart Companion mobile app for Umrah and Hajj pilgrims. It solves:
1. Pilgrim safety — getting lost in massive crowds without internet
2. Travel agency retention — differentiating packages and re-engaging alumni

**Business Model**: B2B2C. Travel agencies buy bulk licenses (B2B), distribute to pilgrims (B2C). Pilgrims generate a shared photo album ("Jejak Ibadah") that serves as the agency's CRM for post-trip marketing.

---

## Product Boundary

**In Scope**: Offline GPS navigation, Panic Button with silent-mode bypass, subscription paywall, location-contextual prayer surfacing (Virtual Muthawif), photo CRM.

**Out of Scope**: PWA for mobile, generative AI voice, WhatsApp bot, Saudi Nusuk API integration, real-time visa processing.

---

## Architecture

```
Flutter Mobile (iOS/Android)          React Web Dashboard
     │                                        │
     ├─ Offline Mapbox tiles (300MB max)     ├─ Agency onboarding
     ├─ Panic Button → FCM                  ├─ Volume license purchase
     ├─ Virtual Muthawif (geofence)          ├─ Jejak Ibadah CRM gallery
     ├─ Photo queue → watermark sync        └─ Alumni broadcast
     └─ Riverpod state management
              │
         Supabase
     ┌───────┼───────┐
     │       │       │
  PostgreSQL Auth    Storage
  (RLS multi-tenant) │
                 Edge Functions
     ┌─────────┼─────────┐
 fcm-panic-alert  photo-watermark  midtrans-webhook
```

---

## User Roles

| Role | Code | Description |
|------|------|-------------|
| Jamaah | `jamaah` | Pilgrim end-user |
| Muthawif | `muthawif` | Group leader |
| Travel Agency Admin | `travel_admin` | B2B agency using web dashboard |
| System Admin | `sys_admin` | Internal operator |

---

## Subscription Tiers

| Tier | Code | Access |
|------|------|--------|
| Free Trial | `free_trial` | 7 days, limited features |
| Active | `active` | Lifetime B2C pass OR B2B group |
| Expired | `expired` | Paywall enforced |

**Pricing**:
- B2C: Rp 120,000 lifetime (Haramain Safety Pass)
- B2B: Rp 90,000 × N × (1 - D)
  - N ≤ 100: D = 0% (Rp 90K/pax)
  - 101 ≤ N ≤ 500: D = 11% (Rp 80K/pax)
  - N ≥ 501: D = 22% (Rp 70K/pax)

---

## Key Features (F01–F08)

| ID | Feature | Status |
|----|---------|--------|
| F01 | Onboarding + PDPL Consent Gate | Not started |
| F02 | Offline Mapbox Navigation | Not started |
| F03 | Panic Button + FCM Alert | Not started |
| F04 | Virtual Muthawif (Geofence + Doa) | Not started |
| F05 | B2C Paywall + Midtrans | Not started |
| F06 | B2B Group (Rombongan) Join | Not started |
| F07 | Jejak Ibadah Photo CRM | Not started |
| F08 | B2B Web Dashboard | Not started |

---

## Critical Technical Constraints

1. **Offline-first**: App must work without internet. Mapbox tiles cached locally.
2. **PDPL Compliance**: Saudi data law. Explicit consent required. 30-day GPS TTL purge.
3. **Multi-tenant isolation**: Supabase RLS enforced. Agency A cannot see Agency B data.
4. **Silent-mode bypass**: FCM critical alerts must override iOS/Android DND.
5. **Image compression**: Mobile pre-compress before Edge Function to avoid Deno OOM.
6. **300MB storage limit**: Mapbox offline tiles must not exceed this.

---

## Implementation Timeline

- **Week 1–6**: Foundation — Auth, PDPL, Offline Architecture, Maps, GPS, Panic
- **Week 7–12**: Monetization — Trial, Paywall, Midtrans B2C
- **Week 13–18**: B2B — Agency Portal, Licensing, Group Management
- **Week 19–21**: Photo CRM — Camera, Watermark, Gallery
- **Week 22–24**: Compliance & Launch

**MVP Target**: Week 16
**Production Launch**: Week 24

---

## Current Project State

| Area | Status |
|------|--------|
| PRD (haramain-v.2.1.md) | ✅ Final |
| System Blueprint | ✅ Final |
| Schema (schema-overview.md) | ✅ Final — is AUTHORITY |
| Feature Plans (F01–F08) | ✅ Complete |
| Technical Plans (CTO Codex) | ✅ Complete |
| Knowledge System Structure | ✅ Complete |
| Paraflow Docs | ✅ Integrated (REFERENCE ONLY) |
| Flutter Codebase | ❌ Empty shell |
| Supabase Schema | ❌ Not migrated |
| Trae Report | ❌ None received |

---

## Documentation Authority

| Document | Status | Role |
|----------|--------|------|
| `haramain-v.2.1.md` | ✅ Final | **PRIMARY** — Master PRD |
| `SYSTEM_BLUEPRINT.md` | ✅ Final | **PRIMARY** — Control systems |
| `schema-overview.md` | ✅ Final | **PRIMARY** — Database schema |
| `knowledge-system/04_execution/roadmap.md` | ✅ Updated | Implementation timeline |
| `paraflow-product-docs/` | ✅ Integrated | **REFERENCE ONLY** |

---

## Next Actions (Priority Order)

1. **Setup Flutter lib structure** — Create `lib/core/` and `lib/features/` per project-structure.md
2. **Setup Supabase project** — Initialize schema migrations using schema-overview.md
3. **Install 14 Trae Skills** — git-commit, react-best-practices, webapp-testing, etc.
4. **Begin Milestone 1** — External API probes (FCM, Mapbox, Midtrans, Twilio)
5. **Begin F01 (Onboarding + PDPL)** — This gates all other features

---

## Contact & Context

- **Founder**: Coach Chaidir Mohammad Yusuf (non-technical, solo founder)
- **CTO Agent**: Hermes (me) — reviews Trae output, provides Next Action
- **Engineer**: Trae AI (MiniMax-M2.7-highspeed)
- **Workspace**: `/Volumes/StartUp/haramainpro/`
- **Language**: Indonesian (user), English (code/docs)

---

## Key Files

```
haramainpro/
├── docs/
│   ├── haramain-v.2.1.md          # Master PRD
│   ├── SYSTEM_BLUEPRINT.md         # Control systems
│   └── SUPERSEDE.md               # Doc source of truth matrix
├── knowledge-system/
│   ├── 00_ai-context/
│   │   ├── global-summary.md       # THIS FILE
│   │   ├── feature-index.md        # Feature catalog
│   │   └── system-overview.md
│   ├── 03_technical/
│   │   ├── data-model/
│   │   │   └── schema-overview.md  # AUTHORITY — DB schema
│   │   ├── flows/
│   │   │   ├── panic-flow.md
│   │   │   └── user-flows/         # Mobile + Web flows
│   │   └── infra/
│   │       └── project-structure.md # Flutter lib structure
│   └── 04_execution/
│       └── roadmap.md              # 24-week plan
├── brain/
│   ├── 02_features/               # F01–F08 feature briefs
│   └── 04_cto_codex/              # Technical plans
└── haramain_clean/                # Flutter shell (empty lib/)
```
