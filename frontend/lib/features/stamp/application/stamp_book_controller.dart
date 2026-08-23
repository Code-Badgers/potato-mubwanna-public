import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../coupon/application/coupon_controller.dart';
import '../../reward/application/reward_history_controller.dart';
import '../data/stamp_repository.dart';
import '../domain/stamp_book.dart';

final stampRepositoryProvider = Provider<StampRepository>(
  (ref) => StampRepository(dio: ref.watch(dioClientProvider).dio),
);

const _stampScreenCacheDuration = Duration(minutes: 5);

void _keepStampScreenDataAlive(Ref<Object?> ref) {
  final link = ref.keepAlive();
  final timer = Timer(_stampScreenCacheDuration, link.close);
  ref.onDispose(timer.cancel);
}

final stampBookProvider = FutureProvider.autoDispose<StampBook?>((ref) async {
  final authStatus = ref.watch(
    authControllerProvider.select((state) => state.status),
  );
  if (authStatus != AuthStatus.authenticated) {
    return const StampBook(
      progress: StampProgress(
        totalCount: 29,
        acquiredCount: 0,
        stamps: [],
      ),
      nextReward: NextStampReward(
        acquiredCount: 0,
        nextTargetCount: null,
        remainingCount: 29,
        completed: false,
        claimable: false,
        claimableTargetCount: null,
      ),
    );
  }

  final stampBook = await ref.watch(stampRepositoryProvider).fetchStampBook();
  _keepStampScreenDataAlive(ref);
  return stampBook;
});

final stampNextTargetsProvider =
    FutureProvider.autoDispose<List<StampNextTarget>?>((ref) async {
  final authStatus = ref.watch(
    authControllerProvider.select((state) => state.status),
  );
  if (authStatus != AuthStatus.authenticated) {
    return null;
  }

  return ref.watch(stampRepositoryProvider).fetchNextTargets();
});

final stampRallybookSpotsProvider =
    FutureProvider.autoDispose<List<RallybookSpot>?>((ref) async {
  final authStatus = ref.watch(
    authControllerProvider.select((state) => state.status),
  );
  if (authStatus != AuthStatus.authenticated) {
    return const <RallybookSpot>[];
  }

  final spots = await ref.watch(stampRepositoryProvider).fetchRallybookSpots();
  _keepStampScreenDataAlive(ref);
  return spots;
});

final stampRewardClaimProvider = StateNotifierProvider.autoDispose<
    StampRewardClaimController, AsyncValue<StampRewardClaimResult?>>(
  (ref) => StampRewardClaimController(
    ref.watch(stampRepositoryProvider),
    onStampBookRefresh: () => ref.invalidate(stampBookProvider),
    onCouponListRefresh: () => ref.invalidate(couponListProvider),
    onRewardHistoryRefresh: () => ref.invalidate(rewardHistoryProvider),
    acquireKeepAlive: ref.keepAlive,
  ),
);

class StampRewardClaimController
    extends StateNotifier<AsyncValue<StampRewardClaimResult?>> {
  StampRewardClaimController(
    this._repository, {
    required void Function() onStampBookRefresh,
    required void Function() onCouponListRefresh,
    required void Function() onRewardHistoryRefresh,
    KeepAliveLink Function()? acquireKeepAlive,
  })  : _onStampBookRefresh = onStampBookRefresh,
        _onCouponListRefresh = onCouponListRefresh,
        _onRewardHistoryRefresh = onRewardHistoryRefresh,
        _acquireKeepAlive = acquireKeepAlive,
        super(const AsyncValue.data(null));

  final StampRepository _repository;
  final void Function() _onStampBookRefresh;
  final void Function() _onCouponListRefresh;
  final void Function() _onRewardHistoryRefresh;
  final KeepAliveLink Function()? _acquireKeepAlive;

  Future<StampRewardClaimResult?> claim(int targetCount) async {
    // UI 재빌드 전의 연속 입력도 서버로 중복 전달되지 않게 컨트롤러에서 한 번 더 막는다.
    if (state.isLoading) {
      return null;
    }

    // 화면 이탈 뒤 응답이 도착해도 상태 갱신과 세 캐시 무효화를 끝낼 때까지 유지한다.
    final keepAliveLink = _acquireKeepAlive?.call();
    try {
      state = const AsyncValue.loading();
      final result = await _repository.claimReward(
        StampRewardClaimRequest(targetCount: targetCount),
      );
      state = AsyncValue.data(result);
      _onStampBookRefresh();
      _onCouponListRefresh();
      _onRewardHistoryRefresh();
      return result;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    } finally {
      keepAliveLink?.close();
    }
  }
}
