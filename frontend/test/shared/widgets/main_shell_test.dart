import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:potato_mubwanna/shared/widgets/navigation/main_shell.dart';

void main() {
  testWidgets('renders the five footer navigation labels', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
              path: '/main/missions',
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
    expect(find.text('스탬프'), findsOneWidget);
    expect(find.text('감자도감'), findsOneWidget);
    expect(find.text('미션'), findsOneWidget);
    expect(find.text('마이'), findsOneWidget);

    final footerBottom = tester.getBottomLeft(find.text('지도')).dy;
    expect(footerBottom, greaterThan(880));
  });
}
