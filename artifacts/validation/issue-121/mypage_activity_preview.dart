import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:potato_mubwanna/core/storage/token_storage.dart';
import 'package:potato_mubwanna/features/auth/application/auth_controller.dart';
import 'package:potato_mubwanna/features/auth/data/auth_repository.dart';
import 'package:potato_mubwanna/features/auth/data/kakao_login_service.dart';
import 'package:potato_mubwanna/features/mypage/application/user_activity_summary_controller.dart';
import 'package:potato_mubwanna/features/mypage/application/user_profile_controller.dart';
import 'package:potato_mubwanna/features/mypage/domain/user_activity_summary.dart';
import 'package:potato_mubwanna/features/mypage/domain/user_profile.dart';
import 'package:potato_mubwanna/features/mypage/presentation/screen/my_page_screen.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          (ref) => _AuthenticatedAuthController(),
        ),
        userProfileProvider.overrideWith(
          (ref) async => const UserProfile(
            userId: 1,
            nickname: '감자여행자',
            email: 'traveler@example.com',
            profileImage: '',
            createdAt: null,
          ),
        ),
        userActivitySummaryProvider.overrideWith(
          (ref) async => const UserActivitySummary(
            totalSteps: 256842,
            stampCount: 12,
            ownedPotatoCount: 7,
          ),
        ),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MyPageScreen(),
      ),
    ),
  );
}

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
