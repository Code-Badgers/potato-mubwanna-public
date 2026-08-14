enum LegalDocumentType {
  serviceTerms,
  privacyPolicy,
  locationServiceTerms,
  healthDataConsent,
}

class LegalDocument {
  const LegalDocument({
    required this.type,
    required this.title,
    required this.summary,
    required this.effectiveDate,
    required this.sections,
  });

  final LegalDocumentType type;
  final String title;
  final String summary;
  final String effectiveDate;
  final List<LegalDocumentSection> sections;
}

class LegalDocumentSection {
  const LegalDocumentSection({
    required this.title,
    this.paragraphs = const [],
    this.items = const [],
  });

  final String title;
  final List<String> paragraphs;
  final List<String> items;
}
