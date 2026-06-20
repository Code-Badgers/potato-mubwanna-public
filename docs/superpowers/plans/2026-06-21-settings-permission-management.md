# Settings Permission Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let My Page users inspect and manage location and notification permissions safely on Android.

**Architecture:** `PermissionService` remains the single native-plugin boundary and gains status and app-settings methods. `SettingsScreen` receives that service through its constructor so widget tests can inject a fake implementation; the router creates the production service. My Page only owns navigation callbacks, while the Android manifest declares the permissions requested by the service.

**Tech Stack:** Flutter 3.x, Dart, GoRouter, permission_handler, Android manifest, Flutter widget tests.

---

## File Structure

- Modify: `frontend/lib/core/permissions/permission_service.dart` - expose location/notification status, request, and app-settings methods.
- Create: `frontend/lib/features/settings/presentation/screen/settings_screen.dart` - stateful settings UI and state-dependent actions.
- Modify: `frontend/lib/app/router/app_router.dart` - add `/settings` outside `ShellRoute`.
- Modify: `frontend/lib/features/mypage/presentation/screen/my_page_screen.dart` - connect header and account-menu settings entry points.
- Modify: `frontend/android/app/src/main/AndroidManifest.xml` - declare only location and notifications permissions used by the screen.
- Create: `frontend/test/features/settings/settings_screen_test.dart` - fake-service tests for states, request refresh, app-settings flow, and fallback back navigation.
- Modify: `frontend/test/features/mypage/my_page_screen_test.dart` - prove both My Page settings entry points navigate to settings.
- Create: `artifacts/validation/issue-32/VALIDATION.md` - capture test-first evidence and Android build result.

### Task 1: Extend the Permission Boundary

**Files:**
- Modify: `frontend/lib/core/permissions/permission_service.dart`
- Create: `frontend/test/features/settings/settings_screen_test.dart`

- [ ] **Step 1: Write a failing fake-service test for status display**

```dart
testWidgets('shows permission states from the injected service', (tester) async {
  final service = _FakePermissionService(
    locationStatus: PermissionStatus.granted,
    notificationStatus: PermissionStatus.denied,
  );

  await tester.pumpWidget(MaterialApp(home: SettingsScreen(permissionService: service)));
  await tester.pumpAndSettle();

  expect(find.text('위치 권한'), findsOneWidget);
  expect(find.text('알림 권한'), findsOneWidget);
  expect(find.text('허용됨'), findsOneWidget);
  expect(find.text('허용하기'), findsOneWidget);
});
```

- [ ] **Step 2: Run the test and verify it fails because `SettingsScreen` does not exist**

Run: `flutter test --no-pub test/features/settings/settings_screen_test.dart`

Expected: compile failure for missing settings screen import.

- [ ] **Step 3: Add service methods used by the screen**

```dart
class PermissionService {
  Future<PermissionStatus> locationStatus() => Permission.locationWhenInUse.status;
  Future<PermissionStatus> notificationStatus() => Permission.notification.status;
  Future<PermissionStatus> requestLocation() => Permission.locationWhenInUse.request();
  Future<PermissionStatus> requestNotification() => Permission.notification.request();
  Future<bool> openSettings() => openAppSettings();
}
```

- [ ] **Step 4: Run the test and verify it still fails only because the UI is missing**

Run: `flutter test --no-pub test/features/settings/settings_screen_test.dart`

Expected: compile failure for missing `SettingsScreen`, not for the fake service overrides.

### Task 2: Build the Settings Screen With Testable Permission States

**Files:**
- Create: `frontend/lib/features/settings/presentation/screen/settings_screen.dart`
- Modify: `frontend/test/features/settings/settings_screen_test.dart`

- [ ] **Step 1: Implement the injected service and initial status load**

```dart
class SettingsScreen extends StatefulWidget {
  SettingsScreen({PermissionService? permissionService, super.key})
      : permissionService = permissionService ?? PermissionService();

  final PermissionService permissionService;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

Future<void> _loadStatuses() async {
  final location = await widget.permissionService.locationStatus();
  final notification = await widget.permissionService.notificationStatus();
  if (mounted) setState(() { _locationStatus = location; _notificationStatus = notification; });
}
```

Use a compact header with safe back navigation, two 8px-radius permission rows, a retry button if `_loadStatuses` throws, and existing `AppColors` for text and surfaces.

- [ ] **Step 2: Add a failing request-refresh test**

```dart
await tester.tap(find.widgetWithText(FilledButton, '허용하기'));
await tester.pumpAndSettle();

expect(service.notificationRequestCalls, 1);
expect(find.text('허용됨'), findsNWidgets(2));
```

