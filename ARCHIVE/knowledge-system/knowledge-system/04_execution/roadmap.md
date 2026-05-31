# Implementation Roadmap — Haramain Pro

## Source
Imported from Paraflow-generated docs (`paraflow-product-docs/paraflow/Feature Plan/implementation_plan.md`)

## Version
1.0 — Imported 2026-04-27

## Timeline Overview
- **Total Duration**: 24 weeks (6 months)
- **MVP Target**: Week 16
- **Production Launch**: Week 24
- **Post-Launch**: Continuous improvement and feature expansion

---

## Phase 1: Foundation & Core Safety (Weeks 1-6)

### Sprint 1-2: Project Setup & Infrastructure (Weeks 1-4)

#### Week 1: Environment Setup
**Mobile Team**
- [ ] Initialize Flutter project with clean architecture structure
- [ ] Configure iOS/Android build environments
- [ ] Set up Riverpod state management
- [ ] Implement base repository pattern and dependency injection
- [ ] Configure environment variables and build flavors (dev, staging, prod)

**Web Team**
- [ ] Initialize Next.js 14 project with TypeScript
- [ ] Configure Tailwind CSS and design system foundations
- [ ] Set up Zustand stores and React Query
- [ ] Implement authentication layout structure
- [ ] Configure environment variables

**Backend Team**
- [ ] Initialize NestJS project with modular architecture
- [ ] Set up PostgreSQL database with Docker
- [ ] Configure Prisma ORM and initial schema
- [ ] Set up Redis for caching and sessions
- [ ] Implement JWT authentication strategy
- [ ] Configure API documentation (Swagger)

**DevOps**
- [ ] Set up GitHub repository with branch protection
- [ ] Configure Docker Compose for local development
- [ ] Set up CI/CD pipelines (GitHub Actions)
- [ ] Provision development AWS infrastructure (RDS, S3, ElastiCache)

#### Week 2: Authentication & User Management
**Mobile Team**
- [ ] Implement login screen UI
- [ ] Implement registration screen UI
- [ ] Build authentication flow (login, register, token refresh)
- [ ] Implement secure token storage (flutter_secure_storage)
- [ ] Add biometric authentication option

**Web Team**
- [ ] Build login page
- [ ] Build agency registration page
- [ ] Implement authentication context and protected routes
- [ ] Add session management with auto-refresh

**Backend Team**
- [ ] Implement user registration endpoint with password hashing
- [ ] Implement login endpoint with JWT token generation
- [ ] Build token refresh mechanism
- [ ] Create user CRUD endpoints
- [ ] Implement role-based access control (RBAC) guards
- [ ] Add email validation and duplicate checks

#### Week 3: PDPL Compliance Foundation
**Mobile Team**
- [ ] Design and implement PDPL onboarding screens
- [ ] Build consent collection UI (location, biometric, data processing)
- [ ] Implement consent storage in local SQLite
- [ ] Create consent settings screen
- [ ] Add data deletion request UI

**Backend Team**
- [ ] Create `pdpl_compliance` module
- [ ] Build consent tracking database schema
- [ ] Implement consent grant/withdraw endpoints
- [ ] Create data deletion queue system
- [ ] Add audit logging for consent changes
- [ ] Build 7-day grace period scheduler for deletions

**Legal/Compliance**
- [ ] Finalize privacy policy text (Indonesian, Arabic, English)
- [ ] Review PDPL consent flow with legal counsel
- [ ] Prepare NRC registration documentation

#### Week 4: Local Database & Offline Architecture
**Mobile Team**
- [ ] Set up SQLite database with migration system
- [ ] Create local tables schema (GPS queue, photo queue, cached data)
- [ ] Implement repository pattern with offline/online data sources
- [ ] Build sync manager for offline-first architecture
- [ ] Add connectivity monitoring service
- [ ] Implement exponential backoff retry mechanism

**Backend Team**
- [ ] Build sync endpoints for batch GPS uploads
- [ ] Implement conflict resolution strategy
- [ ] Add timestamp-based delta sync
- [ ] Create data validation middleware

### Sprint 3-4: Offline Maps & Location Tracking (Weeks 5-8)

#### Week 5: Mapbox Integration
**Mobile Team**
- [ ] Integrate Mapbox Maps SDK
- [ ] Implement offline region download for Makkah
- [ ] Implement offline region download for Madinah
- [ ] Build map UI with user location marker
- [ ] Add storage management (check available space)
- [ ] Show download progress UI

**Backend Team**
- [ ] Generate and host offline map tile packages (.mbtiles)
- [ ] Create map metadata API endpoint
- [ ] Set up CDN distribution (CloudFront)
- [ ] Implement version checking for map updates

#### Week 6: GPS Tracking System
**Mobile Team**
- [ ] Implement foreground GPS tracking with geolocator
- [ ] Implement background GPS tracking service
- [ ] Request iOS/Android location permissions properly
- [ ] Build GPS data queue in SQLite
- [ ] Implement batch upload scheduler (every 5 minutes)
- [ ] Add movement detection for battery optimization

