# Feature Brief: B2B Agency Dashboard (Travel Admin)

_Feature ID: F-08_
_Status: Updated for PRD v1.10-FINAL_
_Date: 2026-05-02_
_Author: Hermes (CTO) — updated from PRD v1.10-FINAL_

---

## 1. Problem Statement

Travel agencies need to:
- Register and get verified (PPIU license)
- Purchase seat licenses at their tier pricing
- Manage Jamaah under their travel
- Assign Muthawif leaders to groups
- Send targeted broadcasts to their own Jamaah only
- View analytics for their travel
- White Label customers need full custom-branded dashboard

---

## 2. Goal

Provide a React-based web dashboard where Travel Admin can:
- Register with license upload
- Purchase seat licenses (B2B tier pricing via Midtrans)
- Manage Jamaah and Rombongan
- Assign Muthawif to groups
- Send FCM broadcast to their Jamaah only
- View analytics (licenses, usage, conversion)
- **White Label: full custom branding + exclusive dashboard**

---

## 3. Pricing Model (UPDATED v1.10-FINAL)

### B2B Travel Tiers

| Level | Commitment | Price/pax | Min Total |
|-------|-----------|-----------|-----------|
| Independent | Tidak ada | Rp 90,000 | Rp 90,000/order |
| Small | 45 pax/bulan | Rp 75,000 | Rp 3,375,000 |
| Medium | 90 pax/bulan | Rp 60,000 | Rp 5,400,000 |
| Enterprise | White Label customer | Rp 50,000 | Custom quote |

> **Enterprise tier ONLY for White Label customers.** Tanpa White Label, maksimum tier adalah Medium.

### White Label

| Item | Price |
|------|-------|
| Lisensi White Label | Rp 30,000,000 (sekali bayar, lifetime) |
| Biaya Maintenance | Rp 12,000,000/tahun (mulai tahun ke-2) |

White Label mencakup: custom branding (logo, warna, nama app), subdomain sendiri, **dashboard eksklusif Travel**.

### Lisensi Satuan (All Tiers)

Travel di semua level dapat membeli lisensi satuan di luar komitmen: **Rp 90,000/pax**

---

## 4. User Flows

### Agency Registration
```
Agency visits dashboard URL
       ↓
[Register as Agency] → form:
  - Company name
  - PPIU License number (upload document)
  - Agency logo (upload image, min 200x200px)
  - Admin email/password
       ↓
Submit → pending approval (is_approved: false)
       ↓
Admin reviews → approves → agency notified
       ↓
Agency selects tier (Independent/Small/Medium/Enterprise)
       ↓
Agency can now purchase licenses
```

### Purchase Seat Licenses
```
Agency dashboard → [Buy Licenses]
       ↓
Select tier → System shows pricing:
  Independent: Rp 90,000/pax (no commitment)
  Small: Rp 75,000/pax (45 pax/month commitment)
  Medium: Rp 60,000/pax (90 pax/month commitment)
  Enterprise: Rp 50,000/pax (WHITE LABEL only)
       ↓
Input: Number of pax (N)
       ↓
Total displayed
       ↓
[Checkout] → Midtrans Snap redirect
       ↓
Payment completes → webhook confirms
       ↓
Licenses credited to agency account
```

### Create Package + Assign Muthawif
```
Agency → [New Umrah Package]
       ↓
Form: Package name, dates, Muthawif (select from dropdown)
       ↓
System creates Rombongan with invite code
       ↓
Agency shares invite code + QR with Muthawif
       ↓
Muthawif joins → sees assigned pilgrims (who used code)
       ↓
Jamaah accepts/declines invitation (7-day expiry)
```

### Send Broadcast
```
Agency → [Broadcasts] → [New Broadcast]
       ↓
Select recipient: specific Rombongan or all Jamaah
       ↓
Compose: Title + Message
       ↓
[Send] → FCM push (tagged with travel_id)
       ↓
Delivery report shown (only to THIS travel's Jamaah)
```

### White Label Custom Branding
```
Enterprise (WL) → [Dashboard Settings]
       ↓
Upload: Logo, accent color, app name
       ↓
System generates: custom subdomain + branded login
       ↓
Jamaah of this travel see white-labeled app
```

