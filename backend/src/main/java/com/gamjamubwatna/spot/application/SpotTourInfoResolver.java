package com.gamjamubwatna.spot.application;

import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.infrastructure.TourApiClient;
import com.gamjamubwatna.spot.infrastructure.TourApiClient.TourApiSpotItem;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

@Service
public class SpotTourInfoResolver {

    private static final Logger log = LoggerFactory.getLogger(SpotTourInfoResolver.class);

    private final TourApiClient tourApiClient;
    private final TourApiSpotReferenceResolver tourApiSpotReferenceResolver;
    private final Map<String, SpotTourInfo> tourInfoCache = new ConcurrentHashMap<>();

    public SpotTourInfoResolver(
        TourApiClient tourApiClient,
        TourApiSpotReferenceResolver tourApiSpotReferenceResolver
    ) {
        this.tourApiClient = tourApiClient;
        this.tourApiSpotReferenceResolver = tourApiSpotReferenceResolver;
    }

    public SpotTourInfo resolve(TouristSpot spot) {
        Optional<TourApiSpotItem> reference = tourApiSpotReferenceResolver.resolve(spot);
        if (reference.isEmpty()) {
            return SpotTourInfo.empty();
        }
        TourApiSpotItem item = reference.get();
        return tourInfoCache.computeIfAbsent(
            item.contentId(),
            contentId -> fetchTourInfoOrEmpty(contentId, item.contentTypeId())
        );
    }

    public SpotTourInfo resolveCached(TouristSpot spot) {
        return tourApiSpotReferenceResolver.resolveCached(spot)
            .map(item -> tourInfoCache.getOrDefault(item.contentId(), SpotTourInfo.empty()))
            .orElseGet(SpotTourInfo::empty);
    }

    private SpotTourInfo fetchTourInfoOrEmpty(String contentId, Integer contentTypeId) {
        try {
            return tourApiClient.findSpotTourInfo(contentId, contentTypeId)
                .orElseGet(SpotTourInfo::empty);
        } catch (RuntimeException exception) {
            log.warn(
                "TourAPI detail fallback skipped. contentId={}, reason={}",
                contentId,
                exception.getClass().getSimpleName()
            );
            return SpotTourInfo.empty();
        }
    }

}
