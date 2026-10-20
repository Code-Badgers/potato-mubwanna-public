import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/app/theme/app_colors.dart';
import 'package:potato_mubwanna/app/theme/app_theme.dart';

double contrast(Color first, Color second) {
  final a = first.computeLuminance();
  final b = second.computeLuminance();
  return a > b ? (a + .05) / (b + .05) : (b + .05) / (a + .05);
}

void main() {
  test('enabled button labels meet contrast in interaction states', () {
    final theme = AppTheme.light;
    for (final states in <Set<WidgetState>>[
      {},
      {WidgetState.hovered},
      {WidgetState.focused},
      {WidgetState.pressed},
    ]) {
      final filled = theme.filledButtonTheme.style!;
      expect(
        contrast(filled.foregroundColor!.resolve(states)!,
            filled.backgroundColor!.resolve(states)!),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(
            theme.outlinedButtonTheme.style!.foregroundColor!.resolve(states)!,
            AppColors.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(theme.textButtonTheme.style!.foregroundColor!.resolve(states)!,
            AppColors.surface),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  testWidgets('common buttons have labels and 48px tap targets at 200% text',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: Scaffold(
          body: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              FilledButton(onPressed: () {}, child: const Text('다시 시도')),
              OutlinedButton(onPressed: () {}, child: const Text('길찾기')),
              TextButton(onPressed: () {}, child: const Text('전화 문의')),
            ]),
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
  });
}
