import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/application/auth_controller.dart';
import '../data/map_spot_repository.dart';
import '../domain/favorite_spot_route.dart';
import '../domain/map_spot.dart';
import '../domain/spot_recommendation.dart';

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

final favoriteSpotRouteProvider = FutureProvider<FavoriteSpotRoute>(
  (ref) => ref.watch(mapSpotRepositoryProvider).fetchFavoriteSpotRoute(),
);

final favoriteSpotControllerProvider =
    StateNotifierProvider<FavoriteSpotController, AsyncValue<Set<String>>>(
  (ref) => FavoriteSpotController(
    ref.watch(mapSpotRepositoryProvider),
    const LocalFavoriteSpotStorage(),
  )..load(),
);

class FavoriteSpotController extends StateNotifier<AsyncValue<Set<String>>> {
  FavoriteSpotController(this._repository, this._localStorage)
      : super(const AsyncValue.loading());

  final MapSpotRepository _repository;
  final LocalFavoriteSpotStorage _localStorage;

  Future<void> load() async {
    state = const AsyncValue.loading();
    final localSpotIds = await _localStorage.readSpotIds();
    state = AsyncValue.data(localSpotIds);

    try {
      final favoriteSpots = await _repository.fetchFavoriteSpots();
      final remoteSpotIds = favoriteSpots.map((spot) => spot.spotId).toSet();
      final mergedSpotIds = {...localSpotIds, ...remoteSpotIds};
      await _localStorage.saveSpotIds(mergedSpotIds);
      state = AsyncValue.data(mergedSpotIds);
    } catch (_) {
      state = AsyncValue.data(localSpotIds);
    }
  }

  Future<void> toggle(String spotId) async {
    final previous = state.valueOrNull ?? <String>{};
    final shouldAdd = !previous.contains(spotId);
    final next = {...previous};
    if (shouldAdd) {
      next.add(spotId);
    } else {
      next.remove(spotId);
    }
    state = AsyncValue.data(next);
    await _localStorage.saveSpotIds(next);

    try {
      if (shouldAdd) {
        await _repository.addFavoriteSpot(spotId);
      } else {
        await _repository.removeFavoriteSpot(spotId);
      }
    } catch (error, stackTrace) {
      if (_isAuthenticationError(error)) {
        return;
      }
      state = AsyncValue.data(previous);
      await _localStorage.saveSpotIds(previous);
      Error.throwWithStackTrace(
        FavoriteSpotToggleException.from(error),
        stackTrace,
      );
    }
  }

  bool _isAuthenticationError(Object error) {
    return error is DioException &&
        (error.response?.statusCode == 401 ||
            error.response?.statusCode == 403);
  }
}

class LocalFavoriteSpotStorage {
  const LocalFavoriteSpotStorage();

  static const _key = 'favoriteSpotIds';

  Future<Set<String>> readSpotIds() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(_key)?.toSet() ?? <String>{};
  }

  Future<void> saveSpotIds(Set<String> spotIds) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_key, spotIds.toList()..sort());
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
