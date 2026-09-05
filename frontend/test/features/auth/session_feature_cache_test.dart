import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:potato_mubwanna/core/storage/token_storage.dart';
import 'package:potato_mubwanna/features/auth/application/auth_controller.dart';
import 'package:potato_mubwanna/features/auth/data/auth_repository.dart';
import 'package:potato_mubwanna/features/auth/data/kakao_login_service.dart';
import 'package:potato_mubwanna/features/map/application/map_spot_controller.dart';
import 'package:potato_mubwanna/features/map/data/map_spot_repository.dart';
import 'package:potato_mubwanna/features/map/domain/favorite_spot.dart';
import 'package:potato_mubwanna/features/map/domain/favorite_spot_route.dart';
import 'package:potato_mubwanna/features/mission/application/mission_controller.dart';
import 'package:potato_mubwanna/features/mission/data/mission_repository.dart';
import 'package:potato_mubwanna/features/mission/domain/mission_challenge.dart';
import 'package:potato_mubwanna/features/potato/application/potato_collection_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('favorites removed remotely should not reappear from local cache',
      () async {
    final repo = AuditFavorites();
    final controller =
        FavoriteSpotController(repo, const LocalFavoriteSpotStorage());
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.state.value, {'1'});
    repo.items = [];
    await controller.load();
    expect(controller.state.value, isEmpty);
  });

  test('mission cache must reload when account changes', () async {
    final auth = AuditAuth();
    final repo = AuditMissions();
    final container = ProviderContainer(overrides: [
      authControllerProvider.overrideWith((ref) => auth),
      missionRepositoryProvider.overrideWithValue(repo),
      missionStepActivitySyncProvider.overrideWith((ref) async => null),
    ]);
    addTearDown(container.dispose);
    final subscription = container.listen(missionsProvider, (_, __) {});
    addTearDown(subscription.close);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(missionsProvider).value!.single.title, 'Account A');
    auth.setStatus(const AuthState.idle());
    await Future<void>.delayed(Duration.zero);
    repo.account = 'Account B';
    auth.setStatus(const AuthState.authenticated());
    await Future<void>.delayed(Duration.zero);
    expect(container.read(missionsProvider).value!.single.title, 'Account B');
  });

  test(
      'guest favorites remain separate across A and B sessions and routes reload',
      () async {
    final auth = AuditAuth()..setStatus(const AuthState.idle());
    final repo = AuditFavorites();
    final container = ProviderContainer(overrides: [
      authControllerProvider.overrideWith((ref) => auth),
      mapSpotRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);
    final listener =
        container.listen(favoriteSpotControllerProvider, (_, __) {});
    addTearDown(listener.close);
    await Future<void>.delayed(Duration.zero);
    await container
        .read(favoriteSpotControllerProvider.notifier)
        .toggle('guest');
    expect(repo.readCount, 0);
    auth.setStatus(const AuthState.authenticated());
    await Future<void>.delayed(Duration.zero);
    expect(container.read(favoriteSpotControllerProvider).value, {'1'});
    expect((await container.read(favoriteSpotRouteProvider.future)).routeName,
        'Account A');
    auth.setStatus(const AuthState.idle());
    await Future<void>.delayed(Duration.zero);
    expect(container.read(favoriteSpotControllerProvider).value, {'guest'});
    expect((await container.read(favoriteSpotRouteProvider.future)).waypoints,
        isEmpty);
    repo.items = [];
    repo.account = 'Account B';
    auth.setStatus(const AuthState.authenticated());
    await Future<void>.delayed(Duration.zero);
    expect(container.read(favoriteSpotControllerProvider).value, isEmpty);
    expect((await container.read(favoriteSpotRouteProvider.future)).routeName,
        'Account B');
    expect(repo.readCount, 2);
  });

  test('ambiguous legacy favorites are not imported into guest storage',
      () async {
    SharedPreferences.setMockInitialValues({
      'favoriteSpotIds': ['another-account']
    });
    final guest = FavoriteSpotController(
        AuditFavorites(), const LocalFavoriteSpotStorage(),
        isAuthenticated: false);
    addTearDown(guest.dispose);
    await guest.load();
    expect(guest.state.value, isEmpty);
  });

  test('a disposed favorites load cannot publish a late account response',
      () async {
    final response = Completer<List<FavoriteSpot>>();
    final repo = AuditFavorites()..pending = response.future;
    final controller =
        FavoriteSpotController(repo, const LocalFavoriteSpotStorage());
    final loading = controller.load();
    controller.dispose();
    response.complete([]);
    await loading;
  });

  test('a disposed mission load cannot publish a late account response',
      () async {
    final response = Completer<List<MissionChallenge>>();
    final repo = AuditMissions()..pending = response.future;
    final controller = MissionController(repo);
    final loading = controller.load();
    await Future<void>.delayed(Duration.zero);
    controller.dispose();
    response.complete([]);
    await loading;
  });

  test('authenticated favorites do not silently save locally on 401', () async {
    final controller = FavoriteSpotController(
        AuditFavorites(), const LocalFavoriteSpotStorage());
    addTearDown(controller.dispose);
    await controller.load();
    await expectLater(
        controller.toggle('new'), throwsA(isA<FavoriteSpotToggleException>()));
    expect(controller.state.value, {'1'});
    expect(await const LocalFavoriteSpotStorage().readSpotIds(), isEmpty);
  });
}

class AuditFavorites extends MapSpotRepository {
  AuditFavorites() : super(dio: Dio());
  List<FavoriteSpot> items = [
    const FavoriteSpot(
        spotId: '1', name: 'A', category: 'A', latitude: 37, longitude: 128)
  ];
  String account = 'Account A';
  int readCount = 0;
  Future<List<FavoriteSpot>>? pending;
  @override
  Future<List<FavoriteSpot>> fetchFavoriteSpots() async {
    readCount++;
    return pending ?? Future.value(items);
  }

  @override
  Future<FavoriteSpotRoute> fetchFavoriteSpotRoute() async => FavoriteSpotRoute(
        routeName: account,
        totalDistanceKm: 0,
        estimatedMinutes: 0,
        waypoints: [],
        polyline: [],
      );
  @override
  Future<FavoriteSpotToggleResult> addFavoriteSpot(String id) async {
    final options = RequestOptions(path: '/me/favorite-spots/$id');
    throw DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 401));
  }
}

class AuditAuth extends AuthController {
  AuditAuth()
      : super(
            kakaoLoginService: const KakaoLoginService(),
            authRepository: AuthRepository(
              dio: Dio(),
              tokenStorage: const TokenStorage(FlutterSecureStorage()),
            )) {
    state = const AuthState.authenticated();
  }
  void setStatus(AuthState value) {
    state = value;
  }
}

class AuditMissions extends MissionRepository {
  AuditMissions() : super(dio: Dio());
  String account = 'Account A';
  Future<List<MissionChallenge>>? pending;
  @override
  Future<List<MissionChallenge>> fetchMissions() async =>
      pending ??
      Future.value([
        MissionChallenge.fromJson({
          'id': 1,
          'title': account,
          'type': 'VISIT',
          'status': 'READY',
        })
      ]);
}
