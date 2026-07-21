import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:potato_mubwanna/core/storage/token_storage.dart';
import 'package:potato_mubwanna/features/auth/application/auth_controller.dart';
import 'package:potato_mubwanna/features/auth/data/auth_repository.dart';
import 'package:potato_mubwanna/features/auth/data/kakao_login_service.dart';
import 'package:potato_mubwanna/features/coupon/application/coupon_controller.dart';
import 'package:potato_mubwanna/features/coupon/domain/coupon.dart';
import 'package:potato_mubwanna/features/coupon/presentation/screen/coupon_screen.dart';
import 'package:potato_mubwanna/features/reward/application/reward_history_controller.dart';
import 'package:potato_mubwanna/features/reward/domain/reward_history.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          (ref) => _AuthenticatedAuthController(),
        ),
        couponListProvider.overrideWith((ref) async => _coupons),
        rewardHistoryProvider.overrideWith((ref) async => _rewardHistory),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: CouponScreen(),
      ),
    ),
  );
}

final _coupons = [
  CouponSummary(
    userCouponId: 1,
    name: '감자빵 1개 교환권',
    description: '제휴 매장에서 사용할 수 있습니다.',
    benefitAmount: 5000,
    status: CouponStatus.available,
    expiresAt: DateTime.parse('2026-12-31T23:59:59Z'),
  ),
];

final _rewardHistory = [
  RewardHistory(
    rewardHistoryId: 2,
    rewardType: RewardType.coupon,
    rewardName: '강원 감자 제휴점 할인권',
    sourceType: RewardSourceType.stamp,
    sourceId: 6,
    createdAt: DateTime.parse('2026-07-17T09:30:00Z'),
  ),
  RewardHistory(
    rewardHistoryId: 1,
    rewardType: RewardType.potato,
    rewardName: '수미감자 씨앗',
    sourceType: RewardSourceType.mission,
    sourceId: 1001,
    createdAt: DateTime.parse('2026-07-11T09:00:00Z'),
  ),
];

class _AuthenticatedAuthController extends AuthController {
  _AuthenticatedAuthController()
    : super(
        kakaoLoginService: const KakaoLoginService(),
        authRepository: _PreviewAuthRepository(),
      ) {
    state = const AuthState.authenticated();
  }
}

class _PreviewAuthRepository extends AuthRepository {
  _PreviewAuthRepository()
    : super(
        dio: Dio(),
        tokenStorage: const TokenStorage(FlutterSecureStorage()),
      );
}
