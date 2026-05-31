# Product Vision — Haramain Pro

_Last updated: 2026-04-04_

## Product Overview

**Haramain Pro** is a native Flutter mobile app (iOS/Android) + B2B web dashboard. It is a "Smart Companion" for Umrah and Hajj pilgrims.

## Core Value Proposition

1. **Safety** — Offline GPS navigation, Panic Button with silent-mode bypass
2. **Spiritual Guidance** — Virtual Muthawif with location-contextual prayer surfacing
3. **CRM for Travel Agencies** — "Jejak Ibadah" shared photo album as retention engine

## Target Users

| Actor | Description |
|-------|-------------|
| **B2C Pilgrim** | Primary end-user executing Umrah/Hajj journey |
| **B2B Travel Agency** | Purchases bulk licenses, manages groups |
| **Muthawif** | Field group leader, coordinates pilgrims, captures photos |
| **System Admin** | Internal operator, manages trials, updates regulations |

## Business Model

- **B2C**: Rp 120,000 lifetime "Haramain Safety Pass" via Midtrans
- **B2B**: Volume licensing (Rp 80-90k/pax based on quantity)
- **7-day free trial** for premium features

## Key Features

- Offline Mapbox maps (max 300MB)
- Panic Button → FCM high-priority to Muthawif (bypasses silent/DND)
- Virtual Muthawif (geofenced prayer surfacing)
- QR/6-digit group join code
- "Jejak Ibadah" CRM photo gallery with agency watermarking
- PDPL-compliant consent flow

## Market Goals (Year 1)

- 110,000–130,000 pilgrims (SOM)
- 40–70 B2B travel agency partnerships
- Rp 11–13 billion revenue

## Technical Stack

- **Mobile**: Flutter (Riverpod), Mapbox SDK, SQLite local storage
- **Backend**: Supabase (PostgreSQL, Auth, Storage, Edge Functions)
- **Push**: Firebase Cloud Messaging (iOS Critical Alerts)
- **Payments**: Midtrans Snap API

## Out of Scope

- PWA for mobile
- Generative AI voice / WhatsApp bot
- Direct Nusuk API integration
- Real-time generative AI voice interactions

---

_Generated from PRD.md — 2026-04-04_
