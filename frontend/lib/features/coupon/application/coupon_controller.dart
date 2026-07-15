import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/coupon_repository.dart';
import '../domain/coupon.dart';

final couponRepositoryProvider = Provider<CouponRepository>(
  (ref) => CouponRepository(dio: ref.watch(dioClientProvider).dio),
);

final couponListProvider = FutureProvider.autoDispose<List<CouponSummary>?>((
  ref,
) async {
  final authStatus = ref.watch(
    authControllerProvider.select((state) => state.status),
  );
  if (authStatus != AuthStatus.authenticated) {
    return null;
  }
  return ref.watch(couponRepositoryProvider).fetchCoupons();
});

final couponDetailProvider =
    FutureProvider.autoDispose.family<CouponDetail, int>(
  (ref, userCouponId) =>
      ref.watch(couponRepositoryProvider).fetchCoupon(userCouponId),
);
