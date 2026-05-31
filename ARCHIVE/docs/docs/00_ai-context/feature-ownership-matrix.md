# Feature Ownership Matrix — Haramain Pro

> Owner: Onyx
> Status: Authoritative
> Note: This file defines which platform owns each feature, which systems participate in it, and how AI/development tools should interpret implementation boundaries.

## Purpose
Dokumen ini menjelaskan **ownership boundary** untuk setiap fitur utama Haramain Pro.

Gunakan file ini untuk:
- menentukan platform mana yang menjadi owner utama suatu fitur
- menghindari prompt implementasi yang menyentuh area yang salah
- membantu Antigravity membuat prompt yang terarah
- membantu Trae memahami scope perubahan
- membantu review/UAT agar sesuai dengan boundary fitur
- membantu AI tools memetakan impact lintas mobile, web, backend, dan admin surfaces

Dokumen ini tidak menggantikan:
- feature docs detail
- protocol docs
- API contracts
- decision files

Tetapi file ini adalah **peta ownership operasional**.

---

## Ownership Model

Setiap fitur diklasifikasikan menurut:

- **Mobile** — Flutter app untuk jamaah/muthawif
- **Web** — React dashboard untuk travel agency / sys admin
- **Backend** — Supabase DB/Auth/Realtime/Storage
- **Edge** — Supabase Edge Functions / privileged middleware
- **External** — layanan pihak ketiga seperti Midtrans, FCM, Mapbox, Twilio
- **Primary Owner** — platform yang memimpin implementasi fitur
- **Secondary Owners** — platform yang mendukung tetapi bukan pusat UX/domain
- **Operational Owner** — siapa yang paling sering berubah saat fitur ini dikembangkan

### Legend
- **Primary** = pusat fitur / owner utama
- **Secondary** = mendukung fitur
- **Incidental** = hanya disentuh kecil atau tidak menjadi pusat perubahan
- **N/A** = tidak relevan

---

## High-Level Ownership Matrix

| Feature | Mobile | Web | Backend | Edge | External | Primary Owner | Secondary Owners |
|---|---|---|---|---|---|---|---|
| PDPL Consent | Primary | Incidental | Primary | Secondary | N/A | Mobile + Backend | Edge |
| Marketing Consent | Secondary | Primary | Primary | Incidental | FCM | Web + Backend | Mobile |
| Offline Maps | Primary | N/A | Incidental | N/A | Mapbox | Mobile | External |
| Panic Alert | Primary | N/A | Primary | Primary | FCM, Twilio | Mobile + Edge | Backend |
| Virtual Muthawif | Primary | N/A | Secondary | N/A | Mapbox | Mobile | Backend |
| Subscription Paywall | Primary | Incidental | Primary | Primary | Midtrans | Mobile + Backend | Edge |
| B2B Volume Licensing | Incidental | Primary | Primary | Primary | Midtrans | Web + Backend | Edge |
| Rombongan Group Management | Primary | Secondary | Primary | Secondary | N/A | Shared (Mobile + Backend) | Web |
| Jejak Ibadah | Primary | Secondary | Primary | Primary | Storage | Shared (Mobile + Edge) | Web + Backend |
| Agency Onboarding | N/A | Primary | Primary | Secondary | Storage | Web + Backend | Edge |
| Alumni Broadcast | Receive only | Primary | Primary | Secondary | FCM | Web + Backend | Mobile |
| Admin Tools | Secondary | Primary | Primary | Secondary | Multiple | Web + Backend | Mobile |
| DX Tools | Primary | Secondary | Secondary | Incidental | N/A | Mobile | Web Admin |

---

## Detailed Feature Ownership

## 1. PDPL Consent

### Feature Summary
Mengatur onboarding consent, withdrawal, deletion request, dan access gating berbasis consent.

### Ownership
| Layer | Role |
|---|---|
| Mobile | **Primary** |
| Web | Incidental |
| Backend | **Primary** |
| Edge | Secondary |
| External | N/A |

### Why
- UI consent onboarding dan settings withdrawal hidup di mobile
- source of truth consent state ada di backend
- deletion / revoke workflows membutuhkan backend enforcement
- edge hanya mendukung endpoint khusus bila diperlukan

### Implementation Guidance
Jika task menyangkut:
- onboarding UI
- consent gating
- local purge
maka fokus utama: **Mobile**

Jika task menyangkut:
- consent events
- deletion requests
- legal state persistence
maka fokus utama: **Backend**

---

## 2. Marketing Consent

