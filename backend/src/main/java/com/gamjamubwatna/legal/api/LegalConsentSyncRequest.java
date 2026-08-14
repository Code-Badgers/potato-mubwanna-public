package com.gamjamubwatna.legal.api;

public record LegalConsentSyncRequest(
    String requiredDocumentsVersion,
    String personalLocationConsentVersion,
    String healthDataConsentVersion
) {
}
