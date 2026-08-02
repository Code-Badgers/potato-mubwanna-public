import 'dart:io';

import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/step_count_reader.dart';

StepCountReader createPlatformStepCountReader() => HealthStepCountReader();

class HealthStepCountReader implements StepCountReader {
  HealthStepCountReader({Health? health}) : _health = health ?? Health();

  static const _estimatedMetersPerStep = 0.7;
  static const _backgroundPermissionRequestedKey =
      'healthBackgroundPermissionRequested';

  final Health _health;

  @override
  Future<StepCountSnapshot?> readTodaySteps({
    StepCountAuthorization authorization =
        StepCountAuthorization.requestIfNeeded,
  }) async {
    try {
      final source = Platform.isIOS
          ? ActivitySyncSource.healthKit
          : ActivitySyncSource.healthConnect;
      if (Platform.isAndroid) {
        final activityPermission =
            authorization == StepCountAuthorization.requestIfNeeded
                ? await Permission.activityRecognition.request()
                : await Permission.activityRecognition.status;
        if (!activityPermission.isGranted) {
          return null;
        }
      }

      await _health.configure();
      const types = [HealthDataType.STEPS];
      const permissions = [HealthDataAccess.READ];
      final authorized = authorization == StepCountAuthorization.requestIfNeeded
          ? await _health.requestAuthorization(
              types,
              permissions: permissions,
            )
          : await _hasPreviouslyGrantedBackgroundAccess(
              types,
              permissions,
            );
      if (!authorized) {
        return null;
      }
      if (authorization == StepCountAuthorization.requestIfNeeded &&
          Platform.isAndroid) {
        await _requestBackgroundAuthorizationOnce();
      }

      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final steps = await _health.getTotalStepsInInterval(
        startOfToday,
        now,
        includeManualEntry: false,
      );

      final safeSteps = steps?.clamp(0, 1000000);
      if (safeSteps == null) {
        return null;
      }

      return StepCountSnapshot(
        activityDate: startOfToday,
        steps: safeSteps,
        distanceMeters: safeSteps * _estimatedMetersPerStep,
        source: source,
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> _hasPreviouslyGrantedBackgroundAccess(
    List<HealthDataType> types,
    List<HealthDataAccess> permissions,
  ) async {
    final hasStepPermission =
        await _health.hasPermissions(types, permissions: permissions) == true;
    if (!hasStepPermission || !Platform.isAndroid) {
      return hasStepPermission;
    }

    return await _health.isHealthDataInBackgroundAvailable() &&
        await _health.isHealthDataInBackgroundAuthorized();
  }

  Future<void> _requestBackgroundAuthorizationOnce() async {
    if (!await _health.isHealthDataInBackgroundAvailable() ||
        await _health.isHealthDataInBackgroundAuthorized()) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    if (preferences.getBool(_backgroundPermissionRequestedKey) == true) {
      return;
    }

    await _health.requestHealthDataInBackgroundAuthorization();
    await preferences.setBool(_backgroundPermissionRequestedKey, true);
  }
}
