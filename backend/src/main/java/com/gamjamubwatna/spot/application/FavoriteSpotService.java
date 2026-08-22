package com.gamjamubwatna.spot.application;

import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.spot.api.FavoriteSpotResponse;
import com.gamjamubwatna.spot.api.FavoriteSpotRoutePointResponse;
import com.gamjamubwatna.spot.api.FavoriteSpotRouteResponse;
import com.gamjamubwatna.spot.api.FavoriteSpotRouteWaypointResponse;
import com.gamjamubwatna.spot.api.FavoriteSpotToggleResponse;
import com.gamjamubwatna.spot.domain.FavoriteSpot;
import com.gamjamubwatna.spot.domain.FavoriteSpotRepository;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.domain.TouristSpotRepository;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class FavoriteSpotService {

    private static final double EARTH_RADIUS_KM = 6371.0088;
    private static final double AVERAGE_TRAVEL_SPEED_KMH = 25.0;

    private final UserRepository userRepository;
    private final TouristSpotRepository touristSpotRepository;
    private final FavoriteSpotRepository favoriteSpotRepository;

    public FavoriteSpotService(
        UserRepository userRepository,
        TouristSpotRepository touristSpotRepository,
        FavoriteSpotRepository favoriteSpotRepository
    ) {
        this.userRepository = userRepository;
        this.touristSpotRepository = touristSpotRepository;
        this.favoriteSpotRepository = favoriteSpotRepository;
    }

    @Transactional(readOnly = true)
    public List<FavoriteSpotResponse> getFavoriteSpots(Long userId) {
        return favoriteSpotRepository.findByUserIdWithTouristSpot(userId)
            .stream()
            .map(FavoriteSpotResponse::from)
            .toList();
    }

    @Transactional(readOnly = true)
    public FavoriteSpotRouteResponse getFavoriteSpotRoute(Long userId) {
        List<TouristSpot> routeSpots = orderedRouteSpots(userId);
        List<FavoriteSpotRouteWaypointResponse> waypoints = new ArrayList<>();
        double totalDistanceKm = 0;

        for (int index = 0; index < routeSpots.size(); index++) {
            TouristSpot spot = routeSpots.get(index);
            double distanceFromPreviousKm = index == 0
                ? 0
                : distanceKm(routeSpots.get(index - 1), spot);
            totalDistanceKm += distanceFromPreviousKm;
            waypoints.add(new FavoriteSpotRouteWaypointResponse(
                index + 1,
                spot.getId(),
                spot.getName(),
                spot.getCategory(),
                spot.getLatitude(),
                spot.getLongitude(),
                rounded(distanceFromPreviousKm)
            ));
        }

        return new FavoriteSpotRouteResponse(
            "나만의 감자 동선",
            rounded(totalDistanceKm),
            estimatedMinutes(totalDistanceKm),
            waypoints,
            routeSpots.stream()
                .map(spot -> new FavoriteSpotRoutePointResponse(spot.getLatitude(), spot.getLongitude()))
                .toList()
        );
    }

    @Transactional
    public FavoriteSpotToggleResponse addFavoriteSpot(Long userId, Long spotId) {
        if (favoriteSpotRepository.existsByUserIdAndTouristSpotId(userId, spotId)) {
            return new FavoriteSpotToggleResponse(spotId, true);
        }

        User user = userRepository.findById(userId)
            .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
        TouristSpot spot = touristSpotRepository.findByIdAndActiveTrue(spotId)
            .orElseThrow(() -> new IllegalArgumentException("감자 스팟을 찾을 수 없습니다."));

        // 같은 사용자가 같은 스팟을 중복 저장하지 않도록 DB unique key와 서비스 idempotency를 함께 둔다.
        int nextRouteOrder = favoriteSpotRepository.findMaxRouteOrderByUserId(userId) + 1;
        favoriteSpotRepository.save(new FavoriteSpot(user, spot, Instant.now(), nextRouteOrder));
        return new FavoriteSpotToggleResponse(spotId, true);
    }

    @Transactional
    public FavoriteSpotToggleResponse removeFavoriteSpot(Long userId, Long spotId) {
        favoriteSpotRepository.findByUserIdAndTouristSpotId(userId, spotId)
            .ifPresent(favoriteSpotRepository::delete);
        return new FavoriteSpotToggleResponse(spotId, false);
    }

    @Transactional
    public FavoriteSpotRouteResponse updateFavoriteSpotOrder(Long userId, List<Long> spotIds) {
        if (spotIds == null) {
            throw new IllegalArgumentException("동선 순서를 확인해주세요.");
        }
        List<FavoriteSpot> favoriteSpots = favoriteSpotRepository.findByUserId(userId);
        if (favoriteSpots.size() != spotIds.size()) {
            throw new IllegalArgumentException("저장된 동선 장소를 모두 포함해야 합니다.");
        }

        Map<Long, FavoriteSpot> favoriteSpotBySpotId = favoriteSpots.stream()
            .collect(Collectors.toMap(favorite -> favorite.getTouristSpot().getId(), Function.identity()));
        if (new HashSet<>(spotIds).size() != spotIds.size()
            || !favoriteSpotBySpotId.keySet().equals(new HashSet<>(spotIds))) {
            throw new IllegalArgumentException("저장된 동선 장소만 순서를 변경할 수 있습니다.");
        }

        for (int index = 0; index < spotIds.size(); index++) {
            favoriteSpotBySpotId.get(spotIds.get(index)).updateRouteOrder(index + 1);
        }

        return getFavoriteSpotRoute(userId);
    }

    private List<TouristSpot> orderedRouteSpots(Long userId) {
        return favoriteSpotRepository.findByUserIdWithTouristSpot(userId)
            .stream()
            .map(FavoriteSpot::getTouristSpot)
            .toList();
    }

    private double distanceKm(TouristSpot from, TouristSpot to) {
        double fromLatitude = toRadians(from.getLatitude());
        double toLatitude = toRadians(to.getLatitude());
        double latitudeDelta = toRadians(to.getLatitude().subtract(from.getLatitude()));
        double longitudeDelta = toRadians(to.getLongitude().subtract(from.getLongitude()));

        double a = Math.sin(latitudeDelta / 2) * Math.sin(latitudeDelta / 2)
            + Math.cos(fromLatitude) * Math.cos(toLatitude)
            * Math.sin(longitudeDelta / 2) * Math.sin(longitudeDelta / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return EARTH_RADIUS_KM * c;
    }

    private double toRadians(BigDecimal value) {
        return Math.toRadians(value.doubleValue());
    }

    private int estimatedMinutes(double totalDistanceKm) {
        if (totalDistanceKm <= 0) {
            return 0;
        }
        return (int) Math.ceil((totalDistanceKm / AVERAGE_TRAVEL_SPEED_KMH) * 60);
    }

    private double rounded(double value) {
        return Math.round(value * 10.0) / 10.0;
    }
}
