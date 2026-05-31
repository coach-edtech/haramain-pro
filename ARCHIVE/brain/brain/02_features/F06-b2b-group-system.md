# Feature Brief: B2B Group System (Rombongan)

_Feature ID: F-06_
_Status: Draft_
_Date: 2026-04-04_
_Author: OpenClaw (extracted from PRD)_

---

## 1. Problem Statement

Travel agencies need to group their pilgrims under a designated Muthawif (group leader) so that:
- Pilgrims receive group-specific updates and itineraries
- Panic alerts reach the correct Muthawif
- Photo galleries are organized by group for the CRM
- B2C paywall is bypassed for the duration of the trip

---

## 2. Goal

- Muthawif can generate a unique group code (QR + 6-digit alphanumeric)
- Pilgrims can join a group using the code
- Joining a group immediately bypasses the B2C paywall for that trip duration
- Muthawif can broadcast itinerary updates to all group members
- Muthawif can see distressed pilgrim location on their map when panic triggered

---

## 3. User Flows

### Muthawif: Create Group
```
Muthawif opens app → Dashboard
       ↓
[Create Group] button
       ↓
System generates:
  - 6-digit alphanumeric invite code (e.g., "HJR4K2")
  - QR code (encodes same invite code)
       ↓
Muthawif shares code/QR with pilgrims
       ↓
Muthawif assigns themselves as group leader (system links muthawifId)
       ↓
Group created and active
```

### Pilgrim: Join Group
```
Pilgrim opens app (paywall may be showing)
       ↓
[Join Group] or [Enter Code] button
       ↓
Input: 6-digit code OR scan QR
       ↓
System validates code → links pilgrim to Rombongan
       ↓
PAYWALL BYPASSED
       ↓
Receives "You joined [Group Name]!" confirmation
       ↓
Can now receive itinerary broadcasts
```

### Muthawif: Broadcast Itinerary
```
Muthawif → [New Itinerary]
       ↓
Form: Title, Location, Meeting Point Coordinates, Time
       ↓
[Send to Group]
       ↓
All joined pilgrims receive push notification
       ↓
Pilgrims see: "New itinerary: [Title], [Location], [Time]"
```

---

## 4. Scope

### In Scope
- Muthawif generates unique 6-digit alphanumeric code
- QR code generation (encodes invite code)
- Pilgrim joins via code input OR QR scan
- Automatic paywall bypass on successful join
- Trip duration = until Muthawif marks trip complete OR admin override
- Muthawif broadcasts itinerary with coordinates
- All group members receive FCM notification
- Group view on Muthawif app (member list)

### Out of Scope
- Muthawif manually adds pilgrims (only code-based join)
- Cross-group messaging (within agency)
- Nested groups / subgroups
- Itinerary history retention (>30 days)

---

## 5. Invite Code Rules

- Format: 6 characters, alphanumeric (A-Z, 0-9, excluding ambiguous: 0/O, 1/I/L)
- Example: `HJR4K2`, `MKM9XN`
- One-time use? No — same code can be used by multiple pilgrims to join same group
- Expiration: None (but Muthawif can deactivate group)
- Uniqueness: Global uniqueness across all agencies (enforced by backend)

---

## 6. Paywall Bypass Logic

```
Pilgrim joins Rombongan
       ↓
subscriptionTier remains "free_trial" or whatever it was
BUT
Premium features check: is pilgrim in active Rombongan?
       ↓
If YES → grant premium access until tripEndDate
If NO → enforce paywall
```

**Override rules:**
- Rombongan-based access is TEMPORARY (trip duration)
- If trip ends → premium access revoked (unless purchased directly)
- Muthawif can mark trip as "completed" → all members lose group-based access

---

## 7. Acceptance Criteria

- [ ] Muthawif can create group and receive unique 6-digit code + QR
- [ ] Code can be shared via WhatsApp/share sheet (includes QR image)
- [ ] Pilgrim can join by typing code (max 6 chars, uppercase normalized)
- [ ] Pilgrim can join by scanning QR (camera permission requested)
- [ ] After join, paywall is bypassed immediately
- [ ] Muthawif sees list of joined pilgrims
- [ ] Muthawif can send itinerary broadcast to all members
- [ ] All members receive FCM push notification
- [ ] Panic alert from any group member reaches Muthawif immediately
- [ ] Muthawif can mark trip as complete → all members lose group premium access

---

## 8. Data Model

### Rombongan (Group)
```typescript
{
  id: string,
  agencyId: string,
  muthawifId: string,
  inviteCode: string,        // 6-char unique code
  isActive: boolean,
  tripStartDate: string,
  tripEndDate: string | null,  // null = ongoing
  meetingLat: number | null,
  meetingLng: number | null,
  createdAt: string
}
```

### RombonganMember (implicit via Profile.agencyId + role)
- Profile.rombonganId links pilgrim to group

---

## 9. Edge Cases

| Case | Handling |
|------|----------|
| Invalid code entered | "Code not found. Please check and try again." |
| QR scan fails | Fallback to manual code entry |
| Code already used by max pilgrims | No limit (code is reusable) |
| Muthawif tries to join own group | Not allowed (Muthawif is creator, not joiner) |
| Pilgrim leaves group voluntarily | Lose group premium access immediately |
| Pilgrim already in a group | Must leave current group first |
| Muthawif deactivates group mid-trip | All members lose access immediately |

---

## 10. Dependencies

- QR code generation (qr_flutter package)
- Camera permission for QR scanning
- FCM for group broadcasts
- Supabase: Rombongan table
- Supabase Edge Function for code validation

---

## 11. Related PRD References

- PRD-35: Agency creates Umrah package + assigns Muthawif
- PRD-40: Muthawif generates QR + 6-digit invite code
- PRD-41: Pilgrim input code → bypasses paywall
- PRD-42: Muthawif broadcasts itinerary to group
- PRD-43: Panic alert displays on Muthawif offline map
- PRD-92: Assumption — valid code = automatic paywall bypass

---

## 12. Questions Open

1. What is the max group size? (Practical limit for Muthawif manageability)
2. Should Muthawif be able to remove a pilgrim from group?
3. Can a pilgrim be in multiple groups simultaneously? (Unlikely, but clarify)
4. Should trip end date be manually set by Muthawif, or auto-calculate from Umrah package dates?
5. Is there a notification when a pilgrim joins my group? (Muthawif side)
6. Should there be a "group chat" for the Rombongan?

