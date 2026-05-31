# AI Product Squad Operating System

> Operating system resmi untuk membangun **mobile app** dan **website** menggunakan kolaborasi manusia + AI agents.

---

## Tujuan

Repo / dokumen ini menjadi **panduan kerja resmi** untuk seluruh squad agar:

- semua anggota punya peran yang jelas
- tidak ada overlap tugas yang membingungkan
- setiap fitur bergerak dari ide → spesifikasi → eksekusi → UAT → release
- dokumen panjang bisa dimodularisasi dan digunakan ulang
- keputusan proyek tetap konsisten dari waktu ke waktu

---

## Prinsip Utama

1. **Founder menentukan arah.**
2. **Nautex membuat dokumen formal** untuk fase atau fitur besar.
3. **Onyx merapikan, memodularisasi, dan menyatukan pengetahuan proyek.**
4. **Antigravity mengubah dokumen menjadi prompt eksekusi.**
5. **Trae mengeksekusi implementasi.**
6. **ContextPlus membantu Trae memahami codebase.**
7. **OpenClaw melakukan review dan UAT.**
8. **Codex hanya digunakan untuk second opinion teknis saat dibutuhkan.**

---

## Squad Members & Roles

| Squad Member | Role Resmi | Fungsi Inti |
|---|---|---|
| **Founder** | Vision Owner & Final Decision Maker | Menentukan visi, prioritas, dan keputusan akhir |
| **Nautex.ai** | Spec Engine | Membuat PRD, TRD, dan Implementation Plan |
| **Onyx** | Knowledge Strategist & Document Architect | Memodularisasi dokumen, menyintesis konteks, integrasi competitor insight |
| **Google Antigravity** | CTO Ops / Prompt Compiler | Membaca dokumen dan membuat prompt eksekusi untuk Trae |
| **Trae.ai (GLM 5.x)** | Developer Implementator | Menjalankan implementasi teknis |
| **ContextPlus** | Code Context & Retrieval Layer | Membantu pemahaman codebase dan retrieval context |
| **OpenClaw** | Advisor, Reviewer & UAT Lead | Review hasil, UAT, release sanity check |
| **Codex** | Second-Opinion Technical Reviewer | Review teknis untuk keputusan besar atau kompleks |

---

## Source of Truth

### Dokumen formal utama
Dokumen formal utama berasal dari:

- **PRD**
- **TRD**
- **Implementation Plan**

yang dibuat di **Nautex.ai**.

### Dokumen kerja operasional
Setelah diexport dari Nautex, dokumen akan:

1. disimpan ke lokal / repo
2. dimodularisasi oleh **Onyx**
3. digunakan oleh **Antigravity**, **Trae**, **ContextPlus**, dan **OpenClaw**

> **Rule:** Jangan membuat dua versi aktif untuk dokumen yang sama.  
> Versi formal berasal dari Nautex, versi operasional/modular berasal dari hasil pengolahan Onyx.

---

## Workflow Resmi

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

## Penjelasan Workflow

### 1. Founder
Founder menentukan:
- masalah yang ingin diselesaikan
- tujuan bisnis
- prioritas
- constraint
- keputusan akhir

### 2. Nautex.ai
Nautex dipakai untuk:
- membuat **PRD**
- membuat **TRD**
- membuat **Implementation Plan**

> Nautex **tidak perlu dipakai di setiap task harian**.  
> Ia dipakai untuk fase besar, fitur besar, atau revisi besar.

### 3. Onyx
Onyx dipakai untuk:
- memecah dokumen panjang menjadi modular
- membuat struktur dokumen yang usable
- menyatukan konteks lintas dokumen
- memasukkan competitor analysis atau insight baru
- menjaga konsistensi antar artefak

### 4. Google Antigravity
Antigravity dipakai untuk:
- membaca dokumen modular
- membuat prompt implementasi CTO-grade
- menerjemahkan spesifikasi menjadi instruksi eksekusi untuk Trae

### 5. Trae.ai + ContextPlus
Trae dipakai untuk:
- menjalankan implementasi
- membuat perubahan code
- melaporkan status implementasi

ContextPlus dipakai untuk:
- memahami codebase
- retrieval file relevan
- mapping area perubahan
- membantu Trae menghindari implementasi yang buta konteks

### 6. OpenClaw
OpenClaw dipakai untuk:
- review hasil implementasi
- UAT
- bug reporting
- release recommendation

### 7. Founder Approval
Founder memutuskan:
- approve release
- request revision
- tunda
- ubah prioritas

---

## Kapan Menggunakan Setiap Tool

### Gunakan Nautex jika:
- memulai fitur besar
- memulai fase baru
- scope berubah signifikan
- butuh PRD/TRD/Implementation Plan baru

### Gunakan Onyx jika:
- dokumen terlalu panjang
- dokumen perlu dibuat modular
- perlu sintesis banyak dokumen
- ada competitor analysis baru
- ada kebutuhan gap analysis atau consistency review

