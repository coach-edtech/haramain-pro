# Project Structure — Haramain Pro

## Source
Imported and adapted from Paraflow-generated `files_plan.md`, adjusted to match actual tech stack:
- Flutter (mobile) with Riverpod
- Supabase (backend: PostgreSQL + Edge Functions + Storage)
- Next.js (web dashboard) — future phase

**Note:** Original files_plan.md specified NestJS backend, but Haramain Pro uses Supabase Edge Functions (Deno).

---

## Project Root Structure

```
haramainpro/
├── mobile/                          # Flutter mobile app (haramain_clean)
├── web/                             # Next.js web dashboard (future phase)
├── supabase/                        # Supabase backend
│   ├── migrations/                  # Database migrations
│   └── functions/                   # Edge Functions
├── docs/                            # Product documentation
│   ├── haramain-v.2.1.md           # Master PRD
│   ├── paraflow-product-docs/       # Paraflow exports
│   └── SYSTEM_BLUEPRINT.md          # Production-grade control document
├── knowledge-system/                # AI-context for Trae
├── brain/                           # Feature knowledge
│   ├── 01_product_vision/
│   ├── 02_features/                 # Feature Briefs (F01-F08)
│   ├── 03_decisions/                # Decision Log
│   ├── 04_cto_codex/               # Technical Plans
│   ├── 05_dev_trae/                # Implementation logs
│   ├── 06_qa_openclaw/             # UAT results
│   └── 07_releases/                # Release notes
└── .trae/                          # Trae IDE rules
    └── rules/                       # Project-specific rules
```

---

## Mobile Structure (Flutter)

