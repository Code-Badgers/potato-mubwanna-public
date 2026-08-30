# Issue #460 Validation

- Issue: [FE] fix: Coach Mark 설치별 페이지 1회 노출 및 미션 메인 보강
- Branch: `fix/460-coach-mark-first-run-mission-home`
- Base: `main`

## Scope

- Coach Mark exposure is gated by the persisted page `tourId` seen state.
- A first step is marked as seen only when the overlay actually presents it.
- An incomplete tour is not activated again after the app is restarted or the
  page host is mounted again.
- The existing page-specific `tourId`, step progress, completion persistence,
  and `SharedPreferences` store remain in use.
- Mission home keeps the existing three daily missions and adds a compact
  progress bar using the existing completed/total counts.

## Verification

| Command | Result |
| --- | --- |
| `dart format lib/features/feature_tour/presentation/feature_tour_host.dart lib/features/mission/presentation/screen/mission_screen.dart test/features/feature_tour/feature_tour_test.dart test/features/mission/mission_screen_test.dart` | PASS |
| `flutter test test/features/feature_tour/feature_tour_test.dart test/features/mission/mission_screen_test.dart` | PASS, 36 tests |
| `flutter analyze` | PASS, no issues found |
| `flutter test` | PASS, 355 tests |

## Added coverage

- Seen state survives a new `SharedPreferencesFeatureTourStatusStore` instance
  without requiring completion.
- An incomplete page tour that already presented its first step stays hidden
  when the host is mounted again.
- Mission home renders the progress indicator alongside the existing count.

## Notes

- No API, database, or feature-tour reset behavior was changed.
- `frontend/ios/Podfile.lock` was an existing user change and was intentionally
  left unstaged.
- Physical app termination was not automated in this run; final device QA
  should force-close and relaunch the app once per page tour to confirm the
  persisted behavior with the production storage/runtime.
