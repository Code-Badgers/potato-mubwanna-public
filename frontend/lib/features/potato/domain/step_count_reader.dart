import '../data/step_count_reader_stub.dart'
    if (dart.library.io) '../data/step_count_reader_mobile.dart';

abstract interface class StepCountReader {
  Future<StepCountSnapshot?> readTodaySteps({
    StepCountAuthorization authorization =
        StepCountAuthorization.requestIfNeeded,
  });
}

enum StepCountAuthorization {
  requestIfNeeded,
  previouslyGrantedOnly,
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
