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
