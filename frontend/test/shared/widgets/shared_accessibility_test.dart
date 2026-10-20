import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/app/theme/app_theme.dart';
import 'package:potato_mubwanna/shared/widgets/auth_required_view.dart';
import 'package:potato_mubwanna/shared/widgets/loading/potato_loading_view.dart';

void main() {
  testWidgets(
      'login-required content remains reachable on a short large-text screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var pressed = false;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: Scaffold(
            body: AuthRequiredView(
          description: '로그인하고 나만의 여행 기록과 보상을 확인해보세요.',
          onLogin: () => pressed = true,
        )),
      ),
    ));
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('로그인하러 가기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('로그인하러 가기'));
    expect(pressed, isTrue);
  });

  testWidgets(
      'loading content fits a short screen and exposes its actual status',
      (tester) async {
    tester.view.physicalSize = const Size(320, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(2)),
        child: Scaffold(
            body: PotatoLoadingView.fullScreen(
          message: '로그인 상태를 확인하고 있어요',
          subtitle: '연결 상태에 따라 잠시 걸릴 수 있어요.',
        )),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    expect(
        tester
            .getSemantics(find.bySemanticsLabel('콘텐츠를 불러오는 중'))
            .getSemanticsData()
            .value,
        contains('로그인 상태를 확인하고 있어요'));
    await tester.pumpWidget(const SizedBox());
    semantics.dispose();
  });
}
