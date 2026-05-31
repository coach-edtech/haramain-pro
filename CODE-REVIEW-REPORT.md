# Haramain Pro — Code Quality Report
**Reviewer:** cto-code-review-001
**Date:** 2026-05-16T22:06:00+08:00
**Branch/SHA:** b9ba46a (Mobile responsive: sidebar overlay on mobile, hamburger menu, responsive breakpoints)

## Executive Summary
The web-dashboard is a Vite+React app (NOT Next.js — documented as Next.js in AGENTS.md but built with Vite) serving as a B2B dashboard for Umrah/Hajj travel agents. The codebase is in early-stage development with significant critical issues: Supabase auth is implemented but the entire data layer is mock data with zero real database queries, the role-based access control is entirely client-side and trivially bypassed via the built-in role-switcher, and there are type safety issues (widespread `any` types) plus a hardcoded Twilio credential in the edge function. The Supabase edge functions for panic alerts are more mature, with proper input validation and rate limiting, but the `fcm-panic-alert` function uses the service role key and has CORS set to `*`. The project needs substantial work before production use.

## Issues (Priority Order)

### P0 — Critical (Fix Before Next Deploy)

**P0-1: Client-Side Role Switcher Bypasses All Access Control**
- Location: `src/components/AdminSidebar.tsx` lines 34-38, called via `onRoleSwitch` in `App.tsx`
- The sidebar exposes a role switcher that lets any authenticated user change their `userRole` state to `super_admin`, `admin_haramain_pro`, or `travel_admin` with a single click. Since all route protection is done via this same `userRole` state (not via Supabase RLS or server-side session validation), this completely bypasses all access control.
- No re-authentication required. A travel_agent can instantly become super_admin.
- Fix: Remove the role switcher entirely, OR move role determination to the server and validate on every protected action.

**P0-2: Zero Real Database Queries — All Data Is Mock**
- Location: All pages under `src/pages/` and `src/lib/mockData.ts`
- Every single page (Billing, Users, CRM, Dashboard, etc.) renders data exclusively from `mockData.ts`. There are zero `supabase.select()` calls in the frontend codebase. The Supabase client is initialized (`src/lib/supabase.ts`) but never used for reads or writes.
- The entire dashboard is a UI mockup with no backend integration.
- Fix: Replace mock data imports with actual Supabase queries per page.

**P0-3: No Supabase RLS Policies Visible**
- Location: No RLS policy files found in the repository
- Without Row Level Security policies on Supabase tables, the anon key exposes all data to any authenticated Supabase user. The client-side `canAccessBilling()` and similar checks are cosmetic without RLS.
- Fix: Define RLS policies for every table. At minimum: users can only read/write their own profiles; travel_admins can read their agency's data; only super_admin can read all.

**P0-4: Hardcoded Twilio Auth Token in Edge Function Source**
- Location: `supabase/functions/twilio-voice-fallback/index.ts` lines 24-25
- The Twilio auth token is referenced directly in the edge function. While it uses `Deno.env.get()`, the function source code containing the env var name pattern is committed to version control. Combined with the fact the function uses the service role key directly (`SUPABASE_SERVICE_ROLE_KEY`), any leak of the function source or env config grants full database access.
- Fix: Use Supabase Vault for secrets. Ensure RLS is the primary access control layer, not the service role key.

**P0-5: Type Safety — Widespread `any` Types on Session/User Objects**
- Location: `src/App.tsx` lines 25-28, `src/components/Header.tsx` line 7, `src/components/Layout.tsx` line 23
- `session`, `user`, and `user` (header) are all typed as `any`. This disables TypeScript's type checking for the most security-critical objects in the app — session validation, email access, and user role checks.
- Fix: Define a `Session` interface with proper typing for `session.user.id`, `session.user.email`, etc.

### P1 — High (Fix This Sprint)

