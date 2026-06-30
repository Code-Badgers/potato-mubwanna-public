import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:potato_mubwanna/core/permissions/permission_service.dart';
import 'package:potato_mubwanna/features/onboarding/presentation/screen/onboarding_screen.dart';
import 'package:potato_mubwanna/features/onboarding/presentation/screen/permission_guide_screen.dart';

void main() {
  testWidgets('walks through service intro onboarding pages', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingScreen(),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('터치하여 시작하기'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-430, 0));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('지도로 감자 스팟 찾기'), findsOneWidget);
    expect(find.text('다음'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-430, 0));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('수집하고 보상받기'), findsOneWidget);
    expect(find.text('카카오 로그인하러 가기'), findsOneWidget);
  });

  testWidgets('shows only the runtime permissions currently used',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: PermissionGuideScreen(),
      ),
    );

    expect(find.text('편리한 감자여행을 위해\n접근권한을 확인해주세요'), findsOneWidget);
    expect(find.text('알림 [선택]'), findsOneWidget);
    expect(find.text('위치 [선택]'), findsOneWidget);
    expect(find.text('카메라 [선택]'), findsNothing);
    expect(find.text('사진 및 동영상 [선택]'), findsNothing);
    expect(find.text('닉네임 [필수]'), findsNothing);
    expect(find.text('이메일 [선택]'), findsNothing);
    expect(find.text('확인'), findsOneWidget);
  });

  testWidgets('requests location and enters the map when granted',
      (tester) async {
    final permissionService = _FakePermissionService(
      requestResult: PermissionStatus.granted,
    );
    final router = _permissionRouter(permissionService);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(permissionService.locationRequestCalls, 1);
    expect(find.text('map destination'), findsOneWidget);
  });

  testWidgets('explains denial before allowing entry without permission',
      (tester) async {
    final permissionService = _FakePermissionService(
      requestResult: PermissionStatus.denied,
    );
    final router = _permissionRouter(permissionService);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(permissionService.locationRequestCalls, 1);
    expect(
      find.text('위치 권한 없이 둘러볼 수 있지만 주변 탐색과 방문 인증은 제한됩니다.'),
      findsOneWidget,
    );
    expect(find.text('권한 없이 둘러보기'), findsOneWidget);
    expect(find.text('map destination'), findsNothing);

    await tester.tap(find.text('권한 없이 둘러보기'));
    await tester.pumpAndSettle();

    expect(find.text('map destination'), findsOneWidget);
  });

  testWidgets('does not request runtime permission on the web', (tester) async {
    final permissionService = _FakePermissionService(
      supportsRuntimePermissions: false,
      requestResult: PermissionStatus.denied,
    );
    final router = _permissionRouter(permissionService);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    expect(
      find.text('웹에서는 브라우저 설정에서 위치와 알림 권한을 관리해주세요.'),
      findsOneWidget,
    );

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(permissionService.locationRequestCalls, 0);
    expect(find.text('map destination'), findsOneWidget);
  });
}

GoRouter _permissionRouter(PermissionService permissionService) {
  return GoRouter(
    initialLocation: '/permissions',
    routes: [
      GoRoute(
        path: '/permissions',
        builder: (_, __) => PermissionGuideScreen(
          permissionService: permissionService,
        ),
      ),
      GoRoute(
        path: '/main/map',
        builder: (_, __) => const Scaffold(
          body: Center(child: Text('map destination')),
        ),
      ),
    ],
  );
}

class _FakePermissionService extends PermissionService {
  _FakePermissionService({
    this.supportsRuntimePermissions = true,
    required this.requestResult,
  });

  @override
  final bool supportsRuntimePermissions;

  final PermissionStatus requestResult;
  int locationRequestCalls = 0;

  @override
  Future<PermissionStatus> requestLocation() async {
    locationRequestCalls++;
    return requestResult;
  }
}
