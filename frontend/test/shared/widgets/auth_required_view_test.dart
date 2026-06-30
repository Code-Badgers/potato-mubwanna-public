import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/shared/widgets/auth_required_view.dart';

void main() {
  testWidgets('renders a login prompt and invokes the login action',
      (tester) async {
    var loginCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuthRequiredView(
            description: '보상함을 확인하려면 로그인해주세요.',
            onLogin: () => loginCalls++,
          ),
        ),
      ),
    );

    expect(find.text('로그인이 필요한 서비스예요'), findsOneWidget);
    expect(find.text('보상함을 확인하려면 로그인해주세요.'), findsOneWidget);

    await tester.tap(find.text('로그인하러 가기'));

    expect(loginCalls, 1);
  });
}
