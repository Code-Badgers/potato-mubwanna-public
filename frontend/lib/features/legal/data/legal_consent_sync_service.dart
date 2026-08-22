import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import '../domain/legal_consent_snapshot.dart';
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
  LegalConsentSyncService({
    required Dio dio,
    required LegalConsentStore store,
    LegalConsentSnapshotStore? snapshotStore,
  })  : _dio = dio,
        _store = store,
        _snapshotStore = snapshotStore ??
            (store is LegalConsentSnapshotStore
                ? store as LegalConsentSnapshotStore
                : null);

  final Dio _dio;
  final LegalConsentStore _store;
  final LegalConsentSnapshotStore? _snapshotStore;

  @override
  Future<void> synchronize() async {
    final snapshotStore = _snapshotStore;
    if (snapshotStore == null) {
      await _uploadCurrentLocalSnapshot();
      return;
    }

    if (await snapshotStore.hasPendingChanges()) {
      if (await _uploadCurrentLocalSnapshot()) {
        await snapshotStore.markSynchronized();
      }
      return;
    }

    final localSnapshot = await snapshotStore.readSnapshot();
    final serverSnapshot = await _fetchServerSnapshot();
    if (serverSnapshot.requiredDocumentsVersion == null &&
        localSnapshot.requiredDocumentsVersion ==
            SharedPreferencesLegalConsentStore.requiredDocumentVersion) {
      if (await _uploadCurrentLocalSnapshot()) {
        await snapshotStore.markSynchronized();
      }
      return;
    }

    await snapshotStore.applyServerSnapshot(serverSnapshot);
  }

  Future<LegalConsentSnapshot> _fetchServerSnapshot() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.myLegalConsents,
    );
    return LegalConsentSnapshot.fromJson(response.data?['data']);
  }

  Future<bool> _uploadCurrentLocalSnapshot() async {
    final requiredAccepted = await _store.hasAcceptedRequiredDocuments();
    if (!requiredAccepted) {
      return false;
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
    return true;
  }
}
