import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potato_mubwanna/app/app.dart';

void main() {
  testWidgets('renders onboarding entry screen', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: PotatoMubwannaApp()),
    );
    await tester.pump();

    expect(find.text('터치하여 시작하기'), findsOneWidget);
  });
}
