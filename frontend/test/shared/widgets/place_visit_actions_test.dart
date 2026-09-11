import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:potato_mubwanna/shared/widgets/place_visit_actions.dart';

void main() {
  testWidgets('opens phone and website and reports launch failure',
      (tester) async {
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    final urls = <String>[];
    var succeeds = true;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      urls.add((call.arguments as Map)['url'] as String);
      return succeeds;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
      body: PlaceVisitActions(
          phone: '033-123-4567', website: 'https://example.com/store'),
    )));
    await tester.tap(find.text('전화 문의'));
    await tester.pumpAndSettle();
    expect(urls.single, 'tel:0331234567');
    await tester.tap(find.text('홈페이지'));
    await tester.pumpAndSettle();
    expect(urls.last, 'https://example.com/store');
    succeeds = false;
    await tester.tap(find.text('전화 문의'));
    await tester.pumpAndSettle();
    expect(find.text('연결할 수 없어요. 잠시 후 다시 시도해주세요.'), findsOneWidget);
  });
  test('accepts only safe public website and plain telephone links', () {
    expect(placeWebsiteUri('https://example.com/store')?.host, 'example.com');
    expect(placeWebsiteUri('javascript:alert(1)'), isNull);
    expect(placeWebsiteUri('https://user:pass@example.com'), isNull);
    expect(placePhoneUri('033-123-4567')?.toString(), 'tel:0331234567');
    expect(placePhoneUri('033-123-4567 / 010-1234-5678'), isNull);
    expect(placePhoneUri(''), isNull);
  });

  testWidgets('contact actions and per-menu provenance fit a small viewport',
      (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: Column(children: [
      PlaceVisitActions(phone: '033-123-4567', website: 'https://example.com'),
      PlaceSourceCaption(
          sourceUrl: 'https://apis.data.go.kr/B551011/KorService2/detailIntro2',
          verifiedOn: '2026-09-10'),
    ]))));
    expect(find.text('전화 문의'), findsOneWidget);
    expect(find.text('홈페이지'), findsOneWidget);
    expect(find.text('출처: 한국관광공사 · 2026.09.10 확인'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing contact and provenance do not fabricate labels',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: Column(children: [
      PlaceVisitActions(),
      PlaceSourceCaption(),
    ]))));
    expect(find.byType(TextButton), findsNothing);
    expect(find.textContaining('확인'), findsNothing);
  });
}
