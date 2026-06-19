import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/mypage/presentation/screen/my_page_screen.dart';

void main() {
  testWidgets('renders profile summary, quick actions, and account menu',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: MyPageScreen(),
      ),
    );

    expect(find.text('마이'), findsOneWidget);
    expect(find.text('감자여행자'), findsOneWidget);
    expect(find.text('Lv.2'), findsOneWidget);
    expect(find.text('6,420 / 10,000'), findsOneWidget);

    expect(find.text('누적 걸음 수'), findsOneWidget);
    expect(find.text('256,842'), findsOneWidget);
    expect(find.text('누적 스탬프 수'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('보유 감자 수'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);

    expect(find.text('보상함'), findsOneWidget);
    expect(find.text('여행 기록'), findsOneWidget);
    expect(find.text('내 미션'), findsOneWidget);
    expect(find.text('감자 도감'), findsOneWidget);

    expect(find.text('강원 감자 여행'), findsOneWidget);
    expect(find.text('기록을 확인해보세요!'), findsOneWidget);
    expect(find.text('설정'), findsOneWidget);
    expect(find.text('공지사항'), findsOneWidget);
    expect(find.text('고객센터'), findsOneWidget);
    expect(find.text('로그아웃'), findsOneWidget);
  });
}
