import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final legalConsentStoreProvider = Provider<LegalConsentStore>(
  (ref) => const SharedPreferencesLegalConsentStore(),
);

abstract interface class LegalConsentStore {
  Future<bool> hasAcceptedRequiredDocuments();

  Future<bool> hasAcceptedPersonalLocation();

  Future<bool> hasAcceptedHealthData();

  Future<void> acceptRequiredDocuments();

  Future<void> setPersonalLocationConsent(bool accepted);

  Future<void> setHealthDataConsent(bool accepted);
}

class SharedPreferencesLegalConsentStore implements LegalConsentStore {
  const SharedPreferencesLegalConsentStore();

  // v2는 서비스 이용약관 동의와 만 14세 이상 확인을 함께 의미한다.
  static const requiredDocumentVersion = '2026-08-15-v2';
  static const personalLocationConsentVersion = '2026-08-14-v1';
  static const healthDataConsentVersion = '2026-08-14-v1';

  static const _requiredDocumentsKey = 'legal.requiredDocumentsVersion';
  static const _personalLocationKey = 'legal.personalLocationVersion';
  static const _healthDataKey = 'legal.healthDataVersion';

  @override
  Future<bool> hasAcceptedRequiredDocuments() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_requiredDocumentsKey) ==
        requiredDocumentVersion;
  }

  @override
  Future<bool> hasAcceptedPersonalLocation() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_personalLocationKey) ==
        personalLocationConsentVersion;
  }

  @override
  Future<bool> hasAcceptedHealthData() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_healthDataKey) == healthDataConsentVersion;
  }

  @override
  Future<void> acceptRequiredDocuments() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _requiredDocumentsKey,
      requiredDocumentVersion,
    );
  }

  @override
  Future<void> setPersonalLocationConsent(bool accepted) async {
    final preferences = await SharedPreferences.getInstance();
    if (accepted) {
      await preferences.setString(
        _personalLocationKey,
        personalLocationConsentVersion,
      );
      return;
    }
    await preferences.remove(_personalLocationKey);
  }

  @override
  Future<void> setHealthDataConsent(bool accepted) async {
    final preferences = await SharedPreferences.getInstance();
    if (accepted) {
      await preferences.setString(_healthDataKey, healthDataConsentVersion);
      return;
    }
    await preferences.remove(_healthDataKey);
  }
}
