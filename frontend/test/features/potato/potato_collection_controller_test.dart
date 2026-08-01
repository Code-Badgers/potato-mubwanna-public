import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/core/storage/token_storage.dart';
import 'package:potato_mubwanna/features/auth/application/auth_controller.dart';
import 'package:potato_mubwanna/features/auth/data/auth_repository.dart';
import 'package:potato_mubwanna/features/auth/data/kakao_login_service.dart';
import 'package:potato_mubwanna/features/potato/application/potato_collection_controller.dart';
import 'package:potato_mubwanna/features/potato/data/potato_repository.dart';
import 'package:potato_mubwanna/features/potato/domain/potato_collection.dart';
import 'package:potato_mubwanna/features/potato/domain/step_count_reader.dart';

void main() {
  test('syncs activity once before collection and growth summary queries',
      () async {
    final authController = AuthController(
      kakaoLoginService: const KakaoLoginService(),
      authRepository: _SessionAuthRepository(),
    );
    await authController.refreshSession();
    final repository = _RecordingPotatoRepository();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith((ref) => authController),
        potatoRepositoryProvider.overrideWithValue(repository),
        stepCountReaderProvider.overrideWithValue(_FixedStepCountReader()),
      ],
    );
    addTearDown(container.dispose);
    final collectionSubscription = container.listen(
      potatoCollectionProvider,
      (_, __) {},
    );
    final summarySubscription = container.listen(
      potatoGrowthSummaryProvider,
      (_, __) {},
    );
    addTearDown(collectionSubscription.close);
    addTearDown(summarySubscription.close);

    await Future.wait([
      container.read(potatoCollectionProvider.future),
      container.read(potatoGrowthSummaryProvider.future),
    ]);

    expect(repository.operations.first, 'sync');
    expect(
        repository.operations.where((value) => value == 'sync'), hasLength(1));
    expect(repository.operations, containsAll(['collection', 'summary']));
  });

  test('loads the collection with server data when activity sync fails',
      () async {
    final authController = AuthController(
      kakaoLoginService: const KakaoLoginService(),
      authRepository: _SessionAuthRepository(),
    );
    await authController.refreshSession();
    final repository = _RecordingPotatoRepository(syncFails: true);
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith((ref) => authController),
        potatoRepositoryProvider.overrideWithValue(repository),
        stepCountReaderProvider.overrideWithValue(_FixedStepCountReader()),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      potatoCollectionProvider,
      (_, __) {},
    );
    addTearDown(subscription.close);

    final collection = await container.read(potatoCollectionProvider.future);

    expect(collection, isNotNull);
    expect(repository.operations, ['sync', 'collection']);
  });
}

class _RecordingPotatoRepository extends PotatoRepository {
  _RecordingPotatoRepository({this.syncFails = false}) : super(dio: Dio());

  final bool syncFails;
  final List<String> operations = [];

  @override
  Future<void> syncDailyActivity(StepCountSnapshot snapshot) async {
    operations.add('sync');
    if (syncFails) {
      throw StateError('sync failed');
    }
  }

  @override
  Future<PotatoCollection> fetchMyPotatoes() async {
    operations.add('collection');
    return const PotatoCollection(
      totalCount: 0,
      acquiredCount: 0,
      items: [],
    );
  }

  @override
  Future<PotatoGrowthSummary> fetchGrowthSummary() async {
    operations.add('summary');
    return const PotatoGrowthSummary(
      todaySteps: 100,
      dailyStepGoal: 10000,
      weeklyDistanceKm: 0.07,
      monthlyDistanceKm: 0.07,
      remainingDistanceKmForRepresentative: 2.93,
    );
  }
}

class _FixedStepCountReader implements StepCountReader {
  @override
  Future<StepCountSnapshot?> readTodaySteps() async {
    return StepCountSnapshot(
      activityDate: DateTime(2026, 8, 1),
      steps: 100,
      distanceMeters: 70,
      source: ActivitySyncSource.healthConnect,
    );
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
}
