# Issue #460 Validation

- Issue: [FE] fix: Coach Mark 설치별 페이지 1회 노출 및 미션 메인 보강
- Branch: `fix/460-coach-mark-first-run-mission-home`
- Base: `main`

## Scope

- Coach Mark exposure is gated by the persisted page `tourId` seen state.
- A first step is marked as seen only when the overlay actually presents it.
- An incomplete tour resumes its saved step while the same app process is
  alive, preserving map/detail navigation and other multi-screen guidance.
- After a full app restart, the persisted seen state prevents that page tour
  from appearing again even if it was not completed.
- The existing page-specific `tourId`, step progress, completion persistence,
  and `SharedPreferences` store remain in use.
- `FEATURE_TOUR_PREVIEW_CYCLE` can create one isolated local preview cycle
  without clearing or changing production users' stored tour state.
- Mission home keeps the existing three daily missions and adds a visible but
  restrained daily summary with status copy and progress.

## Verification

| Command | Result |
| --- | --- |
| `dart format lib/features/feature_tour/presentation/feature_tour_host.dart lib/features/mission/presentation/screen/mission_screen.dart test/features/feature_tour/feature_tour_test.dart test/features/mission/mission_screen_test.dart` | PASS |
| `flutter test test/features/feature_tour/feature_tour_test.dart test/features/mission/mission_screen_test.dart` | PASS, 37 tests |
| `flutter analyze` | PASS, no issues found |
| `flutter test` | PASS, 357 tests |

## Added coverage

- Seen state survives a new `SharedPreferencesFeatureTourStatusStore` instance
  without requiring completion.
- Current-process state is distinguished from persisted state after a process
  restart.
- An incomplete page tour resumes at the saved step during the same process.
- The same incomplete tour stays hidden after a simulated app process restart.
- Mission home renders a keyed daily summary, status copy, count, and progress.

## Notes

- No API, database, or production feature-tour reset behavior was changed.
- Local QA can append
  `--dart-define=FEATURE_TOUR_PREVIEW_CYCLE=seohyeon-20260830` to display one
  fresh page-specific preview cycle. Reusing the same value still preserves
  the install-level one-time policy.
- `frontend/ios/Podfile.lock` was an existing user change and was intentionally
  left unstaged.
- Physical app termination was not automated in this run; final device QA
  should force-close and relaunch the app once per page tour to confirm the
  persisted behavior with the production storage/runtime.