**P1-1: Route Protection Checks Only `session`, Not Role or Route Authorization**
- Location: `src/App.tsx` lines 68-70
- The only route protection is `if (!session) return <Login />`. Once logged in, ANY authenticated user can access ANY route. There is no check that a `travel_admin` is not accessing `/admin/*` routes or that a `jamaah` is not accessing `/travel-admin/*`.
- The `userRole` state is used for sidebar rendering but NOT for route guarding.
- Fix: Add a `<ProtectedRoute>` wrapper that checks both `session` AND `userRole` against allowed roles for that route.

**P1-2: `.env.local` Contains Identical Placeholder Content as `.env.example`**
- Location: `.env.local` vs `.env.example`
- Both files contain the same placeholder values (`your-anon-key`, `your-t...oken`). This means: (a) developers cannot distinguish which env vars are actually set vs still placeholder, and (b) there is no `.env.local` override of `.env.example` — they are duplicates.
- Fix: `.env.local` should contain NO values (all commented out or empty), serving as a "copy to fill" template, distinct from `.env.example`.

**P1-3: CORS Wildcard on Panic Alert Edge Function**
- Location: `supabase/functions/fcm-panic-alert/index.ts` line 5, `supabase/functions/twilio-voice-fallback/index.ts` line 8
- `Access-Control-Allow-Origin: *` allows any origin to trigger panic alerts. Combined with no webhook signature verification, any website or app could craft requests to this endpoint.
- Fix: Restrict to known mobile app origins. Add a secret header check (`X-Webhook-Secret`) validated server-side.

**P1-4: `jamaaah_id` Field Name Typo Inconsistent Across Types and DB**
- Location: `src/types/index.ts` line 25 (`jamaaah_id`), `src/types/index.ts` line 31 (`jamaaah_id`), `supabase/functions/fcm-panic-alert/index.ts` line 23 (`JamaaahId`), line 225 (`jamaaah_id`)
- Three different spellings across the codebase: `jamaaah_id` (with double 'a'), `JamaaahId` (PascalCase), `jamaaah_id` (lowercase). This will cause silent runtime errors when the frontend sends `jamaaah_id` but the DB column is `jamaah_id` or vice versa.
- Fix: Standardize on `jamaah_id` (single 'a') everywhere. Create a database migration to fix the column name.

### P2 — Medium (Schedule Fix)

**P2-1: No Pagination on Any Table**
- Location: `src/pages/admin/Users.tsx`, `src/pages/admin/Billing.tsx`, `src/pages/travel-admin/CRM.tsx`
- All tables render the full mock dataset in a single page. When real data is connected, tables like "Users" (platform-wide) and "Billing" will have hundreds of rows with no pagination, scroll, or virtualization.
- Fix: Implement pagination (Supabase `.range()`) or virtualized scrolling for all list views.

**P2-2: Hardcoded Magic Numbers in Dashboard**
- Location: `src/pages/travel-admin/Dashboard.tsx` lines 141-155
- `33` seat balance, `Rp 12M` revenue, `4` agents, `4.7` rating are hardcoded JSX values. These are not from mock data — they are literal numbers embedded in the UI.
- Fix: Move to `mockData.ts` or real Supabase queries.

**P2-3: Missing TypeScript Strict Mode**
- Location: `tsconfig.json`
- The `tsconfig.json` has no `strict: true` or `noImplicitAny: true`. The project allows implicit `any` and has no NullPointer checks.
- Fix: Enable `strict: true` in tsconfig.json and fix the resulting type errors.

**P2-4: Dashboard State Updated with `setTimeout` Mock**
- Location: `src/pages/travel-admin/Dashboard.tsx` lines 17-27
- Stats are set via `setTimeout(() => { ... setStats(...) ... }, 500)`. This is a fake async pattern that simulates loading but will need to be removed when real queries are added. It hides real async patterns from appearing in code review.
- Fix: Replace with real Supabase data fetching with proper loading/error states.

