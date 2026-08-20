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
  static const _healthAuthorizationRequestedKey =
      'healthAuthorizationRequested';

  final Health _health;

  @override
  Future<StepCountReadResult> readTodaySteps({
    StepCountAuthorization authorization =
        StepCountAuthorization.requestIfNeeded,
  }) async {
    try {
      final source = Platform.isIOS
          ? ActivitySyncSource.healthKit
          : ActivitySyncSource.healthConnect;
      if (Platform.isAndroid) {
        if (!await _health.isHealthConnectAvailable()) {
          return const StepCountReadResult(
            status: StepCountReadStatus.healthPlatformUnavailable,
          );
        }
        final activityPermission =
            authorization == StepCountAuthorization.requestIfNeeded
                ? await Permission.activityRecognition.request()
                : await Permission.activityRecognition.status;
        if (!activityPermission.isGranted) {
          return const StepCountReadResult(
            status: StepCountReadStatus.activityPermissionRequired,
          );
        }
      }

      await _health.configure();
      const types = [HealthDataType.STEPS];
      const permissions = [HealthDataAccess.READ];
      final authorized = authorization == StepCountAuthorization.requestIfNeeded
          ? await _requestAuthorization(types, permissions)
          : await _hasPreviouslyGrantedAccess(
              types,
              permissions,
              requireBackground: authorization ==
                  StepCountAuthorization.backgroundPreviouslyGrantedOnly,
            );
      if (!authorized) {
        return const StepCountReadResult(
          status: StepCountReadStatus.healthPermissionRequired,
        );
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
        return const StepCountReadResult(
          status: StepCountReadStatus.failed,
        );
      }

      return StepCountReadResult.success(
        StepCountSnapshot(
          activityDate: startOfToday,
          steps: safeSteps,
          distanceMeters: safeSteps * _estimatedMetersPerStep,
          source: source,
        ),
      );
    } on UnsupportedError {
      return const StepCountReadResult(
        status: StepCountReadStatus.healthPlatformUnavailable,
      );
    } catch (_) {
      return const StepCountReadResult(
        status: StepCountReadStatus.failed,
      );
    }
  }

  @override
  Future<void> openHealthSettings() async {
    if (Platform.isAndroid) {
      if (!await _health.isHealthConnectAvailable()) {
        await _health.installHealthConnect();
        return;
      }
    }
    await openAppSettings();
  }

  Future<bool> _requestAuthorization(
    List<HealthDataType> types,
    List<HealthDataAccess> permissions,
  ) async {
    final authorized = await _health.requestAuthorization(
      types,
      permissions: permissions,
    );
    if (authorized) {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_healthAuthorizationRequestedKey, true);
    }
    return authorized;
  }

  Future<bool> _hasPreviouslyGrantedAccess(
    List<HealthDataType> types,
    List<HealthDataAccess> permissions, {
    required bool requireBackground,
  }) async {
    if (Platform.isIOS) {
      // HealthKit은 읽기 권한 상태를 공개하지 않으므로 이전 요청 여부로만
      // 조회 가능성을 판단하고 실제 데이터 조회 결과를 최종 기준으로 삼는다.
      final preferences = await SharedPreferences.getInstance();
      return preferences.getBool(_healthAuthorizationRequestedKey) == true;
    }

    final hasStepPermission =
        await _health.hasPermissions(types, permissions: permissions) == true;
    if (!hasStepPermission) {
      return false;
    }

    if (!requireBackground) {
      return true;
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
