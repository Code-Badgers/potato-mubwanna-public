import '../domain/step_count_reader.dart';

StepCountReader createPlatformStepCountReader() =>
    const UnsupportedStepCountReader();

class UnsupportedStepCountReader implements StepCountReader {
  const UnsupportedStepCountReader();

  @override
  Future<int?> readTodaySteps() async => null;
}
