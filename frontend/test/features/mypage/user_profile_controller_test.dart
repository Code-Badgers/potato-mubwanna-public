import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/core/storage/token_storage.dart';
import 'package:potato_mubwanna/features/auth/application/auth_controller.dart';
import 'package:potato_mubwanna/features/auth/data/auth_repository.dart';
import 'package:potato_mubwanna/features/auth/data/kakao_login_service.dart';
import 'package:potato_mubwanna/features/mypage/application/user_profile_controller.dart';
import 'package:potato_mubwanna/features/mypage/data/user_profile_repository.dart';
import 'package:potato_mubwanna/features/mypage/domain/user_profile.dart';

void main() {
  test('refetches the profile after the last listener is removed', () async {
    final authController = AuthController(
      kakaoLoginService: const KakaoLoginService(),
      authRepository: _SessionAuthRepository(),
    );
    await authController.refreshSession();
    final repository = _CountingUserProfileRepository();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith((ref) => authController),
        userProfileRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final firstSubscription = container.listen(
      userProfileProvider,
      (_, __) {},
    );
    await container.read(userProfileProvider.future);
    expect(repository.fetchCount, 1);

    firstSubscription.close();
    await container.pump();

    final secondSubscription = container.listen(
      userProfileProvider,
      (_, __) {},
    );
    addTearDown(secondSubscription.close);
    await container.read(userProfileProvider.future);

    expect(repository.fetchCount, 2);
  });

  test('clears and refetches profile when the auth session changes', () async {
    final authController = AuthController(
      kakaoLoginService: const KakaoLoginService(),
      authRepository: _SessionAuthRepository(),
    );
    final repository = _QueuedUserProfileRepository([
      _profile(1, '감자A'),
      _profile(2, '감자B'),
    ]);
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith((ref) => authController),
        userProfileRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(userProfileProvider, (_, __) {});
    addTearDown(subscription.close);

    expect(await container.read(userProfileProvider.future), isNull);
    expect(repository.fetchCount, 0);

    await authController.refreshSession();
    await container.pump();
    expect((await container.read(userProfileProvider.future))?.nickname, '감자A');

    await authController.logout();
    await container.pump();
    expect(await container.read(userProfileProvider.future), isNull);

    await authController.refreshSession();
    await container.pump();
    expect((await container.read(userProfileProvider.future))?.nickname, '감자B');
    expect(repository.fetchCount, 2);
  });
}

UserProfile _profile(int id, String nickname) => UserProfile(
      userId: id,
      nickname: nickname,
      email: '$id@example.com',
      profileImage: '',
      createdAt: null,
    );

class _CountingUserProfileRepository extends UserProfileRepository {
  _CountingUserProfileRepository() : super(dio: Dio());

  int fetchCount = 0;

  @override
  Future<UserProfile> fetchProfile() async {
    fetchCount++;
    return UserProfile(
      userId: fetchCount,
      nickname: '사용자 $fetchCount',
      email: 'user$fetchCount@example.com',
      profileImage: '',
      createdAt: null,
    );
  }
}

class _QueuedUserProfileRepository extends UserProfileRepository {
  _QueuedUserProfileRepository(this._profiles) : super(dio: Dio());

  final List<UserProfile> _profiles;
  int fetchCount = 0;

  @override
  Future<UserProfile> fetchProfile() async {
    final profile = _profiles[fetchCount];
    fetchCount++;
    return profile;
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
