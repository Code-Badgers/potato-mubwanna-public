# Issue #43 Validation

## Scope

- Team A: authenticated stamp-book query APIs
- Team A: 18 Gangwon city/county stamp master data
- Team A: 6, 12, 18 next-reward calculation
- Team A: Flutter rallybook repository, provider, and screen states
- Excluded: visit verification, stamp acquisition writes, coupon issuance, Team B map/potato/mission files
- External public-data API credentials are not stored or used by this change.

## Baseline

Fresh worktree from `origin/main` at `dc816c4`:

- `backend\\gradlew.bat test`: passed
- `flutter analyze`: passed
- `flutter test test/features/stamp/stamp_book_screen_test.dart`: 1 passed

## TDD Evidence

### Backend RED

- `StampMigrationTest`: failed to compile because `Stamp` and `StampRepository` did not exist.
- `StampQueryServiceTest`: failed to compile because the query service and response DTOs did not exist.
- `StampControllerTest`: failed to compile because `StampController` did not exist.
- Deleted-user test: failed because `StampQueryService` did not validate the JWT user against `UserRepository`.

### Backend GREEN

- `StampMigrationTest`: passed with 18 ordered Gangwon stamps.
- `StampQueryServiceTest`: passed for empty/acquired states, deleted users, and reward boundaries.
- `StampControllerTest` and `StampControllerSecurityTest`: passed for authenticated responses, malformed principals, and missing bearer tokens.

### Flutter RED

- Repository/provider tests failed because stamp models, repository, and provider did not exist.
- Screen tests failed because the static screen ignored API data and had no loading, error, completion, or signed-out states.

### Flutter GREEN

- Repository parses `/stamps/me` and `/stamps/rewards/check` and reports common API failures.
- Provider does not fetch while signed out and refetches across user A -> logout -> user B.
- Screen renders API progress plus loading, error/retry, completion, and signed-out states.

## Final Verification

### Backend

Command:

```powershell
cd backend
.\\gradlew.bat test --rerun-tasks --console=plain
```

Result: `BUILD SUCCESSFUL in 35s`.

### Flutter analysis

Command:

```powershell
cd frontend
flutter analyze
```

Result: `No issues found!`.

### Focused Flutter tests

Command:

```powershell
cd frontend
flutter test test/features/stamp
```

Result: 8 tests passed.

### Full Flutter test suite

Command:

```powershell
cd frontend
flutter test --no-pub
```

Result: 41 tests passed and 1 existing Team B map test failed.

Existing failure:

- `frontend/test/features/map/map_screen_test.dart`
- `MapScreen` is created without `ProviderScope`.
- Error: `Bad state: No ProviderScope found`
- The failing file is unchanged by issue #43.

### Android debug APK

Command:

```powershell
cd frontend
flutter build apk --debug --no-pub
```

Result: build succeeded.

- Path: `frontend/build/app/outputs/flutter-apk/app-debug.apk`
- Size: `204658571` bytes
- Existing Kotlin/Java compatibility warnings were emitted; no build error occurred.

## Change Boundary

`git diff --name-only origin/main...HEAD` contains no Team B map, mission, potato, spot, or visit source/test files.

No runtime screenshot was added because this change preserves the existing rallybook layout; widget tests cover all newly added visual states.
