# 001 — Mobile Stack: Flutter

> Owner: OpenClaw
> Status: Approved
> Note: Starter content — based on master doc direction.

## Decision
Use **Flutter** as the primary mobile development framework for Haramain Pro (iOS + Android).

## Rationale
- Single codebase for iOS/Android
- Strong offline-first ecosystem (Isar, Hive)
- Fast development iteration
- Good Mapbox integration support
- Dart language enables shared logic with backend

## Alternatives Considered
- **React Native**: Less suited for offline-first local DB integration
- **Native (Swift/Kotlin)**: Higher development cost, two codebases

## Implementation Notes
- Flutter 3.x with null-safety
- State management: BLoC or Riverpod (TBD)
- Local DB: Isar (primary)
- Maps: mapbox_gl package
- Push: firebase_messaging

## Related
- `docs/03_technical/architecture/client-tier.md`
- `docs/03_technical/data-model/local-storage.md`
