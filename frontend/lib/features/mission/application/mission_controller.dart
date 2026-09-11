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
  (ref) {
    final authStatus =
        ref.watch(authControllerProvider.select((state) => state.status));
    final controller = MissionController(
      ref.watch(missionRepositoryProvider),
      isAuthenticated: authStatus == AuthStatus.authenticated,
      onCouponReward: () => ref.invalidate(couponListProvider),
      beforeLoad: () async {
        try {
          ref.invalidate(missionStepActivitySyncProvider);
          await ref.read(missionStepActivitySyncProvider.future);
        } catch (_) {
          // 걸음 동기화 실패가 걸음 외 미션 목록 진입을 막지 않게 한다.
        }
      },
    );
    return controller..load();
  },
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
    bool isAuthenticated = true,
  })  : _onCouponReward = onCouponReward,
        _beforeLoad = beforeLoad,
        _isAuthenticated = isAuthenticated,
        super(const AsyncValue.loading());

  final MissionRepository _repository;
  final void Function()? _onCouponReward;
  final Future<void> Function()? _beforeLoad;
  final bool _isAuthenticated;
  int _loadGeneration = 0;

  Future<void> load() async {
    if (!_isAuthenticated) {
      state = const AsyncValue.data([]);
      return;
    }
    final generation = ++_loadGeneration;
    state = const AsyncValue.loading();
    try {
      await _beforeLoad?.call();
      if (!mounted || generation != _loadGeneration) return;
      final missions = await _repository.fetchMissions();
      if (mounted && generation == _loadGeneration) {
        state = AsyncValue.data(missions);
      }
    } catch (error, stackTrace) {
      if (mounted && generation == _loadGeneration) {
        state = AsyncValue.error(error, stackTrace);
      }
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
      completedAt: result.completedAt,
    );
    // 로그아웃 후 도착한 응답은 폐기된 세션의 상태/보상 캐시를 변경하지 않는다.
    if (!mounted) return completedMission;
    ++_loadGeneration;
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
