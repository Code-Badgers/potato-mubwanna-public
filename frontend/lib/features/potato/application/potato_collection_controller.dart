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

final potatoActivitySyncProvider =
    FutureProvider.autoDispose<void>((ref) async {
  final authStatus = ref.watch(
    authControllerProvider.select((state) => state.status),
  );
  if (authStatus != AuthStatus.authenticated) {
    return;
  }

  final snapshot = await ref.watch(stepCountReaderProvider).readTodaySteps();
  if (snapshot == null) {
    return;
  }

  try {
    await ref.watch(potatoRepositoryProvider).syncDailyActivity(snapshot);
  } catch (_) {
    // 동기화 실패가 도감 진입 자체를 막으면 안 되므로 서버의 마지막 상태를 계속 사용한다.
  }
});

final potatoCollectionProvider =
    FutureProvider.autoDispose<PotatoCollection?>((ref) async {
  final authStatus = ref.watch(
    authControllerProvider.select((state) => state.status),
  );
  if (authStatus != AuthStatus.authenticated) {
    return null;
  }

  await ref.watch(potatoActivitySyncProvider.future);
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

  await ref.watch(potatoActivitySyncProvider.future);
  return ref.watch(potatoRepositoryProvider).fetchGrowthSummary();
});