### Feature Summary
Mengatur opt-in/opt-out promosi dari travel agency secara terpisah dari consent operasional.

### Ownership
| Layer | Role |
|---|---|
| Mobile | Secondary |
| Web | **Primary** |
| Backend | **Primary** |
| Edge | Incidental |
| External | FCM |

### Why
- user bisa mengelola preference dari UI mobile/profile
- travel admin menggunakan web untuk broadcast
- backend menjadi source of truth untuk eligibility
- FCM hanya delivery channel

### Implementation Guidance
Jika task tentang:
- audience filtering
- per-agency preference
- broadcast gating
maka fokus: **Web + Backend**

---

## 3. Offline Maps

### Feature Summary
Mapbox offline rendering, tile download, local storage management, dan storage limit enforcement.

### Ownership
| Layer | Role |
|---|---|
| Mobile | **Primary** |
| Web | N/A |
| Backend | Incidental |
| Edge | N/A |
| External | Mapbox |

### Why
- seluruh pengalaman maps terjadi di mobile
- backend bukan pusat fitur ini
- Mapbox adalah dependency penting, tetapi bukan owner domain

### Implementation Guidance
Perubahan pada feature ini hampir selalu berarti:
- Flutter UI/state
- local storage
- Mapbox integration
- storage guardrails

---

## 4. Panic Alert

### Feature Summary
Fitur emergency yang menangkap koordinat user dan mengirim alert ke muthawif dengan fallback berlapis.

### Ownership
| Layer | Role |
|---|---|
| Mobile | **Primary** |
| Web | N/A |
| Backend | Primary |
| Edge | **Primary** |
| External | FCM, Twilio |

### Why
- trigger berasal dari mobile
- routing target, delivery orchestration, fallback, dan provider integration terjadi di edge/backend
- ini adalah fitur shared yang sangat sensitif

### Implementation Guidance
Prompt implementasi panic alert hampir selalu harus mempertimbangkan:
- mobile trigger UX
- backend target resolution
- edge orchestration
- external delivery reliability

### Caution
Jangan menganggap ini feature mobile-only.  
Secara ownership dia adalah:
# **Mobile + Edge co-owned feature**

---

## 5. Virtual Muthawif

### Feature Summary
Doa kontekstual berdasarkan geofence dan local prayer repository.

### Ownership
| Layer | Role |
|---|---|
| Mobile | **Primary** |
| Web | N/A |
| Backend | Secondary |
| Edge | N/A |
| External | Mapbox |

### Why
- pengalaman utamanya mobile
- backend hanya menyediakan data master / sync support
- geofence dan UI logic hidup di client

### Implementation Guidance
Mayoritas perubahan:
- Flutter
- local caching
- geofence detection
- UI presentation

---

## 6. Subscription Paywall

### Feature Summary
Mengatur trial, paywall, checkout, settlement unlock, dan entitlement state.

### Ownership
| Layer | Role |
|---|---|
| Mobile | **Primary** |
| Web | Incidental |
| Backend | **Primary** |
| Edge | **Primary** |
| External | Midtrans |

### Why
- paywall UI dan trial banner hidup di mobile
- backend menyimpan entitlement state
- edge memverifikasi webhook dan unlock
- Midtrans menjadi payment channel

### Implementation Guidance
Jika task menyangkut:
- paywall rendering
- trial countdown
- lock/unlock UX
maka fokus: **Mobile**

Jika task menyangkut:
- settlement verification
- transaction state
- entitlement final
maka fokus: **Backend + Edge**

---

## 7. B2B Volume Licensing

### Feature Summary
Pembelian seat licenses bulk oleh travel agency dengan volume-based pricing.

### Ownership
| Layer | Role |
|---|---|
| Mobile | Incidental |
| Web | **Primary** |
| Backend | **Primary** |
| Edge | **Primary** |
| External | Midtrans |

### Why
- UX inti berada di web dashboard
- total pricing tidak boleh dipercaya dari client
- payment flow membutuhkan backend/edge verification

### Implementation Guidance
Prompt untuk fitur ini biasanya adalah:
# **Web + Backend first**
bukan mobile-first.

---

## 8. Rombongan Group Management

### Feature Summary
Pembuatan rombongan, assignment muthawif, join via PIN, trip lifecycle, bypass access, dan coordination state.

### Ownership
| Layer | Role |
|---|---|
| Mobile | **Primary** |
| Web | Secondary |
| Backend | **Primary** |
| Edge | Secondary |
| External | N/A |