---

## 5. Scope

### In Scope
- Agency registration with PPIU license upload
- Agency logo upload and storage
- Seat license purchase via Midtrans (tier pricing)
- Tier selection (Independent/Small/Medium/Enterprise)
- Package creation (Rombongan)
- Muthawif assignment
- **Invitation Approval Flow** (Jamaah accept/decline, 7-day expiry)
- FCM broadcast (travel_id scoped — only own Jamaah)
- Analytics: licenses available vs used, conversion rate
- **White Label: full dashboard + custom branding**

### Out of Scope
- Muthawif CRUD beyond assignment
- Financial reporting / invoices
- Automated email marketing
- Two-way chat with pilgrims
- Cross-travel data visibility
- SuperAdmin `/admin` dashboard (for Haramain Pro only)

---

## 6. Muthawif Assignment

- Muthawif must already be a registered user (with `role: "muthawif"`)
- Agency can assign any registered Muthawif to a package
- One Muthawif per Rombongan
- Muthawif can be reassigned (if original unavailable)

---

## 7. Acceptance Criteria

- [ ] Agency can register with PPIU license + logo upload
- [ ] Registration requires admin approval
- [ ] Tier pricing displays correctly per commitment level
- [ ] Midtrans checkout works and confirms payment
- [ ] Licenses credited immediately on webhook confirmation
- [ ] Agency can create Rombongan + assign Muthawif
- [ ] Jamaah receives invitation → can Accept/Decline (7-day expiry)
- [ ] Broadcast sent ONLY to agency's own Jamaah (travel_id scoped)
- [ ] Agency logo stored and used for watermark on photos
- [ ] **White Label: custom branding applied + exclusive dashboard**
- [ ] **Enterprise = White Label only (without WL = max Medium tier)**

---

## 8. Edge Cases

| Case | Handling |
|------|----------|
| PPIU license number invalid | Show error, don't submit |
| Non-WL agency tries to access Enterprise tier | Block + show "Upgrade to White Label" CTA |
| Broadcast to 0 Jamaah | Prevent send, show "No recipients" |
| FCM delivery failure | Show failure count; retry available |
| Midtrans payment pending > 1 hour | Auto-cancel order, credit not applied |
| Invitation expired (7 days) | Jamaah must request new invite from Admin |

---

## 9. Dependencies

- React web app (B2B Travel Admin dashboard)
- Supabase Auth (agency admin accounts + travel_id)
- Supabase Database (agencies, packages, licenses, rombongan_members)
- Supabase Storage (agency logo, photos)
- Midtrans Snap API
- FCM (Firebase Cloud Messaging) — tagged with travel_id
- **White Label: subdomain routing + custom branding engine**

---

## 10. Related PRD References

- PRD Section 3.5: Travel Admin B2B Feature
- PRD Section 3.8: Invitation Approval Flow (Accept/Decline, 7-day)
- PRD Section 4.2: B2B Travel Pricing (4-tier)
- PRD Section 4.2.2: White Label
- PRD Section 3.7: Fitur Tidak Ada — Dasbor Web ❌ → ✅ (WL gets dashboard)
- PRD Section 10.2: Database Schema (rombongan_members, invitations)

---

## 11. Decisions from PRD v1.10-FINAL

| Decision | Source |
|----------|--------|
| Enterprise = White Label customer only | Coach Chaidir, 2026-05-02 |
| White Label DASHBOARD = ✅ (was ❌) | Coach Chaidir, 2026-05-02 |
| Revenue Share Sales Agent = HAPUS | Coach Chaidir, 2026-05-02 |
| Jejak Ibadah REMOVED from Mandiri | Coach Chaidir, 2026-05-02 |
| OSM tiles (not Mapbox) | OQ-02 Resolved |
| SDAIA NRC = HARD REQUIREMENT | Dependencies Table |

---

## 12. Questions — All Resolved

| OQ | Resolution |
|----|------------|
| OQ-02: Mapbox vs OSM | OSM self-hosted tiles |
| OQ-05: SDAIA NRC | HARD REQUIREMENT — verify via SDAIA/SEVE portal |
| OQ-06: Audio doa via earphone | Diperbolehkan di dalam masjid |

