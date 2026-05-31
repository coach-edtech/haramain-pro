# ARCHIVE — OBSOLETE FILES

**DO NOT USE THESE FILES FOR DEVELOPMENT**

These files have been moved here because they are outdated or have been superseded by:

- `PRD/Haramain-Pro-PRD-v1.10-FINAL.md` — Master source of truth
- `techspec/` — Current implementation reference
- `decisions/decision-log.md` — Current decision log
- `features/` — Current feature briefs

---

## Why Are These Archived?

| Folder | Reason |
|--------|--------|
| `brain/` | Contains outdated feature briefs and CTO Codex technical plans from PRD v1.3 (April 4, 2026). Key decisions have changed: OSM vs Mapbox, Enterprise = White Label only, Revenue Share removed, Jejak Ibadah removed from Mandiri. |
| `knowledge-system/` | Contains `global-summary.md` which references Mapbox, old pricing (volume discount), and F07 (Jejak Ibadah Photo — deleted). Schema references `profiles` table but PRD uses `users`. |

---

## What Changed (Since April 4, 2026)

1. **OSM replaces Mapbox** — Self-hosted tiles, no licensing fee
2. **Pricing restructure** — B2B 4-tier fixed pricing, no volume discount
3. **Enterprise = White Label only** — No WL = max Medium tier
4. **Revenue Share removed** — Sales Agent gets license from Travel
5. **Jejak Ibadah removed from Mandiri** —各族自己保存照片
6. **Panic Button dual responder** — Muthawif + Team-Support
7. **Database schema updated** — Uses `users` not `profiles`

---

**If you need historical context**, read these archives. But for implementation, use the active folders.

---

_Archived: 2026-05-02 by Hermes (CTO)_
