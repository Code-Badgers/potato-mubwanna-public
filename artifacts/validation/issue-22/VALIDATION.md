# Issue #22 Validation

## Goal

- Replace the reward coupon placeholder with an Android-oriented reward inbox UI.
- Keep coupon API integration, QR payload generation, and redemption behavior out of scope.

## Changes Verified

- Available and used coupon tabs render their mock coupon states.
- Available coupons expose a QR preview dialog with a close action.
- The preview entrypoint renders CouponScreen directly for Android emulator review.

## Commands And Results

| Command | Result |
| --- | --- |
| `flutter test --no-pub test\features\coupon\coupon_screen_test.dart` before implementation | Failed as expected because the CouponScreen placeholder did not render the reward inbox. |
| `flutter test --no-pub test\features\coupon\coupon_screen_test.dart` after implementation | Passed: 2 tests. |
| `flutter run -d emulator-5554 -t ..\artifacts\validation\issue-22\coupon_preview.dart --debug --no-pub` | Passed: preview app launched on Pixel 7 API 36 emulator. |
| `flutter analyze` | Passed: `No issues found!` |
| `flutter test --no-pub` | Passed: 16 tests. |
| `flutter build apk --debug` | Passed: built `build\app\outputs\flutter-apk\app-debug.apk`. |

## Android UI Evidence

- Screenshots:
  - `artifacts/validation/issue-22/coupon-android-available.png`
  - `artifacts/validation/issue-22/coupon-android-qr.png`
- Device profile: Pixel 7, API 36, x86_64 Google APIs system image.
- Visual check:
  - The header, tab control, reward summary, available coupon cards, benefit text, and QR actions render without visible clipping or overlap.
  - The QR preview modal renders above the coupon list with the coupon name, validity date, close icon, and close button.

## Notes And Risks

- Coupon values and QR display are static UI mock data until the existing coupon API contract is connected.
- The QR dialog uses a visual preview only and does not represent a redeemable QR payload.
- CouponScreen routing is intentionally excluded from this issue and requires a follow-up route or My Page quick-action connection.
