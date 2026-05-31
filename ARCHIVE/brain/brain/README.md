# Brain Repo — Haramain Pro

Single source of truth untuk project knowledge dan decisions.

## Folder Structure

| Folder | Contents |
|--------|----------|
| `01_product_vision/` | Vision, target user, positioning |
| `02_features/` | Feature briefs (MVP — F01-F08, F09-F10 NEW) |
| `03_decisions/` | Decision log — keputusan penting dan alasannya |
| `04_cto_codex/` | Technical plans, implementation approach from Codex |
| `05_dev_trae/` | Implementation logs from Trae |
| `06_qa_openclaw/` | UAT results, bug reports |
| `07_releases/` | Release notes, known issues |
| `08_feedback/` | User feedback, insights |

## How to Use

1. **Setiap ide/fitur baru** → masuk ke `02_features/` as Feature Brief
2. **Keputusan penting** → catat di `03_decisions/`
3. **Plan Codex** → simpan di `04_cto_codex/`
4. **Hasil Trae** → ringkasan di `05_dev_trae/`
5. **UAT results** → simpan di `06_qa_openclaw/`
6. **Setelah release** → update `07_releases/`
7. **Tech Spec modular** → `knowledge-system/03_technical/techspec/` (context-efficient for Trae)

## Curator

**Hermes (CTO)** adalah curator utama. Semua write-back melalui Hermes kecuali ada instruksi explicit dari Coach Chaidir.

## Tech Spec (Context-Efficient)

Tech Spec baru ada di: `knowledge-system/03_technical/techspec/`

Struktur modular — Trae load hanya feature yang sedang di-build:

```
techspec/
  00-overview.md        ← Architecture + critical decisions (load FIRST)
  F02-panic-button.md   ← Panic Button module
  F03-offline-maps.md    ← OSM maps module
  DB-schema.md           ← Full schema reference
  F09-informasi-umrah.md ← Content library
  F10-ux-tooltip.md      ← Accessibility tooltip
```

**Context Management:** Setiap module self-contained. Trae tidak perlu load entire PRD untuk satu feature.

---

_Updated: 2026-05-02_
_Updated: 2026-04-04_