**P2-5: `clsx` Dependency for Simple Conditional Classes**
- Location: `src/components/AdminSidebar.tsx` line 13, `package.json`
- A 2kb library (`clsx`) is used for simple 2-class ternary switches that could use plain template literals. E.g. `isActive ? 'bg-amber-500 text-amber-400' : 'text-gray-300'`.
- Fix: Use template literals. Reserve `clsx` for complex dynamic class composition.

### P3 — Low / Tech Debt

**P3-1: Version String Hardcoded in Sidebar Footer**
- Location: `src/components/AdminSidebar.tsx` line 141
- `v1.12 - Dashboard` is hardcoded. No single source of truth for app version.
- Fix: Use `import.meta.env.VITE_APP_VERSION` or read from `package.json` at build time.

**P3-2: Unused Imports in `App.tsx`**
- Location: `src/App.tsx` lines 4-6
- `getDefaultRouteForRole` is imported from `auth.ts` but the default route logic for unauthenticated users is handled by React Router's `<Navigate>`. It is also used in `handleRoleSwitch` but that function itself is only triggered by the role switcher (P0-1).
- Fix: Remove unused import or wire it to real post-login redirect.

**P3-3: Supabase Client Created with Anon Key in Edge Functions**
- Location: `supabase/functions/fcm-panic-alert/index.ts` line 143
- The function uses `SUPABASE_ANON_KEY` (not service role) for initial client creation, then attempts `getUser()`. This is correct pattern. However, the `SUPABASE_SERVICE_ROLE_KEY` is not used, meaning RLS applies. Confirm this is intentional and RLS policies exist for `profiles` and `panic_alerts` tables.

**P3-4: Project AGENTS.md States Next.js But Project Uses Vite**
- Location: `AGENTS.md` (in repo root) vs actual codebase
- AGENTS.md says "Framework: Next.js (App Router)" but the project is built with Vite+React. This misleads any agent reading AGENTS.md to understand the tech stack.
- Fix: Update AGENTS.md to say Vite+React.

**P3-5: Comment Describes Stale Pattern**
- Location: `src/pages/travel-admin/CRM.tsx` line 35
- `onClick={() => setTab(t.id as any)}` — the `as any` cast is a code smell indicating the tab state type doesn't match the button id type. This should be properly typed.

## Pattern Violations

1. **Client-side auth only** — `canAccessBilling()`, `canAccessAdmin()` etc. in `auth.ts` are pure JS functions with no server-side enforcement. Anyone can modify state in browser DevTools.
2. **No `noUncheckedIndexedAccess`** — arrays accessed via index (e.g., `user.name.split(' ').map(n => n[0])`) can produce `undefined` with no TS warning.
3. **Inconsistent naming: `jamaaah` vs `jamaah`** — `types/index.ts` uses `jamaaah` (double-a) throughout. Standard Indonesian spelling is `jamaah` (single-a).
4. **No error boundaries** — React components have no error boundaries; a runtime error in any page crashes the whole app.
5. **No loading skeletons** — pages show a spinner instead of skeleton loaders during data transitions.

## Security Audit

- **Secrets**: No real secrets in `.env.local` (same as `.env.example`, all placeholders). Safe to commit.
- **Auth flow**: Supabase `signInWithPassword` is called correctly in `Login.tsx`. Session is stored in React state.
- **Auth bypass**: The role switcher (P0-1) is the primary auth gap — any logged-in user can elevate to super_admin.
- **SQL injection**: No raw SQL. Supabase JS client used throughout edge functions. Safe.
- **XSS**: All user data rendered via React (auto-escaped). No `dangerouslySetInnerHTML` found.
- **CORS**: Edge functions use `*` — mitigated somewhat by requiring Supabase auth header, but not sufficient.
- **Edge function secrets**: Twilio credentials accessed via `Deno.env.get()` in edge functions. Service role key used in `twilio-voice-fallback`. RLS must be primary defense.
- **Rate limiting**: Present in `fcm-panic-alert` (5-min per user) and `twilio-voice-fallback` (5-min per user). Good.
- **Input validation**: `fcm-panic-alert` validates lat/lng ranges, UUID format. Good. `twilio-voice-fallback` validates required payload fields. Good.

