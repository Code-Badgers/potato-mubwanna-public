import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:potato_mubwanna/core/permissions/permission_service.dart';
import 'package:potato_mubwanna/features/settings/presentation/screen/settings_screen.dart';

void main() {
  testWidgets('shows permission states from the injected service',
      (tester) async {
    final service = _FakePermissionService(
      location: PermissionStatus.granted,
      notification: PermissionStatus.denied,
    );

    await tester.pumpWidget(
      MaterialApp(home: SettingsScreen(permissionService: service)),
    );
    await tester.pumpAndSettle();

    expect(find.text('권한 관리'), findsOneWidget);
    expect(find.text('위치 권한'), findsOneWidget);
    expect(find.text('알림 권한'), findsOneWidget);
    expect(find.text('허용됨'), findsOneWidget);
    expect(find.text('허용하기'), findsOneWidget);
  });

  testWidgets('requests a denied permission and refreshes its state',
      (tester) async {
    final service = _FakePermissionService(
      location: PermissionStatus.granted,
      notification: PermissionStatus.denied,
    );

    await tester.pumpWidget(
      MaterialApp(home: SettingsScreen(permissionService: service)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, '허용하기'));
    await tester.pumpAndSettle();

    expect(service.notificationRequestCalls, 1);
    expect(find.text('허용됨'), findsNWidgets(2));
  });

  testWidgets('opens system settings for a permanently denied permission',
      (tester) async {
    final service = _FakePermissionService(
      location: PermissionStatus.permanentlyDenied,
      notification: PermissionStatus.granted,
    );

    await tester.pumpWidget(
      MaterialApp(home: SettingsScreen(permissionService: service)),
    );
    await tester.pumpAndSettle();

    expect(find.text('설정에서 허용 필요'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, '설정 열기'));

    expect(service.openSettingsCalls, 1);
  });
}

class _FakePermissionService extends PermissionService {
  _FakePermissionService({
    required this.location,
    required this.notification,
  });

  PermissionStatus location;
  PermissionStatus notification;
  int notificationRequestCalls = 0;
  int openSettingsCalls = 0;

  @override
  Future<PermissionStatus> locationStatus() async => location;

  @override
  Future<PermissionStatus> notificationStatus() async => notification;

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
