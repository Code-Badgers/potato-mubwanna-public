package com.gamjamubwatna.spot.application;

import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.infrastructure.TourApiClient;
import java.util.ArrayList;
import java.util.List;
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
    private final Map<String, List<String>> tourApiImageCache = new ConcurrentHashMap<>();

    public SpotImageResolver(
        TourApiClient tourApiClient,
        SpotImageCacheWriter spotImageCacheWriter
    ) {
        this.tourApiClient = tourApiClient;
        this.spotImageCacheWriter = spotImageCacheWriter;
    }

    public String resolveImageUrl(TouristSpot spot) {
        List<String> imageUrls = resolveImageUrls(spot, 1);
        return imageUrls.isEmpty() ? null : imageUrls.get(0);
    }

    public List<String> resolveImageUrls(TouristSpot spot, int limit) {
        if (limit <= 0) {
            return List.of();
        }
        List<String> imageUrls = new ArrayList<>();
        if (hasText(spot.getImageUrl())) {
            imageUrls.add(spot.getImageUrl());
            if (limit == 1) {
                return imageUrls;
            }
        }
        String contentId = spot.getContentId();
        if (!isTourApiContentId(contentId)) {
            return imageUrls;
        }
        List<String> resolvedImageUrls = tourApiImageCache.computeIfAbsent(
            contentId,
            this::fetchTourApiImagesOrEmpty
        );
        if (resolvedImageUrls.isEmpty()) {
            return imageUrls;
        }
        // 최초 조회 결과를 DB에 저장해 이후 목록 렌더링이 외부 API에 의존하지 않게 한다.
        if (!hasText(spot.getImageUrl())) {
            spotImageCacheWriter.cacheResolvedImage(spot.getId(), resolvedImageUrls.get(0));
        }
        for (String resolvedImageUrl : resolvedImageUrls) {
            if (imageUrls.size() >= limit) {
                break;
            }
            if (!imageUrls.contains(resolvedImageUrl)) {
                imageUrls.add(resolvedImageUrl);
            }
        }
        return List.copyOf(imageUrls);
    }

    private List<String> fetchTourApiImagesOrEmpty(String contentId) {
        try {
            return tourApiClient.findRepresentativeImages(contentId, 3);
        } catch (RuntimeException exception) {
            log.warn("TourAPI image fallback skipped. contentId={}, reason={}", contentId, exception.getMessage());
            return List.of();
        }
    }

    private boolean isTourApiContentId(String contentId) {
        return hasText(contentId) && contentId.chars().allMatch(Character::isDigit);
    }

    private boolean hasText(String value) {
        return value != null && !value.isBlank();
    }
}
