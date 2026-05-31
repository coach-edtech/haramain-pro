# Glossary

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Definitions of key terms used throughout Haramain Pro documentation.

## Core Terms

### Jamaah
A Muslim pilgrim performing Hajj or Umrah. Primary end-user of the mobile app.

### Muthawif
Islamic tour guide specializing in Hajj/Umrah guidance. Provides spiritual guidance during the pilgrimage journey.

### Rombongan
A group of pilgrims traveling together under a travel agency or muthawif. Core organizational unit in the app.

### Travel Admin
Staff member at a travel agency (PPIU) who managesrombongan, passengers, and coordinates with muthawif.

### Sys Admin
System administrator managing the overall platform, agencies, and system-wide settings.

### Safety Pass
B2C subscription product — Rp 120,000 lifetime access to premium safety and spiritual features. Includes 7-day free trial.

### Jejak Ibadah
"Ibadah Trail" — feature that records and timestamps spiritual activities (prayers, dua, visits) with photo evidence and watermarking.

### PDPL
Personal Data Protection Law (Indonesia) — compliance framework governing consent, data retention, and user rights.

### trip_end_at
Timestamp marking the end of a pilgrimage trip. Used to expire group access and trigger data retention policies.

### B2B Invite Bypass
Mechanism allowing travel agencies to invite Jamaah intorombongan without the standard join flow (numeric PIN bypass).

### PPIU
Penyelenggara Perjalanan Ibadah Umrah — licensed travel agency for Umrah pilgrimage in Indonesia.

### Muthawif Field Ops
Mobile operations conducted by muthawif in the field — GPS tracking, group management, emergency response.

### Offline Engine
Mobile subsystem handling data sync, queue management, and local storage when network is unavailable.

## Technical Terms

### RLS
Row Level Security — PostgreSQL/Supabase mechanism for multi-tenant data isolation.

### Isar
Local mobile database (Flutter) — primary storage for offline-first data.

### Mapbox Offline Tiles
Pre-downloaded map regions for offline navigation (max 300MB per region).

### Watermark Sync
Process of applying watermarks to photos before upload, ensuring pilgrimage evidence integrity.

### Fallback Layering
Panic alert escalation: FCM Push → Twilio SMS → WhatsApp → local loopback signal.

## Related
- `docs/03_technical/data-model/` — data entity definitions
- `docs/02_product/personas/` — user role details
