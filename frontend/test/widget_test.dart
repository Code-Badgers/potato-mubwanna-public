import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potato_mubwanna/app/app.dart';
import 'package:potato_mubwanna/app/router/app_router.dart';
import 'package:potato_mubwanna/app/router/session_startup_route_gate.dart';
import 'package:potato_mubwanna/features/map/application/map_spot_controller.dart';
import 'package:potato_mubwanna/features/map/data/map_spot_repository.dart';
import 'package:potato_mubwanna/features/map/domain/favorite_spot_route.dart';
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

  testWidgets('system back closes the full map before the root fallback', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({
      'completedFeatureTourVersions': ['map-v9'],
    });
    sessionStartupRouteGate.completeSessionStartup(
      fallbackRoute: '/main/map',
      isAuthenticated: false,
    );
    appRouter.go('/main/map');
    addTearDown(() => appRouter.go('/startup'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapSpotsProvider.overrideWith((ref) async => const []),
          favoriteSpotControllerProvider.overrideWith(
            (ref) => FavoriteSpotController(
              MapSpotRepository(dio: Dio()),
              const LocalFavoriteSpotStorage(),
            )..state = const AsyncValue.data(<String>{}),
          ),
          favoriteSpotRouteProvider.overrideWith(
            (ref) async => const FavoriteSpotRoute(
              routeName: '나만의 감자 동선',
              totalDistanceKm: 0,
              estimatedMinutes: 0,
              waypoints: [],
              polyline: [],
            ),
          ),
        ],
        child: const PotatoMubwannaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('map-discovery-home')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('open-full-map-button')),
      -260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-full-map-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('map-discovery-home')), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('map-discovery-home')), findsOneWidget);
    expect(find.text('현재 첫 화면입니다.'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.byKey(const ValueKey('map-discovery-home')), findsOneWidget);
    expect(find.text('현재 첫 화면입니다.'), findsOneWidget);
  });
}
