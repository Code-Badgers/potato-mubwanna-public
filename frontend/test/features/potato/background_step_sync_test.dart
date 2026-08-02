import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/potato/application/background_step_sync.dart';
import 'package:potato_mubwanna/features/potato/domain/potato_collection.dart';
import 'package:potato_mubwanna/features/potato/domain/step_count_reader.dart';

void main() {
  final snapshot = StepCountSnapshot(
    activityDate: DateTime(2026, 8, 2),
    steps: 1200,
    distanceMeters: 840,
    source: ActivitySyncSource.healthConnect,
  );

  test('skips health access when there is no authenticated session', () async {
    var healthReadCount = 0;
    final service = BackgroundStepSyncService(
      readRefreshToken: () async => null,
      readAuthorizedSteps: () async {
        healthReadCount++;
        return snapshot;
      },
      synchronizeActivity: (_) async => null,
      savePendingGrowth: (_) async {},
    );

    final outcome = await service.synchronize();

    expect(outcome, BackgroundStepSyncOutcome.skipped);
    expect(healthReadCount, 0);
  });

  test('skips sync without showing permission UI when health access is absent',
      () async {
    var syncCount = 0;
    final service = BackgroundStepSyncService(
      readRefreshToken: () async => 'refresh-token',
      readAuthorizedSteps: () async => null,
      synchronizeActivity: (_) async {
        syncCount++;
        return null;
      },
      savePendingGrowth: (_) async {},
    );

    final outcome = await service.synchronize();

    expect(outcome, BackgroundStepSyncOutcome.skipped);
    expect(syncCount, 0);
  });

  test('stores a background level-up for the next foreground entry', () async {
    PotatoGrowthResult? savedGrowth;
    const growthResult = PotatoGrowthResult(
      potatoId: '2',
      potatoName: '곤드레감자',
      previousLevel: 2,
      currentLevel: 3,
      leveledUp: true,
      fullyGrown: false,
    );
    final service = BackgroundStepSyncService(
      readRefreshToken: () async => 'refresh-token',
      readAuthorizedSteps: () async => snapshot,
      synchronizeActivity: (receivedSnapshot) async {
        expect(receivedSnapshot, same(snapshot));
        return growthResult;
      },
      savePendingGrowth: (result) async {
        savedGrowth = result;
      },
    );

    final outcome = await service.synchronize();

    expect(outcome, BackgroundStepSyncOutcome.completed);
    expect(savedGrowth, same(growthResult));
  });

  test('requests a retry after a transient synchronization failure', () async {
    final service = BackgroundStepSyncService(
      readRefreshToken: () async => 'refresh-token',
      readAuthorizedSteps: () async => snapshot,
      synchronizeActivity: (_) async => throw Exception('offline'),
      savePendingGrowth: (_) async {},
    );

    final outcome = await service.synchronize();

    expect(outcome, BackgroundStepSyncOutcome.retry);
  });
}
