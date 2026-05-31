# B2B Agency Journey

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
End-to-end journey for travel agency (PPIU) using the platform.

## Journey Stages

### 1. Agency Onboarding
**Start**: Agency hears about platform
**End**: Active agency account with tenant context

Steps:
1. Visit registration page
2. Submit PPIU license information
3. Upload agency logo
4. Admin reviews and approves
5. Agency account created → dashboard access

**Pain Point**: License verification takes time

### 2. Volume License Purchase
**Start**: Agency dashboard, no active license
**End**: Credits loaded in agency account

Steps:
1. See license pricing (Rp 90,000/pax base)
2. Select passenger count
3. Proceed to Midtrans payment
4. Payment confirmed → credits added
5. Credits visible in dashboard

### 3. Group (Rombongan) Creation
**Start**: Credits available
**End**: Activerombongan with invite codes

Steps:
1. Click "New Group" in dashboard
2. Enter group details (name, trip dates)
3. Trip dates set (trip_start_at, trip_end_at)
4. System generates group PIN
5. Distribute PIN to Jamaah (via WhatsApp/SMS)

**Alternative**: B2B bypass invite — assign Jamaah directly without PIN

### 4. Passenger Management
**Start**: Rombongan active
**End**: All passengers checked in

Steps:
1. Upload passenger list (CSV or manual)
2. Assign each passenger to group
3. Monitor consent status per passenger
4. See Safety Pass activation status per passenger
5. Receive notifications for issues

### 5. Muthawif Assignment
**Start**: Group created
**End**: Muthawif linked to kelompok

Steps:
1. Assign muthawif to specificrombongan
2. Muthawif receives notification
3. Muthawif can view assigned group

### 6. Active Trip Monitoring
**Start**: trip_start_at reached
**End**: Trip ongoing

Steps:
1. Dashboard shows all active groups
2. Real-time panic alerts if triggered
3. View group member locations (if GPS sharing on)
4. Send group announcements
5. Monitor consent compliance

### 7. Post-Trip Review
**Start**: trip_end_at passed
**End**: Group archived

Steps:
1. Group becomes read-only
2. Download passenger reports
3. Alumni data retained for broadcast
4. Archive group

## End States
| State | Access Level |
|-------|-------------|
| No License | Dashboard view only |
| License Active | Full B2B tools |
| License Expired | Purchase required to manage |
| Group Active | Full group tools |
| Group Expired | Read-only archive |

## Related
- `docs/02_product/personas/travel-agency.md`
- `docs/05_features/agency-onboarding/`
- `docs/05_features/b2b-volume-licensing/`
- `docs/05_features/rombongan-group-management/`
