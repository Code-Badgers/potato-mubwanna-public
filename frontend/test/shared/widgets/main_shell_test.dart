import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:potato_mubwanna/shared/widgets/main_shell.dart';

void main() {
  testWidgets('renders the five footer navigation labels', (tester) async {
    final router = GoRouter(
      initialLocation: '/main/map',
      routes: [
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: '/main/map',
              builder: (context, state) => const SizedBox(),
            ),
            GoRoute(
              path: '/main/stamps',
              builder: (context, state) => const SizedBox(),
            ),
            GoRoute(
              path: '/main/potatoes',
              builder: (context, state) => const SizedBox(),
            ),
            GoRoute(
              path: '/main/coupons',
              builder: (context, state) => const SizedBox(),
            ),
            GoRoute(
              path: '/main/mypage',
              builder: (context, state) => const SizedBox(),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    expect(find.text('지도'), findsOneWidget);
    expect(find.text('랠리북'), findsOneWidget);
    expect(find.text('감자 도감'), findsOneWidget);
    expect(find.text('보상'), findsOneWidget);
    expect(find.text('마이'), findsOneWidget);
  });
}
