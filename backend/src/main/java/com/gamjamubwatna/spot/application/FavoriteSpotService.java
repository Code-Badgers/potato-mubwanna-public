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
import java.util.List;
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
        List<TouristSpot> routeSpots = recommendedRouteSpots(userId);
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
        favoriteSpotRepository.save(new FavoriteSpot(user, spot, Instant.now()));
        return new FavoriteSpotToggleResponse(spotId, true);
    }

    @Transactional
    public FavoriteSpotToggleResponse removeFavoriteSpot(Long userId, Long spotId) {
        favoriteSpotRepository.findByUserIdAndTouristSpotId(userId, spotId)
            .ifPresent(favoriteSpotRepository::delete);
        return new FavoriteSpotToggleResponse(spotId, false);
    }

    private List<TouristSpot> recommendedRouteSpots(Long userId) {
        List<TouristSpot> favoriteSpots = favoriteSpotRepository.findByUserIdWithTouristSpot(userId)
            .stream()
            .map(FavoriteSpot::getTouristSpot)
            .toList();
        if (favoriteSpots.size() <= 2) {
            return favoriteSpots;
        }

        List<TouristSpot> remaining = new ArrayList<>(favoriteSpots);
        List<TouristSpot> route = new ArrayList<>();
        TouristSpot current = remaining.remove(0);
        route.add(current);

        // 외부 길찾기 최적화 전까지는 최근 저장한 장소에서 가까운 장소를 잇는 예측 가능한 MVP 경로를 쓴다.
        while (!remaining.isEmpty()) {
            TouristSpot origin = current;
            TouristSpot next = remaining.stream()
                .min((first, second) -> Double.compare(distanceKm(origin, first), distanceKm(origin, second)))
                .orElseThrow();
            remaining.remove(next);
            route.add(next);
            current = next;
        }
        return route;
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
