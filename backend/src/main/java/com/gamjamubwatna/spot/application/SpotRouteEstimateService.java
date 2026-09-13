package com.gamjamubwatna.spot.application;

import com.gamjamubwatna.spot.api.SpotRouteEstimateResponse;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.domain.TouristSpotRepository;
import com.gamjamubwatna.spot.infrastructure.KakaoMobilityDirectionsClient;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class SpotRouteEstimateService {

    private static final int MINIMUM_SPOT_COUNT = 2;
    private static final int MAXIMUM_SPOT_COUNT = 7;

    private final TouristSpotRepository touristSpotRepository;
    private final KakaoMobilityDirectionsClient directionsClient;
    private final long cacheTtlNanos;
    private final Map<List<Long>, CachedRouteEstimate> cache = new ConcurrentHashMap<>();

    public SpotRouteEstimateService(
        TouristSpotRepository touristSpotRepository,
        KakaoMobilityDirectionsClient directionsClient,
        @Value("${external.kakao-mobility.cache-ttl-seconds}") long cacheTtlSeconds
    ) {
        this.touristSpotRepository = touristSpotRepository;
        this.directionsClient = directionsClient;
        this.cacheTtlNanos = Math.max(0, cacheTtlSeconds) * 1_000_000_000L;
    }

    public SpotRouteEstimateResponse estimate(List<Long> spotIds) {
        validate(spotIds);
        List<Long> cacheKey = List.copyOf(spotIds);
        long now = System.nanoTime();
        CachedRouteEstimate cached = cache.get(cacheKey);
        if (cached != null && cached.expiresAtNanos() > now) {
            return cached.response();
        }
        List<TouristSpot> spots = activeSpotsInRequestOrder(spotIds);
        KakaoMobilityDirectionsClient.RouteEstimate estimate = directionsClient.estimate(spots);
        SpotRouteEstimateResponse response = new SpotRouteEstimateResponse(
            estimate.distanceMeters(),
            estimate.durationSeconds(),
            estimate.source()
        );
        if (cache.size() >= 256) {
            cache.entrySet().removeIf(entry -> entry.getValue().expiresAtNanos() <= now);
            if (cache.size() >= 256) {
                cache.clear();
            }
        }
        if (cacheTtlNanos > 0) {
            cache.put(cacheKey, new CachedRouteEstimate(response, now + cacheTtlNanos));
        }
        return response;
    }

    private void validate(List<Long> spotIds) {
        if (spotIds == null
            || spotIds.size() < MINIMUM_SPOT_COUNT
            || spotIds.size() > MAXIMUM_SPOT_COUNT) {
            throw new IllegalArgumentException("경로 장소는 2개 이상 7개 이하로 선택해주세요.");
        }
        if (spotIds.stream().anyMatch(id -> id == null || id <= 0)
            || new HashSet<>(spotIds).size() != spotIds.size()) {
            throw new IllegalArgumentException("경로 장소 ID를 중복 없이 확인해주세요.");
        }
    }

    private List<TouristSpot> activeSpotsInRequestOrder(List<Long> spotIds) {
        Map<Long, TouristSpot> activeSpotsById = touristSpotRepository.findAllById(spotIds).stream()
            .filter(spot -> Boolean.TRUE.equals(spot.isActive()))
            .collect(Collectors.toMap(TouristSpot::getId, Function.identity()));
        if (activeSpotsById.size() != spotIds.size()) {
            throw new IllegalArgumentException("활성 감자 스팟을 모두 찾을 수 없습니다.");
        }
        return spotIds.stream().map(activeSpotsById::get).toList();
    }

    private record CachedRouteEstimate(
        SpotRouteEstimateResponse response,
        long expiresAtNanos
    ) {
    }
}
