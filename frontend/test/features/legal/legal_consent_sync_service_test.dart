import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/legal/data/legal_consent_store.dart';
import 'package:potato_mubwanna/features/legal/data/legal_consent_sync_service.dart';
import 'package:potato_mubwanna/features/legal/domain/legal_consent_snapshot.dart';

void main() {
  test('synchronizes the current local consent snapshot', () async {
    final requests = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: const {'success': true, 'message': '요청이 성공했습니다.'},
              ),
            );
          },
        ),
      );
    final service = LegalConsentSyncService(
      dio: dio,
      store: _ConsentStore(locationAccepted: true, healthAccepted: false),
    );

    await service.synchronize();

    expect(requests, hasLength(1));
    expect(requests.single.method, 'PUT');
    expect(requests.single.path, '/users/me/legal-consents');
    expect(requests.single.data, {
      'requiredDocumentsVersion': '2026-08-15-v2',
      'personalLocationConsentVersion': '2026-08-14-v1',
      'healthDataConsentVersion': null,
    });
  });

  test('does not synchronize before required documents are accepted', () async {
    final requests = <RequestOptions>[];
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(onRequest: (options, handler) {
          requests.add(options);
          handler.reject(DioException(requestOptions: options));
        }),
      );
    final service = LegalConsentSyncService(
      dio: dio,
      store: _ConsentStore(requiredAccepted: false),
    );

    await service.synchronize();

    expect(requests, isEmpty);
  });

  test('uploads pending local withdrawal before reading the server', () async {
    final requests = <RequestOptions>[];
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: const {'success': true, 'data': null},
            ),
          );
        }),
      );
    final store = _ReconciliationConsentStore(
      snapshot: const LegalConsentSnapshot(
        requiredDocumentsVersion: '2026-08-15-v2',
        personalLocationConsentVersion: null,
        healthDataConsentVersion: null,
      ),
      pending: true,
    );
    final service = LegalConsentSyncService(dio: dio, store: store);

    await service.synchronize();

    expect(requests, hasLength(1));
    expect(requests.single.method, 'PUT');
    expect(requests.single.data, {
      'requiredDocumentsVersion': '2026-08-15-v2',
      'personalLocationConsentVersion': null,
      'healthDataConsentVersion': null,
    });
    expect(store.markSynchronizedCalls, 1);
  });

  test('keeps pending local changes when the upload fails', () async {
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(onRequest: (options, handler) {
          handler.reject(DioException(requestOptions: options));
        }),
      );
    final store = _ReconciliationConsentStore(
      snapshot: const LegalConsentSnapshot(
        requiredDocumentsVersion: '2026-08-15-v2',
        personalLocationConsentVersion: null,
        healthDataConsentVersion: null,
      ),
      pending: true,
    );
    final service = LegalConsentSyncService(dio: dio, store: store);

    await expectLater(service.synchronize(), throwsA(isA<DioException>()));

    expect(store.pending, isTrue);
    expect(store.markSynchronizedCalls, 0);
  });

  test('restores the server snapshot when local state has no pending changes',
      () async {
    final requests = <RequestOptions>[];
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: const {
                'success': true,
                'data': {
                  'requiredDocumentsVersion': '2026-08-15-v2',
                  'personalLocationConsentVersion': '2026-08-14-v1',
                  'healthDataConsentVersion': null,
                },
              },
            ),
          );
        }),
      );
    final store = _ReconciliationConsentStore(
      snapshot: const LegalConsentSnapshot(
        requiredDocumentsVersion: '2026-08-15-v2',
        personalLocationConsentVersion: null,
        healthDataConsentVersion: '2026-08-14-v1',
      ),
    );
    final service = LegalConsentSyncService(dio: dio, store: store);

    await service.synchronize();

    expect(requests, hasLength(1));
    expect(requests.single.method, 'GET');
    expect(store.appliedSnapshots, hasLength(1));
    expect(
      store.appliedSnapshots.single.personalLocationConsentVersion,
      '2026-08-14-v1',
    );
    expect(store.appliedSnapshots.single.healthDataConsentVersion, isNull);
  });

  test('preserves a valid existing local consent when the server is empty',
      () async {
    final requests = <RequestOptions>[];
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: options.method == 'GET'
                  ? const {
                      'success': true,
                      'data': {
                        'requiredDocumentsVersion': null,
                        'personalLocationConsentVersion': null,
                        'healthDataConsentVersion': null,
                      },
                    }
                  : const {'success': true, 'data': null},
            ),
          );
        }),
      );
    final store = _ReconciliationConsentStore(
      snapshot: const LegalConsentSnapshot(
        requiredDocumentsVersion: '2026-08-15-v2',
        personalLocationConsentVersion: '2026-08-14-v1',
        healthDataConsentVersion: null,
      ),
    );
    final service = LegalConsentSyncService(dio: dio, store: store);

    await service.synchronize();

    expect(requests.map((request) => request.method), ['GET', 'PUT']);
    expect(store.appliedSnapshots, isEmpty);
    expect(store.markSynchronizedCalls, 1);
  });
}

class _ConsentStore implements LegalConsentStore {
  _ConsentStore({
    this.requiredAccepted = true,
    this.locationAccepted = false,
    this.healthAccepted = false,
  });

  final bool requiredAccepted;
  final bool locationAccepted;
  final bool healthAccepted;

  @override
  Future<void> acceptRequiredDocuments() async {}

  @override
  Future<bool> hasAcceptedHealthData() async => healthAccepted;

  @override
  Future<bool> hasAcceptedPersonalLocation() async => locationAccepted;

  @override
  Future<bool> hasAcceptedRequiredDocuments() async => requiredAccepted;

  @override
  Future<void> setHealthDataConsent(bool accepted) async {}

  @override
  Future<void> setPersonalLocationConsent(bool accepted) async {}
}

class _ReconciliationConsentStore
    implements LegalConsentStore, LegalConsentSnapshotStore {
  _ReconciliationConsentStore({required this.snapshot, this.pending = false});

  LegalConsentSnapshot snapshot;
  bool pending;
  int markSynchronizedCalls = 0;
  final appliedSnapshots = <LegalConsentSnapshot>[];

  @override
  Future<void> acceptRequiredDocuments() async {}

  @override
  Future<void> applyServerSnapshot(LegalConsentSnapshot snapshot) async {
    this.snapshot = snapshot;
    appliedSnapshots.add(snapshot);
    pending = false;
  }

  @override
  Future<bool> hasAcceptedHealthData() async =>
      snapshot.healthDataConsentVersion == '2026-08-14-v1';

  @override
  Future<bool> hasAcceptedPersonalLocation() async =>
      snapshot.personalLocationConsentVersion == '2026-08-14-v1';

  @override
  Future<bool> hasAcceptedRequiredDocuments() async =>
      snapshot.requiredDocumentsVersion == '2026-08-15-v2';

  @override
  Future<bool> hasPendingChanges() async => pending;

  @override
  Future<void> markSynchronized() async {
    markSynchronizedCalls++;
    pending = false;
  }

  @override
  Future<LegalConsentSnapshot> readSnapshot() async => snapshot;

  @override
  Future<void> setHealthDataConsent(bool accepted) async {}

  @override
  Future<void> setPersonalLocationConsent(bool accepted) async {}
}
