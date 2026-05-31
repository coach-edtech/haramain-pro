# WORKFLOW.md

> Workflow resmi squad untuk membangun **mobile app** dan **website** dengan kolaborasi Founder + AI agents.

---

## Tujuan

Dokumen ini menjelaskan alur kerja resmi dari:

- ide
- spesifikasi
- modularisasi dokumen
- prompt eksekusi
- implementasi
- UAT
- release / revisi

Agar semua anggota squad bekerja dengan peran yang jelas dan tidak saling overlap.

---

# 1. Workflow Inti

```text
Founder
  ↓
Nautex.ai
  ↓
Onyx
  ↓
Google Antigravity
  ↓
Trae.ai + ContextPlus
  ↓
OpenClaw
  ↓
Founder Approval
```plaintext

---

# 2. Peran Tiap Tahap

| Tahap | Pemilik Utama | Tujuan |
|---|---|---|
| Ide & Prioritas | Founder | Menentukan apa yang mau dibangun |
| PRD / TRD / Implementation Plan | Nautex.ai | Membuat dokumen formal |
| Modularisasi & Sintesis | Onyx | Memecah dokumen panjang jadi usable |
| Prompt Eksekusi | Google Antigravity | Mengubah dokumen jadi prompt untuk Trae |
| Implementasi | Trae.ai | Mengerjakan coding / perubahan teknis |
| Code Context | ContextPlus | Membantu Trae memahami codebase |
| Review / UAT | OpenClaw | Menguji hasil dan memberi feedback |
| Approval | Founder | Menentukan lanjut, revisi, atau release |

---

# 3. Workflow per Fase

## FASE A — Discovery / Ideation

### Tujuan
Mengubah ide mentah menjadi requirement yang jelas.

### Langkah
1. Founder menuliskan ide, masalah user, dan tujuan bisnis.
2. Jika fitur cukup besar, ide masuk ke Nautex.
3. Nautex menghasilkan:
   - PRD
   - TRD
   - Implementation Plan

### Output
- dokumen formal siap kerja
- scope awal
- constraint awal

### Pemilik tahap
- Founder
- Nautex.ai

---

## FASE B — Document Structuring

### Tujuan
Mengubah dokumen panjang dari Nautex menjadi bentuk modular yang mudah dipakai oleh squad.

### Langkah
1. Export dokumen dari Nautex ke Markdown lokal.
2. Onyx membaca dokumen export.
3. Onyx memecah dokumen menjadi:
   - feature hubs
   - product notes
   - technical notes
   - implementation breakdown
   - acceptance criteria
   - decision log bila diperlukan
4. Jika perlu, Onyx menyarankan struktur folder / naming.

### Output
- dokumen modular
- struktur yang mudah dibaca
- artefak yang siap dipakai Antigravity dan Trae

### Pemilik tahap
- Onyx

---

## FASE C — CTO Prompting

### Tujuan
Mengubah dokumen modular menjadi prompt eksekusi yang tajam.

### Langkah
1. Founder atau Onyx menyiapkan konteks modular.
2. Antigravity membaca dokumen tersebut.
3. Antigravity menghasilkan prompt eksekusi untuk Trae.

### Prompt Antigravity ke Trae idealnya memuat:
- tujuan
- scope
- file/area target
- acceptance criteria
- constraints
- verification
- output wajib

### Output
- prompt implementasi siap eksekusi

### Pemilik tahap
- Google Antigravity

---

## FASE D — Implementation

### Tujuan
Mengerjakan perubahan teknis di codebase.

### Langkah
1. Trae menerima prompt dari Antigravity.
2. ContextPlus membantu Trae:
   - memahami codebase
   - menemukan file relevan
   - membaca context dokumen lokal bila diperlukan
3. Trae melakukan implementasi.
4. Trae memberikan:
   - status implementasi
   - daftar file yang berubah
   - blocker / risk notes
   - implementation summary

### Output
- code changes
- implementation summary
- technical notes

### Pemilik tahap
- Trae.ai
- ContextPlus

---

## FASE E — Review & UAT

### Tujuan
Memastikan hasil implementasi sesuai intent dan layak dilanjutkan.

### Langkah
1. OpenClaw membaca:
   - tujuan fitur
   - acceptance criteria
   - implementation summary
2. OpenClaw melakukan:
   - UAT
   - review flow
   - review UX
   - identifikasi bug / mismatch
3. OpenClaw menghasilkan:
   - bug list
   - improvement notes
   - release recommendation

### Output
- UAT result
- bug report
- review notes
- release recommendation

### Pemilik tahap
- OpenClaw

---

## FASE F — Founder Decision

### Tujuan
Mengambil keputusan final berdasarkan hasil implementasi dan UAT.

### Founder dapat memilih:
- approve
- revise
- postpone
- cut scope
- release

### Output
- keputusan final sprint / fitur / release

### Pemilik tahap
- Founder

---

# 4. Workflow Harian Sederhana

## Jika sedang membangun fitur baru
1. Founder siapkan ide
2. Nautex buat PRD/TRD/Implementation Plan
3. Onyx modularisasi dokumen
4. Antigravity buat prompt eksekusi
5. Trae + ContextPlus implementasi
6. OpenClaw UAT
7. Founder approve / minta revisi

---

