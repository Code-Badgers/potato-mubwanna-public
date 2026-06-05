import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/onboarding/presentation/screen/onboarding_screen.dart';

void main() {
  testWidgets('shows the first onboarding step', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingScreen(),
      ),
    );

    expect(find.text('감자무봤나?'), findsOneWidget);
    expect(find.text('강원도 감자여행'), findsOneWidget);
    expect(find.text('스탬프를 모아보세요!'), findsOneWidget);
    expect(find.text('다음'), findsOneWidget);
  });
}
