package com.gamjamubwatna.spot.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Duration;
import java.time.Instant;

@Entity
@Table(name = "tourist_spot_google_place_cache")
public class GooglePlaceDetailsCache {

    @Id
    @Column(name = "tourist_spot_id")
    private Long touristSpotId;

    @Column(name = "google_place_id", length = 255)
    private String googlePlaceId;

    @Column(name = "details_payload", columnDefinition = "TEXT")
    private String detailsPayload;

    @Column(name = "matched_at")
    private Instant matchedAt;

    @Column(name = "details_fetched_at")
    private Instant detailsFetchedAt;

    @Column(name = "details_expires_at")
    private Instant detailsExpiresAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected GooglePlaceDetailsCache() {
    }

    public GooglePlaceDetailsCache(Long touristSpotId, Instant now) {
        this.touristSpotId = touristSpotId;
        this.createdAt = now;
        this.updatedAt = now;
    }

    public void recordMatch(String googlePlaceId, Instant now) {
        if (googlePlaceId == null || googlePlaceId.isBlank()) {
            return;
        }
        this.googlePlaceId = googlePlaceId;
        this.matchedAt = now;
        this.updatedAt = now;
    }

    public void cacheDetails(String googlePlaceId, String detailsPayload, Instant now, Duration ttl) {
        recordMatch(googlePlaceId, now);
        this.detailsPayload = detailsPayload;
        this.detailsFetchedAt = now;
        this.detailsExpiresAt = now.plus(ttl);
        this.updatedAt = now;
    }

    public boolean hasFreshDetails(Instant now) {
        return hasDetails() && detailsExpiresAt != null && now.isBefore(detailsExpiresAt);
    }

    public boolean hasDetails() {
        return detailsPayload != null && !detailsPayload.isBlank();
    }

    public Long getTouristSpotId() {
        return touristSpotId;
    }

    public String getGooglePlaceId() {
        return googlePlaceId;
    }

    public String getDetailsPayload() {
        return detailsPayload;
    }

    public Instant getDetailsFetchedAt() {
        return detailsFetchedAt;
    }

    public Instant getDetailsExpiresAt() {
        return detailsExpiresAt;
    }
}