## Jika sedang bugfix kecil
1. Founder atau OpenClaw menjelaskan bug
2. Jika tidak mengubah scope besar, **tidak perlu buka Nautex**
3. Antigravity buat prompt bugfix
4. Trae + ContextPlus memperbaiki
5. OpenClaw retest
6. Founder approve

---

## Jika sedang perubahan scope besar
1. Founder memutuskan perubahan arah
2. Kembali ke Nautex untuk update dokumen formal
3. Onyx memperbarui struktur modular
4. Lanjut lagi ke Antigravity → Trae → OpenClaw

---

# 5. Decision Rules

## Gunakan Nautex jika:
- fitur baru cukup besar
- ada perubahan scope besar
- perlu PRD/TRD/Implementation Plan baru
- arah fitur berubah signifikan

## Gunakan Onyx jika:
- dokumen terlalu panjang
- dokumen perlu dipecah jadi modular
- perlu menyatukan banyak dokumen
- ada competitor insight baru
- perlu consistency check atau gap analysis

## Gunakan Antigravity jika:
- spesifikasi sudah siap diubah menjadi prompt eksekusi
- perlu task yang lebih konkret untuk Trae

## Gunakan Trae jika:
- task implementasi sudah jelas
- prompt sudah siap
- code perlu diubah

## Gunakan ContextPlus jika:
- Trae perlu memahami codebase
- perlu retrieval file atau area teknis relevan

## Gunakan OpenClaw jika:
- implementasi selesai
- perlu UAT / review
- perlu sanity check sebelum release

## Gunakan Codex jika:
- ada keputusan teknis besar
- solusi terasa berisiko
- perlu second opinion arsitektural

---

# 6. Aturan Operasional

## Rule 1 — Satu source of truth untuk planning
PRD, TRD, dan Implementation Plan utama berasal dari Nautex.

## Rule 2 — Dokumen panjang tidak langsung dilempar ke Trae
Dokumen panjang harus dirapikan/modularisasi dulu melalui Onyx.

## Rule 3 — Antigravity hanya bekerja dari context yang jelas
Jangan minta prompt eksekusi jika requirement masih kabur.

## Rule 4 — Trae tidak menentukan strategi produk
Trae fokus pada implementasi.

## Rule 5 — OpenClaw tidak menjadi builder utama
OpenClaw fokus review, UAT, dan feedback.

## Rule 6 — Codex tidak dipakai setiap hari
Codex hanya untuk second opinion teknis saat perlu.

## Rule 7 — Founder tetap approval akhir
Semua release atau perubahan besar tetap ditentukan Founder.

---

# 7. Standar Output Tiap Tahap

| Tahap | Output Minimum |
|---|---|
| Founder | tujuan, prioritas, constraint |
| Nautex | PRD, TRD, Implementation Plan |
| Onyx | dokumen modular, feature hub, gap notes |
| Antigravity | prompt eksekusi siap Trae |
| Trae | code changes, status, implementation summary |
| OpenClaw | UAT result, bug list, release recommendation |
| Founder | approve / revise / release decision |

---

# 8. Artefak Minimum per Fitur

Setiap fitur idealnya memiliki minimal:

- Feature Brief / ide awal
- PRD *(jika fitur besar)*
- TRD *(jika teknis signifikan)*
- Implementation Plan
- Dokumen modular / feature hub
- Prompt eksekusi Antigravity
- Implementation summary dari Trae
- UAT result dari OpenClaw
- Decision note jika ada perubahan scope

---

# 9. Struktur Folder yang Direkomendasikan

```text
haramain-pro/
├── README.md
├── WORKFLOW.md
├── docs/
│   ├── nautex/
│   │   ├── raw/
│   │   ├── normalized/
│   │   └── hubs/
│   ├── product/
│   ├── technical/
│   ├── implementation/
│   ├── qa/
│   └── decisions/
├── apps/
└── notes/
```plaintext

---

# 10. Prompt Flow Standar

## A. Founder → Nautex
Dipakai untuk membuat dokumen formal.

## B. Nautex → Onyx
Dipakai untuk modularisasi dan knowledge structuring.

## C. Onyx → Antigravity
Dipakai untuk menyiapkan konteks yang bersih dan terarah.

## D. Antigravity → Trae
Dipakai untuk execution prompt.

## E. Trae → OpenClaw
Dipakai untuk review/UAT.

## F. OpenClaw → Founder
Dipakai untuk keputusan final.

---

# 11. Kapan Workflow Harus Kembali ke Awal?

Workflow kembali ke tahap awal jika:
- scope berubah besar
- hasil UAT menunjukkan requirement awal salah
- competitor analysis mengubah positioning
- implementasi mentok karena asumsi awal salah
- ada keputusan bisnis baru

Jika itu terjadi:
1. Founder revisi arah
2. Nautex update dokumen formal
3. Onyx re-modularisasi
4. Antigravity buat prompt baru
5. Trae implement ulang / revisi

---

# 12. Workflow Ringkas Satu Kalimat

> **Founder menentukan arah → Nautex membuat spesifikasi → Onyx merapikan pengetahuan → Antigravity menyusun prompt eksekusi → Trae membangun dengan bantuan ContextPlus → OpenClaw menguji → Founder memutuskan.**

---

# 13. Official Working Motto

> **Clarity first. Context structured. Execution sharp.**