**Backend Team**
- [ ] Create `location` module with GPS tracking endpoints
- [ ] Build bulk GPS insert endpoint
- [ ] Implement GPS history query with spatial indexing
- [ ] Create 30-day auto-purge scheduler (PDPL compliance)
- [ ] Add geospatial queries for proximity detection

#### Week 7: Geofencing & Virtual Muthawif
**Backend Team**
- [ ] Create `geofence` module
- [ ] Seed database with sacred location boundaries:
  - Ka'bah (21.4225°N, 39.8262°E, 500m radius)
  - Sa'i corridor
  - Raudhah (24.4672°N, 39.6111°E, 200m radius)
  - Jabal Rahmah
- [ ] Add prayer library in 3 languages (Arabic, Latin, Indonesian)
- [ ] Build geofence list API endpoint

**Mobile Team**
- [ ] Download and cache geofence data on app start
- [ ] Implement proximity monitoring service
- [ ] Trigger local notifications when entering geofence
- [ ] Build prayer detail screen with Arabic/Latin/ID text
- [ ] Add audio playback for prayers (optional)

#### Week 8: Panic Button & Emergency Alerts
**Mobile Team**
- [ ] Design prominent panic button UI (always accessible)
- [ ] Implement panic button action (capture GPS, send alert)
- [ ] Queue panic alerts locally if offline
- [ ] Retry failed alerts with high priority

**Backend Team**
- [ ] Create `emergency` module
- [ ] Build panic alert endpoint
- [ ] Implement FCM high-priority notification sender
- [ ] Configure silent-mode bypass for iOS (criticalAlert)
- [ ] Configure Do Not Disturb bypass for Android (FULL_SCREEN_INTENT)
- [ ] Store panic alert history

---

## Phase 2: Monetization & B2C Features (Weeks 7-12)

### Sprint 5-6: Trial System & Paywall (Weeks 9-12)

#### Week 9: Trial Management
**Backend Team**
- [ ] Create `subscription` module
- [ ] Implement trial start logic (7 days from registration)
- [ ] Build trial status check endpoint
- [ ] Create trial expiration cron job (runs daily)
- [ ] Implement feature gate middleware

**Mobile Team**
- [ ] Display trial countdown banner on home screen
- [ ] Calculate and show days remaining
- [ ] Lock premium features when trial expires
- [ ] Show "Upgrade to Premium" prompts

#### Week 10: Paywall UI & UX
**Mobile Team**
- [ ] Design full-screen paywall modal
- [ ] Implement psychological conversion hooks:
  - "100% Peace of Mind Guarantee"
  - "Lifetime Access - One-Time Payment"
- [ ] Add social proof (testimonials, ratings)
- [ ] Show feature comparison (Free vs Premium)
- [ ] Implement "Restore Purchase" option

#### Week 11: Midtrans Integration (B2C)
**Backend Team**
- [ ] Integrate Midtrans Snap API
- [ ] Create B2C transaction endpoint (Rp 120,000)
- [ ] Generate unique order IDs (format: HP-B2C-YYYYMMDD-XXX)
- [ ] Build Midtrans webhook handler
- [ ] Implement signature verification
- [ ] Handle payment status updates

**Mobile Team**
- [ ] Implement "Buy Safety Pass" button
- [ ] Open Midtrans Snap WebView
- [ ] Handle payment callback (success/failure)
- [ ] Show payment success animation
- [ ] Instantly unlock premium features on success

#### Week 12: Subscription State Synchronization
**Mobile Team**
- [ ] Poll subscription status on app resume
- [ ] Sync premium status from server
- [ ] Handle edge cases (purchase on different device)

**Backend Team**
- [ ] Build subscription status endpoint
- [ ] Implement device-agnostic premium access (by user_id)
- [ ] Add transaction history endpoint

---

## Phase 3: B2B Features & Group Management (Weeks 13-18)

### Sprint 7-8: Agency Portal & Licensing (Weeks 13-16)

#### Week 13: Agency Registration (Web)
**Web Team**
- [ ] Build agency registration form
- [ ] Add PPIU license number input with validation
- [ ] Implement logo upload with preview
- [ ] Show agency profile page

**Backend Team**
- [ ] Create `agencies` module
- [ ] Build agency registration endpoint
- [ ] Validate PPIU license uniqueness
- [ ] Store agency logo in S3

#### Week 14: B2B License Purchase
**Web Team**
- [ ] Build license purchase page
- [ ] Show pricing table with volume discounts:
  - 1-100 seats: Rp 90k/pax
  - 101-500 seats: Rp 80k/pax (11% discount)
  - 501+ seats: Rp 70k/pax (22% discount)
- [ ] Implement quantity selector with live price calculation
- [ ] Integrate Midtrans Snap checkout

**Backend Team**
- [ ] Create B2B license purchase endpoint
- [ ] Implement volume discount calculation logic
- [ ] Generate unique B2B order IDs
- [ ] Build Midtrans webhook handler for B2B
- [ ] Update agency seat balance on successful payment