### Gunakan Antigravity jika:
- dokumen sudah siap menjadi prompt eksekusi
- perlu task framing yang jelas untuk Trae
- perlu prompt implementasi yang terstruktur

### Gunakan Trae jika:
- task sudah jelas
- implementasi siap dilakukan
- refactor/fix perlu dieksekusi

### Gunakan ContextPlus jika:
- Trae perlu memahami codebase
- perlu semantic retrieval file atau area code
- perlu impact/blast radius awareness

### Gunakan OpenClaw jika:
- implementasi selesai
- perlu UAT
- perlu review kualitas hasil
- perlu sanity check sebelum release

### Gunakan Codex jika:
- ada keputusan teknis besar
- ada keraguan arsitektural
- perlu second opinion
- ada issue kompleks yang butuh audit tambahan

---

## Hal yang Tidak Boleh Tercampur

### Onyx bukan:
- builder utama
- IDE
- tool coding harian

### Antigravity bukan:
- source of truth jangka panjang
- knowledge base permanen

### Trae bukan:
- penentu strategi produk
- pembuat PRD/TRD

### OpenClaw bukan:
- implementator utama
- planner formal

### Codex bukan:
- planner harian utama
- pengganti Nautex

---

## Decision Rules

### Jika masalahnya adalah **arah / spesifikasi / scope besar**
→ pakai **Nautex**

### Jika masalahnya adalah **dokumen terlalu panjang / berantakan / perlu diintegrasikan**
→ pakai **Onyx**

### Jika masalahnya adalah **mengubah spesifikasi menjadi task prompt**
→ pakai **Antigravity**

### Jika masalahnya adalah **eksekusi teknis**
→ pakai **Trae**

### Jika masalahnya adalah **pemahaman codebase**
→ pakai **ContextPlus**

### Jika masalahnya adalah **review / UAT / release check**
→ pakai **OpenClaw**

### Jika masalahnya adalah **keputusan teknis sulit**
→ pakai **Codex**

---

## Standar Prompt Execution

Prompt dari Antigravity ke Trae idealnya selalu memiliki struktur:

1. **Tujuan**
2. **Scope**
3. **File / area target**
4. **Acceptance Criteria**
5. **Constraints**
6. **Verification**
7. **Output wajib**

---

## Standar Artefak Minimum per Fitur

Setiap fitur idealnya memiliki artefak berikut:

- **Feature Brief**
- **PRD** *(jika fitur besar)*
- **TRD** *(jika fitur besar / teknis signifikan)*
- **Implementation Plan**
- **Dokumen modular / feature hub**
- **Prompt eksekusi dari Antigravity**
- **Implementation summary dari Trae**
- **UAT notes dari OpenClaw**
- **Decision update jika ada perubahan scope**

---

## Struktur Kerja yang Direkomendasikan

```text
docs/
├── nautex/
│   ├── raw/
│   ├── normalized/
│   └── hubs/
├── product/
├── technical/
├── implementation/
├── qa/
└── decisions/
```plaintext

### Penjelasan singkat
- `docs/nautex/raw/` → export asli dari Nautex
- `docs/nautex/normalized/` → versi yang dirapikan
- `docs/nautex/hubs/` → feature hub modular untuk dibaca cepat
- `docs/product/` → problem, user, scope
- `docs/technical/` → architecture, technical notes
- `docs/implementation/` → task breakdown, implementation summary
- `docs/qa/` → UAT, bugs, test result
- `docs/decisions/` → keputusan penting dan perubahan arah

---

## Default Operating Mode

### Fase planning
Founder → Nautex → Onyx

### Fase eksekusi
Onyx → Antigravity → Trae + ContextPlus

### Fase validasi
Trae → OpenClaw → Founder

### Fase audit khusus
Founder / Onyx → Codex

---

## Working Agreement

- Kita mengutamakan **kejelasan dibanding kompleksitas**
- Kita mengutamakan **dokumen modular dibanding dokumen panjang tunggal**
- Kita mengutamakan **source of truth yang jelas**
- Kita mengutamakan **prompt eksekusi yang spesifik**
- Kita mengutamakan **human approval sebelum release penting**

---

## Current Default Stack

- **Planning:** Nautex.ai
- **Knowledge Structuring:** Onyx
- **CTO Execution Prompting:** Google Antigravity
- **Implementation:** Trae.ai (**GLM 5.x**)
- **Code Retrieval:** ContextPlus
- **Review & UAT:** OpenClaw
- **Technical Second Opinion:** Codex

---

## Summary

Sistem kerja ini dirancang agar:

- Founder tidak harus memegang semua konteks sendirian
- Dokumen besar tidak menghambat eksekusi
- Prompt ke developer agent lebih akurat
- Implementasi lebih grounded ke spesifikasi
- UAT lebih konsisten
- Pengetahuan proyek terus terjaga

---

## Official Squad Motto

> **Clarity first. Context structured. Execution sharp.**