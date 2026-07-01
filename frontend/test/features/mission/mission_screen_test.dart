import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/mission/presentation/screen/mission_screen.dart';

void main() {
  testWidgets('renders mission list and category filters', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: MissionScreen()),
      ),
    );

    expect(find.text('미션'), findsOneWidget);
    expect(find.text('점순이와 함께 도전해요'), findsOneWidget);
    expect(find.text('정선 5일장 곤드레 퀴즈'), findsOneWidget);
    expect(find.text('점순이'), findsNothing);
    expect(find.text('일일'), findsOneWidget);
    expect(find.text('주간'), findsOneWidget);
    expect(find.text('이벤트'), findsOneWidget);

    await tester.tap(find.text('일일').first);
    await tester.pumpAndSettle();

    expect(find.text('정선 5일장 곤드레 퀴즈'), findsNothing);
    expect(find.text('10,000걸음 걷기'), findsOneWidget);

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

  testWidgets('disables completion action for completed missions',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: MissionScreen()),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('스탬프 1개 획득하기'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('스탬프 1개 획득하기'));
    await tester.pumpAndSettle();

    final completedButton = tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, '완료된 미션'));
    expect(completedButton.onPressed, isNull);

    await tester.tap(find.widgetWithText(FilledButton, '완료된 미션'));
    await tester.pumpAndSettle();

    expect(find.text('미션 완료!'), findsNothing);
  });
}
