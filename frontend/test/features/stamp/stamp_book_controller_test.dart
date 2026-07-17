import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/core/storage/token_storage.dart';
import 'package:potato_mubwanna/features/auth/application/auth_controller.dart';
import 'package:potato_mubwanna/features/auth/data/auth_repository.dart';
import 'package:potato_mubwanna/features/auth/data/kakao_login_service.dart';
import 'package:potato_mubwanna/features/coupon/application/coupon_controller.dart';
import 'package:potato_mubwanna/features/stamp/application/stamp_book_controller.dart';
import 'package:potato_mubwanna/features/stamp/data/stamp_repository.dart';
import 'package:potato_mubwanna/features/stamp/domain/stamp_book.dart';

void main() {
  test('clears and refetches rallybook when the auth session changes',
      () async {
    final authController = AuthController(
      kakaoLoginService: const KakaoLoginService(),
      authRepository: _SessionAuthRepository(),
    );
    final repository = _QueuedStampRepository([
      _stampBook(1),
      _stampBook(2),
    ]);
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith((ref) => authController),
        stampRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(stampBookProvider, (_, __) {});
    addTearDown(subscription.close);

    expect(await container.read(stampBookProvider.future), isNull);
    expect(repository.fetchCount, 0);

    await authController.refreshSession();
    await container.pump();
    expect(
      (await container.read(stampBookProvider.future))?.progress.acquiredCount,
      1,
    );

    await authController.logout();
    await container.pump();
    expect(await container.read(stampBookProvider.future), isNull);

    await authController.refreshSession();
    await container.pump();
    expect(
      (await container.read(stampBookProvider.future))?.progress.acquiredCount,
      2,
    );
    expect(repository.fetchCount, 2);
  });

  test('reward claim refreshes the rallybook and coupon list after success',
      () async {
    var stampBookRefreshCount = 0;
    var couponListRefreshCount = 0;
    final repository = _ClaimStampRepository();
    final controller = StampRewardClaimController(
      repository,
      onStampBookRefresh: () => stampBookRefreshCount += 1,
      onCouponListRefresh: () => couponListRefreshCount += 1,
    );

    final result = await controller.claim(6);

    expect(repository.claimCount, 1);
    expect(repository.requestedTargetCount, 6);
    expect(result?.userCouponId, 21);
    expect(controller.state.valueOrNull?.couponName, '강원 감자 할인권');
    expect(stampBookRefreshCount, 1);
    expect(couponListRefreshCount, 1);
  });

  test('reward claim ignores a second request while the first is pending',
      () async {
    final completer = Completer<StampRewardClaimResult>();
    final repository = _ClaimStampRepository(completer: completer);
    final controller = StampRewardClaimController(
      repository,
      onStampBookRefresh: () {},
      onCouponListRefresh: () {},
    );

    final firstClaim = controller.claim(6);
    final secondClaim = controller.claim(6);

    expect(controller.state.isLoading, isTrue);
    expect(repository.claimCount, 1);
    expect(await secondClaim, isNull);

    completer.complete(_claimResult);
    expect(await firstClaim, same(_claimResult));
    expect(repository.claimCount, 1);
  });

  test('pending reward claim survives auto-dispose and refreshes both caches',
      () async {
    final completer = Completer<StampRewardClaimResult>();
    final repository = _ClaimStampRepository(completer: completer);
    var stampBookLoadCount = 0;
    var couponListLoadCount = 0;
    final container = ProviderContainer(
      overrides: [
        stampRepositoryProvider.overrideWithValue(repository),
        stampBookProvider.overrideWith((ref) async {
          stampBookLoadCount += 1;
          return null;
        }),
        couponListProvider.overrideWith((ref) async {
          couponListLoadCount += 1;
          return null;
        }),
      ],
    );
    addTearDown(container.dispose);
    final stampBookSubscription = container.listen(
      stampBookProvider,
      (_, __) {},
    );
    final couponListSubscription = container.listen(
      couponListProvider,
      (_, __) {},
    );
    addTearDown(stampBookSubscription.close);
    addTearDown(couponListSubscription.close);
    await container.read(stampBookProvider.future);
    await container.read(couponListProvider.future);

    final claimSubscription = container.listen(
      stampRewardClaimProvider,
      (_, __) {},
    );
    final claimFuture =
        container.read(stampRewardClaimProvider.notifier).claim(6);
    claimSubscription.close();
    await container.pump();

    completer.complete(_claimResult);

    expect(await claimFuture, same(_claimResult));
    await container.pump();
    await container.read(stampBookProvider.future);
    await container.read(couponListProvider.future);
    expect(stampBookLoadCount, 2);
    expect(couponListLoadCount, 2);
  });
}

StampBook _stampBook(int acquiredCount) => StampBook(
      progress: StampProgress(
        totalCount: 18,
        acquiredCount: acquiredCount,
        stamps: const [],
      ),
      nextReward: NextStampReward(
        acquiredCount: acquiredCount,
        nextTargetCount: 6,
        remainingCount: 6 - acquiredCount,
        completed: false,
        claimable: false,
        claimableTargetCount: null,
      ),
    );

class _QueuedStampRepository extends StampRepository {
  _QueuedStampRepository(this._books) : super(dio: Dio());

  final List<StampBook> _books;
  int fetchCount = 0;

  @override
  Future<StampBook> fetchStampBook() async {
    final book = _books[fetchCount];
    fetchCount++;
    return book;
  }
}

class _ClaimStampRepository extends StampRepository {
  _ClaimStampRepository({this.completer}) : super(dio: Dio());

  final Completer<StampRewardClaimResult>? completer;
  int claimCount = 0;
  int? requestedTargetCount;

  @override
  Future<StampRewardClaimResult> claimReward(
    StampRewardClaimRequest request,
  ) async {
    claimCount += 1;
    requestedTargetCount = request.targetCount;
    if (completer != null) {
      return completer!.future;
    }
    return _claimResult;
  }
}

final _claimResult = StampRewardClaimResult(
  targetCount: 6,
  rewardHistoryId: 10,
  userCouponId: 21,
  couponName: '강원 감자 할인권',
  expiresAt: DateTime.parse('2026-08-16T00:00:00Z'),
);

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
