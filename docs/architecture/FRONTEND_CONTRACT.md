# Frontend Data Master Contract

## Status: ACCEPTED — 2026-05-31

## Single Source of Truth per Data Entity

| Entity | Master Frontend | Rationale |
|---|---|---|
| Panic Alerts | **Flutter** (haramain_pro) | Field-facing, triggered by muthawif/jamaah on mobile. Workflow starts here. React dashboard is read-only viewer. |
| Groups / Broadcast | **Flutter** (haramain_pro) | Muthawif manages groups in the field. Group creation, join, QR, and broadcast originate from mobile. React mirrors this data for admin visibility. |
| Payments | **React** (web-dashboard) | Admin operations: refunds, billing adjustments, Xendit webhook reconciliation. Flutter initiates payments but does not own reversal or adjustment logic. |
| User Management | **React** (web-dashboard) | Admin operations: role assignment, bans, team management. Flutter reads user profile but does not write to profiles table directly. |

## Principles

1. **Write authority is exclusive.** Only the master frontend may write to a given entity. The other frontend may only read.
2. **React reads from Supabase directly.** Flutter is the source for panic and groups; React queries the same tables in read-only capacity for admin dashboards.
3. **Flutter never calls Supabase Admin API.** Payments and user management involve sensitive operations; Flutter uses edge functions (which carry the service role key) rather than direct writes.
4. **Conflict resolution.** If a non-master frontend attempts a write, the edge function or RLS policy must reject it. If it passes, the master frontend wins.

## Implications

- Flutter panic/broadcast edge functions should be the only places `INSERT`/`UPDATE`/`DELETE` on `panic_alerts` and `groups` are allowed.
- React payments page calls `/functions/v1/payments-admin` (or equivalent admin edge function) for refunds — not direct table writes.
- React users page calls `/functions/v1/users-admin` for role/ban changes — not direct table writes.
- Flutter `paywall_screen` and `payment_service` initiate payment intent only; do not handle reversal logic.

## Review

When adding a new shared data entity, assign a master frontend before implementation starts. Document it in this file.
