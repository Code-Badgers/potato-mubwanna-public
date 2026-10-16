package com.gamjamubwatna.spot.application;

import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.infrastructure.TourApiClient;
import com.gamjamubwatna.spot.infrastructure.TourApiClient.TourApiSpotItem;
import java.math.BigDecimal;
import java.text.Normalizer;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

@Service
public class TourApiSpotReferenceResolver {

    private static final Logger log = LoggerFactory.getLogger(TourApiSpotReferenceResolver.class);
    private static final double MIN_MATCH_SCORE = 0.68;
    private static final double EARTH_RADIUS_KM = 6371.0088;

    private final TourApiClient tourApiClient;
    private final Map<String, Optional<TourApiSpotItem>> cache = new ConcurrentHashMap<>();

    public TourApiSpotReferenceResolver(TourApiClient tourApiClient) {
        this.tourApiClient = tourApiClient;
    }

    public Optional<TourApiSpotItem> resolve(TouristSpot spot) {
        String contentId = spot.getContentId();
        if (isNumericContentId(contentId)) {
            return Optional.of(new TourApiSpotItem(
                contentId,
                spot.getContentTypeId(),
                spot.getName(),
                spot.getAddress(),
                spot.getLatitude(),
                spot.getLongitude(),
                spot.getImageUrl()
            ));
        }
        if (isBlank(spot.getName())) {
            return Optional.empty();
        }

        String cacheKey = cacheKey(spot);
        return cache.computeIfAbsent(cacheKey, ignored -> findReference(spot));
    }

    public Optional<TourApiSpotItem> resolveCached(TouristSpot spot) {
        if (isNumericContentId(spot.getContentId())) {
            return Optional.of(new TourApiSpotItem(
                spot.getContentId(), spot.getContentTypeId(), spot.getName(), spot.getAddress(),
                spot.getLatitude(), spot.getLongitude(), spot.getImageUrl()
            ));
        }
        return cache.getOrDefault(cacheKey(spot), Optional.empty());
    }

    private Optional<TourApiSpotItem> findReference(TouristSpot spot) {
        try {
            for (String query : searchQueries(spot)) {
                Optional<ScoredItem> best = tourApiClient.searchByKeyword(query, 10).stream()
                    .map(item -> new ScoredItem(item, score(spot, item)))
                    .max(Comparator.comparingDouble(ScoredItem::score));
                if (best.isPresent() && best.get().score() >= MIN_MATCH_SCORE) {
                    TourApiSpotItem item = best.get().item();
                    log.info(
                        "spotId={} tourApiContentId={} match=SUCCESS",
                        spot.getId(),
                        item.contentId()
                    );
                    return Optional.of(item);
                }
            }
            log.info("spotId={} tourApiContentId=none match=MISS", spot.getId());
        } catch (RuntimeException exception) {
            log.warn(
                "TourAPI reference lookup skipped. spotId={}, reason={}",
                spot.getId(),
                exception.getClass().getSimpleName()
            );
        }
        return Optional.empty();
    }

    private List<String> searchQueries(TouristSpot spot) {
        String city = nullToEmpty(spot.getCityName());
        return List.of(
            "%s %s".formatted(spot.getName(), city).trim(),
            spot.getName().trim()
        ).stream().filter(query -> !query.isBlank()).distinct().toList();
    }

    private double score(TouristSpot spot, TourApiSpotItem item) {
        String spotName = normalize(spot.getName());
        String itemName = normalize(item.title());
        if (spotName.isBlank() || itemName.isBlank()) {
            return 0;
        }

        double score = 0;
        if (itemName.equals(spotName)) {
            score += 0.68;
        } else if (itemName.contains(spotName) || spotName.contains(itemName)) {
            score += 0.54;
        } else if (sharesNameToken(spotName, itemName)) {
            score += 0.36;
        }

        String city = normalize(spot.getCityName());
        String address = normalize(item.address());
        if (!city.isBlank() && address.contains(city)) {
            score += 0.17;
        }

        Double distanceKm = distanceKm(spot.getLatitude(), spot.getLongitude(), item.latitude(), item.longitude());
        if (distanceKm != null) {
            if (distanceKm <= 0.5) {
                score += 0.15;
            } else if (distanceKm <= 3) {
                score += 0.08;
            } else if (distanceKm > 15) {
                score -= 0.25;
            }
        }
        return Math.min(score, 1.0);
    }

    private boolean sharesNameToken(String left, String right) {
        for (String token : left.split("\\s+")) {
            if (token.length() >= 2 && right.contains(token)) {
                return true;
            }
        }
        return false;
    }

    private Double distanceKm(BigDecimal latitude1, BigDecimal longitude1, BigDecimal latitude2, BigDecimal longitude2) {
        if (latitude1 == null || longitude1 == null || latitude2 == null || longitude2 == null) {
            return null;
        }
        double lat1 = Math.toRadians(latitude1.doubleValue());
        double lat2 = Math.toRadians(latitude2.doubleValue());
        double deltaLat = lat2 - lat1;
        double deltaLon = Math.toRadians(longitude2.doubleValue() - longitude1.doubleValue());
        double a = Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2)
            + Math.cos(lat1) * Math.cos(lat2)
            * Math.sin(deltaLon / 2) * Math.sin(deltaLon / 2);
        return EARTH_RADIUS_KM * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }

    private String cacheKey(TouristSpot spot) {
        if (spot.getId() != null) {
            return "spot:" + spot.getId();
        }
        return "%s|%s|%s".formatted(spot.getName(), spot.getCityName(), spot.getAddress());
    }

    private boolean isNumericContentId(String contentId) {
        return !isBlank(contentId) && contentId.chars().allMatch(Character::isDigit);
    }

    private String normalize(String value) {
        if (isBlank(value)) {
            return "";
        }
        return Normalizer.normalize(value, Normalizer.Form.NFKC)
            .replaceAll("[^\\p{L}\\p{N}]", "")
            .toLowerCase();
    }

    private String nullToEmpty(String value) {
        return value == null ? "" : value;
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    private record ScoredItem(TourApiSpotItem item, double score) {
    }
}
