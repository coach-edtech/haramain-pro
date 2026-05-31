# HARAMAIN PRO — Frontend Specification

**Version:** 1.0
**Date:** 2026-05-25
**Status:** DRAFT — Ready for Trae Agent Handoff
**Author:** Hermes (CTO)
**For:** Frontend Agent (Trae Desktop)

---

## Changelog

| Version | Date | Change |
|---------|------|--------|
| 1.0 | 2026-05-25 | Initial spec from PRD v1.10 + v1.12 |

---

# SECTION 1: Source of Truth

1. **PRD Main:** `PRD/Haramain-Pro-PRD-v1.10-FINAL.md` — Features, user flows, requirements
2. **PRD Dashboards:** `PRD/Haramain-Pro-PRD-v1.12-Dashboards.md` — Web dashboard specs
3. **This document:** Visual + interaction spec, component definitions, build order

---

# SECTION 2: Applications

Haramain Pro has TWO frontend applications:

## App 1: Mobile App (Flutter)
**Path:** `apps/haramain_pro/`
**Stack:** Flutter (iOS + Android)
**Channel:** B2C — Jamaah, Muthawif, Team-Support, Sales Agen, Muthawif-Mandiri
**Priority:** PRIMARY — revenue-critical

## App 2: Web Dashboard (React)
**Path:** `apps/web-dashboard/`
**Stack:** React + Tailwind CSS + Vite + Supabase
**Channel:** B2B — Travel Admin, SuperAdmin, Admin HaramainPro
**Priority:** SECONDARY — operational tooling

---

# SECTION 3: Design Language

## 3.1 Visual Identity — "Kemewahan Tanah Suci"

**Aesthetic Direction:** Luxury Islamic — terinspirasi arsitektur Masjidil Haram, kaligrafi modern, langit malam Makkah dengan bintang. Tidak berlebihan, tidak generik "Islamic startup." Kontras tinggi, warna-warna profond.

## 3.2 Color Palette

```
Primary (Deep Emerald):
  emerald-900  #064e3b   — Primary dark, headers
  emerald-700  #047857   — Primary base
  emerald-500  #10b981   — Interactive elements
  emerald-100  #d1fae5   — Subtle backgrounds

Accent Gold:
  amber-500    #f59e0b   — Primary accent, CTAs, highlights
  amber-400    #fbbf24   — Hover states
  amber-600    #d97706   — Active states
  amber-50     #fffbeb   — Warm background tints

Danger (Panic Red):
  red-600      #dc2626   — Panic button
  red-500      #ef4444   — Panic button hover
  red-100      #fee2e2   — Alert backgrounds

Neutral:
  slate-900    #0f172a   — Text primary
  slate-600    #475569   — Text secondary
  slate-200    #e2e8f0   — Borders
  slate-50     #f8fafc   — Page background
  white        #ffffff   — Cards, surfaces

Arabic Texture:
  cream        #fef9e7   — Alternative warm surface
  dark-navy    #0c1929   — Alternate dark theme
```

## 3.3 Typography

```
Display / Headers:
  Font: "Playfair Display" (Google Fonts) — elegant serif untuk headings
  Fallback: Georgia, serif

Body / UI:
  Font: "Inter" (Google Fonts) — clean sans-serif untuk body dan UI
  Fallback: system-ui, sans-serif

Arabic / Doa:
  Font: "Amiri Quran" (Google Fonts) — untuk teks Arab dan doa
  Fallback: "Traditional Arabic", serif

Scale (Mobile):
  Display: 32px / 700
  H1:      28px / 700
  H2:      24px / 600
  H3:      20px / 600
  Body:    16px / 400
  Caption: 14px / 400
  Small:   12px / 400

Scale (Web Dashboard):
  H1:      24px / 700
  H2:      20px / 600
  H3:      16px / 600
  Body:    14px / 400
  Caption: 12px / 400
```

## 3.4 Spacing System

