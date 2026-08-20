import '../data/step_count_reader_stub.dart'
    if (dart.library.io) '../data/step_count_reader_mobile.dart';

abstract interface class StepCountReader {
  Future<StepCountReadResult> readTodaySteps({
    StepCountAuthorization authorization =
        StepCountAuthorization.requestIfNeeded,
  });

  Future<void> openHealthSettings();
}

enum StepCountAuthorization {
  requestIfNeeded,
  previouslyGrantedOnly,
  backgroundPreviouslyGrantedOnly,
}

enum StepCountReadStatus {
  success,
  consentRequired,
  activityPermissionRequired,
  healthPermissionRequired,
  healthPlatformUnavailable,
  unsupported,
  failed,
}

class StepCountReadResult {
  const StepCountReadResult({
    required this.status,
    this.snapshot,
  });

  const StepCountReadResult.success(StepCountSnapshot snapshot)
      : this(status: StepCountReadStatus.success, snapshot: snapshot);

  final StepCountReadStatus status;
  final StepCountSnapshot? snapshot;
}

class StepCountSnapshot {
  const StepCountSnapshot({
    required this.activityDate,
    required this.steps,
    required this.distanceMeters,
    required this.source,
  });

  final DateTime activityDate;
  final int steps;
  final double distanceMeters;
  final ActivitySyncSource source;
}

enum ActivitySyncSource {
  healthKit,
  healthConnect,
  manual,
  unknown,
}

String activitySyncSourceToApi(ActivitySyncSource source) {
  return switch (source) {
    ActivitySyncSource.healthKit => 'HEALTH_KIT',
    ActivitySyncSource.healthConnect => 'HEALTH_CONNECT',
    ActivitySyncSource.manual => 'MANUAL',
    ActivitySyncSource.unknown => 'UNKNOWN',
  };
}

StepCountReader createStepCountReader() => createPlatformStepCountReader();
