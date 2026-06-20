# Travel Record Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a mock-data travel-record screen reachable from My Page with a reliable return path.

**Architecture:** Keep travel-record presentation self-contained in a new feature screen. The shared app router owns the standalone route, while My Page owns only the quick-action navigation callback. Immutable mock records remain private to the new screen so a later repository can replace the data source without changing route consumers.

**Tech Stack:** Flutter 3.x, Dart, GoRouter, Flutter widget tests, Riverpod test host.

---

## File Structure

- Create: `frontend/lib/features/travel_record/presentation/screen/travel_record_screen.dart` - standalone summary, visit-record list, and back control.
- Modify: `frontend/lib/app/router/app_router.dart` - import and expose `/travel-records` outside `ShellRoute`.
- Modify: `frontend/lib/features/mypage/presentation/screen/my_page_screen.dart:287-295` - connect only the `여행 기록` quick action with `context.push`.
- Modify: `frontend/test/features/mypage/my_page_screen_test.dart:158-222` - cover My Page to travel-record route and pop behavior.
- Create: `frontend/test/features/travel_record/travel_record_screen_test.dart` - cover visible summary, grouped record content, and header back control.
- Create: `artifacts/validation/issue-30/VALIDATION.md` - record scope, test-first evidence, commands, and residual risks.

### Task 1: Add the Travel Record Screen Test

**Files:**
- Create: `frontend/test/features/travel_record/travel_record_screen_test.dart`
- Create: `frontend/lib/features/travel_record/presentation/screen/travel_record_screen.dart`

- [ ] **Step 1: Write the failing content test**

```dart
testWidgets('renders the travel summary and acquired stamp records',
    (tester) async {
  await tester.pumpWidget(
    const MaterialApp(home: TravelRecordScreen()),
  );

  expect(find.text('여행 기록'), findsOneWidget);
  expect(find.text('총 3곳 방문'), findsOneWidget);
  expect(find.text('정선 5일장'), findsOneWidget);
  expect(find.text('강릉 커피거리'), findsOneWidget);
  expect(find.text('스탬프 획득'), findsNWidgets(3));
});
```

- [ ] **Step 2: Run the test and verify it fails because the screen import does not exist**

Run: `flutter test --no-pub test/features/travel_record/travel_record_screen_test.dart`

Expected: compile failure for missing `travel_record_screen.dart`.

- [ ] **Step 3: Implement the minimal standalone screen**

```dart
class TravelRecordScreen extends StatelessWidget {
  const TravelRecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _TravelRecordHeader(onBack: context.pop)),
            const SliverToBoxAdapter(child: _TravelSummary()),
            SliverList.separated(
              itemBuilder: (_, index) => _TravelRecordCard(record: _records[index]),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemCount: _records.length,
            ),
          ],
        ),
      ),
    );
  }
}
```

Use three private immutable `_TravelRecord` entries for `정선 5일장`, `강릉 커피거리`, and `대관령 양떼목장`. Each card shows a visit date, city, spot, and `스탬프 획득` state. Keep card corners at 8px and use only existing `AppColors` plus local screen constants.

- [ ] **Step 4: Run the content test and verify it passes**

Run: `flutter test --no-pub test/features/travel_record/travel_record_screen_test.dart`

Expected: `All tests passed!`

- [ ] **Step 5: Commit the self-contained screen and its test**

```bash
git add frontend/lib/features/travel_record/presentation/screen/travel_record_screen.dart frontend/test/features/travel_record/travel_record_screen_test.dart
git commit -m "[FE] feat(travel-record): 여행 기록 화면 추가 (#30)"
```

### Task 2: Add the Route and My Page Entry Point

**Files:**
- Modify: `frontend/lib/app/router/app_router.dart:4-34`
- Modify: `frontend/lib/features/mypage/presentation/screen/my_page_screen.dart:286-296`
- Modify: `frontend/test/features/mypage/my_page_screen_test.dart:158-222`

- [ ] **Step 1: Write the failing My Page navigation test**

```dart
testWidgets('opens travel records from the My Page quick action',
    (tester) async {
  final router = GoRouter(
    initialLocation: '/main/mypage',
    routes: [
      GoRoute(path: '/main/mypage', builder: (_, __) => const MyPageScreen()),
      GoRoute(path: '/travel-records', builder: (_, __) => const TravelRecordScreen()),
    ],
  );

  await tester.pumpWidget(ProviderScope(
    child: MaterialApp.router(routerConfig: router),
  ));

  await tester.tap(find.text('여행 기록'));
  await tester.pumpAndSettle();

  expect(find.text('총 3곳 방문'), findsOneWidget);
  expect(router.canPop(), isTrue);
});
```

- [ ] **Step 2: Run the My Page test and verify it fails because the quick action is disabled**

Run: `flutter test --no-pub test/features/mypage/my_page_screen_test.dart`

Expected: travel-record navigation test fails because `여행 기록` has no `onTap` callback.

- [ ] **Step 3: Wire the minimal route and callback**

```dart
// app_router.dart
import '../../features/travel_record/presentation/screen/travel_record_screen.dart';

GoRoute(
  path: '/travel-records',
  builder: (context, state) => const TravelRecordScreen(),
),

// my_page_screen.dart
_QuickAction(
  icon: Icons.menu_book_rounded,
  label: '여행 기록',
  onTap: () => context.push('/travel-records'),
),
```

Keep `/travel-records` outside `ShellRoute`, matching the existing coupon route. Do not activate `내 미션` or `감자 도감` because those domains remain outside issue #30.

- [ ] **Step 4: Extend the test to prove return navigation**

```dart
router.pop();
await tester.pumpAndSettle();

expect(find.text('여행 기록'), findsOneWidget);
```

- [ ] **Step 5: Run targeted tests and verify they pass**

Run: `flutter test --no-pub test/features/mypage/my_page_screen_test.dart test/features/travel_record/travel_record_screen_test.dart`

Expected: `All tests passed!`

- [ ] **Step 6: Commit the route and navigation connection**

```bash
git add frontend/lib/app/router/app_router.dart frontend/lib/features/mypage/presentation/screen/my_page_screen.dart frontend/test/features/mypage/my_page_screen_test.dart
git commit -m "[FE] feat(mypage): 여행 기록 화면 연결 (#30)"
```

### Task 3: Validate and Record Evidence

**Files:**
- Create: `artifacts/validation/issue-30/VALIDATION.md`

- [ ] **Step 1: Add the validation record**

Record the goal, mock-data boundary, test-first failures, source files, and no API-contract changes. State that loading, error, and empty states are deferred until API integration.

- [ ] **Step 2: Run formatter and static analysis**

Run: `dart format lib/features/travel_record/presentation/screen/travel_record_screen.dart lib/features/mypage/presentation/screen/my_page_screen.dart test/features/mypage/my_page_screen_test.dart test/features/travel_record/travel_record_screen_test.dart`

Run: `flutter analyze`

Expected: `No issues found!`

- [ ] **Step 3: Run the full test suite**

Run: `flutter test --no-pub`

Expected: all existing tests plus the new travel-record tests pass.

- [ ] **Step 4: Inspect the final change set**

Run: `git diff --check` and `git status --short`

Expected: only the six planned source, test, and validation files are changed, in addition to the already committed design and plan documents.

- [ ] **Step 5: Commit validation evidence and push the branch**

```bash
git add artifacts/validation/issue-30/VALIDATION.md
git commit -m "chore(validation): 여행 기록 검증 기록 추가 (#30)"
git push origin feat/30-travel-record-screen
```
