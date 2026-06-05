import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/onboarding/presentation/screen/onboarding_screen.dart';

void main() {
  testWidgets('starts from the image onboarding and moves to permission step',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingScreen(),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('터치하여 시작하기'), findsOneWidget);

    await tester.tap(find.text('터치하여 시작하기'));
    await tester.pumpAndSettle();

    expect(find.text('위치 권한이 필요해요'), findsOneWidget);
    expect(find.text('위치 권한 확인'), findsOneWidget);
  });
}
