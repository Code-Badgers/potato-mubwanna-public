import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/legal/data/legal_consent_store.dart';
import 'package:potato_mubwanna/features/legal/data/legal_consent_sync_service.dart';

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
