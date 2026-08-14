import '../../legal/data/legal_consent_store.dart';
import '../domain/step_count_reader.dart';

class LegalConsentStepCountReader implements StepCountReader {
  const LegalConsentStepCountReader({
    required StepCountReader delegate,
    required LegalConsentStore consentStore,
  })  : _delegate = delegate,
        _consentStore = consentStore;

  final StepCountReader _delegate;
  final LegalConsentStore _consentStore;

  @override
  Future<StepCountSnapshot?> readTodaySteps({
    StepCountAuthorization authorization =
        StepCountAuthorization.requestIfNeeded,
  }) async {
    if (!await _consentStore.hasAcceptedRequiredDocuments() ||
        !await _consentStore.hasAcceptedHealthData()) {
      return null;
    }
    return _delegate.readTodaySteps(authorization: authorization);
  }
}
