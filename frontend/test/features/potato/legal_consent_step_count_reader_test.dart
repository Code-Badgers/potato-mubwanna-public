import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/legal/data/legal_consent_store.dart';
import 'package:potato_mubwanna/features/potato/data/legal_consent_step_count_reader.dart';
import 'package:potato_mubwanna/features/potato/domain/step_count_reader.dart';

void main() {
  test('does not read health data without separate consent', () async {
    final delegate = _RecordingStepCountReader();
    final reader = LegalConsentStepCountReader(
      delegate: delegate,
      consentStore: _FakeLegalConsentStore(healthAccepted: false),
    );

    expect(
      (await reader.readTodaySteps()).status,
      StepCountReadStatus.consentRequired,
    );
    expect(delegate.readCalls, 0);
  });

  test('reads health data after required and health consent', () async {
    final delegate = _RecordingStepCountReader();
    final reader = LegalConsentStepCountReader(
      delegate: delegate,
      consentStore: _FakeLegalConsentStore(healthAccepted: true),
    );

    expect(
      (await reader.readTodaySteps()).status,
      StepCountReadStatus.success,
    );
    expect(delegate.readCalls, 1);
  });
}

class _RecordingStepCountReader implements StepCountReader {
  int readCalls = 0;

  @override
  Future<StepCountReadResult> readTodaySteps({
    StepCountAuthorization authorization =
        StepCountAuthorization.requestIfNeeded,
  }) async {
    readCalls++;
    return StepCountReadResult.success(
      StepCountSnapshot(
        activityDate: DateTime(2026, 8, 14),
        steps: 1000,
        distanceMeters: 700,
        source: ActivitySyncSource.healthConnect,
      ),
    );
  }

  @override
  Future<void> openHealthSettings() async {}
}

class _FakeLegalConsentStore implements LegalConsentStore {
  _FakeLegalConsentStore({required this.healthAccepted});

  final bool healthAccepted;

  @override
  Future<void> acceptRequiredDocuments() async {}

  @override
  Future<bool> hasAcceptedHealthData() async => healthAccepted;

  @override
  Future<bool> hasAcceptedPersonalLocation() async => false;

  @override
  Future<bool> hasAcceptedRequiredDocuments() async => true;

  @override
  Future<void> setHealthDataConsent(bool accepted) async {}

  @override
  Future<void> setPersonalLocationConsent(bool accepted) async {}
}
