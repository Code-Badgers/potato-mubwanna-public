import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/core/storage/token_storage.dart';
import 'package:potato_mubwanna/features/auth/application/auth_controller.dart';
import 'package:potato_mubwanna/features/auth/data/auth_repository.dart';
import 'package:potato_mubwanna/features/auth/data/kakao_login_service.dart';
import 'package:potato_mubwanna/features/reward/application/reward_history_controller.dart';
import 'package:potato_mubwanna/features/reward/data/reward_history_repository.dart';
import 'package:potato_mubwanna/features/reward/domain/reward_history.dart';

void main() {
  test('clears and refetches reward history when auth session changes',
      () async {
    final authController = AuthController(
      kakaoLoginService: const KakaoLoginService(),
      authRepository: _SessionAuthRepository(),
    );
    final repository = _QueuedRewardHistoryRepository([
      [_reward(1)],
      [_reward(2)],
    ]);
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith((ref) => authController),
        rewardHistoryRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(rewardHistoryProvider, (_, __) {});
    addTearDown(subscription.close);

    expect(await container.read(rewardHistoryProvider.future), isNull);
    expect(repository.fetchCount, 0);

    await authController.refreshSession();
    await container.pump();
    expect(
      (await container.read(rewardHistoryProvider.future))
          ?.first
          .rewardHistoryId,
      1,
    );

    await authController.logout();
    await container.pump();
    expect(await container.read(rewardHistoryProvider.future), isNull);

    await authController.refreshSession();
    await container.pump();
    expect(
      (await container.read(rewardHistoryProvider.future))
          ?.first
          .rewardHistoryId,
      2,
    );
    expect(repository.fetchCount, 2);
  });
}

RewardHistory _reward(int id) => RewardHistory(
      rewardHistoryId: id,
      rewardType: RewardType.coupon,
      rewardName: '보상 $id',
      sourceType: RewardSourceType.stamp,
      sourceId: 6,
      createdAt: DateTime.parse('2026-07-17T09:00:00Z'),
    );

class _QueuedRewardHistoryRepository extends RewardHistoryRepository {
  _QueuedRewardHistoryRepository(this._rewards) : super(dio: Dio());

  final List<List<RewardHistory>> _rewards;
  int fetchCount = 0;

  @override
  Future<List<RewardHistory>> fetchRewardHistory() async {
    final result = _rewards[fetchCount];
    fetchCount++;
    return result;
  }
}

class _SessionAuthRepository extends AuthRepository {
  _SessionAuthRepository()
      : super(
          dio: Dio(),
          tokenStorage: const TokenStorage(FlutterSecureStorage()),
        );

  @override
  Future<void> refreshSession() async {}

  @override
  Future<void> logout() async {}
}
