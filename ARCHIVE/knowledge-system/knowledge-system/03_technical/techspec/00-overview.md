# Tech Spec Master Index

_Source: PRD HARAMAIN PRO v1.10-FINAL (May 02, 2026)_
_Context Efficiency: Each module is self-contained — Trae loads ONLY the feature being implemented_

---

## How to Use This Tech Spec

**For Trae (Engineering):**
1. Read `00-overview.md` for high-level architecture + dependencies
2. Load ONLY the feature module (FXX) being implemented
3. Each module contains: schema, API, flows, decisions — no PRD re-reading needed

**Context Management:**
- Max 1 module per session load
- Cross-refs link to other modules (not full content)
- All OQ resolutions embedded in relevant module

---

## Module List

| ID | Feature | Status | Key Decisions |
|----|---------|--------|---------------|
| [F01](F01-onboarding-pdpl.md) | Onboarding + PDPL Consent | IMPLEMENTED | PDPL consent at onboarding |
| [F02](F02-panic-button.md) | Panic Button | IN PROGRESS | Dual responder (Muthawif + Team-Support), auto-deactivate H+1 |
| [F03](F03-offline-maps.md) | Offline Maps (OSM) | PENDING | **OSM tiles NOT Mapbox** — self-hosted |
| [F04](F04-virtual-muthawif.md) | Virtual Muthawif (Nadhira AI) | PENDING | Nadhira AI answers contextual Quranic duas |
| [F05](F05-b2c-paywall.md) | B2C Paywall + Midtrans | PENDING | Safety Pass Rp 120rb lifetime |
| [F06](F06-b2b-group-system.md) | B2B Group System | PENDING | Invitation accept/decline, 7-day expiry |
| [F08](F08-b2b-agency-dashboard.md) | B2B Agency Dashboard | PENDING | **White Label gets dashboard ✅** |
| [F09](F09-informasi-umrah.md) | Informasi Umrah (NEW) | PENDING | Content library, SuperAdmin-created, free |
| [F10](F10-ux-tooltip.md) | UX Accessibility Tooltip (NEW) | PENDING | First-time popup guide, ID/AR |
| [DB](DB-schema.md) | Database Schema | REFERENCE | All tables, RLS policies |

---

## Critical Decisions (Read First)

| # | Decision | Impact |
|---|----------|--------|
| 1 | **OSM tiles NOT Mapbox** | Tile server self-hosted, no licensing fee |
| 2 | **SDAIA NRC = HARD REQUIREMENT** | Cannot launch in Saudi without it |
| 3 | **Enterprise = White Label only** | No WL = max Medium tier (Rp 60rb/pax) |
| 4 | **Revenue Share = HAPUS** | Sales Agent gets license from Travel, no commission |
| 5 | **Jejak Ibadah REMOVED from Mandiri** | Mandiri groups:各族自己保存照片 |
| 6 | **Panic Button: Muthawif + Team-Support** | Both receive alert, both can respond |

---

## Tech Stack Summary

| Layer | Technology |
|-------|------------|
| Mobile | Flutter (iOS + Android) |
| Web Dashboard | React |
| Backend | Supabase (Auth, DB, Storage, FCM) |
| Maps | **OSM self-hosted tiles** (NOT Mapbox) |
| Payments | Midtrans Snap |
| AI | Nadhira AI (contextual Quranic duas) |
| CDN | For Informasi Umrah content |
| Saudi Compliance | **SDAIA NRC registration** |

---

## PRD Reference

PRD File: `~/Library/Mobile Documents/com~apple~CloudDocs/HermesSync/Haramain-Pro/PRDs/Haramain-Pro-PRD-v1.10-FINAL.md`

Changelog v1.6: Panic Button dual responder, UX tooltip
Changelog v1.5: Informasi Umrah content library
Changelog v1.4: Pricing restructure (B2B 4-tier, no revenue share)
Changelog v1.10-FINAL: Enterprise=WL, Revenue Share removed

---

_Maintained by: Hermes (CTO)_
_Last Updated: 2026-05-02_
