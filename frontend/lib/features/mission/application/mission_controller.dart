import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../coupon/application/coupon_controller.dart';
import '../data/mission_repository.dart';
import '../domain/mission_challenge.dart';

final missionRepositoryProvider = Provider<MissionRepository>(
  (ref) => MissionRepository(dio: ref.watch(dioClientProvider).dio),
);

final missionsProvider = StateNotifierProvider<MissionController,
    AsyncValue<List<MissionChallenge>>>(
  (ref) => MissionController(
    ref.watch(missionRepositoryProvider),
    onCouponReward: () => ref.invalidate(couponListProvider),
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
  })  : _onCouponReward = onCouponReward,
        super(const AsyncValue.loading());

  final MissionRepository _repository;
  final void Function()? _onCouponReward;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
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
