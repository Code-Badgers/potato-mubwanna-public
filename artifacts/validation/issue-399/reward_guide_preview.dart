import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:potato_mubwanna/app/theme/app_theme.dart';
import 'package:potato_mubwanna/core/storage/token_storage.dart';
import 'package:potato_mubwanna/features/auth/application/auth_controller.dart';
import 'package:potato_mubwanna/features/auth/data/auth_repository.dart';
import 'package:potato_mubwanna/features/auth/data/kakao_login_service.dart';
import 'package:potato_mubwanna/features/coupon/application/coupon_controller.dart';
import 'package:potato_mubwanna/features/coupon/presentation/screen/coupon_screen.dart';
import 'package:potato_mubwanna/features/reward/application/reward_history_controller.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith((ref) => _PreviewAuthController()),
        couponListProvider.overrideWith((ref) async => const []),
        rewardHistoryProvider.overrideWith((ref) async => const []),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const CouponScreen(),
      ),
    ),
  );
}

class _PreviewAuthController extends AuthController {
  _PreviewAuthController()
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
