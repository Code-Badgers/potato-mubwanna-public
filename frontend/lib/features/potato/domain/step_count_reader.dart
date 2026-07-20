import '../data/step_count_reader_stub.dart'
    if (dart.library.io) '../data/step_count_reader_mobile.dart';

abstract interface class StepCountReader {
  Future<int?> readTodaySteps();
}

StepCountReader createStepCountReader() => createPlatformStepCountReader();