```
mobile/                              # atau: haramain_clean/
├── android/                         # Android-specific
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── AndroidManifest.xml
│   │   │   └── kotlin/
│   │   └── build.gradle
│   └── gradle.properties
│
├── ios/                             # iOS-specific
│   ├── Runner/
│   │   ├── Info.plist
│   │   ├── AppDelegate.swift
│   │   └── Assets.xcassets/
│   └── Podfile
│
├── lib/
│   ├── main.dart                   # Entry point
│   │
│   ├── core/                       # Core utilities
│   │   ├── config/
│   │   │   ├── app_config.dart
│   │   │   ├── environment.dart
│   │   │   └── routes.dart
│   │   ├── constants/
│   │   │   ├── api_endpoints.dart
│   │   │   ├── app_strings.dart
│   │   │   └── dimensions.dart
│   │   ├── errors/
│   │   │   ├── exceptions.dart
│   │   │   └── failures.dart
│   │   ├── network/
│   │   │   ├── supabase_client.dart
│   │   │   ├── network_info.dart
│   │   │   └── interceptors/
│   │   │       ├── auth_interceptor.dart
│   │   │       └── logging_interceptor.dart
│   │   ├── storage/
│   │   │   ├── local_database.dart   # Isar/SQLite
│   │   │   ├── secure_storage.dart   # flutter_secure_storage
│   │   │   └── shared_prefs.dart
│   │   └── utils/
│   │       ├── date_utils.dart
│   │       ├── validators.dart
│   │       └── formatters.dart
│   │
│   ├── features/                   # Feature modules (Clean Architecture)
│   │   │
│   │   ├── auth/                   # F01: Onboarding + PDPL
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── auth_local_datasource.dart
│   │   │   │   │   └── auth_remote_datasource.dart
│   │   │   │   ├── models/
│   │   │   │   │   └── user_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── auth_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── user.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── auth_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── login_usecase.dart
│   │   │   │       ├── register_usecase.dart
│   │   │   │       └── refresh_token_usecase.dart
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── auth_provider.dart
│   │   │       ├── screens/
│   │   │       │   ├── login_screen.dart
│   │   │       │   ├── register_screen.dart
│   │   │       │   └── onboarding_screen.dart
│   │   │       └── widgets/
│   │   │           └── consent_checkbox.dart
│   │   │
│   │   ├── pdpl_compliance/        # F01: Consent management
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── consent_remote_datasource.dart
│   │   │   │   └── repositories/
│   │   │   │       └── consent_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── consent.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── consent_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── grant_consent_usecase.dart
│   │   │   │       └── withdraw_consent_usecase.dart
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── consent_provider.dart
│   │   │       ├── screens/
│   │   │       │   ├── consent_onboarding_screen.dart
│   │   │       │   └── consent_settings_screen.dart
│   │   │       └── widgets/
│   │   │           └── data_deletion_dialog.dart
│   │   │
│   │   ├── subscription/           # F05: B2C Paywall
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── subscription_remote_datasource.dart
│   │   │   │   └── repositories/
│   │   │   │       └── subscription_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── subscription.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── subscription_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── check_trial_status_usecase.dart
│   │   │   │       └── purchase_safety_pass_usecase.dart
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── subscription_provider.dart
│   │   │       ├── screens/
│   │   │       │   ├── paywall_screen.dart
│   │   │       │   └── payment_webview_screen.dart
│   │   │       └── widgets/
│   │   │           ├── trial_countdown_banner.dart
│   │   │           └── paywall_card.dart
│   │   │
│   │   ├── maps/                   # F03: Offline Maps
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── map_local_datasource.dart
│   │   │   │   │   └── map_remote_datasource.dart
│   │   │   │   └── repositories/
│   │   │   │       └── map_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── offline_region.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── map_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── download_offline_maps_usecase.dart
│   │   │   │       └── delete_offline_maps_usecase.dart
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── map_provider.dart
│   │   │       ├── screens/
│   │   │       │   ├── map_screen.dart
│   │   │       │   └── offline_map_download_screen.dart
│   │   │       └── widgets/
│   │   │           ├── map_widget.dart
│   │   │           └── download_progress_widget.dart
│   │   │
│   │   ├── location/               # F03: GPS Tracking
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── location_local_datasource.dart
│   │   │   │   │   └── location_remote_datasource.dart
│   │   │   │   └── repositories/
│   │   │   │       └── location_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── gps_point.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── location_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── start_location_tracking_usecase.dart
│   │   │   │       └── sync_location_history_usecase.dart
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── location_provider.dart
│   │   │       └── services/
│   │   │           ├── background_location_service.dart
│   │   │           └── geofence_monitor_service.dart
│   │   │
│   │   ├── virtual_muthawif/      # F04: Virtual Muthawif
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── prayer_local_datasource.dart
│   │   │   │   └── repositories/
│   │   │   │       └── prayer_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── prayer.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── prayer_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       └── get_prayers_for_location_usecase.dart
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── prayer_provider.dart
│   │   │       ├── screens/
│   │   │       │   └── prayer_detail_screen.dart
│   │   │       └── widgets/
│   │   │           └── prayer_card.dart
│   │   │
│   │   ├── groups/                 # F06: B2B Group System
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── group_remote_datasource.dart
│   │   │   │   └── repositories/
│   │   │   │       └── group_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── package.dart
│   │   │   │   │   └── member.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── group_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── join_group_usecase.dart
│   │   │   │       ├── broadcast_itinerary_usecase.dart
│   │   │   │       └── get_group_members_usecase.dart
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── group_provider.dart
│   │   │       ├── screens/
│   │   │       │   ├── join_group_screen.dart
│   │   │       │   ├── muthawif_dashboard_screen.dart
│   │   │       │   └── broadcast_screen.dart
│   │   │       └── widgets/
│   │   │           ├── qr_code_widget.dart
│   │   │           └── member_list_item.dart
│   │   │
│   │   ├── emergency/              # F02: Panic Button
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── panic_local_datasource.dart
│   │   │   │   │   └── panic_remote_datasource.dart
│   │   │   │   └── repositories/
│   │   │   │       └── emergency_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── panic_alert.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── emergency_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       └── trigger_panic_button_usecase.dart
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── emergency_provider.dart
│   │   │       ├── screens/
│   │   │       │   └── panic_alert_screen.dart
│   │   │       └── widgets/
│   │   │           └── panic_button_widget.dart
│   │   │
│   │   ├── jejak_ibadah/          # F07: Jejak Ibadah Photo
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── photo_local_datasource.dart
│   │   │   │   │   └── photo_remote_datasource.dart
│   │   │   │   └── repositories/
│   │   │   │       └── photo_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── photo.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── photo_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── capture_photo_usecase.dart
│   │   │   │       ├── upload_photo_usecase.dart
│   │   │   │       └── sync_photo_queue_usecase.dart
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── photo_provider.dart
│   │   │       ├── screens/
│   │   │       │   ├── camera_screen.dart
│   │   │       │   ├── photo_gallery_screen.dart
│   │   │       │   └── photo_upload_queue_screen.dart
│   │   │       └── widgets/
│   │   │           └── photo_grid_item.dart
│   │   │
│   │   ├── notifications/          # FCM + Itinerary
│   │   │   ├── data/
│   │   │   │   └── datasources/
│   │   │   │       └── fcm_datasource.dart
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── notification_provider.dart
│   │   │       └── services/
│   │   │           ├── fcm_service.dart
│   │   │           └── local_notification_service.dart
│   │   │
│   │   └── dev_tools/              # Development testing tools
│   │       ├── presentation/
│   │       │   ├── screens/
│   │       │   │   └── dev_menu_screen.dart
│   │       │   └── widgets/
│   │       │       ├── gps_spoof_widget.dart
│   │       │       └── test_controls_widget.dart
│   │
│   ├── shared/                     # Shared widgets
│   │   ├── widgets/
│   │   │   ├── buttons/
│   │   │   │   └── primary_button.dart
│   │   │   ├── inputs/
│   │   │   │   └── text_field.dart
│   │   │   ├── cards/
│   │   │   │   └── info_card.dart
│   │   │   ├── dialogs/
│   │   │   │   └── confirmation_dialog.dart
│   │   │   └── loading/
│   │   │       └── loading_indicator.dart
│   │   └── theme/
│   │       ├── app_theme.dart
│   │       ├── text_styles.dart
│   │       └── color_scheme.dart
│   │
│   └── l10n/                       # i18n
│       ├── app_id.arb              # Indonesian
│       ├── app_ar.arb              # Arabic
│       └── app_en.arb              # English
│
├── assets/
│   ├── icons/
│   ├── images/
│   ├── sounds/
│   │   └── panic_alert.wav
│   └── fonts/
│
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
│
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

---

## Supabase Backend Structure

```
supabase/
├── migrations/
│   └── 001_initial_schema.sql      # Core tables + RLS
│
└── functions/
    ├── refresh-claims/             # JWT refresh + role claims
    │   └── index.ts
    ├── panic-dispatch/             # F02: Panic alert to FCM
    │   └── index.ts
    ├── photo-watermark/            # F07: Photo processing
    │   └── index.ts
    ├── midtrans-webhook/           # F05: Payment webhook
    │   └── index.ts
    └── consent-withdraw/           # F01: PDPL withdrawal
        └── index.ts
```

---

## Related Documents
- `knowledge-system/03_technical/data-model/schema-overview.md` — Database schema
- `knowledge-system/03_technical/architecture/system-topology.md` — System topology
- `brain/04_cto_codex/F0X-ctechnical-plan.md` — Feature technical plans
