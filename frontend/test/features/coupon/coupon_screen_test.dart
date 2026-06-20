import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/coupon/presentation/screen/coupon_screen.dart';

void main() {
  testWidgets('shows available coupons and opens a QR preview', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: CouponScreen(),
      ),
    );

    expect(find.text('보상함'), findsOneWidget);
    expect(find.text('사용 가능 2'), findsOneWidget);
    expect(find.text('강원 감자 여행 상품권'), findsOneWidget);
    expect(find.text('5,000원'), findsOneWidget);

    await tester.tap(find.text('QR 보기').first);
    await tester.pumpAndSettle();

    expect(find.text('QR 코드'), findsOneWidget);
    expect(find.text('닫기'), findsOneWidget);

    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();

    expect(find.text('QR 코드'), findsNothing);
  });

  testWidgets('shows used coupons when the used tab is selected',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CouponScreen(),
      ),
    );

    await tester.tap(find.text('사용 완료 1'));
    await tester.pumpAndSettle();

    expect(find.text('춘천 감자전 할인쿠폰'), findsOneWidget);
    expect(find.text('사용 완료'), findsOneWidget);
    expect(find.text('QR 보기'), findsNothing);
  });
}
