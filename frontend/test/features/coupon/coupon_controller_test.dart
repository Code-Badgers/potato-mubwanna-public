import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/core/storage/token_storage.dart';
import 'package:potato_mubwanna/features/auth/application/auth_controller.dart';
import 'package:potato_mubwanna/features/auth/data/auth_repository.dart';
import 'package:potato_mubwanna/features/auth/data/kakao_login_service.dart';
import 'package:potato_mubwanna/features/coupon/application/coupon_controller.dart';
import 'package:potato_mubwanna/features/coupon/data/coupon_repository.dart';
import 'package:potato_mubwanna/features/coupon/domain/coupon.dart';

void main() {
  test('clears and refetches coupons when auth session changes', () async {
    final authController = AuthController(
      kakaoLoginService: const KakaoLoginService(),
      authRepository: _SessionAuthRepository(),
    );
    final repository = _QueuedCouponRepository([
      [_coupon(1)],
      [_coupon(2)],
    ]);
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith((ref) => authController),
        couponRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(couponListProvider, (_, __) {});
    addTearDown(subscription.close);

    expect(await container.read(couponListProvider.future), isNull);
    expect(repository.fetchCount, 0);

    await authController.refreshSession();
    await container.pump();
    expect(
      (await container.read(couponListProvider.future))?.first.userCouponId,
      1,
    );

    await authController.logout();
    await container.pump();
    expect(await container.read(couponListProvider.future), isNull);

    await authController.refreshSession();
    await container.pump();
    expect(
      (await container.read(couponListProvider.future))?.first.userCouponId,
      2,
    );
    expect(repository.fetchCount, 2);
  });
}

CouponSummary _coupon(int id) => CouponSummary(
      userCouponId: id,
      name: '쿠폰 $id',
      description: '설명',
      benefitAmount: 5000,
      status: CouponStatus.available,
      expiresAt: DateTime.parse('2026-12-31T23:59:59Z'),
    );

class _QueuedCouponRepository extends CouponRepository {
  _QueuedCouponRepository(this._coupons) : super(dio: Dio());

  final List<List<CouponSummary>> _coupons;
  int fetchCount = 0;

  @override
  Future<List<CouponSummary>> fetchCoupons() async {
    final result = _coupons[fetchCount];
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
