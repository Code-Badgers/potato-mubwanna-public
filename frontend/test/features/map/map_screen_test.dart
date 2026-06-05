import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/map/presentation/screen/map_screen.dart';

void main() {
  testWidgets('renders map home discovery UI', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MapScreen(),
      ),
    );

    expect(find.text('감자 찾기'), findsOneWidget);
    expect(find.text('주변 감자 스팟 4곳'), findsOneWidget);
    expect(find.text('전체'), findsOneWidget);
    expect(find.text('관광'), findsOneWidget);
    expect(find.text('정선 5일장'), findsOneWidget);
    expect(find.text('상세보기'), findsOneWidget);
  });
}
