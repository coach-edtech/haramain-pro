# Beta Test Guide - Haramain Pro v0.1.0

**Version:** 0.1.0-beta
**Date:** 2026-05-13
**Test Period:** 2026-05-13 to 2026-05-20

---

## Overview

Haramain Pro is an Umrah companion app with safety features. This guide helps beta testers evaluate the app.

## Features to Test

### 1. Authentication
- [ ] Register with email
- [ ] Login with email
- [ ] Login with Google
- [ ] Login with Apple
- [ ] Logout

### 2. Panic Button (Critical)
- [ ] Panic button visible at bottom of screen
- [ ] Tap panic → 5 second countdown starts
- [ ] Tap Cancel during countdown → alert cancelled
- [ ] After countdown → alert sent confirmation
- [ ] Verify location is attached to alert

### 3. Maps
- [ ] Map loads with current location
- [ ] Online/Offline mode toggle works
- [ ] Search places works
- [ ] Download Makkah/Madinah regions for offline

### 4. Group Management
- [ ] Create group with QR code
- [ ] Join group with QR code
- [ ] View group members

### 5. Payment (Simulated)
- [ ] View Safety Pass tiers
- [ ] Select tier
- [ ] Payment flow (simulated)

### 6. SDAIA NRC
- [ ] Fill NRC form (Passport → Personal → Accommodation → Review)
- [ ] Upload passport photo
- [ ] Upload visa photo
- [ ] Save draft works
- [ ] Submit works

---

## Test Accounts

### Admin Account (Travel Agency)
```
Email: admin@beta.haramain.pro
Password: BetaAdmin123!
Role: admin
```

### Muthawif Accounts
```
Email: muthawif1@beta.haramain.pro
Password: BetaMuthawif123!
Role: muthawif

Email: muthawif2@beta.haramain.pro
Password: BetaMuthawif123!
Role: muthawif
```

### Jamaah Accounts
```
Email: jamaah1@beta.haramain.pro
Password: BetaJamaah123!

Email: jamaah2@beta.haramain.pro
Password: BetaJamaah123!

Email: jamaah3@beta.haramain.pro
Password: BetaJamaah123!

Email: jamaah4@beta.haramain.pro
Password: BetaJamaah123!

Email: jamaah5@beta.haramain.pro
Password: BetaJamaah123!
```

---

## Installation Instructions

### Android
1. Transfer APK file to device
2. Enable "Install from unknown sources" in Settings
3. Open APK file
4. Install and open

### First Time Setup
1. Open app
2. Sign in with test account
3. Grant location permission
4. Grant notification permission
5. You're ready!

---

## Known Limitations (v0.1.0)

1. **Payment** - Simulated only, no real payment
2. **Offline Maps** - Requires manual download of regions
3. **FCM** - Requires google-services.json from Firebase Console
4. **Supabase** - Points to haramain-prod-db

---

## Feedback Channels

### Critical Issues (Crashes, Security)
Email: hermes@haramain.id
Subject: [BETA-P0] Brief description

### Bugs & UX Issues
WhatsApp: [Contact Hermes]
Subject: [BETA-BUG] Brief description

### Feature Requests
Not accepting for v0.1.0 - document for v1.1

---

## Success Criteria

For v0.1.0 beta to be considered successful:

1. ✅ APK installs without crash
2. ✅ Auth flow works (register/login/logout)
3. ✅ Panic button sends alert (simulated)
4. ✅ Maps display and search works
5. ✅ No P0 bugs (crashes, data loss)

---

## Support

For technical issues:
- Hermes (CTO): hermes@haramain.id
- Trae (Engineering): Via Hermes

---

**Thank you for testing Haramain Pro! 🙏**
