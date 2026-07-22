import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/spot_detail_repository.dart';
import '../domain/spot_detail.dart';

final spotDetailRepositoryProvider = Provider<SpotDetailRepository>(
  (ref) => SpotDetailRepository(dio: ref.watch(dioClientProvider).dio),
);

final spotDetailProvider =
    FutureProvider.autoDispose.family<SpotDetail, String>(
  (ref, spotId) =>
      ref.watch(spotDetailRepositoryProvider).fetchSpotDetail(spotId),
);
