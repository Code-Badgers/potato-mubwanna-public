import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/notice/application/notice_controller.dart';
import 'package:potato_mubwanna/features/notice/domain/notice.dart';
import 'package:potato_mubwanna/features/notice/presentation/screen/notice_screen.dart';

void main() {
  testWidgets('shows server notices and opens detail', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [noticesProvider.overrideWith((ref) async => _notices)],
        child: const MaterialApp(home: NoticeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('notice-list')), findsOneWidget);
    expect(find.text('방문 인증 안내'), findsOneWidget);
    expect(find.text('공모전 MVP'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('notice-2')));
    await tester.pumpAndSettle();

    expect(find.text('현장에서 위치를 확인해 주세요.'), findsOneWidget);
    expect(find.text('확인'), findsOneWidget);
  });

  testWidgets('shows empty notice state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          noticesProvider.overrideWith((ref) async => const <Notice>[]),
        ],
        child: const MaterialApp(home: NoticeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('새로운 공지사항이 없어요'), findsOneWidget);
  });

  testWidgets('shows retry action when notice loading fails', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          noticesProvider.overrideWith(
            (ref) => Future<List<Notice>>.error(const _NoticeTestException()),
          ),
        ],
        child: const MaterialApp(home: NoticeScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('공지사항을 불러오지 못했습니다.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
  });
}

final _notices = [
  Notice(
    id: 2,
    title: '방문 인증 안내',
    content: '현장에서 위치를 확인해 주세요.',
    publishedAt: DateTime.utc(2026, 8, 20),
  ),
];

class _NoticeTestException implements Exception {
  const _NoticeTestException();
}
