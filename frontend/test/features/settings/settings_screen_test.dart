import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:potato_mubwanna/core/permissions/permission_service.dart';
import 'package:potato_mubwanna/features/push/application/push_notification_service.dart';
import 'package:potato_mubwanna/features/settings/presentation/screen/settings_screen.dart';
import 'package:potato_mubwanna/features/potato/domain/step_count_reader.dart';

void main() {
  testWidgets('shows browser guidance without querying runtime permissions',
      (tester) async {
    final service = _FakePermissionService(
      supportsRuntimePermissions: false,
      location: PermissionStatus.denied,
      notification: PermissionStatus.denied,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          permissionService: service,
          stepCountReader: const _FixedStepCountReader(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('웹에서는 브라우저 설정에서 위치와 알림 권한을 관리해주세요.'),
      findsOneWidget,
    );
    expect(find.text('권한 상태를 불러오지 못했습니다.'), findsNothing);
    expect(find.text('다시 시도'), findsNothing);
    expect(service.locationStatusCalls, 0);
    expect(service.notificationStatusCalls, 0);
  });

  testWidgets('shows permission states from the injected service',
      (tester) async {
    final service = _FakePermissionService(
      location: PermissionStatus.granted,
      notification: PermissionStatus.denied,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          permissionService: service,
          stepCountReader: const _FixedStepCountReader(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('설정'), findsOneWidget);
    expect(find.text('권한 관리'), findsNothing);
    expect(find.text('필수 기능에 필요한 접근권한을 관리합니다.'), findsNothing);
    expect(find.text('위치 권한'), findsOneWidget);
    expect(find.text('알림 권한'), findsOneWidget);
    expect(find.text('허용됨'), findsOneWidget);
    expect(find.text('허용하기'), findsOneWidget);
  });

  testWidgets('shows when health app permission is still required',
      (tester) async {
    final service = _FakePermissionService(
      location: PermissionStatus.granted,
      notification: PermissionStatus.granted,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          permissionService: service,
          stepCountReader: const _FixedStepCountReader(
            status: StepCountReadStatus.healthPermissionRequired,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('걸음 정보'), findsOneWidget);
    expect(find.text('건강 앱 권한 필요'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '연결하기'), findsOneWidget);
  });

  testWidgets('requests a denied permission and refreshes its state',
      (tester) async {
    final service = _FakePermissionService(
      location: PermissionStatus.granted,
      notification: PermissionStatus.denied,
    );
    final pushLifecycle = _RecordingPushTokenLifecycle();

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          permissionService: service,
          stepCountReader: const _FixedStepCountReader(),
          pushTokenLifecycle: pushLifecycle,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, '허용하기'));
    await tester.pumpAndSettle();

    expect(service.notificationRequestCalls, 1);
    expect(pushLifecycle.unregisterCalls, 1);
    expect(pushLifecycle.synchronizeCalls, 1);
    expect(find.text('허용됨'), findsNWidgets(2));
  });

  testWidgets('requests location permission from settings action',
      (tester) async {
    final service = _FakePermissionService(
      location: PermissionStatus.denied,
      notification: PermissionStatus.granted,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          permissionService: service,
          stepCountReader: const _FixedStepCountReader(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, '허용하기'));
    await tester.pumpAndSettle();

    expect(service.locationRequestCalls, 1);
    expect(find.text('허용됨'), findsNWidgets(2));
  });

  testWidgets('shows a guide when location permission remains denied',
      (tester) async {
    final service = _FakePermissionService(
      location: PermissionStatus.denied,
      notification: PermissionStatus.granted,
      grantLocationOnRequest: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          permissionService: service,
          stepCountReader: const _FixedStepCountReader(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, '허용하기'));
    await tester.pumpAndSettle();

    expect(service.locationRequestCalls, 1);
    expect(
      find.text('위치 권한이 허용되지 않았습니다. 주변 탐색과 방문 인증이 제한됩니다.'),
      findsOneWidget,
    );
  });

  testWidgets('opens system settings for a permanently denied permission',
      (tester) async {
    final service = _FakePermissionService(
      location: PermissionStatus.permanentlyDenied,
      notification: PermissionStatus.granted,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          permissionService: service,
          stepCountReader: const _FixedStepCountReader(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('설정에서 허용 필요'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, '설정 열기'));

    expect(service.openSettingsCalls, 1);
  });

  testWidgets('refreshes permission statuses when the app resumes',
      (tester) async {
    final service = _FakePermissionService(
      location: PermissionStatus.granted,
      notification: PermissionStatus.denied,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          permissionService: service,
          stepCountReader: const _FixedStepCountReader(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    service.notification = PermissionStatus.granted;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(service.locationStatusCalls, 2);
    expect(service.notificationStatusCalls, 2);
    expect(find.text('허용됨'), findsNWidgets(2));
    expect(find.text('허용하기'), findsNothing);
  });

  testWidgets('shows account actions in settings when authenticated',
      (tester) async {
    final service = _FakePermissionService(
      location: PermissionStatus.granted,
      notification: PermissionStatus.granted,
    );
    var logoutCalls = 0;
    var signedOutCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          permissionService: service,
          stepCountReader: const _FixedStepCountReader(),
          showAccountActions: true,
          onLogout: () async => logoutCalls++,
          onSignedOut: () => signedOutCalls++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('로그아웃'), findsOneWidget);
    expect(find.text('회원 탈퇴'), findsOneWidget);

    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();

    expect(logoutCalls, 1);
    expect(signedOutCalls, 1);
  });

  testWidgets('confirms account withdrawal inside settings', (tester) async {
    final service = _FakePermissionService(
      location: PermissionStatus.granted,
      notification: PermissionStatus.granted,
    );
    var withdrawalCalls = 0;
    var signedOutCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          permissionService: service,
          stepCountReader: const _FixedStepCountReader(),
          showAccountActions: true,
          onWithdrawAccount: () async {
            withdrawalCalls++;
            return true;
          },
          onSignedOut: () => signedOutCalls++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('회원 탈퇴'));
    await tester.pumpAndSettle();

    expect(find.text('정말 탈퇴하시겠어요?'), findsOneWidget);
    expect(withdrawalCalls, 0);

    await tester.tap(find.widgetWithText(FilledButton, '회원 탈퇴'));
    await tester.pumpAndSettle();

    expect(withdrawalCalls, 1);
    expect(signedOutCalls, 1);
  });
}

class _FakePermissionService extends PermissionService {
  _FakePermissionService({
    this.supportsRuntimePermissions = true,
    required this.location,
    required this.notification,
    this.grantLocationOnRequest = true,
  });

  @override
  final bool supportsRuntimePermissions;

  PermissionStatus location;
  PermissionStatus notification;
  bool grantLocationOnRequest;
  int locationStatusCalls = 0;
  int notificationStatusCalls = 0;
  int locationRequestCalls = 0;
  int notificationRequestCalls = 0;
  int openSettingsCalls = 0;

  @override
  Future<PermissionStatus> locationStatus() async {
    locationStatusCalls++;
    return location;
  }

  @override
  Future<PermissionStatus> notificationStatus() async {
    notificationStatusCalls++;
    return notification;
  }

  @override
  Future<PermissionStatus> requestLocation() async {
    locationRequestCalls++;
    if (grantLocationOnRequest) {
      location = PermissionStatus.granted;
    }
    return location;
  }

  @override
  Future<PermissionStatus> requestNotification() async {
    notificationRequestCalls++;
    notification = PermissionStatus.granted;
    return notification;
  }

  @override
  Future<bool> openSettings() async {
    openSettingsCalls++;
    return true;
  }
}

class _RecordingPushTokenLifecycle implements PushTokenLifecycle {
  int synchronizeCalls = 0;
  int unregisterCalls = 0;

  @override
  Future<void> synchronize() async {
    synchronizeCalls++;
  }

  @override
  Future<void> unregister() async {
    unregisterCalls++;
  }
}

class _FixedStepCountReader implements StepCountReader {
  const _FixedStepCountReader({
    this.status = StepCountReadStatus.success,
  });

  final StepCountReadStatus status;

  @override
  Future<StepCountReadResult> readTodaySteps({
    StepCountAuthorization authorization =
        StepCountAuthorization.requestIfNeeded,
  }) async {
    if (status != StepCountReadStatus.success) {
      return StepCountReadResult(status: status);
    }
    return StepCountReadResult.success(
      StepCountSnapshot(
        activityDate: DateTime(2026, 8, 20),
        steps: 1200,
        distanceMeters: 840,
        source: ActivitySyncSource.healthConnect,
      ),
    );
  }

  @override
  Future<void> openHealthSettings() async {}
}
