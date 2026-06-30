import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/core/storage/token_storage.dart';
import 'package:potato_mubwanna/features/auth/application/auth_controller.dart';
import 'package:potato_mubwanna/features/auth/data/auth_repository.dart';
import 'package:potato_mubwanna/features/auth/data/kakao_login_service.dart';
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
