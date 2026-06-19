import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  testWidgets('renders permission guide after login step', (tester) async {
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
    expect(find.text('카메라 [선택]'), findsOneWidget);
    expect(find.text('사진 및 동영상 [선택]'), findsOneWidget);
    expect(find.text('위치 [필수]'), findsOneWidget);
    expect(find.text('확인'), findsOneWidget);
  });
}
