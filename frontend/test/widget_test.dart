import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potato_mubwanna/app/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('renders onboarding entry screen', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(child: PotatoMubwannaApp()),
    );
    for (var index = 0; index < 10; index++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.text('터치하여 시작하기').evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.text('터치하여 시작하기'), findsOneWidget);
  });
}
