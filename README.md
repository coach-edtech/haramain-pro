# HARAMAIN PRO — Project Entry Point

**Version:** 1.0
**Date:** 2026-05-02
**Author:** Hermes (CTO)

---

## Quick Start for Trae

**Before writing any code, read this file and the PRD.**

### Source of Truth (In Order)

1. **PRD** → `PRD/Haramain-Pro-PRD-v1.10-FINAL.md` — Master requirements
2. **Tech Spec** → `techspec/` — Implementation reference per feature
3. **Decision Log** → `decisions/decision-log.md` — Key decisions from PRD

---

## Folder Structure

```
Haramain-Pro/
├── README.md              ← YOU ARE HERE (entry point)
├── PRD/
│   └── Haramain-Pro-PRD-v1.10-FINAL.md   ← MASTER SOURCE OF TRUTH
├── techspec/              ← Implementation reference (modular)
│   ├── 00-overview.md     ← Architecture + critical decisions
│   ├── F02-panic-button.md
│   ├── F03-offline-maps.md
│   ├── F09-informasi-umrah.md
│   ├── F10-ux-tooltip.md
│   └── DB-schema.md
├── features/              ← Feature briefs
│   └── F08-b2b-agency-dashboard.md
├── decisions/             ← Decision log
│   └── decision-log.md
├── reports/               ← Trae progress reports (for Hermes review)
│   ├── TEMPLATE-report.md
│   └── REP-F0X-*-*.md
└── ARCHIVE/               ← OLD FILES — DO NOT USE
    ├── brain/             ← OLD brain/ — OBSOLETE
    └── knowledge-system/  ← OLD knowledge-system/ — OBSOLETE
```

---

## Report Format

**File naming:** `REP-{feature}-{YYYYMMDD}-{##}.md`

**Example:** `REP-F02-PanicButton-20260502-01.md`

Reports should be submitted to `reports/` folder for Hermes to review.

---

## Critical Decisions (Read Before Coding)

| # | Decision | Impact |
|---|----------|--------|
| 1 | **OSM tiles NOT Mapbox** | Self-hosted tile server, no licensing fee |
| 2 | **SDAIA NRC = HARD REQUIREMENT** | Cannot launch in Saudi without it |
| 3 | **Enterprise = White Label only** | No WL = max Medium tier (Rp 60rb/pax) |
| 4 | **Revenue Share = HAPUS** | Sales Agent gets license from Travel, no commission |
| 5 | **Jejak Ibadah REMOVED from Mandiri** | Mandiri:各族自己保存照片 |
| 6 | **Panic Button: Muthawif + Team-Support** | Both receive alert, both can respond |
| 7 | **Invitation: Accept/Decline, 7-day expiry** | Admin can resend/cancel |

---

## Pricing Model (FINAL)

| Tier | Price/pax | Commitment |
|------|-----------|------------|
| B2C Safety Pass | Rp 120,000 lifetime | — |
| Independent | Rp 90,000 | Tidak ada |
| Small | Rp 75,000 | 45 pax/bulan |
| Medium | Rp 60,000 | 90 pax/bulan |
| Enterprise | Rp 50,000 | **White Label only** |
| White Label | Rp 30,000,000 + Rp 12,000,000/yr | — |
| Lisensi Satuan | Rp 90,000 | All tiers |

---

## Tech Stack

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

## How to Use Techspec

**For each feature you're implementing:**

1. Read `PRD/Haramain-Pro-PRD-v1.10-FINAL.md` — understand the feature requirement
2. Load `techspec/00-overview.md` — understand architecture
3. Load the relevant `techspec/F0X-*.md` — implementation details
4. Use `techspec/DB-schema.md` for database schema

**Do NOT read files in ARCHIVE/ — they are obsolete.**

---

## Context Efficiency

- Techspec files are **self-contained per feature** (~4-9KB each)
- Trae should load only the feature being implemented
- Full PRD is 3,559 lines — reference by section, don't re-read fully
- Decision log has all key decisions in one place

---

## Contacts

| Role | Name |
|------|------|
| Founder | Coach Chaidir Mohammad Yusuf |
| CTO | Hermes (me — reviews Trae output, provides Next Action) |
| Engineer | Trae AI (MiniMax-M2.7-highspeed) |

---

**Last Updated:** 2026-05-02
**Status:** READY FOR ENGINEERING HANDOFF
