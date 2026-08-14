import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../legal/data/legal_consent_store.dart';
import '../data/legal_consent_step_count_reader.dart';
import '../data/pending_potato_growth_store.dart';
import '../data/potato_repository.dart';
import '../domain/potato_collection.dart';
import '../domain/step_count_reader.dart';

final potatoRepositoryProvider = Provider<PotatoRepository>(
  (ref) => PotatoRepository(dio: ref.watch(dioClientProvider).dio),
);

final stepCountReaderProvider = Provider<StepCountReader>(
  (ref) => LegalConsentStepCountReader(
    delegate: createStepCountReader(),
    consentStore: ref.watch(legalConsentStoreProvider),
  ),
);

final pendingPotatoGrowthStoreProvider = Provider<PendingPotatoGrowthStore>(
  (ref) => const SharedPreferencesPendingPotatoGrowthStore(),
);

final potatoActivitySyncProvider =
    FutureProvider.autoDispose<PotatoGrowthResult?>((ref) async {
  final authStatus = ref.watch(
    authControllerProvider.select((state) => state.status),
  );
  if (authStatus != AuthStatus.authenticated) {
    return null;
  }

  final pendingGrowthStore = ref.watch(pendingPotatoGrowthStoreProvider);
  PotatoGrowthResult? pendingGrowthResult;
  try {
    pendingGrowthResult = await pendingGrowthStore.take();
  } catch (_) {
    // 저장소 오류가 포그라운드 건강 데이터 동기화를 막지 않게 한다.
  }

  final snapshot = await ref.watch(stepCountReaderProvider).readTodaySteps();
  if (snapshot == null) {
    return pendingGrowthResult;
  }

  try {
    final currentGrowthResult =
        await ref.watch(potatoRepositoryProvider).syncDailyActivity(snapshot);
    if (pendingGrowthResult != null && currentGrowthResult?.leveledUp == true) {
      try {
        await pendingGrowthStore.save(currentGrowthResult!);
      } catch (_) {
        // 현재 결과 저장 실패 시 먼저 발생한 성장 안내를 우선 전달한다.
      }
    }
    return pendingGrowthResult ?? currentGrowthResult;
  } catch (_) {
    // 동기화 실패가 도감 진입 자체를 막으면 안 되므로 서버의 마지막 상태를 계속 사용한다.
    return pendingGrowthResult;
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