```
Base unit: 4px

Spacing scale:
  1:  4px   (xs gaps)
  2:  8px   (tight)
  3:  12px  (compact)
  4:  16px  (default)
  5:  20px  (comfortable)
  6:  24px  (section gaps)
  8:  32px  (card padding)
  10: 40px  (section dividers)
  12: 48px  (major sections)
  16: 64px  (page margins mobile)
```

## 3.5 Border Radius

```
Cards:       12px
Buttons:     8px (default), 24px (pill), 4px (small)
Inputs:      8px
Modals:      16px
Bottom sheet: 24px (top corners)
```

## 3.6 Shadows

```
Elevated:   0 4px 6px -1px rgba(0,0,0,0.1), 0 2px 4px -1px rgba(0,0,0,0.06)
Card:        0 1px 3px rgba(0,0,0,0.1), 0 1px 2px rgba(0,0,0,0.06)
Panic Button: 0 0 20px rgba(220,38,38,0.4) — red glow for emergency
Floating:    0 10px 25px -5px rgba(0,0,0,0.1), 0 8px 10px -5px rgba(0,0,0,0.04)
```

## 3.7 Motion Philosophy

**Principle:** Motion should feel reverent, not playful. Like the quiet precision of a call to prayer — not bouncy or playful.

```
Easing:
  Default:    ease-out (300ms) — smooth deceleration
  Enter:      ease-out (200ms) — quick, confident
  Exit:       ease-in (200ms) — swift departure
  Bounce:     NEVER — no spring/bounce animations

Page transitions:
  Mobile:     Fade + slight slide up (20px), 300ms
  Web:        Fade only, 200ms

Micro-interactions:
  Button press: scale(0.97), 100ms
  Card hover:  translateY(-2px), box-shadow increase, 200ms
  Icon tap:    scale(0.9), 80ms

Panic Button animation:
  Idle:       Subtle pulse (scale 1.0 → 1.02), 2s infinite
  Pressed:    Rapid pulse (scale 1.0 → 1.08), 300ms + red glow intensify
```

## 3.8 Icon Library

```
Library: Lucide React (web) / Lucide Icons (Flutter)
Style: Outlined, 24px default, 1.5px stroke
Special icons:
  - Panic Button: Custom — red circle with hand/thumb-up silhouette
  - Map: Custom pin with dome silhouette
  - Doa: Custom — open book with moon crescent
  - Jamaah: Users icon with abaya silhouette
```

## 3.9 Imagery Guidelines

```
Photography style:
  - Warm, golden-hour lighting (Madinah sunrise, Makkah evening)
  - Real Jamaah (diverse, Indonesian context)
  - Architectural detail shots (dome patterns, geometric arabesque)

Illustrations:
  - Geometric arabesque patterns for decorative dividers
  - Minimalist line illustrations for empty states
  - NO cartoon-style illustrations

Maps:
  - Dark theme map tiles (satellite + vector hybrid)
  - Gold accent for points of interest
  - Emerald for current location marker
```

---

# SECTION 4: Mobile App (Flutter) — Component Inventory

## 4.1 Screen Structure

```
App Shell (Flutter)
├── Splash Screen (logo + tagline)
├── Onboarding Flow (3 screens)
│   ├── Screen 1: Welcome + value prop
│   ├── Screen 2: How Panic Button works
│   └── Screen 3: Offline map preview
├── Auth Flow
│   ├── Login (phone/email)
│   ├── Register
│   ├── Forgot Password
│   └── Invitation Code Entry (for Jamaah via Travel)
├── Role-Based Main Shell
│   ├── Jamaah Shell (Bottom nav)
│   │   ├── Home (Panic + Map preview + Doa)
│   │   ├── Groups
│   │   ├── Album
│   │   └── Profile
│   ├── Muthawif Shell (Bottom nav + FAB)
│   │   ├── Home (group overview + Panic receive)
│   │   ├── Groups
│   │   ├── Camera
│   │   ├── Broadcast
│   │   └── Profile
│   ├── TeamSupport Shell
│   │   ├── Home (assigned Jamaah)
│   │   ├── Groups
│   │   └── Profile
│   ├── SalesAgent Shell
│   │   ├── Home (prospect stats)
│   │   ├── Prospects
│   │   ├── Content Bank
│   │   ├── Katalog
│   │   └── Earnings
│   └── MuthawifMandiri Shell
│       ├── Home (group + Panic)
│       ├── Groups
│       ├── Invite
│       ├── Broadcast
│       └── Profile
├── Feature Screens (modal/full-page)
│   ├── Offline Map Viewer
│   ├── Panic Alert Detail
│   ├── Doa Reader
│   ├── Album Gallery
│   ├── Camera (Jejak Ibadah)
│   └── Settings
└── Travel Admin (if invited) — minimal, read-only
```

