package com.gamjamubwatna.spot.application;

import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.infrastructure.TourApiClient;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

@Service
public class SpotTourInfoResolver {

    private static final Logger log = LoggerFactory.getLogger(SpotTourInfoResolver.class);

    private final TourApiClient tourApiClient;
    private final Map<String, SpotTourInfo> tourInfoCache = new ConcurrentHashMap<>();

    public SpotTourInfoResolver(TourApiClient tourApiClient) {
        this.tourApiClient = tourApiClient;
    }

    public SpotTourInfo resolve(TouristSpot spot) {
        if (!isTourApiContentId(spot.getContentId())) {
            return SpotTourInfo.empty();
        }
        return tourInfoCache.computeIfAbsent(
            spot.getContentId(),
            contentId -> fetchTourInfoOrEmpty(contentId, spot.getContentTypeId())
        );
    }

    private SpotTourInfo fetchTourInfoOrEmpty(String contentId, Integer contentTypeId) {
        try {
            return tourApiClient.findSpotTourInfo(contentId, contentTypeId)
                .orElseGet(SpotTourInfo::empty);
        } catch (RuntimeException exception) {
            log.warn("TourAPI detail fallback skipped. contentId={}, reason={}", contentId, exception.getMessage());
            return SpotTourInfo.empty();
        }
    }

    private boolean isTourApiContentId(String contentId) {
        return contentId != null && !contentId.isBlank()
            && contentId.chars().allMatch(Character::isDigit);
    }
}
