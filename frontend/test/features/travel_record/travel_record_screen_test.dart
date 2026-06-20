import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:potato_mubwanna/features/travel_record/presentation/screen/travel_record_screen.dart';

void main() {
  testWidgets('renders the travel summary and acquired stamp records',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TravelRecordScreen()),
    );

    expect(find.text('여행 기록'), findsOneWidget);
    expect(find.text('총 3곳 방문'), findsOneWidget);
    expect(find.text('정선 5일장'), findsOneWidget);
    expect(find.text('강릉 커피거리'), findsOneWidget);
    expect(find.text('스탬프 획득'), findsNWidgets(3));
  });

  testWidgets('returns to My Page when opened without a back stack',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/travel-records',
      routes: [
        GoRoute(
          path: '/travel-records',
          builder: (_, __) => const TravelRecordScreen(),
        ),
        GoRoute(
          path: '/main/mypage',
          builder: (_, __) => const Scaffold(
            body: Center(child: Text('My Page destination')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.tap(find.byTooltip('뒤로 가기'));
    await tester.pumpAndSettle();

    expect(find.text('My Page destination'), findsOneWidget);
  });
}
