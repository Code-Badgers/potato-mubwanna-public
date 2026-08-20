import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/location_service.dart';
import '../../auth/application/auth_controller.dart';
import '../../coupon/application/coupon_controller.dart';
import '../../legal/data/legal_consent_store.dart';
import '../../potato/application/potato_collection_controller.dart';
import '../data/mission_native_input_service.dart';
import '../data/mission_repository.dart';
import '../data/mission_upload_repository.dart';
import '../domain/mission_challenge.dart';

final missionRepositoryProvider = Provider<MissionRepository>(
  (ref) => MissionRepository(dio: ref.watch(dioClientProvider).dio),
);

final missionNativeInputServiceProvider = Provider<MissionNativeInputService>(
  (ref) => MissionNativeInputService(),
);

final missionUploadRepositoryProvider = Provider<MissionUploadRepository>(
  (ref) => MissionUploadRepository(dio: ref.watch(dioClientProvider).dio),
);

final missionLocationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(
    hasPersonalLocationConsent:
        ref.watch(legalConsentStoreProvider).hasAcceptedPersonalLocation,
  ),
);

final missionsProvider = StateNotifierProvider<MissionController,
    AsyncValue<List<MissionChallenge>>>(
  (ref) => MissionController(
    ref.watch(missionRepositoryProvider),
    onCouponReward: () => ref.invalidate(couponListProvider),
    beforeLoad: () async {
      try {
        ref.invalidate(missionStepActivitySyncProvider);
        await ref.read(missionStepActivitySyncProvider.future);
      } catch (_) {
        // 걸음 동기화 실패가 걸음 외 미션 목록 진입을 막지 않게 한다.
      }
    },
  )..load(),
);

final missionByIdProvider = Provider.family<MissionChallenge?, String>(
  (ref, missionId) {
    final missions = ref.watch(missionsProvider).valueOrNull ?? const [];
    for (final mission in missions) {
      if (mission.id == missionId) {
        return mission;
      }
    }
    return null;
  },
);

class MissionController
    extends StateNotifier<AsyncValue<List<MissionChallenge>>> {
  MissionController(
    this._repository, {
    void Function()? onCouponReward,
    Future<void> Function()? beforeLoad,
  })  : _onCouponReward = onCouponReward,
        _beforeLoad = beforeLoad,
        super(const AsyncValue.loading());

  final MissionRepository _repository;
  final void Function()? _onCouponReward;
  final Future<void> Function()? _beforeLoad;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      await _beforeLoad?.call();
      state = AsyncValue.data(await _repository.fetchMissions());
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<MissionChallenge> complete(
    String missionId,
    MissionVerificationPayload payload,
  ) async {
    final missions = state.valueOrNull ?? const <MissionChallenge>[];
    final mission = missions.firstWhere((mission) => mission.id == missionId);
    final result = await _repository.verifyMission(missionId, payload);
    final completedMission = mission.copyWith(
      status: MissionStatus.completed,
      progress: mission.target,
    );
    state = AsyncValue.data([
      for (final item in missions)
        if (item.id == missionId) completedMission else item,
    ]);
    if (result.rewardType == MissionRewardType.coupon) {
      _onCouponReward?.call();
    }
    return completedMission;
  }
}
