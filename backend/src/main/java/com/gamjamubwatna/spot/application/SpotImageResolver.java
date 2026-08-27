package com.gamjamubwatna.spot.application;

import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.infrastructure.TourApiClient;
import com.gamjamubwatna.spot.infrastructure.TourApiClient.TourApiSpotItem;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

@Service
public class SpotImageResolver {

    private static final Logger log = LoggerFactory.getLogger(SpotImageResolver.class);
    private static final String KAKAO_PLACE_PAGE_HOST = "place.map.kakao.com";

    private final TourApiClient tourApiClient;
    private final TourApiSpotReferenceResolver tourApiSpotReferenceResolver;
    private final SpotImageCacheWriter spotImageCacheWriter;
    private final Map<String, List<String>> tourApiImageCache = new ConcurrentHashMap<>();

    public SpotImageResolver(
        TourApiClient tourApiClient,
        SpotImageCacheWriter spotImageCacheWriter,
        TourApiSpotReferenceResolver tourApiSpotReferenceResolver
    ) {
        this.tourApiClient = tourApiClient;
        this.spotImageCacheWriter = spotImageCacheWriter;
        this.tourApiSpotReferenceResolver = tourApiSpotReferenceResolver;
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
        imageUrls.addAll(resolveStoredImageUrls(spot, limit));
        if (imageUrls.size() >= limit) {
            return List.copyOf(imageUrls);
        }
        for (String resolvedImageUrl : resolveTourApiImageUrls(spot, limit)) {
            if (imageUrls.size() >= limit) {
                break;
            }
            if (!imageUrls.contains(resolvedImageUrl)) {
                imageUrls.add(resolvedImageUrl);
            }
        }
        return List.copyOf(imageUrls);
    }

    public List<String> resolveStoredImageUrls(TouristSpot spot, int limit) {
        if (limit <= 0) {
            return List.of();
        }
        if (isRenderableImageUrl(spot.getImageUrl())) {
            return List.of(spot.getImageUrl());
        }
        return List.of();
    }

    public List<String> resolveTourApiImageUrls(TouristSpot spot, int limit) {
        if (limit <= 0) {
            return List.of();
        }
        Optional<TourApiSpotItem> reference = tourApiSpotReferenceResolver.resolve(spot);
        if (reference.isEmpty()) {
            return List.of();
        }
        String contentId = reference.get().contentId();
        List<String> resolvedImageUrls = tourApiImageCache.computeIfAbsent(
            contentId,
            this::fetchTourApiImagesOrEmpty
        );
        if (resolvedImageUrls.isEmpty()) {
            return List.of();
        }
        // 최초 조회 결과를 DB에 저장해 이후 목록 렌더링이 외부 API에 의존하지 않게 한다.
        if (!isRenderableImageUrl(spot.getImageUrl())) {
            spotImageCacheWriter.cacheResolvedImage(spot.getId(), resolvedImageUrls.get(0));
        }
        List<String> imageUrls = new ArrayList<>();
        for (String resolvedImageUrl : resolvedImageUrls) {
            if (imageUrls.size() >= limit) {
                break;
            }
            imageUrls.add(resolvedImageUrl);
        }
        return List.copyOf(imageUrls);
    }

    private List<String> fetchTourApiImagesOrEmpty(String contentId) {
        try {
            return tourApiClient.findRepresentativeImages(contentId, 3);
        } catch (RuntimeException exception) {
            log.warn(
                "TourAPI image fallback skipped. contentId={}, reason={}",
                contentId,
                exception.getClass().getSimpleName()
            );
            return List.of();
        }
    }

    private boolean hasText(String value) {
        return value != null && !value.isBlank();
    }

    private boolean isRenderableImageUrl(String value) {
        if (!hasText(value)) {
            return false;
        }
        try {
            URI uri = new URI(value);
            String scheme = uri.getScheme();
            String host = uri.getHost();
            if (!("http".equalsIgnoreCase(scheme) || "https".equalsIgnoreCase(scheme)) || host == null) {
                return false;
            }
            // Kakao 장소 상세 URL은 HTML 페이지이므로 Flutter Image.network에서 렌더링할 수 없다.
            return !KAKAO_PLACE_PAGE_HOST.equalsIgnoreCase(host);
        } catch (URISyntaxException exception) {
            return false;
        }
    }
}
