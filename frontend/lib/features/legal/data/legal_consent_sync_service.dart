import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import 'legal_consent_store.dart';

abstract interface class LegalConsentLifecycle {
  Future<void> synchronize();
}

class NoopLegalConsentLifecycle implements LegalConsentLifecycle {
  const NoopLegalConsentLifecycle();

  @override
  Future<void> synchronize() async {}
}

class LegalConsentSyncService implements LegalConsentLifecycle {
  const LegalConsentSyncService(
      {required Dio dio, required LegalConsentStore store})
      : _dio = dio,
        _store = store;

  final Dio _dio;
  final LegalConsentStore _store;

  @override
  Future<void> synchronize() async {
    final requiredAccepted = await _store.hasAcceptedRequiredDocuments();
    if (!requiredAccepted) {
      return;
    }

    final locationAccepted = await _store.hasAcceptedPersonalLocation();
    final healthAccepted = await _store.hasAcceptedHealthData();
    await _dio.put<Map<String, dynamic>>(
      ApiPaths.myLegalConsents,
      data: {
        'requiredDocumentsVersion':
            SharedPreferencesLegalConsentStore.requiredDocumentVersion,
        'personalLocationConsentVersion': locationAccepted
            ? SharedPreferencesLegalConsentStore.personalLocationConsentVersion
            : null,
        'healthDataConsentVersion': healthAccepted
            ? SharedPreferencesLegalConsentStore.healthDataConsentVersion
            : null,
      },
    );
  }
}