## Performance Audit

- **N+1 queries**: Not applicable — no real queries exist yet.
- **Bundle size**: No bundle analysis visible. `clsx` (2kb), `lucide-react` (tree-shakeable) are acceptable. Vite build exists in `dist/`.
- **Render performance**: No `React.memo`, `useMemo`, or `useCallback` used. Sidebar re-renders on every route change due to `useLocation` in `AdminSidebar`/`TravelAdminSidebar`. Minor issue at current scale.
- **Data loading**: All mock data is imported statically — zero network requests for data. Will be a major refactor when replaced with real queries.
- **Images/assets**: No image optimization pipeline visible. Flutter app has `build/` directory suggesting compiled assets.

## Recommendations

1. **Immediate: Remove the role switcher** (`AdminSidebar.tsx` / `TravelAdminSidebar.tsx`) or gate it behind a server-side role validation API call. This is the single highest-impact security fix.

2. **This sprint: Wire up Supabase data layer**. Start with one page (e.g., `Dashboard.tsx` stats) as a proof-of-concept with real `supabase.from().select()` queries, proper loading/error states, and RLS policies on the underlying tables.

3. **This sprint: Define RLS policies**. For each Supabase table (`profiles`, `rombongans`, `panic_alerts`, `seat_licenses`, `invoices`), define who can SELECT/INSERT/UPDATE. RLS is the foundation of the security model.

4. **Next sprint: Add TypeScript strict mode**. Enable `strict: true` in `tsconfig.json`. Fix all `any` types on `session`, `user`, and `HeaderProps.user`. Proper typing prevents the class of bugs that cause auth bypasses.

5. **Next sprint: Add pagination to all list pages**. Implement Supabase `.range()` pagination with page controls on `Users.tsx`, `Billing.tsx`, and `CRM.tsx` before real data makes these tables scroll indefinitely.

## Files Reviewed

**Frontend (web-dashboard/src/):**
- `App.tsx` — routing, auth session handling, role state
- `main.tsx` — app entry
- `lib/supabase.ts` — Supabase client init
- `lib/auth.ts` — role utilities, MOCK_USERS
- `lib/mockData.ts` — all mock data (the entire data layer)
- `types/index.ts` — TypeScript interfaces
- `components/Layout.tsx` — page wrapper
- `components/Header.tsx` — top navigation
- `components/AdminSidebar.tsx` — admin navigation (role switcher here)
- `components/TravelAdminSidebar.tsx` — travel admin navigation
- `components/StatsCard.tsx` — stat display component
- `pages/Login.tsx` — auth entry
- `pages/admin/Users.tsx` — user management (mock)
- `pages/admin/Billing.tsx` — billing management (mock)
- `pages/admin/Dashboard.tsx` — admin dashboard (mock)
- `pages/admin/SeatLicenses.tsx`, `Travels.tsx`, `System.tsx` — admin pages (scan)
- `pages/travel-admin/Dashboard.tsx` — travel admin dashboard
- `pages/travel-admin/CRM.tsx` — pilgrim lifecycle
- `pages/travel-admin/Payments.tsx`, `SeatLicenses.tsx`, `OTA.tsx`, `Team.tsx`, `Agents.tsx` — travel admin pages (scan)
- `vite.config.ts`, `tsconfig.json`, `tailwind.config.js`, `package.json`

**Edge Functions (supabase/functions/):**
- `fcm-panic-alert/index.ts` — panic alert handler with FCM + Twilio fallback
- `twilio-voice-fallback/index.ts` — Twilio voice call fallback

**Config:**
- `.env.example`, `.env.local` — env var templates

**Out of Scope:**
- Flutter mobile app (`apps/haramain_pro/`) — not the web dashboard
- `supabase/functions/fcm-broadcast/`, `photo-watermark/` — not reviewed
