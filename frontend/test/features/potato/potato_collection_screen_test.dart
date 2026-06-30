import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/potato/presentation/screen/potato_collection_screen.dart';

void main() {
  testWidgets('shows the potato collection placeholder in Korean', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PotatoCollectionScreen()));

    expect(find.text('감자 도감'), findsNWidgets(2));
    expect(find.text('수집한 지역 감자와 아직 잠긴 감자를 확인할 수 있습니다.'), findsOneWidget);
    expect(find.text('Potato Collection'), findsNothing);
  });
}