## 4.2 Core Components

### PanicButton
```
Widget: PanicButton
Location: Home screen (Jamaah, MuthawifMandiri)
Size: 80x80dp (mobile), prominent
States:
  - idle:        red-600 background, subtle pulse animation, hand icon white
  - pressed:    red-500, scale 1.08, intense glow
  - loading:    spinner overlay, "Mengirim..." text
  - sent:       green-600 checkmark, "Telah dikirim"
  - acknowledged: green + responder name + ETA
  - error:      red + retry icon

Behavior:
  - Debounce 30 detik — subsequent presses ignored during cooldown
  - Confirmation dialog: "Kirim Panic Alert?" (can be disabled in settings)
  - Haptic feedback on press (heavy impact)
```

### BottomNavBar
```
Widget: CustomBottomNav
Items: 4 (adjustable per role)
Style: white background, icons + labels, emerald-600 when active
Height: 64dp + safe area
Behavior: Cross-fade between tabs, no page jump
```

### GroupCard
```
Widget: GroupCard
Content: Group name, member count, status badge, travel name (if applicable)
States: active (green border), alumni (muted), pending (amber)
Actions: Tap → Group detail, long-press → quick actions
```

### JamaahAvatar
```
Widget: JamaahAvatar
Content: Circular avatar with role badge
Size: 40dp (list), 64dp (detail)
Badge: Role-colored dot (Muthawif=emerald, Jamaah=blue, TS=amber)
Offline indicator: greyed out + "Offline" label
```

### DoaCard
```
Widget: DoaCard
Content: Arabic text (Amiri Quran font), latin, terjemahan
Header: Location badge (e.g., "📍 Ka'bah")
Audio button: earphone icon (earphone-only playback)
Bookmark toggle
```

### MapWidget
```
Widget: OfflineMapPreview
Size: Full-width, 200dp height on home
Content: Current location pin, nearby POI dots
Overlay: Distance to nearest sacred site
Action: Tap → full map viewer
```

### AlertBanner
```
Widget: AlertBanner (toast-style)
Types: info (slate), success (emerald), warning (amber), error (red)
Position: Top of screen, below status bar
Animation: Slide down + fade in, auto-dismiss 4s
Action: Optional CTA button
```

### EmptyState
```
Widget: EmptyState
Content: Illustration (geometric, muted), headline, description, CTA button
Usage: Empty group, no album photos, no prospects
```

## 4.3 Mobile Screen Specifications

### Home (Jamaah Role)
```
Layout:
  ┌─────────────────────────────┐
  │ Greeting + date (Hijri/Gregorian)
  │ Panic Button (centered, 80dp)
  │ "Tekan jika butuh bantuan"
  ├─────────────────────────────┤
  │ Map Preview Widget (200dp)
  │ "Peta Luring Aktif"
  ├─────────────────────────────┤
  │ Next Prayer + countdown
  │ Doa Suggestion card
  ├─────────────────────────────┤
  │ Active Groups (horizontal scroll)
  └─────────────────────────────┘
```

### Home (Muthawif Role)
```
Layout:
  ┌─────────────────────────────┐
  │ Greeting + group name
  │ Incoming Alert Banner (if any)
  │ Quick Stats: X Jamaah, Y lokasi
  ├─────────────────────────────┤
  │ Group Members list (compact)
  │ Status indicators per Jamaah
  ├─────────────────────────────┤
  │ FAB: Broadcast (green, 56dp)
  └─────────────────────────────┘
```

