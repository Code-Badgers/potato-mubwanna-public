package com.gamjamubwatna.spot.application;

import com.gamjamubwatna.spot.domain.GooglePlaceDetailsCache;
import com.gamjamubwatna.spot.domain.GooglePlaceDetailsCacheRepository;
import java.time.Duration;
import java.time.Instant;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Service
public class GooglePlaceDetailsCacheWriter {

    private final GooglePlaceDetailsCacheRepository repository;

    public GooglePlaceDetailsCacheWriter(GooglePlaceDetailsCacheRepository repository) {
        this.repository = repository;
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void recordMatch(Long spotId, String googlePlaceId) {
        if (spotId == null || googlePlaceId == null || googlePlaceId.isBlank()) {
            return;
        }
        Instant now = Instant.now();
        GooglePlaceDetailsCache cache = repository.findById(spotId)
            .orElseGet(() -> new GooglePlaceDetailsCache(spotId, now));
        cache.recordMatch(googlePlaceId, now);
        repository.save(cache);
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void cacheDetails(Long spotId, ExternalPlaceDetails details, String payload, Duration ttl) {
        if (spotId == null || details == null || details.googlePlaceId() == null || details.googlePlaceId().isBlank()
            || payload == null || payload.isBlank()) {
            return;
        }
        Instant now = Instant.now();
        GooglePlaceDetailsCache cache = repository.findById(spotId)
            .orElseGet(() -> new GooglePlaceDetailsCache(spotId, now));
        cache.cacheDetails(details.googlePlaceId(), payload, now, ttl);
        repository.save(cache);
    }
}
