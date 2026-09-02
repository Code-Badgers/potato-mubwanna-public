package com.gamjamubwatna.spot.application;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gamjamubwatna.spot.domain.GooglePlaceDetailsCache;
import com.gamjamubwatna.spot.domain.GooglePlaceDetailsCacheRepository;
import com.gamjamubwatna.spot.domain.SpotCategory;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.infrastructure.GooglePlacesApiException;
import com.gamjamubwatna.spot.infrastructure.GooglePlacesClient;
import com.gamjamubwatna.spot.infrastructure.GooglePlacesClient.GooglePlaceSearchResult;
import java.math.BigDecimal;
import java.math.MathContext;
import java.text.Normalizer;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class ExternalPlaceDetailsResolver {

    private static final Logger log = LoggerFactory.getLogger(ExternalPlaceDetailsResolver.class);
    private static final double MIN_MATCH_SCORE = 0.62;
    private static final double EARTH_RADIUS_KM = 6371.0088;

    private final GooglePlacesClient googlePlacesClient;
    private final GooglePlaceDetailsCacheRepository googlePlaceDetailsCacheRepository;
    private final GooglePlaceDetailsCacheWriter googlePlaceDetailsCacheWriter;
    private final ObjectMapper objectMapper;
    private final Duration cacheTtl;
    private final Map<Long, CachedExternalPlaceDetails> cache = new ConcurrentHashMap<>();

    public ExternalPlaceDetailsResolver(
        GooglePlacesClient googlePlacesClient,
        GooglePlaceDetailsCacheRepository googlePlaceDetailsCacheRepository,
        GooglePlaceDetailsCacheWriter googlePlaceDetailsCacheWriter,
        ObjectMapper objectMapper,
        @Value("${external.google-places.cache-ttl-seconds}") long cacheTtlSeconds
    ) {
        this.googlePlacesClient = googlePlacesClient;
        this.googlePlaceDetailsCacheRepository = googlePlaceDetailsCacheRepository;
        this.googlePlaceDetailsCacheWriter = googlePlaceDetailsCacheWriter;
        this.objectMapper = objectMapper;
        this.cacheTtl = Duration.ofSeconds(Math.max(60, cacheTtlSeconds));
    }

    public ExternalPlaceDetails resolve(TouristSpot spot) {
        if (!shouldUseGooglePlaces(spot)) {
            return ExternalPlaceDetails.empty();
        }

        CachedExternalPlaceDetails cached = cache.get(spot.getId());
        if (cached != null && cached.isFresh(cacheTtl)) {
            log.info("spotId={} google enrichment cache=HIT", spot.getId());
            return cached.details();
        }

        Optional<GooglePlaceDetailsCache> persistedCache = googlePlaceDetailsCacheRepository.findById(spot.getId());
        Instant now = Instant.now();
        if (persistedCache.filter(value -> value.hasFreshDetails(now)).isPresent()) {
            Optional<ExternalPlaceDetails> persistedDetails = readCachedDetails(persistedCache.get());
            if (persistedDetails.isPresent()) {
                log.info("spotId={} google enrichment cache=HIT", spot.getId());
                cache.put(spot.getId(), new CachedExternalPlaceDetails(persistedDetails.get(), now));
                return persistedDetails.get();
            }
        }

        ExternalPlaceDetails details = fetchOrFallback(spot, persistedCache);
        cache.put(spot.getId(), new CachedExternalPlaceDetails(details, Instant.now()));
        return details;
    }

    public Map<Long, ExternalPlaceDetails> resolveCached(List<TouristSpot> spots) {
        Map<Long, ExternalPlaceDetails> detailsBySpotId = new HashMap<>();
        List<Long> persistedCacheSpotIds = new ArrayList<>();

        for (TouristSpot spot : spots) {
            if (!shouldUseGooglePlaces(spot)) {
                continue;
            }
            CachedExternalPlaceDetails cached = cache.get(spot.getId());
            if (cached != null) {
                detailsBySpotId.put(spot.getId(), cached.details());
            } else {
                persistedCacheSpotIds.add(spot.getId());
            }
        }

        if (persistedCacheSpotIds.isEmpty()) {
            return Map.copyOf(detailsBySpotId);
        }

        for (GooglePlaceDetailsCache persistedCache
            : googlePlaceDetailsCacheRepository.findAllById(persistedCacheSpotIds)) {
            Optional<ExternalPlaceDetails> details = readCachedDetails(persistedCache);
            if (details.isEmpty()) {
                continue;
            }
            Instant fetchedAt = Optional.ofNullable(persistedCache.getDetailsFetchedAt())
                .orElse(Instant.EPOCH);
            cache.put(
                persistedCache.getTouristSpotId(),
                new CachedExternalPlaceDetails(details.get(), fetchedAt)
            );
            detailsBySpotId.put(persistedCache.getTouristSpotId(), details.get());
        }
        return Map.copyOf(detailsBySpotId);
    }

    private ExternalPlaceDetails fetchOrFallback(
        TouristSpot spot,
        Optional<GooglePlaceDetailsCache> persistedCache
    ) {
        try {
            Optional<String> persistedPlaceId = persistedCache
                .map(GooglePlaceDetailsCache::getGooglePlaceId)
                .filter(value -> !value.isBlank());
            Optional<GooglePlaceSearchResult> match = Optional.empty();
            String googlePlaceId = persistedPlaceId.orElse(null);
            if (googlePlaceId == null) {
                match = findBestMatch(spot);
                if (match.isEmpty()) {
                    return fallbackFromCacheOrEmpty(spot, persistedCache);
                }
                googlePlaceId = match.get().placeId();
                googlePlaceDetailsCacheWriter.recordMatch(spot.getId(), googlePlaceId);
                log.info("spotId={} googlePlaceId={} match=SUCCESS", spot.getId(), googlePlaceId);
            }

            Optional<ExternalPlaceDetails> details = googlePlacesClient.findDetails(googlePlaceId);
            if (details.isEmpty()) {
                return fallbackFromCacheOrEmpty(spot, persistedCache);
            }
            logSources(spot, details.get());
            writeDetailsCache(spot.getId(), details.get());
            return details.get();
        } catch (GooglePlacesApiException exception) {
            log.warn(
                "Google Places enrichment skipped. spotId={}, status={}, reason={}",
                spot.getId(),
                exception.getStatusCode(),
                exception.getReason()
            );
            return fallbackFromCacheOrEmpty(spot, persistedCache);
        } catch (RuntimeException exception) {
            log.warn(
                "Google Places enrichment skipped. spotId={}, reason={}",
                spot.getId(),
                exception.getClass().getSimpleName()
            );
            return fallbackFromCacheOrEmpty(spot, persistedCache);
        }
    }

    private Optional<GooglePlaceSearchResult> findBestMatch(TouristSpot spot) {
        List<String> queries = searchQueries(spot);
        for (String query : queries) {
            List<GooglePlaceSearchResult> results = googlePlacesClient.searchText(query);
            Optional<ScoredPlace> best = results.stream()
                .map(result -> new ScoredPlace(result, score(spot, result)))
                .max(Comparator.comparingDouble(ScoredPlace::score));
            if (best.isPresent() && best.get().score() >= MIN_MATCH_SCORE) {
                return Optional.of(best.get().place());
            }
        }
        return Optional.empty();
    }

    private ExternalPlaceDetails fallbackFromCacheOrEmpty(
        TouristSpot spot,
        Optional<GooglePlaceDetailsCache> persistedCache
    ) {
        Optional<ExternalPlaceDetails> cachedDetails = persistedCache.flatMap(this::readCachedDetails);
        if (cachedDetails.isPresent()) {
            log.info("spotId={} google enrichment cache=STALE_FALLBACK", spot.getId());
            return cachedDetails.get();
        }
        return ExternalPlaceDetails.empty();
    }

    private Optional<ExternalPlaceDetails> readCachedDetails(GooglePlaceDetailsCache cache) {
        if (!cache.hasDetails()) {
            return Optional.empty();
        }
        try {
            return Optional.of(objectMapper.readValue(cache.getDetailsPayload(), ExternalPlaceDetails.class));
        } catch (JsonProcessingException exception) {
            log.warn(
                "Google Places cached payload skipped. spotId={}, reason={}",
                cache.getTouristSpotId(),
                exception.getMessage()
            );
            return Optional.empty();
        }
    }

    private void writeDetailsCache(Long spotId, ExternalPlaceDetails details) {
        try {
            googlePlaceDetailsCacheWriter.cacheDetails(
                spotId,
                details,
                objectMapper.writeValueAsString(details),
                cacheTtl
            );
        } catch (JsonProcessingException exception) {
            log.warn("Google Places cache payload skipped. spotId={}, reason={}", spotId, exception.getMessage());
        }
    }

    private void logSources(TouristSpot spot, ExternalPlaceDetails details) {
        if (details.imageUrls() != null && !details.imageUrls().isEmpty()) {
            log.info("spotId={} photoSource=GOOGLE", spot.getId());
        }
        if (details.openingHours() != null && details.openingHours().hasText()) {
            log.info("spotId={} openingHoursSource=GOOGLE", spot.getId());
        }
    }

    private List<String> searchQueries(TouristSpot spot) {
        List<String> queries = new ArrayList<>();
        addQuery(queries, "%s %s".formatted(spot.getName(), nullToEmpty(spot.getCityName())));
        addQuery(queries, "%s %s".formatted(spot.getName(), nullToEmpty(spot.getAddress())));
        addQuery(queries, "%s %s".formatted(spot.getName(), categoryKeyword(spot.getCategory())));
        return List.copyOf(queries);
    }

    private double score(TouristSpot spot, GooglePlaceSearchResult result) {
        double score = 0.0;
        String spotName = normalize(spot.getName());
        String resultName = normalize(result.name());
        String spotCity = normalize(spot.getCityName());
        String resultAddress = normalize(result.formattedAddress());

        if (!spotName.isBlank() && !resultName.isBlank()) {
            if (resultName.contains(spotName) || spotName.contains(resultName)) {
                score += 0.45;
            } else if (sharesNameToken(spotName, resultName)) {
                score += 0.24;
            }
        }
        if (!spotCity.isBlank() && resultAddress.contains(spotCity)) {
            score += 0.20;
        }
        Double distanceKm = distanceKm(spot, result);
        if (distanceKm != null) {
            if (distanceKm <= 0.3) {
                score += 0.30;
            } else if (distanceKm <= 1.0) {
                score += 0.20;
            } else if (distanceKm <= 3.0) {
                score += 0.10;
            } else {
                score -= 0.20;
            }
        }
        return Math.min(1.0, score);
    }

    private boolean shouldUseGooglePlaces(TouristSpot spot) {
        return switch (spot.getCategory()) {
            case POTATO_RESTAURANT,
                POTATO_CAFE,
                POTATO_SNACK,
                POTATO_BREWERY,
                POTATO_TOUR,
                POTATO_EXPERIENCE,
                POTATO_MARKET,
                POTATO_SHOP -> true;
            default -> false;
        };
    }

    private Double distanceKm(TouristSpot spot, GooglePlaceSearchResult result) {
        if (spot.getLatitude() == null || spot.getLongitude() == null
            || result.latitude() == null || result.longitude() == null) {
            return null;
        }
        double lat1 = toDouble(spot.getLatitude());
        double lon1 = toDouble(spot.getLongitude());
        double lat2 = toDouble(result.latitude());
        double lon2 = toDouble(result.longitude());
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
            + Math.cos(Math.toRadians(lat1))
            * Math.cos(Math.toRadians(lat2))
            * Math.sin(dLon / 2)
            * Math.sin(dLon / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return EARTH_RADIUS_KM * c;
    }

    private double toDouble(BigDecimal value) {
        return value.round(MathContext.DECIMAL64).doubleValue();
    }

    private boolean sharesNameToken(String spotName, String resultName) {
        for (String token : spotName.split("\\s+")) {
            if (token.length() >= 2 && resultName.contains(token)) {
                return true;
            }
        }
        return false;
    }

    private void addQuery(List<String> queries, String query) {
        String normalized = query.trim().replaceAll("\\s+", " ");
        if (!normalized.isBlank() && !queries.contains(normalized)) {
            queries.add(normalized);
        }
    }

    private String categoryKeyword(SpotCategory category) {
        return switch (category) {
            case POTATO_CAFE, POTATO_SNACK -> "카페";
            case POTATO_BREWERY -> "음식점";
            default -> "식당";
        };
    }

    private String normalize(String value) {
        if (value == null) {
            return "";
        }
        return Normalizer.normalize(value, Normalizer.Form.NFKC)
            .replaceAll("[^가-힣a-zA-Z0-9\\s]", "")
            .toLowerCase()
            .trim();
    }

    private String nullToEmpty(String value) {
        return value == null ? "" : value;
    }

    private record ScoredPlace(
        GooglePlaceSearchResult place,
        double score
    ) {
    }

    private record CachedExternalPlaceDetails(
        ExternalPlaceDetails details,
        Instant fetchedAt
    ) {
        boolean isFresh(Duration ttl) {
            return Instant.now().isBefore(fetchedAt.plus(ttl));
        }
    }
}
