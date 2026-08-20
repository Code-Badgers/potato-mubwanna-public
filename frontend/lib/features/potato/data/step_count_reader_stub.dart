import '../domain/step_count_reader.dart';

StepCountReader createPlatformStepCountReader() =>
    const UnsupportedStepCountReader();

class UnsupportedStepCountReader implements StepCountReader {
  const UnsupportedStepCountReader();

  @override
  Future<StepCountReadResult> readTodaySteps({
    StepCountAuthorization authorization =
        StepCountAuthorization.requestIfNeeded,
  }) async =>
      const StepCountReadResult(status: StepCountReadStatus.unsupported);

  @override
  Future<void> openHealthSettings() async {}
}
