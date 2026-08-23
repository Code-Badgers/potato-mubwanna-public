package com.gamjamubwatna.spot.application;

import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.infrastructure.TourApiClient;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

@Service
public class SpotImageResolver {

    private static final Logger log = LoggerFactory.getLogger(SpotImageResolver.class);

    private final TourApiClient tourApiClient;
    private final SpotImageCacheWriter spotImageCacheWriter;
    private final Map<String, String> tourApiImageCache = new ConcurrentHashMap<>();

    public SpotImageResolver(
        TourApiClient tourApiClient,
        SpotImageCacheWriter spotImageCacheWriter
    ) {
        this.tourApiClient = tourApiClient;
        this.spotImageCacheWriter = spotImageCacheWriter;
    }

    public String resolveImageUrl(TouristSpot spot) {
        if (hasText(spot.getImageUrl())) {
            return spot.getImageUrl();
        }
        String contentId = spot.getContentId();
        if (!isTourApiContentId(contentId)) {
            return null;
        }
        String resolvedImageUrl = tourApiImageCache.computeIfAbsent(contentId, this::fetchTourApiImageOrEmpty);
        if (resolvedImageUrl.isBlank()) {
            return null;
        }
        // 최초 조회 결과를 DB에 저장해 이후 목록 렌더링이 외부 API에 의존하지 않게 한다.
        spotImageCacheWriter.cacheResolvedImage(spot.getId(), resolvedImageUrl);
        return resolvedImageUrl;
    }

    private String fetchTourApiImageOrEmpty(String contentId) {
        try {
            return tourApiClient.findRepresentativeImage(contentId).orElse("");
        } catch (RuntimeException exception) {
            log.warn("TourAPI image fallback skipped. contentId={}, reason={}", contentId, exception.getMessage());
            return "";
        }
    }

    private boolean isTourApiContentId(String contentId) {
        return hasText(contentId) && contentId.chars().allMatch(Character::isDigit);
    }

    private boolean hasText(String value) {
        return value != null && !value.isBlank();
    }
}