- [ ] **Step 3: Implement the denied and permanently denied actions**

```dart
Future<void> _handlePermission(PermissionType type, PermissionStatus status) async {
  if (status.isPermanentlyDenied || status.isRestricted) {
    await widget.permissionService.openSettings();
  } else if (type == PermissionType.location) {
    await widget.permissionService.requestLocation();
    await _loadStatuses();
  } else {
    await widget.permissionService.requestNotification();
    await _loadStatuses();
  }
}
```

Render `설정 열기` for permanently denied or restricted and `허용하기` for denied.

- [ ] **Step 4: Add and run the app-settings test**

```dart
expect(find.text('설정에서 허용 필요'), findsOneWidget);
await tester.tap(find.widgetWithText(OutlinedButton, '설정 열기'));
expect(service.openSettingsCalls, 1);
```

Run: `flutter test --no-pub test/features/settings/settings_screen_test.dart`

Expected: `All tests passed!`

- [ ] **Step 5: Commit the permission boundary and screen**

```bash
git add frontend/lib/core/permissions/permission_service.dart frontend/lib/features/settings/presentation/screen/settings_screen.dart frontend/test/features/settings/settings_screen_test.dart
git commit -m "[FE] feat(settings): 권한 관리 화면 추가 (#32)"
```

### Task 3: Connect My Page, Router, and Android Declarations

**Files:**
- Modify: `frontend/lib/app/router/app_router.dart`
- Modify: `frontend/lib/features/mypage/presentation/screen/my_page_screen.dart`
- Modify: `frontend/android/app/src/main/AndroidManifest.xml`
- Modify: `frontend/test/features/mypage/my_page_screen_test.dart`

- [ ] **Step 1: Write a failing My Page navigation test**

```dart
await tester.tap(find.byTooltip('설정'));
await tester.pumpAndSettle();
expect(find.text('권한 관리'), findsOneWidget);
```

Use a test `GoRouter` with `/main/mypage` and `/settings` routes. Add a separate test that scrolls to and taps the account-menu `설정` row.

- [ ] **Step 2: Wire the two My Page entry points and route**

```dart
GoRoute(path: '/settings', builder: (_, __) => SettingsScreen()),

_MyPageHeader(onSettings: () => context.push('/settings')),

_AccountMenu(
  onSettings: () => context.push('/settings'),
  isLoggingOut: isLoggingOut,
  onLogout: onLogout,
)
```

Keep notice and customer-service menu rows as no-op placeholders.

- [ ] **Step 3: Declare only requested Android permissions**

```xml
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

Place them before `<application>` in `frontend/android/app/src/main/AndroidManifest.xml`.

- [ ] **Step 4: Run settings and My Page tests**

Run: `flutter test --no-pub test/features/settings/settings_screen_test.dart test/features/mypage/my_page_screen_test.dart`

Expected: `All tests passed!`

- [ ] **Step 5: Commit navigation and Android configuration**

```bash
git add frontend/lib/app/router/app_router.dart frontend/lib/features/mypage/presentation/screen/my_page_screen.dart frontend/android/app/src/main/AndroidManifest.xml frontend/test/features/mypage/my_page_screen_test.dart
git commit -m "[FE] feat(settings): 마이페이지 권한 설정 연결 (#32)"
```

### Task 4: Validate and Record Evidence

**Files:**
- Create: `artifacts/validation/issue-32/VALIDATION.md`

- [ ] **Step 1: Record the test-first failures, Android permission declarations, and excluded scope**

- [ ] **Step 2: Format and run static analysis**

Run: `dart format lib/core/permissions/permission_service.dart lib/features/settings/presentation/screen/settings_screen.dart lib/features/mypage/presentation/screen/my_page_screen.dart test/features/settings/settings_screen_test.dart test/features/mypage/my_page_screen_test.dart`

Run: `flutter analyze`

Expected: `No issues found!`

- [ ] **Step 3: Run full test and Android build verification**

Run: `flutter test --no-pub`

Run: `flutter build apk --debug`

Expected: all tests pass and `build/app/outputs/flutter-apk/app-debug.apk` exists.

- [ ] **Step 4: Inspect, commit, and push the final scope**

Run: `git diff --check` and `git status --short`

```bash
git add artifacts/validation/issue-32/VALIDATION.md
git commit -m "chore(validation): 권한 설정 검증 기록 추가 (#32)"
git push origin feat/32-settings-permission-management
```
