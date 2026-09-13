import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/application/auth_controller.dart';
import '../data/map_spot_repository.dart';
import '../domain/favorite_spot_route.dart';
import '../domain/map_spot.dart';
import '../domain/spot_detail.dart';
import '../domain/spot_recommendation.dart';
import '../domain/travel_course_route_estimate.dart';

final mapSpotRepositoryProvider = Provider<MapSpotRepository>(
  (ref) => MapSpotRepository(dio: ref.watch(dioClientProvider).dio),
);

final mapSpotsProvider = FutureProvider<List<MapSpot>>(
  (ref) => ref.watch(mapSpotRepositoryProvider).fetchSpots(),
);

final spotRecommendationsProvider =
    FutureProvider.autoDispose.family<List<SpotRecommendation>, String>(
  (ref, spotId) =>
      ref.watch(mapSpotRepositoryProvider).fetchSpotRecommendations(spotId),
);

final spotDetailProvider =
    FutureProvider.autoDispose.family<SpotDetail, String>(
  (ref, spotId) => ref.watch(mapSpotRepositoryProvider).fetchSpotDetail(spotId),
);

final travelCourseRouteEstimateProvider = FutureProvider.autoDispose.family<
    TravelCourseRouteEstimate, TravelCourseRouteKey>(
  (ref, route) => ref
      .watch(mapSpotRepositoryProvider)
      .fetchTravelCourseRouteEstimate(route.spotIds),
);

final favoriteSpotRouteProvider = FutureProvider<FavoriteSpotRoute>(
  (ref) {
    final status =
        ref.watch(authControllerProvider.select((state) => state.status));
    if (status != AuthStatus.authenticated) {
      return const FavoriteSpotRoute(
        routeName: '나만의 감자 동선',
        totalDistanceKm: 0,
        estimatedMinutes: 0,
        waypoints: [],
        polyline: [],
      );
    }
    return ref.watch(mapSpotRepositoryProvider).fetchFavoriteSpotRoute();
  },
);

final favoriteSpotControllerProvider =
    StateNotifierProvider<FavoriteSpotController, AsyncValue<Set<String>>>(
  (ref) => FavoriteSpotController(
    ref.watch(mapSpotRepositoryProvider),
    const LocalFavoriteSpotStorage(),
    isAuthenticated:
        ref.watch(authControllerProvider.select((state) => state.status)) ==
            AuthStatus.authenticated,
  )..load(),
);

class FavoriteSpotController extends StateNotifier<AsyncValue<Set<String>>> {
  FavoriteSpotController(this._repository, this._localStorage,
      {bool isAuthenticated = true})
      : _isAuthenticated = isAuthenticated,
        super(const AsyncValue.loading());

  final MapSpotRepository _repository;
  final LocalFavoriteSpotStorage _localStorage;
  final bool _isAuthenticated;
  int _loadGeneration = 0;

  Future<void> load() async {
    final generation = ++_loadGeneration;
    state = const AsyncValue.loading();
    try {
      // 로그인 찜은 서버가 기준이다. 기기 공통 캐시를 합치면 원격 삭제와 계정 분리가 깨진다.
      final spotIds = _isAuthenticated
          ? (await _repository.fetchFavoriteSpots())
              .map((spot) => spot.spotId)
              .toSet()
          : await _localStorage.readSpotIds();
      if (mounted && generation == _loadGeneration) {
        state = AsyncValue.data(spotIds);
      }
    } catch (error, stackTrace) {
      if (mounted && generation == _loadGeneration) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  Future<void> toggle(String spotId) async {
    ++_loadGeneration;
    final previous = state.valueOrNull ?? <String>{};
    final shouldAdd = !previous.contains(spotId);
    final next = {...previous};
    if (shouldAdd) {
      next.add(spotId);
    } else {
      next.remove(spotId);
    }
    state = AsyncValue.data(next);
    try {
      if (!_isAuthenticated) {
        await _localStorage.saveSpotIds(next);
      } else if (shouldAdd) {
        await _repository.addFavoriteSpot(spotId);
      } else {
        await _repository.removeFavoriteSpot(spotId);
      }
    } catch (error, stackTrace) {
      if (!mounted) return;
      state = AsyncValue.data(previous);
      Error.throwWithStackTrace(
        FavoriteSpotToggleException.from(error),
        stackTrace,
      );
    }
  }

  Future<void> reorder(List<String> spotIds) async {
    try {
      if (_isAuthenticated) {
        await _repository.updateFavoriteSpotOrder(spotIds);
      } else {
        await _localStorage.saveSpotOrder(spotIds);
      }
    } catch (error, stackTrace) {
      if (!mounted) return;
      Error.throwWithStackTrace(
        FavoriteSpotToggleException.from(error),
        stackTrace,
      );
    }
  }
}

class LocalFavoriteSpotStorage {
  const LocalFavoriteSpotStorage();

  // 기존 키는 여러 계정의 데이터가 섞여 있을 수 있으므로 자동으로 가져오지 않는다.
  static const _key = 'guestFavoriteSpotIdsV2';
  static const _orderKey = 'guestFavoriteSpotOrderV2';

  Future<Set<String>> readSpotIds() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(_key)?.toSet() ?? <String>{};
  }

  Future<void> saveSpotIds(Set<String> spotIds) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_key, spotIds.toList()..sort());
  }

  Future<void> saveSpotOrder(List<String> spotIds) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_orderKey, spotIds);
  }
}

class FavoriteSpotToggleException implements Exception {
  const FavoriteSpotToggleException(this.message);

  factory FavoriteSpotToggleException.from(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        return const FavoriteSpotToggleException('로그인 후 내 동선을 저장할 수 있습니다.');
      }
      if (statusCode == 404) {
        return const FavoriteSpotToggleException('선택한 감자 스팟을 찾을 수 없습니다.');
      }
    }
    return const FavoriteSpotToggleException(
        '내 동선을 저장하지 못했습니다. 잠시 후 다시 시도해주세요.');
  }

  final String message;

  @override
  String toString() => message;
}
