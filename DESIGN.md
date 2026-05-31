---
name: HARAMAIN Pro
description: Umrah companion app — panic button, offline maps, real-time group tracking, B2B agency dashboard for Indonesian umrah pilgrims
version: alpha

colors:
  primary: "#065F46"
  primary-light: "#059669"
  primary-dark: "#047857"
  secondary: "#0D9488"
  accent: "#F59E0B"
  accent-warm: "#D97706"
  background: "#F9FAFB"
  surface: "#FFFFFF"
  surface-warm: "#FEF3C7"
  surface-green: "#ECFDF5"
  text-primary: "#111827"
  text-secondary: "#4B5563"
  text-muted: "#9CA3AF"
  border: "#E5E7EB"
  success: "#059669"
  warning: "#F59E0B"
  error: "#DC2626"
  holy-gold: "#B45309"
  mecca-sand: "#FDE68A"

typography:
  display:
    fontFamily: "Plus Jakarta Sans, Inter, system-ui, sans-serif"
    fontSize: 32px
    fontWeight: 700
    lineHeight: 1.1
  h1:
    fontFamily: "Plus Jakarta Sans, Inter, system-ui, sans-serif"
    fontSize: 26px
    fontWeight: 700
    lineHeight: 1.2
  h2:
    fontFamily: "Plus Jakarta Sans, Inter, system-ui, sans-serif"
    fontSize: 20px
    fontWeight: 600
    lineHeight: 1.3
  h3:
    fontFamily: "Plus Jakarta Sans, Inter, system-ui, sans-serif"
    fontSize: 16px
    fontWeight: 600
    lineHeight: 1.4
  body-lg:
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: 18px
    fontWeight: 400
    lineHeight: 1.6
  body:
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: 16px
    fontWeight: 400
    lineHeight: 1.5
  body-sm:
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: 14px
    fontWeight: 400
    lineHeight: 1.5
  caption:
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: 12px
    fontWeight: 500
    lineHeight: 1.4

rounded:
  none: 0px
  sm: 4px
  md: 8px
  lg: 12px
  xl: 16px
  full: 9999px

spacing:
  2xs: 4px
  xs: 8px
  sm: 12px
  md: 16px
  lg: 24px
  xl: 32px
  2xl: 48px

components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "#FFFFFF"
    rounded: "{rounded.md}"
    padding: "12px 24px"
    fontWeight: 600
  button-secondary:
    backgroundColor: "transparent"
    textColor: "{colors.primary}"
    borderColor: "{colors.primary}"
    borderWidth: 2px
    rounded: "{rounded.md}"
    padding: "10px 24px"
    fontWeight: 600
  button-panic:
    backgroundColor: "{colors.error}"
    textColor: "#FFFFFF"
    rounded: "{rounded.full}"
    padding: "16px 32px"
    fontWeight: 700
    fontSize: 18px
  card:
    backgroundColor: "{colors.surface}"
    borderColor: "{colors.border}"
    rounded: "{rounded.lg}"
    padding: 20px
    boxShadow: "0 1px 3px rgba(0,0,0,0.08)"
  card-green:
    backgroundColor: "{colors.surface-green}"
    borderColor: "{colors.success}"
    borderWidth: 1px
    rounded: "{rounded.lg}"
    padding: 20px
  card-warm:
    backgroundColor: "{colors.surface-warm}"
    borderColor: "{colors.accent}"
    borderWidth: 1px
    rounded: "{rounded.lg}"
    padding: 20px
  input:
    backgroundColor: "{colors.surface}"
    borderColor: "{colors.border}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.md}"
    padding: "12px 16px"
  map-marker:
    backgroundColor: "{colors.primary}"
    textColor: "#FFFFFF"
    rounded: "{rounded.full}"
    padding: "6px 12px"
    fontWeight: 600
    fontSize: 12px
  group-badge:
    backgroundColor: "{colors.primary-light}"
    textColor: "#FFFFFF"
    rounded: "{rounded.full}"
    padding: "4px 10px"
    fontSize: 11px
    fontWeight: 600
  badge:
    backgroundColor: "{colors.primary-light}"
    textColor: "#FFFFFF"
    rounded: "{rounded.full}"
    padding: "4px 12px"
    fontSize: 12px
    fontWeight: 600

---

## Overview

**HARAMAIN Pro** is a comprehensive Umrah companion app for Indonesian pilgrims. Features include panic button for emergencies, offline maps for Mecca/Madinah navigation, real-time group tracking, comprehensive Umrah information, and a B2B agency dashboard for tour operators.

**Visual DNA:** Premium, trustworthy, reverent. Think of a trusted travel app meets Islamic heritage — clean, professional, but with warmth and respect for the sacred journey. Not flashy. Not casual. Reverent professionalism.

**Target users:** Indonesian umrah pilgrims (ages 30-65), group leaders, and B2B travel agencies. Mobile-first. Needs to work offline in Mecca/Madinah.

**Critical user needs:** Emergency preparedness (panic button), navigation without internet (offline maps), group cohesion (real-time tracking), information access (Umrah guides).

---

## Colors

**Primary — Emerald (#065F46):** Trust, Islamic heritage, growth. Deep green connects to Islamic tradition. Used for primary actions, navigation, key branding.

**Secondary — Teal (#0D9488):** Supporting actions, secondary emphasis.

**Accent — Amber (#F59E0B):** Warnings, important callouts, highlights.

**Holy Gold (#B45309):** Mecca/Madinah specific contexts, sacred moments, premium features.

**Mecca Sand (#FDE68A):** Warm backgrounds for sacred context sections.

**Surface Green (#ECFDF5):** Success states, confirmed bookings, positive indicators.

**Surface Warm (#FEF3C7):** Information callouts, tips, guidance sections.

---

## Typography

**Primary:** Plus Jakarta Sans — premium, trustworthy, modern.

**Body:** Inter — clean, highly readable for information-dense screens.

**Icons:** Lucide React or Heroicons — consistent, clean line icons.

---

## Layout

**Approach:** Card-based, information-dense but organized. Clear visual hierarchy for stressed users in unfamiliar environments.

**Navigation:** Bottom tab bar (Home, Map, Group, Info, Profile). Panic button always accessible (floating action button).

**Offline-first:** All critical features work without internet. Clear offline indicators.

**Accessibility:** Large touch targets (minimum 44px), high contrast, clear iconography.

---

## Components

### Panic Button
Large, red, floating action button. Always visible. One-tap emergency contact. Critical UX element.

### Map Cards
Location name + distance + offline availability indicator. Easy scanning in crowded places.

### Group Tracker Card
Member photo + name + last location + online/offline indicator.

### Info Cards
Category icon + title + expand indicator. Accordion-style for dense information.

### B2B Dashboard Cards
Stats overview (pilgrims count, active groups, upcoming departures) + quick actions.

---

## Do's and Don'ts

**DO:**
- Reverent but not archaic
- Premium, trustworthy aesthetic
- Clear emergency features
- Offline-first functionality
- Large touch targets for gloved hands
- High contrast for outdoor visibility
- Indonesian language primary
- Group management tools

**DON'T:**
- Casual or playful design
- Religious clichés in imagery
- Complicated navigation under stress
- Small text or low contrast
- Features requiring internet when offline
- Cluttered interfaces
- Non-Indonesian language critical info
- Unclear emergency escalation paths
