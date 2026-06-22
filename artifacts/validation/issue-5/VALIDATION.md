# Issue #5 Validation

## Goal

Implement the first onboarding UI for the Flutter app based on the local UI reference image, `frontend/assets/onboading.png`, and product documents.

## Scope

- Step 1: full-screen `onboading.png` introduction with "터치하여 시작하기"
- Step 2: location permission explanation inspired by the provided permission reference
- Step 3: notification permission explanation without a potato inside the bell icon
- Mobile-width web preview for screenshot validation

## Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d web-server --web-hostname=127.0.0.1 --web-port=54631
```

## Result

- `flutter pub get`: passed
- `flutter analyze`: passed with no issues
- `flutter test`: passed
- Web preview screenshots were captured from `http://127.0.0.1:54631/#/onboarding`

## Screenshots

- `onboarding-step-1.png`
- `onboarding-step-2.png`
- `onboarding-step-3.png`

## Notes

- The actual runtime permission request flow is intentionally left for a later issue.
- `mobile_scanner` was removed from this onboarding branch because QR scanning is not part of this step and its web plugin blocked web screenshot validation on Flutter 3.10.
- Performance profiling with Flutter DevTools or Android Profiler should be done after a runnable Android/iOS target is available for the onboarding flow.
