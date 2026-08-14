package com.gamjamubwatna.legal.domain;

import com.gamjamubwatna.auth.domain.User;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "legal_consent_events")
public class LegalConsentEvent {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "legal_consent_event_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(name = "consent_type", nullable = false, length = 40)
    private LegalConsentType type;

    @Column(name = "document_version", nullable = false, length = 80)
    private String documentVersion;

    @Column(name = "accepted", nullable = false)
    private boolean accepted;

    @Column(name = "recorded_at", nullable = false, updatable = false)
    private Instant recordedAt;

    protected LegalConsentEvent() {
    }

    public LegalConsentEvent(
        User user,
        LegalConsentType type,
        String documentVersion,
        boolean accepted,
        Instant recordedAt
    ) {
        this.user = user;
        this.type = type;
        this.documentVersion = documentVersion;
        this.accepted = accepted;
        this.recordedAt = recordedAt;
    }

    public String getDocumentVersion() {
        return documentVersion;
    }

    public boolean isAccepted() {
        return accepted;
    }
}
