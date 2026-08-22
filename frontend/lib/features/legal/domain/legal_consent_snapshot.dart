class LegalConsentSnapshot {
  const LegalConsentSnapshot({
    required this.requiredDocumentsVersion,
    required this.personalLocationConsentVersion,
    required this.healthDataConsentVersion,
  });

  final String? requiredDocumentsVersion;
  final String? personalLocationConsentVersion;
  final String? healthDataConsentVersion;

  factory LegalConsentSnapshot.fromJson(Object? json) {
    final data = json as Map<String, dynamic>? ?? const <String, dynamic>{};
    return LegalConsentSnapshot(
      requiredDocumentsVersion: data['requiredDocumentsVersion'] as String?,
      personalLocationConsentVersion:
          data['personalLocationConsentVersion'] as String?,
      healthDataConsentVersion: data['healthDataConsentVersion'] as String?,
    );
  }
}
