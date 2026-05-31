# Codemagic

> Owner: OpenClaw
> Status: Starter content created
> Note: This file contains initial operational content and may be refined later by Onyx.

## Purpose
Codemagic CI/CD configuration for Flutter builds.

## Configuration
```yaml
# codemagic.yaml
workflows:
  flutter-workflow:
    name: Flutter CI/CD
    environment:
      flutter: stable
      xcode: latest
    scripts:
      - flutter pub get
      - flutter analyze
      - flutter test
      - flutter build ipa --release
      - flutter build apk --release
    artifacts:
      - build/ios/ipa/*.ipa
      - build/app/outputs/flutter-apk/*.apk
```

## Use Cases
- Advanced iOS provisioning
- Multiple Flutter versions testing
- Custom build caching

## Related
- `docs/03_technical/infra/github-actions.md`
- `docs/03_technical/infra/ci-cd.md`
