import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/map_spot_repository.dart';
import '../domain/map_spot.dart';

final mapSpotRepositoryProvider = Provider<MapSpotRepository>(
  (ref) => MapSpotRepository(dio: ref.watch(dioClientProvider).dio),
);

final mapSpotsProvider = FutureProvider<List<MapSpot>>(
  (ref) => ref.watch(mapSpotRepositoryProvider).fetchSpots(),
);

final favoriteSpotControllerProvider =
    StateNotifierProvider<FavoriteSpotController, AsyncValue<Set<String>>>(
  (ref) => FavoriteSpotController(ref.watch(mapSpotRepositoryProvider))..load(),
);

class FavoriteSpotController extends StateNotifier<AsyncValue<Set<String>>> {
  FavoriteSpotController(this._repository) : super(const AsyncValue.loading());

  final MapSpotRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final favoriteSpots = await _repository.fetchFavoriteSpots();
      return favoriteSpots.map((spot) => spot.spotId).toSet();
    });
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

    try {
      if (shouldAdd) {
        await _repository.addFavoriteSpot(spotId);
      } else {
        await _repository.removeFavoriteSpot(spotId);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.data(previous);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}