### Why
- jamaah join group di mobile
- agency/muthawif setup group bisa terjadi via web/admin flows
- trip lifecycle dan group state disimpan di backend

### Implementation Guidance
Fitur ini adalah:
# **Shared domain**
dan sering menjadi penghubung antara:
- B2B
- B2C
- access logic
- trip lifecycle

Jangan memperlakukan fitur ini sebagai feature kecil.

---

## 9. Jejak Ibadah

### Feature Summary
Capture foto offline, queue lokal, edge watermark processing, dan CRM gallery exposure.

### Ownership
| Layer | Role |
|---|---|
| Mobile | **Primary** |
| Web | Secondary |
| Backend | Primary |
| Edge | **Primary** |
| External | Storage |

### Why
- capture dan queue berasal dari mobile
- watermark processing terjadi di edge
- hasil akhirnya dipakai di web CRM
- backend menyimpan metadata dan media references

### Implementation Guidance
Fitur ini adalah:
# **Shared media pipeline**
Jangan hanya fokus pada camera UI; perhatikan juga:
- queue semantics
- upload error handling
- expired group handling
- storage contracts

---

## 10. Agency Onboarding

### Feature Summary
Registrasi agency, PPIU input, logo upload, dan bootstrap tenant context.

### Ownership
| Layer | Role |
|---|---|
| Mobile | N/A |
| Web | **Primary** |
| Backend | **Primary** |
| Edge | Secondary |
| External | Storage |

### Why
- feature ini berpusat di dashboard
- backend menyimpan identity/agency context
- logo/media handling dapat menyentuh storage pipeline

### Implementation Guidance
Ini adalah:
# **Web-led feature**

---

## 11. Alumni Broadcast

### Feature Summary
Segmentasi cohort dan pengiriman broadcast promosi kepada alumni yang eligible.

### Ownership
| Layer | Role |
|---|---|
| Mobile | Receive only |
| Web | **Primary** |
| Backend | **Primary** |
| Edge | Secondary |
| External | FCM |

### Why
- composer dan audience selection hidup di web
- backend wajib memfilter eligibility
- mobile hanya penerima akhir

### Implementation Guidance
Jangan mendesain fitur ini dari perspektif mobile sender.
Ini adalah:
# **Web CRM feature with backend gating**

---

## 12. Admin Tools

### Feature Summary
Metrics, trial override, test mode, watermark preview, dan internal controls.

### Ownership
| Layer | Role |
|---|---|
| Mobile | Secondary |
| Web | **Primary** |
| Backend | **Primary** |
| Edge | Secondary |
| External | Multiple |

### Why
- admin portal utama hidup di web
- backend menyediakan state dan privileged operations
- beberapa mobile/admin UX bisa muncul terbatas

### Implementation Guidance
Ini adalah:
# **Web-admin-led feature**
dengan backend yang sangat penting.

---

## 13. DX Tools

### Feature Summary
GPS spoofer, alert loopback, consent reset, dan tooling non-production.

### Ownership
| Layer | Role |
|---|---|
| Mobile | **Primary** |
| Web | Secondary |
| Backend | Secondary |
| Edge | Incidental |
| External | N/A |

### Why
- mayoritas DX tools dibutuhkan untuk testing perilaku mobile lapangan
- beberapa admin toggles bisa muncul di web
- backend hanya mendukung sebagian state

### Implementation Guidance
Ini adalah:
# **Mobile-led internal tooling feature**
dan harus selalu dilihat bersama production gating rules.

---

## Ownership by Platform

## Mobile-led Features
Fitur yang terutama dipimpin oleh mobile:

- `offline-maps`
- `virtual-muthawif`
- `dx-tools`
- bagian besar dari `pdpl-consent`
- bagian besar dari `panic-alert`
- bagian besar dari `subscription-paywall`
- bagian besar dari `jejak-ibadah`
- bagian besar dari `rombongan-group-management`

### Meaning
Jika prompt implementasi menyasar fitur-fitur ini, default context harus:
- Flutter
- local state
- route/UI behavior
- offline behavior
- local persistence

---

## Web-led Features
Fitur yang terutama dipimpin oleh web:

- `agency-onboarding`
- `b2b-volume-licensing`
- `alumni-broadcast`
- bagian besar dari `admin-tools`
- bagian besar dari `marketing-consent`

### Meaning
Jika prompt implementasi menyasar fitur-fitur ini, default context harus:
- React dashboard
- admin/travel workflows
- table/form/filter state
- backend-backed data views

---

