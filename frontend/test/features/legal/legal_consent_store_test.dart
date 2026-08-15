import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/legal/data/legal_consent_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('stores required and optional consent versions separately', () async {
    const store = SharedPreferencesLegalConsentStore();

    expect(await store.hasAcceptedRequiredDocuments(), isFalse);
    expect(await store.hasAcceptedPersonalLocation(), isFalse);
    expect(await store.hasAcceptedHealthData(), isFalse);

    await store.acceptRequiredDocuments();
    await store.setPersonalLocationConsent(true);

    expect(await store.hasAcceptedRequiredDocuments(), isTrue);
    expect(await store.hasAcceptedPersonalLocation(), isTrue);
    expect(await store.hasAcceptedHealthData(), isFalse);
  });

  test('withdraws optional consent without clearing required terms', () async {
    const store = SharedPreferencesLegalConsentStore();
    await store.acceptRequiredDocuments();
    await store.setPersonalLocationConsent(true);
    await store.setPersonalLocationConsent(false);

    expect(await store.hasAcceptedRequiredDocuments(), isTrue);
    expect(await store.hasAcceptedPersonalLocation(), isFalse);
  });

  test('requires consent again after the minimum age policy version changes',
      () async {
    SharedPreferences.setMockInitialValues({
      'legal.requiredDocumentsVersion': '2026-08-14-v1',
    });
    const store = SharedPreferencesLegalConsentStore();

    expect(await store.hasAcceptedRequiredDocuments(), isFalse);
  });
}
