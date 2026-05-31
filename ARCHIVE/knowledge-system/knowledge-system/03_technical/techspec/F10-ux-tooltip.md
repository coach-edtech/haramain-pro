# Tech Spec: F10 — UX Accessibility Tooltip

_Source: PRD v1.10-FINAL Section 7.4 (NEW)_
_Status: NEW — Added in v1.6_

---

## Overview

First-time popup guide for every feature. Designed for non-tech-savvy users (Muthawif, Jamaah elderly). Ensures users understand features without separate training.

---

## UX Pattern

### Trigger Conditions
1. **First time** user opens a feature (tracked via local flag)
2. **After major update** — if feature UI changes, reset flag for existing users
3. **Manual trigger** — "Tampilkan lagi" option in Settings

### Display
```
[?] icon appears on feature
       ↓
User taps → tooltip overlay appears
       ↓
Tooltip: icon + short explanation in Bahasa Indonesia
       ↓
Tap outside OR tap "Mengerti" → dismiss
       ↓
Tooltip won't show again for this feature (local flag)
```

### Multi-Language
- Primary: Bahasa Indonesia
- Secondary: Arabic
- Toggle via Settings

---

## Example Tooltips (from PRD)

| Feature | Tooltip Text (ID) | Tooltip Text (AR) |
|---------|-------------------|-------------------|
| Panic Button | "Tekan tombol ini jika Anda butuh bantuan darurat. Lokasi Anda akan dikirim ke Muthawif." | "اضغط على هذا الزر إذا كنت بحاجة إلى مساعدة طارئة. سيتم إرسال موقعك إلى المشرف." |
| Doa Kontekstual | "Doa ini berubah sesuai lokasi Anda. Pastikan GPS menyala." | "تتغير هذه الدعاء حسب موقعك. تأكد من تشغيل GPS." |
| Offline Maps | "Peta ini bisa digunakan tanpa internet. Unduh dulu di settings." | "يمكن استخدام هذه الخريطة بدون إنترنت. قم بالتنزيل أولاً من الإعدادات." |

---

## Implementation

### Local Storage (Flutter)

```dart
// SharedPreferences
Map<String, bool> tooltipFlags = {
  'panic_button_seen': false,
  'doa_kontekstual_seen': false,
  'offline_maps_seen': false,
  'broadcast_seen': false,
  // ...
};
```

### Tooltip Component

```dart
TooltipOverlay(
  message: 'Tekan tombol ini jika Anda butuh bantuan darurat.',
  image: tooltip_gif,  // optional animation
  onDismiss: () {
    prefs.setBool('${featureId}_seen', true);
  }
)
```

### "Tampilkan lagi" in Settings

```
Settings → Bantuan → [Feature List]
       ↓
Toggle: "Tampilkan tooltip saat pertama buka fitur"
       ↓
If ON: normal behavior
If OFF: no tooltips shown
       ↓
Individual: [Reset tooltip for Feature X]
```

---

## Feature Coverage

All MVP features should have tooltip:

| Feature | Priority |
|---------|----------|
| Panic Button | HIGH |
| Doa Kontekstual | HIGH |
| Offline Maps | HIGH |
| Broadcast | MEDIUM |
| Grup Rombongan | MEDIUM |
| Kamera + Watermark | MEDIUM |
| Jejak Ibadah (Travel only) | MEDIUM |
| AI Nadhira | HIGH |

---

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| Local flag (not server) | Privacy, no tracking needed |
| Multi-language support | Saudi market + Indonesian workers |
| Optional via Settings | Power users can disable |
| Reset per feature | Users can re-learn specific features |

---

## Dependencies

- Flutter (local storage via SharedPreferences)
- No backend required
- L10n framework for translations

---

_Maintained by: Hermes (CTO)_
_Last Updated: 2026-05-02 (v1.10-FINAL)_
