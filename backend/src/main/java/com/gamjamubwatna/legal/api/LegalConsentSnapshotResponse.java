package com.gamjamubwatna.legal.api;

public record LegalConsentSnapshotResponse(
    String requiredDocumentsVersion,
    String personalLocationConsentVersion,
    String healthDataConsentVersion
) {
}
