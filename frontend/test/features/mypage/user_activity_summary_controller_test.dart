import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/core/storage/token_storage.dart';
import 'package:potato_mubwanna/features/auth/application/auth_controller.dart';
import 'package:potato_mubwanna/features/auth/data/auth_repository.dart';
import 'package:potato_mubwanna/features/auth/data/kakao_login_service.dart';
import 'package:potato_mubwanna/features/mypage/application/user_activity_summary_controller.dart';
import 'package:potato_mubwanna/features/mypage/data/user_activity_summary_repository.dart';
import 'package:potato_mubwanna/features/mypage/domain/user_activity_summary.dart';

void main() {
  test(
    'clears and refetches activity summary when auth session changes',
    () async {
      final authController = AuthController(
        kakaoLoginService: const KakaoLoginService(),
        authRepository: _SessionAuthRepository(),
      );
      final repository = _QueuedUserActivitySummaryRepository([
        const UserActivitySummary(
          totalSteps: 100,
          stampCount: 1,
          ownedPotatoCount: 2,
        ),
        const UserActivitySummary(
          totalSteps: 200,
          stampCount: 3,
          ownedPotatoCount: 4,
        ),
      ]);
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith((ref) => authController),
          userActivitySummaryRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        userActivitySummaryProvider,
        (_, __) {},
      );
      addTearDown(subscription.close);

      expect(await container.read(userActivitySummaryProvider.future), isNull);
      expect(repository.fetchCount, 0);

      await authController.refreshSession();
      await container.pump();
      expect(
        (await container.read(userActivitySummaryProvider.future))?.totalSteps,
        100,
      );

      await authController.logout();
      await container.pump();
      expect(await container.read(userActivitySummaryProvider.future), isNull);

      await authController.refreshSession();
      await container.pump();
      expect(
        (await container.read(userActivitySummaryProvider.future))?.totalSteps,
        200,
      );
      expect(repository.fetchCount, 2);
    },
  );
}

class _QueuedUserActivitySummaryRepository
    extends UserActivitySummaryRepository {
  _QueuedUserActivitySummaryRepository(this._summaries) : super(dio: Dio());

  final List<UserActivitySummary> _summaries;
  int fetchCount = 0;

  @override
  Future<UserActivitySummary> fetchActivitySummary() async {
    final summary = _summaries[fetchCount];
    fetchCount++;
    return summary;
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
