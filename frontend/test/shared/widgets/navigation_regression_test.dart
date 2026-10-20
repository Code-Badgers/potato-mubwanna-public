import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:potato_mubwanna/app/theme/app_colors.dart';
import 'package:potato_mubwanna/features/map/application/map_spot_controller.dart';
import 'package:potato_mubwanna/features/map/data/map_spot_repository.dart';
import 'package:potato_mubwanna/features/map/domain/favorite_spot.dart';
import 'package:potato_mubwanna/features/map/domain/favorite_spot_route.dart';
import 'package:potato_mubwanna/features/map/presentation/screen/map_screen.dart';
import 'package:potato_mubwanna/shared/widgets/navigation/main_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('selected footer follows pushed tab', (tester) async {
    await mount(tester);
    await tester.tap(find.text('스탬프'));
    await tester.pumpAndSettle();
    expect(find.text('STAMP PAGE'), findsOneWidget);
    expect(
        tester.widget<Text>(find.text('스탬프')).style!.color, AppColors.actionGreen);
  });

  testWidgets('map footer tap returns from a pushed stamp tab', (tester) async {
    await mount(tester);
    await tester.tap(find.text('스탬프'));
    await tester.pumpAndSettle();
    expect(find.text('STAMP PAGE'), findsOneWidget);
    await tester.tap(find.text('지도'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('map-discovery-home')), findsOneWidget);
  });

  testWidgets('full map back closes modal before the underlying full map',
      (tester) async {
    await mount(tester);
    await openFullMap(tester);
    final context = tester.element(find.byType(MapScreen));
    showModalBottomSheet<void>(
        context: context, builder: (_) => const Text('AUDIT MODAL'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('AUDIT MODAL'), findsNothing);
    expect(find.byKey(const ValueKey('map-discovery-home')), findsNothing);
  });

  testWidgets('back on another tab should not be swallowed by hidden full map',
      (tester) async {
    await mount(tester);
    await openFullMap(tester);
    await tester.tap(find.text('스탬프'));
    await tester.pumpAndSettle();
    expect(find.text('STAMP PAGE'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('STAMP PAGE'), findsNothing);
    expect(find.byKey(const ValueKey('map-discovery-home')), findsNothing);
  });
}

Future<void> openFullMap(WidgetTester tester) async {
  final button = find.byKey(const ValueKey('open-full-map-button'));
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('map-discovery-home')), findsNothing);
}

Future<void> mount(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(initialLocation: '/main/map', routes: [
    ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
              path: '/main/map',
              builder: (_, __) => MapScreen(
                    hasMapConfiguration: true,
                    mapViewBuilder: (_, __) => const SizedBox.expand(),
                  )),
          GoRoute(
              path: '/main/stamps',
              builder: (_, __) => const Center(child: Text('STAMP PAGE'))),
        ]),
  ]);
  addTearDown(router.dispose);
  await tester.pumpWidget(ProviderScope(overrides: [
    mapSpotsProvider.overrideWith((ref) async => []),
    favoriteSpotControllerProvider.overrideWith((ref) => FavoriteSpotController(
          AuditFavorites(),
          const LocalFavoriteSpotStorage(),
        )..state = const AsyncValue.data(<String>{})),
    favoriteSpotRouteProvider
        .overrideWith((ref) async => const FavoriteSpotRoute(
              routeName: 'audit',
              totalDistanceKm: 0,
              estimatedMinutes: 0,
              waypoints: [],
              polyline: [],
            )),
  ], child: MaterialApp.router(routerConfig: router)));
  await tester.pumpAndSettle();
}

class AuditFavorites extends MapSpotRepository {
  AuditFavorites() : super(dio: Dio());
  List<FavoriteSpot> items = [
    const FavoriteSpot(
        spotId: '1', name: 'A', category: 'A', latitude: 37, longitude: 128)
  ];
  @override
  Future<List<FavoriteSpot>> fetchFavoriteSpots() async => items;
}
