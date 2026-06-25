import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/mission/presentation/screen/mission_screen.dart';

void main() {
  testWidgets('renders mission list and filters jumsooni missions',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: MissionScreen()),
      ),
    );

    expect(find.text('미션'), findsOneWidget);
    expect(find.text('점순이와 함께 도전해요'), findsOneWidget);
    expect(find.text('정선 5일장 곤드레 퀴즈'), findsOneWidget);

    await tester.tap(find.text('점순이').first);
    await tester.pumpAndSettle();

    expect(find.text('정선 5일장 곤드레 퀴즈'), findsOneWidget);
    expect(find.text('10,000걸음 걷기'), findsNothing);

    await tester.tap(find.text('전체').first);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('10,000걸음 걷기'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('10,000걸음 걷기'), findsOneWidget);
  });

  testWidgets('opens mission detail and reward dialog', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: MissionScreen()),
      ),
    );

    await tester.tap(find.text('정선 5일장 곤드레 퀴즈'));
    await tester.pumpAndSettle();

    expect(find.text('점순이의 미션'), findsOneWidget);
    expect(find.text('퀴즈 풀기'), findsOneWidget);
    expect(find.textContaining('황금감자 성장 아이템'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '퀴즈 풀기'));
    await tester.pumpAndSettle();

    expect(find.text('미션 완료!'), findsOneWidget);
    expect(find.text('황금감자 성장 아이템을 획득했어요.'), findsOneWidget);
  });
}