## Backend-led Features
Domain yang source of truth-nya sangat bergantung pada backend:

- `pdpl-consent`
- `marketing-consent`
- `subscription-paywall`
- `rombongan-group-management`
- `b2b-volume-licensing`
- `alumni-broadcast`
- `admin-tools`

### Meaning
Jika task mengubah rules, access, lifecycle, retention, atau provisioning:
- jangan berhenti di UI saja
- selalu cek backend implications

---

## Edge-led Features
Fitur yang privileged middleware-nya sangat menentukan:

- `panic-alert`
- `subscription-paywall`
- `b2b-volume-licensing`
- `jejak-ibadah`

### Meaning
Jika task menyentuh:
- Midtrans verification
- Twilio fallback
- watermark processing
- service-role operations

maka Edge harus dianggap sebagai owner penting.

---

## Shared Features Requiring Multi-Surface Coordination
Fitur berikut hampir selalu butuh koordinasi lintas platform:

| Feature | Why it is shared |
|---|---|
| `pdpl-consent` | Mobile UI + backend legal state |
| `marketing-consent` | User preference + CRM broadcast gating |
| `panic-alert` | Mobile trigger + edge delivery + backend target resolution |
| `subscription-paywall` | Mobile UX + backend entitlement + edge settlement |
| `rombongan-group-management` | Mobile join + backend lifecycle + web setup/admin |
| `jejak-ibadah` | Mobile capture + edge watermark + web CRM consumption |

---

## AI Implementation Guidance

## If a feature is Mobile-led
AI should prioritize reading:
1. feature summary
2. feature TRD
3. local storage / offline protocols
4. mobile-related child specs

## If a feature is Web-led
AI should prioritize reading:
1. feature summary
2. feature PRD/TRD
3. relevant API contract docs
4. admin/agency workflow context

## If a feature is Shared
AI should:
- identify all touched surfaces first
- avoid partial changes that break cross-surface assumptions
- check decisions and protocol docs before coding

## If a feature is Edge-led
AI should:
- avoid trusting client payloads
- verify contracts and error paths
- inspect service-role implications

---

## Ownership Matrix by Concern Type

| Concern Type | Dominant Owner |
|---|---|
| Offline UX | Mobile |
| Travel admin workflow | Web |
| Consent persistence | Backend |
| Emergency delivery | Edge + Mobile |
| Payment verification | Edge + Backend |
| Media processing | Edge |
| CRM operations | Web + Backend |
| Tenant isolation | Backend |
| Production gating | Backend + Web Admin + Build config |
| Diagnostic simulation | Mobile + Admin tooling |

---

## Prompting Guidance for Antigravity / Trae
Saat membuat prompt implementasi:

### Always clarify:
- fitur yang disentuh
- surface yang disentuh:
  - mobile?
  - web?
  - backend?
  - edge?
- apakah feature ini shared?
- apakah ada contract / decision / protocol yang harus dibaca dulu?

### Do not assume:
- semua perubahan cukup di UI
- semua rules ada di client
- feature ownership itu tunggal jika sebenarnya shared

---

## Review Guidance for OpenClaw
Saat review/UAT:

### Untuk mobile-led features
cek:
- behavior di device
- state transition
- offline behavior
- UX clarity

### Untuk web-led features
cek:
- form flow
- filtering
- access control
- business workflow consistency

### Untuk shared features
cek:
- cross-surface consistency
- backend consequences
- entitlement/consent/retention side effects

---

## Summary
Feature ownership matrix ini ada untuk mencegah kesalahan umum seperti:
- menganggap fitur shared sebagai fitur mobile-only
- mengubah UI tanpa mengubah backend rule
- mengubah backend rule tanpa memperhatikan UX
- membuat prompt implementasi yang terlalu sempit
- gagal melihat impact lintas platform

Prinsip utamanya:
- setiap fitur punya **owner utama**
- banyak fitur punya **secondary owners**
- beberapa fitur bersifat **deeply shared**
- AI harus menentukan ownership lebih dulu sebelum menulis atau mengubah code

---

## Related Documents
- `docs/00_ai-context/global-summary.md`
- `docs/00_ai-context/system-overview.md`
- `docs/00_ai-context/feature-index.md`
- `docs/00_ai-context/system-rules.md`
- `docs/03_technical/protocols/auth-role-model.md`
- `docs/03_technical/protocols/subscription-access-state-machine.md`
- `docs/03_technical/protocols/trip-lifecycle.md`
- `docs/03_technical/non-functional-requirements.md`