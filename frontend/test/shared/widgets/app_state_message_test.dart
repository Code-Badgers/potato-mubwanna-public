import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/app/theme/app_colors.dart';
import 'package:potato_mubwanna/app/theme/app_design_tokens.dart';
import 'package:potato_mubwanna/app/theme/app_theme.dart';
import 'package:potato_mubwanna/shared/widgets/app_state_message.dart';

void main() {
  testWidgets('shared state fits small screens and retains retry action',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var retries = 0;
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
              child: SingleChildScrollView(
                  child: AppStateMessage(
            icon: Icons.cloud_off_outlined,
            title: '감자 스팟 정보를 불러오지 못했습니다.',
            description: '네트워크 연결을 확인한 뒤 다시 시도해주세요.',
            actionLabel: '다시 시도',
            onAction: () => retries++,
          ))),
        )));
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(AppDimens.buttonHeight));
    await tester.tap(find.text('다시 시도'));
    expect(retries, 1);
  });

  testWidgets('empty state does not expose an inactive action', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: AppStateMessage(
      icon: Icons.flag_outlined,
      title: '표시할 미션이 없습니다.',
    ))));
    expect(find.byType(FilledButton), findsNothing);
  });

  test('theme shares button sizing without changing the primary palette', () {
    final theme = AppTheme.light;
    expect(theme.colorScheme.primary, AppColors.primary);
    final primary = theme.filledButtonTheme.style!;
    final secondary = theme.outlinedButtonTheme.style!;
    expect(primary.minimumSize!.resolve({})!.height, AppDimens.buttonHeight);
    expect(secondary.minimumSize!.resolve({})!.height, AppDimens.buttonHeight);
    expect(primary.textStyle!.resolve({}), AppTextStyles.button);
    expect(AppDimens.landscapeImageRatio, 16 / 9);
  });
}
