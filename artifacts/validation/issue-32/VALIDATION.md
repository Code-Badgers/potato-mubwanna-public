# Issue #32 Validation

## Goal

- Provide a dedicated settings permission screen for location and notifications.
- Open it from both My Page settings entry points and declare the Android permissions it needs.

## Implemented Scope

- Added `PermissionService` and `SettingsScreen` with status, request, and app-settings flows.
- Added the `/settings` route and connected the My Page header icon and account-menu row.
- Declared coarse location, fine location, and notification permissions in the Android manifest.
- Added widget coverage for permission states/actions and both My Page entry points.
- Refreshed permission statuses when the app resumes after returning from
  system settings, and avoided the initial synchronous error-state reset.

## Issue Encountered And Resolution

- The account-menu navigation test initially used Flutter's default 800x600 test view. The settings row remained below the visible test surface, so its tap target was outside the view.
- The test now uses the existing mobile test viewport of 430x932 and verifies both the header icon and account-menu entry point.
- `flutter build apk --debug` returned while Gradle continued in the background. The generated APK was verified after the Gradle processes completed.

## Validation Commands

| Command | Result |
| --- | --- |
| `flutter test --no-pub test\\features\\settings\\settings_screen_test.dart test\\features\\mypage\\my_page_screen_test.dart` | Passed: 10 tests |
| `flutter analyze` | Passed: no issues |
| `flutter test --no-pub` | Passed: 27 tests |
| `flutter build apk --debug` | Passed: `build/app/outputs/flutter-apk/app-debug.apk` created (204,619,891 bytes) |
| `flutter devices` | No Android device or emulator connected; Windows, Chrome, and Edge only |

## Gemini Review Follow-up

- Added `WidgetsBindingObserver` to reload permission statuses when the app
  resumes after the user changes an app setting.
- Added a widget regression test that changes the fake notification status,
  sends an `AppLifecycleState.resumed` event, and verifies the UI refreshes.
- Installed Flutter 3.44.2, Dart 3.12.2, and the Android SDK API 36 toolchain
  locally for this follow-up.

| Command | Result |
| --- | --- |
| `flutter test --no-pub test\features\settings\settings_screen_test.dart` | Passed: 4 tests |
| `flutter test --no-pub` | Passed: 28 tests |
| `flutter analyze` | Passed: no issues |
| `flutter build apk --debug` | Passed: `build/app/outputs/flutter-apk/app-debug.apk` created (204,618,959 bytes) |

## Android Runtime Permission Capture

- Verified on the Pixel 7 API 36 Google APIs emulator after a fresh app install.
- `issue-32-location-permission.png` captures the Android system location
  permission dialog with precise/approximate and foreground/one-time choices.
- `issue-32-notification-permission.png` captures the Android system
  notification permission dialog.
- The emulator's system language is English; the app's settings screen remains
  Korean underneath each system dialog.

## Residual Risk

- The runtime Android permission dialog and the system settings return flow still need confirmation on an Android emulator or physical device.
- iOS permission configuration is excluded from this Android-focused issue.
