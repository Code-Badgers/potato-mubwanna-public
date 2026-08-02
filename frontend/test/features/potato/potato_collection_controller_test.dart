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
import 'package:potato_mubwanna/features/potato/data/pending_potato_growth_store.dart';
import 'package:potato_mubwanna/features/potato/domain/potato_collection.dart';
import 'package:potato_mubwanna/features/potato/domain/step_count_reader.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('parses the server-confirmed potato growth result', () {
    final result = PotatoActivitySyncResult.fromJson({
      'growthResult': {
        'potatoId': 2,
        'potatoName': '곤드레감자',
        'previousLevel': 2,
        'currentLevel': 3,
        'leveledUp': true,
        'fullyGrown': false,
      },
    });

    expect(result.growthResult?.potatoId, '2');
    expect(result.growthResult?.potatoName, '곤드레감자');
    expect(result.growthResult?.previousLevel, 2);
    expect(result.growthResult?.currentLevel, 3);
    expect(result.growthResult?.leveledUp, isTrue);
    expect(result.growthResult?.fullyGrown, isFalse);
  });

  test('parses a sync response without potato growth', () {
    final result = PotatoActivitySyncResult.fromJson({
      'growthResult': null,
    });

    expect(result.growthResult, isNull);
  });

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

  test('returns the server-confirmed potato growth result', () async {
    final authController = AuthController(
      kakaoLoginService: const KakaoLoginService(),
      authRepository: _SessionAuthRepository(),
    );
    await authController.refreshSession();
    const growthResult = PotatoGrowthResult(
      potatoId: '2',
      potatoName: '곤드레감자',
      previousLevel: 2,
      currentLevel: 3,
      leveledUp: true,
      fullyGrown: false,
    );
    final repository = _RecordingPotatoRepository(
      growthResult: growthResult,
    );
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith((ref) => authController),
        potatoRepositoryProvider.overrideWithValue(repository),
        stepCountReaderProvider.overrideWithValue(_FixedStepCountReader()),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(potatoActivitySyncProvider.future);

    expect(result, same(growthResult));
  });

  test('returns a background growth result once on the next foreground sync',
      () async {
    final authController = AuthController(
      kakaoLoginService: const KakaoLoginService(),
      authRepository: _SessionAuthRepository(),
    );
    await authController.refreshSession();
    const backgroundGrowthResult = PotatoGrowthResult(
      potatoId: '2',
      potatoName: '곤드레감자',
      previousLevel: 2,
      currentLevel: 3,
      leveledUp: true,
      fullyGrown: false,
    );
    final pendingGrowthStore = _MemoryPendingPotatoGrowthStore(
      backgroundGrowthResult,
    );
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith((ref) => authController),
        potatoRepositoryProvider.overrideWithValue(
          _RecordingPotatoRepository(),
        ),
        stepCountReaderProvider.overrideWithValue(_FixedStepCountReader()),
        pendingPotatoGrowthStoreProvider.overrideWithValue(
          pendingGrowthStore,
        ),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(potatoActivitySyncProvider.future);

    expect(result, same(backgroundGrowthResult));
    expect(await pendingGrowthStore.take(), isNull);
  });
}

class _RecordingPotatoRepository extends PotatoRepository {
  _RecordingPotatoRepository({
    this.syncFails = false,
    this.growthResult,
  }) : super(dio: Dio());

  final bool syncFails;
  final PotatoGrowthResult? growthResult;
  final List<String> operations = [];

  @override
  Future<PotatoGrowthResult?> syncDailyActivity(
    StepCountSnapshot snapshot,
  ) async {
    operations.add('sync');
    if (syncFails) {
      throw StateError('sync failed');
    }
    return growthResult;
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
  Future<StepCountSnapshot?> readTodaySteps({
    StepCountAuthorization authorization =
        StepCountAuthorization.requestIfNeeded,
  }) async {
    return StepCountSnapshot(
      activityDate: DateTime(2026, 8, 1),
      steps: 100,
      distanceMeters: 70,
      source: ActivitySyncSource.healthConnect,
    );
  }
}

class _MemoryPendingPotatoGrowthStore implements PendingPotatoGrowthStore {
  _MemoryPendingPotatoGrowthStore(this._growthResult);

  PotatoGrowthResult? _growthResult;

  @override
  Future<void> save(PotatoGrowthResult growthResult) async {
    _growthResult = growthResult;
  }

  @override
  Future<PotatoGrowthResult?> take() async {
    final growthResult = _growthResult;
    _growthResult = null;
    return growthResult;
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
