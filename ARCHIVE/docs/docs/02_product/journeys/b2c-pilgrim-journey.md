# B2C Pilgrim Journey

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
End-to-end journey for individual pilgrim (Jamaah) using the app.

## Journey Stages

### 1. Discovery & Signup
**Start**: Downloads app from Play Store / App Store
**End**: Account created with phone OTP

Steps:
1. Install app → onboarding screen
2. Enter phone number → OTP sent
3. Verify OTP → account created
4. Land on home screen (pre-consent)

### 2. Consent & Trial
**Start**: Home screen prompting for consents
**End**: Trial activated

Steps:
1. See PDPL consent dialog (location, media, notifications)
2. Accept/decline each consent category
3. See 7-day trial activation screen
4. Trial starts → full feature access

**Pain Point**: Consent fatigue — too many checkboxes
**Pain Point**: Unclear why consents are needed

### 3. Group Join
**Start**: Trial active, prompted to join group
**End**: Member of aktifombongan

Steps:
1. Tap "Join Group" on home screen
2. Enter 6-digit PIN (from travel agency/muthawif)
3. See rombongan details → confirm join
4. Group appears on home screen

**Pain Point**: PIN delivery method unclear (SMS? WhatsApp?)

### 4. Pre-Trip Preparation (Optional)
**Start**: Joined group, trip not yet started
**End**: Offline maps downloaded, ready for trip

Steps:
1. Browse "Prepare for Trip" section
2. Download Mecca offline maps (~150MB)
3. Download Medina offline maps (~100MB)
4. See preparation checklist

### 5. Active Trip
**Start**: Within trip dates (trip_start_at reached)
**End**: Trip ends (trip_end_at)

Steps:
1. Receive daily prayer notifications
2. View map for navigation
3. Log jejak ibadah entries (photo + prayer type)
4. Receive group announcements from muthawif
5. Trigger panic alert if emergency

**Pain Points**:
- Panic alert: when does user trigger? How does it work?
- Offline mode: user needs to know what's available without internet

### 6. Safety Pass Conversion
**Start**: Trial expiring or user wants premium
**End**: Safety Pass purchased, lifetime access

Steps:
1. See trial expiry banner
2. Tap "Get Safety Pass" (Rp 120,000)
3. Midtrans payment flow
4. Payment confirmed → pass activated
5. Features unlocked permanently

**Pain Point**: Price anchoring — is Rp 120k worth it?

### 7. Post-Trip (Alumni)
**Start**: trip_end_at passed
**End**: Alumni state, broadcast-enabled if consented

Steps:
1. Group becomes read-only
2. If marketing consent given → eligible for alumni broadcasts
3. Access to past jejak ibadah records
4. Optional: leave review

## End States
| State | Access Level |
|-------|-------------|
| Pre-trial | Limited (onboarding only) |
| Trial Active | Full B2C features |
| Trial Expired | Paywall active, limited access |
| Safety Pass | Full B2C features permanently |
| Alumni | Read-only + broadcasts |

## Related
- `docs/02_product/personas/pilgrim.md`
- `docs/05_features/subscription-paywall/`
- `docs/05_features/rombongan-group-management/`
