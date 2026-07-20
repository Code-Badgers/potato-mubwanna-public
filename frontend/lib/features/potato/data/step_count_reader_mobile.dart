import 'dart:io';

import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

import '../domain/step_count_reader.dart';

StepCountReader createPlatformStepCountReader() => HealthStepCountReader();

class HealthStepCountReader implements StepCountReader {
  HealthStepCountReader({Health? health}) : _health = health ?? Health();

  final Health _health;

  @override
  Future<int?> readTodaySteps() async {
    try {
      if (Platform.isAndroid) {
        final activityPermission =
            await Permission.activityRecognition.request();
        if (!activityPermission.isGranted) {
          return null;
        }
      }

      await _health.configure();
      const types = [HealthDataType.STEPS];
      const permissions = [HealthDataAccess.READ];
      final authorized = await _health.requestAuthorization(
        types,
        permissions: permissions,
      );
      if (!authorized) {
        return null;
      }

      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final steps = await _health.getTotalStepsInInterval(
        startOfToday,
        now,
        includeManualEntry: false,
      );

      return steps?.clamp(0, 1000000);
    } catch (_) {
      return null;
    }
  }
}