### Offline Map Viewer (Full Page)
```
Layout:
  ┌─────────────────────────────┐
  │ [←] [Search] [Layers] [⊕]  │  ← App bar
  ├─────────────────────────────┤
  │                             │
  │     Full-screen map         │
  │     (OSM offline tiles)     │
  │                             │
  │  [Current location pin]    │
  │  [POI markers gold]        │
  │  [Route line emerald]       │
  │                             │
  ├─────────────────────────────┤
  │ Bottom sheet: POI details  │
  │ or current location info   │
  └─────────────────────────────┘
```

### Broadcast Composer
```
Layout:
  ┌─────────────────────────────┐
  │ [←] Broadcast          [Send]
  ├─────────────────────────────┤
  │ To: [Group Name ▼]
  │ [        Message input   ] │
  │    [Attach photo 📷]        │
  │ [Schedule] [Send Now]       │
  └─────────────────────────────┘
```

---

# SECTION 5: Web Dashboard (React) — Component Inventory

## 5.1 Page Structure

```
Web Dashboard (/apps/web-dashboard/)
├── /login
├── /admin/                    ← SuperAdmin + Admin HaramainPro
│   ├── Dashboard              ← Platform overview
│   ├── SeatLicenses           ← License management
│   ├── Travels                ← Travel accounts
│   ├── Billing                ← Invoicing
│   ├── Users                  ← Platform users
│   └── System                 ← Health monitoring
└── /travel-admin/             ← Travel Admin
    ├── Dashboard              ← Travel overview
    ├── SeatLicenses           ← Self-purchase / manage
    ├── Payments               ← Payment history
    ├── CRM                    ← Jamaah lifecycle
    ├── OTA                    ← Update management
    ├── Team                   ← Muthawif + TS management
    └── Agents                 ← Sales agents
```

## 5.2 Layout System

```
Desktop-first, mobile-responsive.
Max content width: 1280px centered.
Sidebar: 256px fixed (collapsible to 64px icons-only on tablet).

Page layout:
  ┌────────┬──────────────────────────────────┐
  │ Sidebar│ Header (breadcrumb + user menu)   │
  │  256px ├──────────────────────────────────┤
  │        │                                  │
  │        │  Page Content                    │
  │        │  (cards, tables, forms)          │
  │        │                                  │
  │        │                                  │
  └────────┴──────────────────────────────────┘
```

## 5.3 Web Component Library

### StatsCard
```
Props: title, value, change (%), icon, trend
Style: White card, 12px radius, subtle shadow
States: loading (skeleton), populated, error (muted)
Variants: default, highlighted (amber border-left)
```

### DataTable
```
Features: sortable columns, pagination, row selection, bulk actions
Style: Clean rows, alternating subtle backgrounds, hover highlight
States: loading (skeleton rows), empty (illustration + message), error
Actions: Row click → detail, kebab menu → quick actions
```

### Sidebar Navigation
```
Style: Dark slate background (#0f172a), white text, gold active indicator
Items: Icon + label, active = gold left border + emerald text
Collapse: Icon-only mode (64px), tooltip on hover
```

### Form Components
```
Inputs: slate-200 border, 8px radius, focus: emerald-500 ring
Select: Custom dropdown, searchable
Buttons: Primary (emerald-600), Secondary (slate-100), Danger (red-600)
All inputs: 40px height (desktop), error states with red border + message
```

### Alert/Notification
```
Types: success, warning, error, info
Style: Colored left border, icon, message, optional dismiss
Position: Top-right toast stack (max 3 visible)
Animation: Slide in from right, fade out
```

### Modal
```
Overlay: rgba(0,0,0,0.5), blur(4px)
Card: White, 16px radius, max-width 560px
Animation: Fade + scale from 0.95
```

---

# SECTION 6: Web Dashboard — Page Specifications

## 6.1 /admin/Dashboard (SuperAdmin)

