import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:potato_mubwanna/shared/widgets/navigation/main_shell.dart';

void main() {
  testWidgets('renders the five footer navigation labels', (tester) async {
    await _setMobileViewport(tester);
    final router = _buildRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    expect(find.text('지도'), findsOneWidget);
    expect(find.text('스탬프'), findsOneWidget);
    expect(find.text('감자밭'), findsOneWidget);
    expect(find.text('미션'), findsOneWidget);
    expect(find.text('마이'), findsOneWidget);

    final footerBottom = tester.getBottomLeft(find.text('지도')).dy;
    expect(footerBottom, greaterThan(880));
  });

  testWidgets('system back returns through previously visited tabs', (
    tester,
  ) async {
    await _setMobileViewport(tester);
    final router = _buildRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('스탬프'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('감자밭'));
    await tester.pumpAndSettle();
    expect(find.text('감자밭 화면'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('스탬프 화면'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('지도 화면'), findsOneWidget);
  });

  testWidgets('system back closes an inner sheet before leaving its tab', (
    tester,
  ) async {
    await _setMobileViewport(tester);
    final router = _buildRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('스탬프'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-inner-sheet')));
    await tester.pumpAndSettle();
    expect(find.text('작은 화면'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('작은 화면'), findsNothing);
    expect(find.text('스탬프 화면'), findsOneWidget);
  });

  testWidgets('system back returns from an inner route to its parent tab', (
    tester,
  ) async {
    await _setMobileViewport(tester);
    final router = _buildRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('스탬프'));
    await tester.pumpAndSettle();
    router.push('/main/stamps/cities');
    await tester.pumpAndSettle();
    expect(find.text('지역별 스탬프 화면'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('스탬프 화면'), findsOneWidget);
    expect(find.text('지도 화면'), findsNothing);
  });

  testWidgets('system back keeps the root map open', (tester) async {
    await _setMobileViewport(tester);
    final router = _buildRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.text('지도 화면'), findsOneWidget);
    expect(find.text('현재 첫 화면입니다.'), findsOneWidget);
  });

  testWidgets('system back closes an inner sheet on the root map', (
    tester,
  ) async {
    await _setMobileViewport(tester);
    final router = _buildRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-inner-sheet')));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('작은 화면'), findsNothing);
    expect(find.text('지도 화면'), findsOneWidget);
  });
}

Future<void> _setMobileViewport(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/main/map',
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/main/map',
            builder: (context, state) => const _TestPage(
              label: '지도 화면',
              canOpenInnerSheet: true,
            ),
          ),
          GoRoute(
            path: '/main/stamps',
            builder: (context, state) => const _TestPage(
              label: '스탬프 화면',
              canOpenInnerSheet: true,
            ),
          ),
          GoRoute(
            path: '/main/stamps/cities',
            builder: (context, state) => const _TestPage(label: '지역별 스탬프 화면'),
          ),
          GoRoute(
            path: '/main/potatoes',
            builder: (context, state) => const _TestPage(label: '감자밭 화면'),
          ),
          GoRoute(
            path: '/main/missions',
            builder: (context, state) => const _TestPage(label: '미션 화면'),
          ),
          GoRoute(
            path: '/main/mypage',
            builder: (context, state) => const _TestPage(label: '마이 화면'),
          ),
        ],
      ),
    ],
  );
}

class _TestPage extends StatelessWidget {
  const _TestPage({required this.label, this.canOpenInnerSheet = false});

  final String label;
  final bool canOpenInnerSheet;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (canOpenInnerSheet)
            FilledButton(
              key: const ValueKey('open-inner-sheet'),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (context) => const SizedBox(
                  height: 240,
                  child: Center(child: Text('작은 화면')),
                ),
              ),
              child: const Text('작은 화면 열기'),
            ),
        ],
      ),
    );
  }
}
