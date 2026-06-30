import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/stamp/application/stamp_book_controller.dart';
import 'package:potato_mubwanna/features/stamp/domain/stamp_book.dart';
import 'package:potato_mubwanna/features/stamp/presentation/screen/stamp_book_screen.dart';

void main() {
  testWidgets('renders API rallybook progress, city stamps, and next reward',
      (tester) async {
    await _pumpScreen(
      tester,
      override: stampBookProvider.overrideWith((ref) async => _stampBook()),
    );
    await tester.pumpAndSettle();

    expect(find.text('랠리북'), findsOneWidget);
    expect(find.text('수집률'), findsOneWidget);
    expect(find.text('8 / 18'), findsOneWidget);
    expect(find.text('12개 달성까지 4개 남았어요'), findsOneWidget);
    expect(find.text('시군별 스탬프'), findsOneWidget);
    expect(find.text('강릉시'), findsOneWidget);
    expect(find.text('정선군'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('철원군'), findsOneWidget);
    expect(find.text('12개 달성 시 지역쿠폰 지급'), findsOneWidget);
    expect(find.text('앞으로 4개만 더 모으면 받을 수 있어요.'), findsOneWidget);
  });

  testWidgets('shows a loading indicator while rallybook is loading',
      (tester) async {
    final completer = Completer<StampBook?>();

    await _pumpScreen(
      tester,
      override: stampBookProvider.overrideWith((ref) => completer.future),
    );

    expect(find.text('랠리북'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows an error and retry action when rallybook loading fails',
      (tester) async {
    await _pumpScreen(
      tester,
      override: stampBookProvider.overrideWith(
        (ref) => Future<StampBook?>.error(Exception('network unavailable')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('랠리북'), findsOneWidget);
    expect(find.text('랠리북을 불러오지 못했습니다.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
  });

  testWidgets('shows completion copy after all city stamps are acquired',
      (tester) async {
    await _pumpScreen(
      tester,
      override: stampBookProvider.overrideWith(
        (ref) async => _stampBook(acquiredCount: 18, completed: true),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.text('18개 시군 랠리를 모두 완주했어요.'), findsOneWidget);
  });

  testWidgets('prompts signed-out users to log in', (tester) async {
    await _pumpScreen(
      tester,
      override: stampBookProvider.overrideWith((ref) async => null),
    );
    await tester.pumpAndSettle();

    expect(find.text('로그인 후 랠리북을 확인할 수 있어요.'), findsOneWidget);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required Override override,
}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [override],
      child: const MaterialApp(home: StampBookScreen()),
    ),
  );
}

StampBook _stampBook({
  int acquiredCount = 8,
  bool completed = false,
}) {
  const cityNames = [
    '강릉시',
    '정선군',
    '평창군',
    '춘천시',
    '속초시',
    '홍천군',
    '횡성군',
    '영월군',
    '원주시',
    '동해시',
    '태백시',
    '삼척시',
    '양양군',
    '고성군',
    '인제군',
    '양구군',
    '화천군',
    '철원군',
  ];

  return StampBook(
    progress: StampProgress(
      totalCount: cityNames.length,
      acquiredCount: acquiredCount,
      stamps: [
        for (var index = 0; index < cityNames.length; index++)
          RallybookStamp(
            stampId: index + 1,
            cityName: cityNames[index],
            stampName: '감자 ${index + 1}',
            stampImage: null,
            acquired: index < acquiredCount,
            acquiredAt: index < acquiredCount
                ? DateTime.parse('2026-06-30T00:00:00Z')
                : null,
          ),
      ],
    ),
    nextReward: NextStampReward(
      acquiredCount: acquiredCount,
      nextTargetCount: completed ? null : 12,
      remainingCount: completed ? 0 : 4,
      completed: completed,
    ),
  );
}
