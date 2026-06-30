# Issue #41 Validation

## Goal

- Return a consistent HTTP 401 failure envelope for missing, invalid, expired,
  malformed-user, and deleted-user authentication cases.
- Prevent a previous user's profile data or error state from surviving logout
  and a subsequent login session.

## Root Cause

- Spring Security had no custom authentication entry point, so protected
  requests without an accepted Bearer token used the framework's default 403
  response instead of the 401 response required by the Flutter refresh flow.
- Profile principal parsing and missing-user lookup used generic
  `IllegalArgumentException`, which could escape as HTTP 500.
- The auto-disposed profile provider did not observe authentication state, so
  an already-mounted consumer could retain the current profile across a session
  transition.

## TDD Evidence

- Backend RED: four real security-chain tests failed. Missing, invalid, and
  expired Bearer tokens returned the wrong status, while a deleted JWT user
  propagated a servlet exception.
- Frontend RED: the session lifecycle test expected no profile while logged
  out but received the previously fetched `UserProfile`.
- Backend GREEN: real JWT filter-chain tests now cover valid, missing, invalid,
  expired, malformed-principal, and deleted-user behavior. Unexpected service
  failures are not converted into authentication failures.
- Frontend GREEN: the provider performs no profile request while unauthenticated
  and verifies user A -> logout fallback -> user B refetch.

## Validation Commands

| Command | Result |
| --- | --- |
| `backend\gradlew.bat test --rerun-tasks` | Passed |
| `flutter analyze` | Passed: no issues |
| `flutter test --no-pub test/features/mypage/user_profile_controller_test.dart test/features/mypage/user_profile_repository_test.dart test/features/mypage/my_page_screen_test.dart` | Passed: 14 tests |
| `flutter test --no-pub` | Existing Team B map test failure only: 34 passed, 1 failed |
| `flutter build apk --debug` | Passed: `app-debug.apk` created (204,655,219 bytes) |

## Scope Check

- No map, mission, visit verification, favorite, database migration, or Team B
  file was changed.
- No visual layout changed, so a new UI screenshot is not required.
- The authentication entry point is intentionally shared by all protected API
  routes so clients receive the same 401 envelope and can trigger refresh.

## Known External Failure

- `test/features/map/map_screen_test.dart` still creates `MapScreen` without a
  `ProviderScope`, producing `Bad state: No ProviderScope found`. This failure
  exists on the base `main`, is unrelated to issue #41, and remains unchanged.
