import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/potato_repository.dart';
import '../domain/potato_collection.dart';
import '../domain/step_count_reader.dart';

final potatoRepositoryProvider = Provider<PotatoRepository>(
  (ref) => PotatoRepository(dio: ref.watch(dioClientProvider).dio),
);

final stepCountReaderProvider = Provider<StepCountReader>(
  (ref) => createStepCountReader(),
);

final potatoCollectionProvider =
    FutureProvider.autoDispose<PotatoCollection?>((ref) async {
  final authStatus = ref.watch(
    authControllerProvider.select((state) => state.status),
  );
  if (authStatus != AuthStatus.authenticated) {
    return null;
  }

  return ref.watch(potatoRepositoryProvider).fetchMyPotatoes();
});

final potatoGrowthSummaryProvider =
    FutureProvider.autoDispose<PotatoGrowthSummary?>((ref) async {
  final authStatus = ref.watch(
    authControllerProvider.select((state) => state.status),
  );
  if (authStatus != AuthStatus.authenticated) {
    return null;
  }

  final summary =
      await ref.watch(potatoRepositoryProvider).fetchGrowthSummary();
  final todaySteps = await ref.watch(stepCountReaderProvider).readTodaySteps();

  if (todaySteps == null) {
    return summary;
  }

  return summary.copyWith(todaySteps: todaySteps);
});