```
Purpose: Platform-wide overview

Widgets:
  ┌─────────────────────────────────────────────┐
  │ Total Jamaah    Total Travel   Revenue MTD  │
  │ [12,450]        [38]           [Rp 847jt]   │
  ├─────────────────────────────────────────────┤
  │ Seat License Usage (bar chart)              │
  │ [======70%=====  ] 32,450/46,000 seats     │
  ├─────────────────────────────────────────────┤
  │ Panic Alerts Today: [X]  │  Active Groups   │
  ├─────────────────────────────────────────────┤
  │ Recent Activity Feed (table, last 10)       │
  │ - New Travel signup: "Al-Mabrur Travel"     │
  │ - Panic alert: Jamaah #8821 acknowledged   │
  │ - License purchased: "Mekkah Wisata" 50seat│
  └─────────────────────────────────────────────┘
```

## 6.2 /admin/SeatLicenses

```
Purpose: Track all seat license purchases + consumption

Table columns:
  | Travel Name | Plan | Total Seats | Used | Available | Status | Expiry |

Actions:
  - View detail → seat consumption breakdown
  - Adjust seats (add/remove)
  - Extend expiry
  - Issue refund (warning: confirmation required)

Filters: Status (active/expired/expiring-soon), Plan tier, Date range
```

## 6.3 /admin/Travels

```
Purpose: Manage all travel company accounts

Table columns:
  | Travel Name | PPIU License | Jamaah Count | Seat License | WL Status | Joined |

Actions:
  - View detail → full travel profile
  - Enable/Disable White Label
  - Access audit log
  - Impersonate (debug only, logged)
```

## 6.4 /travel-admin/Dashboard

```
Purpose: Travel Admin's home base

Widgets:
  ┌─────────────────────────────────────────────┐
  │ Jamaah Aktif    Grup Aktif    Panic Alerts  │
  │ [342]           [8]           [2 hari ini]   │
  ├─────────────────────────────────────────────┤
  │ Seat License: [====45/50=====] 5 tersisa   │
  │ [Beli Seat License] ← CTA button           │
  ├─────────────────────────────────────────────┤
  │ Recent Jamaah Activity                      │
  │  - 3 Jamaah baru join via kode              │
  │  - 1 Panic alert acknowledged               │
  ├─────────────────────────────────────────────┤
  │ Quick Actions                               │
  │ [ 生成 Kode ] [ Kirim Broadcast ] [+ Jamaah]│
  └─────────────────────────────────────────────┘
```

## 6.5 /travel-admin/CRM

```
Purpose: Full Jamaah lifecycle management

Sections:
  1. Funnel Overview: Lead → Interested → Booked → Active → Alumni
  2. Jamaah Table: Searchable, filterable, sortable
  3. Individual Jamaah Profile (slide-over panel):
     - Contact info
     - Join date + travel package
     - Panic alert history
     - Album access
     - Notes (internal)
```

## 6.6 /travel-admin/Agents

```
Purpose: Sales Agent management

Table columns:
  | Agent Name | Code | Leads | Converted | Earnings | Status |

Stats:
  - Total earnings paid
  - Pending payouts
  - Top performer badge
```

---

# SECTION 7: Interaction Patterns

## 7.1 Panic Button Flow (Mobile)

```
1. User taps Panic Button
   → Heavy haptic (if available)
   → Button scales to 1.08
   → Confirmation dialog (if enabled): "Kirim Panic Alert?"
   → User confirms

2. Sending state
   → Button shows spinner + "Mengirim..."
   → GPS coordinates fetched (cached if fails)
   → FCM Critical Alert dispatched

3. Sent state (< 5s target)
   → Button turns green + checkmark
   → Toast: "Alert terkirim ke Muthawif"
   → Audio confirmation (if device supports)

4. Acknowledged state (when Muthawif responds)
   → Full-screen takeover (if app backgrounded): "Muthawif Ahmad menuju lokasi Anda"
   → Show responder name + ETA
   → Map with responder location

5. Resolved (30 min default or manual)
   → Return to normal state
```

