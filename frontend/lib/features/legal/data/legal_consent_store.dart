import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/legal_consent_snapshot.dart';

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

abstract interface class LegalConsentSnapshotStore {
  Future<LegalConsentSnapshot> readSnapshot();

  Future<void> applyServerSnapshot(LegalConsentSnapshot snapshot);

  Future<bool> hasPendingChanges();

  Future<void> markSynchronized();
}

class SharedPreferencesLegalConsentStore
    implements LegalConsentStore, LegalConsentSnapshotStore {
  const SharedPreferencesLegalConsentStore();

  // v2는 서비스 이용약관 동의와 만 14세 이상 확인을 함께 의미한다.
  static const requiredDocumentVersion = '2026-08-15-v2';
  static const personalLocationConsentVersion = '2026-08-14-v1';
  static const healthDataConsentVersion = '2026-08-14-v1';

  static const _requiredDocumentsKey = 'legal.requiredDocumentsVersion';
  static const _personalLocationKey = 'legal.personalLocationVersion';
  static const _healthDataKey = 'legal.healthDataVersion';
  static const _pendingSyncKey = 'legal.pendingSync';

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
    await preferences.setBool(_pendingSyncKey, true);
  }

  @override
  Future<void> setPersonalLocationConsent(bool accepted) async {
    final preferences = await SharedPreferences.getInstance();
    if (accepted) {
      await preferences.setString(
        _personalLocationKey,
        personalLocationConsentVersion,
      );
      await preferences.setBool(_pendingSyncKey, true);
      return;
    }
    await preferences.remove(_personalLocationKey);
    await preferences.setBool(_pendingSyncKey, true);
  }

  @override
  Future<void> setHealthDataConsent(bool accepted) async {
    final preferences = await SharedPreferences.getInstance();
    if (accepted) {
      await preferences.setString(_healthDataKey, healthDataConsentVersion);
      await preferences.setBool(_pendingSyncKey, true);
      return;
    }
    await preferences.remove(_healthDataKey);
    await preferences.setBool(_pendingSyncKey, true);
  }

  @override
  Future<LegalConsentSnapshot> readSnapshot() async {
    final preferences = await SharedPreferences.getInstance();
    return LegalConsentSnapshot(
      requiredDocumentsVersion: preferences.getString(_requiredDocumentsKey),
      personalLocationConsentVersion:
          preferences.getString(_personalLocationKey),
      healthDataConsentVersion: preferences.getString(_healthDataKey),
    );
  }

  @override
  Future<void> applyServerSnapshot(LegalConsentSnapshot snapshot) async {
    final preferences = await SharedPreferences.getInstance();
    await _applyVersion(
      preferences,
      key: _requiredDocumentsKey,
      receivedVersion: snapshot.requiredDocumentsVersion,
      currentVersion: requiredDocumentVersion,
    );
    await _applyVersion(
      preferences,
      key: _personalLocationKey,
      receivedVersion: snapshot.personalLocationConsentVersion,
      currentVersion: personalLocationConsentVersion,
    );
    await _applyVersion(
      preferences,
      key: _healthDataKey,
      receivedVersion: snapshot.healthDataConsentVersion,
      currentVersion: healthDataConsentVersion,
    );
    await preferences.remove(_pendingSyncKey);
  }

  @override
  Future<bool> hasPendingChanges() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_pendingSyncKey) ?? false;
  }

  @override
  Future<void> markSynchronized() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_pendingSyncKey);
  }

  Future<void> _applyVersion(
    SharedPreferences preferences, {
    required String key,
    required String? receivedVersion,
    required String currentVersion,
  }) async {
    if (receivedVersion == currentVersion) {
      await preferences.setString(key, currentVersion);
      return;
    }
    await preferences.remove(key);
  }
}
