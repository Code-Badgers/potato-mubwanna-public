import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../../../app/config/app_environment.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../data/pending_potato_growth_store.dart';
import '../data/potato_repository.dart';
import '../domain/potato_collection.dart';
import '../domain/step_count_reader.dart';

const backgroundStepSyncTaskName = 'backgroundPotatoStepSync';
const backgroundStepSyncUniqueName = 'periodicBackgroundPotatoStepSync';
const backgroundStepSyncTag = 'potatoStepSync';
const _iosBackgroundStepSyncChannel =
    MethodChannel('potato_mubwanna/health_background_sync');
const _iosBackgroundStepSyncStartMethod = 'start';
const _iosBackgroundStepSyncCompletedMethod = 'completed';

enum BackgroundStepSyncOutcome { completed, skipped, retry }

class BackgroundStepSyncService {
  const BackgroundStepSyncService({
    required Future<String?> Function() readRefreshToken,
    required Future<StepCountSnapshot?> Function() readAuthorizedSteps,
    required Future<PotatoGrowthResult?> Function(StepCountSnapshot snapshot)
        synchronizeActivity,
    required Future<void> Function(PotatoGrowthResult growthResult)
        savePendingGrowth,
  })  : _readRefreshToken = readRefreshToken,
        _readAuthorizedSteps = readAuthorizedSteps,
        _synchronizeActivity = synchronizeActivity,
        _savePendingGrowth = savePendingGrowth;

  final Future<String?> Function() _readRefreshToken;
  final Future<StepCountSnapshot?> Function() _readAuthorizedSteps;
  final Future<PotatoGrowthResult?> Function(StepCountSnapshot snapshot)
      _synchronizeActivity;
  final Future<void> Function(PotatoGrowthResult growthResult)
      _savePendingGrowth;

  Future<BackgroundStepSyncOutcome> synchronize() async {
    try {
      final refreshToken = await _readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return BackgroundStepSyncOutcome.skipped;
      }

      final snapshot = await _readAuthorizedSteps();
      if (snapshot == null) {
        return BackgroundStepSyncOutcome.skipped;
      }

      final growthResult = await _synchronizeActivity(snapshot);
      if (growthResult?.leveledUp == true) {
        try {
          await _savePendingGrowth(growthResult!);
        } catch (_) {
          // 서버 반영은 끝났으므로 저장 실패를 재시도해 같은 활동을 다시 보내지 않는다.
        }
      }
      return BackgroundStepSyncOutcome.completed;
    } on ApiException catch (error) {
      final statusCode = error.statusCode;
      if (statusCode != null && statusCode < 500) {
        return BackgroundStepSyncOutcome.skipped;
      }
      return BackgroundStepSyncOutcome.retry;
    } on DioException {
      return BackgroundStepSyncOutcome.retry;
    } catch (_) {
      return BackgroundStepSyncOutcome.retry;
    }
  }
}

Future<void> initializeAndroidBackgroundStepSync() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return;
  }

  final workmanager = Workmanager();
  await workmanager.initialize(backgroundStepSyncCallbackDispatcher);
  await workmanager.registerPeriodicTask(
    backgroundStepSyncUniqueName,
    backgroundStepSyncTaskName,
    frequency: const Duration(hours: 1),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingWorkPolicy.update,
    backoffPolicy: BackoffPolicy.exponential,
    backoffPolicyDelay: const Duration(minutes: 15),
    tag: backgroundStepSyncTag,
  );
}

@pragma('vm:entry-point')
void backgroundStepSyncCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != backgroundStepSyncTaskName) {
      return true;
    }

    final outcome = await runBackgroundStepSync();
    return outcome != BackgroundStepSyncOutcome.retry;
  });
}

void initializeIosHealthBackgroundSyncEntrypoint() {
  WidgetsFlutterBinding.ensureInitialized();
  _iosBackgroundStepSyncChannel.setMethodCallHandler((call) async {
    if (call.method != _iosBackgroundStepSyncStartMethod) {
      return;
    }

    try {
      await runIosHealthBackgroundStepSync();
    } catch (_) {
      // Native code owns a timeout fallback, so the headless isolate can end quietly.
    }
  });
}

@visibleForTesting
Future<void> runIosHealthBackgroundStepSync({
  Future<BackgroundStepSyncOutcome> Function()? synchronize,
  Future<void> Function()? notifyCompletion,
}) async {
  try {
    await (synchronize ?? runBackgroundStepSync)();
  } finally {
    if (notifyCompletion != null) {
      await notifyCompletion();
    } else {
      await _iosBackgroundStepSyncChannel.invokeMethod<void>(
        _iosBackgroundStepSyncCompletedMethod,
      );
    }
  }
}

Future<BackgroundStepSyncOutcome> runBackgroundStepSync() async {
  const tokenStorage = TokenStorage(applicationSecureStorage);
  final dioClient = DioClient(
    tokenStorage: tokenStorage,
    baseUrl: AppEnvironment.apiBaseUrl,
  );
  final repository = PotatoRepository(dio: dioClient.dio);
  final stepCountReader = createStepCountReader();
  const pendingGrowthStore = SharedPreferencesPendingPotatoGrowthStore();

  return BackgroundStepSyncService(
    readRefreshToken: tokenStorage.readRefreshToken,
    readAuthorizedSteps: () => stepCountReader.readTodaySteps(
      authorization: StepCountAuthorization.previouslyGrantedOnly,
    ),
    synchronizeActivity: repository.syncDailyActivity,
    savePendingGrowth: pendingGrowthStore.save,
  ).synchronize();
}
