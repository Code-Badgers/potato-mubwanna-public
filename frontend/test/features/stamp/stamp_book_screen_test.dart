import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/stamp/presentation/screen/stamp_book_screen.dart';

void main() {
  testWidgets('renders rallybook progress, city stamps, and reward',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: StampBookScreen(),
      ),
    );

    expect(find.text('랠리북'), findsOneWidget);
    expect(find.text('수집률'), findsOneWidget);
    expect(find.text('8 / 18'), findsOneWidget);
    expect(find.text('10개 달성까지 2개 남았어요'), findsOneWidget);
    expect(find.text('시군별 스탬프'), findsOneWidget);
    expect(find.text('강릉'), findsOneWidget);
    expect(find.text('정선'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('철원'), findsOneWidget);
    expect(find.text('10개 달성 시 지역쿠폰 지급'), findsOneWidget);
    expect(find.text('앞으로 2개만 더 모으면 받을 수 있어요.'), findsOneWidget);
  });
}