## 7.2 Offline Map Download Flow

```
1. First launch after install:
   → Banner: "Download peta Makkah & Madinah untuk navigasi luring?"
   → "Download Sekarang (250MB)" | "Nanti"

2. Download progress:
   → Full-screen modal with progress bar
   → "Mengunduh peta... 45%"
   → Can background — notification on complete

3. Download complete:
   → Confirmation toast
   → Map ready indicator in-app

4. Update flow (OTA):
   → Silent background update if < 20MB delta
   → Notification if major update
```

## 7.3 Join Group via PIN Flow

```
1. User receives PIN from Muthawif (WhatsApp/verbal)
2. User opens app → prompted to enter PIN
3. User enters 6-char PIN (e.g., "HM7X2K")
4. Validation:
   → Valid + not expired → "Bergabung dengan [Group Name]?"
   → Valid + expired → "Kode sudah kadaluarsa"
   → Invalid → "Kode tidak valid"
5. Confirm → Jamaah added to group, paywall bypassed
6. Redirect to Group Home
```

---

# SECTION 8: Technical Stack

## Mobile (Flutter)

```
Framework: Flutter 3.x (iOS + Android)
State Management: Riverpod or BLoC
Local Storage: Hive (offline data, doa library)
Maps: flutter_map + OSM tiles (offline-capable)
Push: Firebase Cloud Messaging (FCM) with Critical Alert entitlement
Backend: Supabase (Auth, DB, Storage, Realtime)
Payments: Xendit (Flutter SDK)
Image Compression: flutter_image_compress
Audio: just_audio (doa playback)
```

## Web Dashboard (React)

```
Framework: React 18 + Vite
Styling: Tailwind CSS (current config preserved)
State: React Context + hooks (no Redux needed)
Routing: React Router v6 (current)
Backend: Supabase (Auth, DB, Realtime)
Charts: Recharts or Tremor
Tables: TanStack Table or custom
Icons: Lucide React (already in use)
```

---

# SECTION 9: Build Order

## Phase 1: Web Dashboard (Priority — faster iteration)

```
Step 1: Update Tailwind config with design system colors
        → Current green palette → new emerald + amber palette

Step 2: Component library refinement
        → Restyle StatsCard, DataTable, Sidebar to design spec
        → Add new components: AlertBanner, Modal, EmptyState

Step 3: Page completion (based on PRD v1.12)
        → Admin: Billing, System Health
        → TravelAdmin: Agents, OTA

Step 4: Polish
        → Animations, loading states, error states
        → Responsive check on tablet
```

## Phase 2: Mobile App — Core UI (Priority — revenue-critical)

```
Step 1: Project setup + design system
        → Colors, typography, spacing as Flutter theme

Step 2: App shell + navigation
        → Bottom nav per role
        → Auth flow

Step 3: Panic Button (most critical feature)
        → Full flow: press → send → acknowledge
        → Haptic + audio feedback
        → Confirmation dialog

Step 4: Offline Map viewer
        → OSM tiles integration
        → Current location
        → POI markers

Step 5: Group management
        → Join via PIN
        → View members
        → Broadcast (Muthawif only)
```

---

# SECTION 10: Assets Required

## Fonts (Google Fonts — free)
- Playfair Display (400, 600, 700)
- Inter (400, 500, 600, 700)
- Amiri Quran (regular)

## Icons
- Lucide React / Lucide Icons (MIT license)
- Custom: Panic Button icon (SVG, to be designed)

## Images
- Splash screen: Haramain Pro logo + Makkah night sky background
- Onboarding illustrations: 3 geometric/architectural illustrations
- Empty states: Geometric arabesque patterns
- Map tiles: OSM Makkah + Madinah (pre-downloaded)

---

# SECTION 11: Out of Scope (v1)

- Video recording in Jejak Ibadah
- Offline SMS fallback (when network completely down)
- White Label app customization (theming per travel)
- In-app voice call (Muthawif ↔ Jamaah)
- Arabic OCR for doa translation
- Apple Watch / WearOS companion app