#### Week 15: Package Creation
**Web Team**
- [ ] Build "Create Package" form
- [ ] Auto-generate 6-digit alphanumeric pin
- [ ] Display package details page with QR code
- [ ] Show package list with status

**Backend Team**
- [ ] Create `packages` module
- [ ] Build package creation endpoint
- [ ] Validate agency has available seat licenses
- [ ] Implement pin generation algorithm
- [ ] Deduct seats from agency balance

#### Week 16: Group Join Flow (Mobile)
**Mobile Team**
- [ ] Build "Join Group" screen with PIN input
- [ ] Implement QR code scanner
- [ ] Send join request to backend
- [ ] Display "Group Info" card on home screen

**Backend Team**
- [ ] Create `groups` module
- [ ] Build group join endpoint
- [ ] Validate pin exists and package is active
- [ ] Override user subscription to 'b2b_group' (bypass paywall)

### Sprint 9: Muthawif Tools (Weeks 17-18)

#### Week 17: Muthawif Dashboard (Mobile)
**Mobile Team**
- [ ] Build Muthawif home screen showing assigned packages
- [ ] Display member list with real-time count
- [ ] Show QR code for current package
- [ ] Add "Share PIN" button (WhatsApp deep link)

**Backend Team**
- [ ] Create endpoint to fetch Muthawif's packages
- [ ] Build member list endpoint with pagination

#### Week 18: Itinerary Broadcasting
**Mobile Team**
- [ ] Build "Broadcast Message" screen
- [ ] Add fields: title, message body, meeting location
- [ ] Send broadcast request to backend

**Backend Team**
- [ ] Create `broadcasts` module
- [ ] Build broadcast itinerary endpoint
- [ ] Fetch all active members of package
- [ ] Send FCM push notification to all members

---

## Phase 4: Photo CRM & Jejak Ibadah (Weeks 19-21)

### Sprint 10: Photo Capture & Upload (Weeks 19-20)

#### Week 19: Camera Implementation (Mobile)
**Mobile Team**
- [ ] Build "Jejak Ibadah Camera" screen
- [ ] Implement camera preview
- [ ] Capture photo with GPS coordinates
- [ ] Save to local storage with metadata
- [ ] Add to upload queue in SQLite

**Backend Team**
- [ ] Create `photos` module
- [ ] Build photo upload endpoint (multipart/form-data)
- [ ] Store original photo in S3 (temporary bucket)
- [ ] Insert photo record with status 'pending'
- [ ] Enqueue photo processing job

#### Week 20: Photo Processing Pipeline
**Backend Team**
- [ ] Set up BullMQ queue for photo processing
- [ ] Implement photo processing worker:
  - Download original from S3
  - Compress image (max 1920x1080, quality 85%)
  - Fetch agency logo from S3
  - Apply watermark to bottom-right corner
  - Upload processed photo to S3
  - Update database with final URLs
- [ ] Add error handling and retry logic

**Mobile Team**
- [ ] Implement background sync service
- [ ] Auto-upload queued photos when online
- [ ] Show upload progress in queue screen

### Sprint 11: CRM Gallery & Alumni Management (Week 21)

#### Week 21: CRM Dashboard (Web)
**Web Team**
- [ ] Build "Jejak Ibadah" gallery page
- [ ] Display photos in grid layout with infinite scroll
- [ ] Add filter by package/date range
- [ ] Implement bulk download functionality

**Backend Team**
- [ ] Build gallery fetch endpoint with pagination
- [ ] Add filtering and sorting options
- [ ] Create alumni cohort selection endpoint

**Web Team (Alumni Management)**
- [ ] Build "Alumni" page showing past packages
- [ ] Implement cohort selection (checkboxes)
- [ ] Build promotional broadcast flow

---

## Phase 5: Compliance & Polish (Weeks 22-24)

### Week 22-23: PDPL Compliance Finalization
- [ ] Finalize privacy policy text (all languages)
- [ ] NRC registration submission
- [ ] Data deletion flow end-to-end testing
- [ ] Consent audit logging verification

### Week 24: Production Launch
- [ ] Final security audit
- [ ] Performance testing
- [ ] Production environment deployment
- [ ] Monitoring and alerting setup
- [ ] Post-launch bug fixes and optimization

---

## Dependencies

| Phase | Depends On | Enables |
|-------|------------|---------|
| Phase 1 | — | All subsequent phases |
| Phase 2 | Phase 1 (Auth) | Phase 3 (B2B) |
| Phase 3 | Phase 1 + Phase 2 | Phase 4 |
| Phase 4 | Phase 3 (Groups) | Phase 5 |
| Phase 5 | All previous | Production |

---

## Related Documents
- `knowledge-system/03_technical/flows/user-flows/` — User navigation flows
- `knowledge-system/03_technical/flows/panic-flow.md` — Technical panic flow
- `knowledge-system/03_technical/flows/payment-webhook-flow.md` — Payment processing
- `brain/04_cto_codex/F0X-ctechnical-plan.md` — Feature-level technical plans
