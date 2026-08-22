package com.gamjamubwatna.spot.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.auth.domain.AuthProvider;
import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.spot.api.FavoriteSpotToggleResponse;
import com.gamjamubwatna.spot.api.FavoriteSpotRouteResponse;
import com.gamjamubwatna.spot.domain.FavoriteSpot;
import com.gamjamubwatna.spot.domain.FavoriteSpotRepository;
import com.gamjamubwatna.spot.domain.SpotCategory;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.domain.TouristSpotRepository;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

class FavoriteSpotServiceTest {

    private final UserRepository userRepository = mock(UserRepository.class);
    private final TouristSpotRepository touristSpotRepository = mock(TouristSpotRepository.class);
    private final FavoriteSpotRepository favoriteSpotRepository = mock(FavoriteSpotRepository.class);

    private final FavoriteSpotService favoriteSpotService = new FavoriteSpotService(
        userRepository,
        touristSpotRepository,
        favoriteSpotRepository
    );

    @Test
    void addFavoriteSpotSavesUserRouteSpot() {
        User user = user(1L);
        TouristSpot spot = spot(10L);
        when(favoriteSpotRepository.existsByUserIdAndTouristSpotId(1L, 10L))
            .thenReturn(false);
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(touristSpotRepository.findByIdAndActiveTrue(10L)).thenReturn(Optional.of(spot));

        FavoriteSpotToggleResponse response = favoriteSpotService.addFavoriteSpot(1L, 10L);

        assertThat(response.spotId()).isEqualTo(10L);
        assertThat(response.favorite()).isTrue();
        verify(favoriteSpotRepository).save(any(FavoriteSpot.class));
    }

    @Test
    void addFavoriteSpotDoesNotSaveDuplicateRouteSpot() {
        when(favoriteSpotRepository.existsByUserIdAndTouristSpotId(1L, 10L))
            .thenReturn(true);

        FavoriteSpotToggleResponse response = favoriteSpotService.addFavoriteSpot(1L, 10L);

        assertThat(response.favorite()).isTrue();
        verify(userRepository, never()).findById(1L);
        verify(touristSpotRepository, never()).findByIdAndActiveTrue(10L);
        verify(favoriteSpotRepository, never()).save(any(FavoriteSpot.class));
    }

    @Test
    void removeFavoriteSpotIsIdempotent() {
        FavoriteSpot favoriteSpot = new FavoriteSpot(user(1L), spot(10L), Instant.parse("2026-06-21T00:00:00Z"));
        when(favoriteSpotRepository.findByUserIdAndTouristSpotId(1L, 10L))
            .thenReturn(Optional.of(favoriteSpot))
            .thenReturn(Optional.empty());

        FavoriteSpotToggleResponse firstResponse = favoriteSpotService.removeFavoriteSpot(1L, 10L);
        FavoriteSpotToggleResponse secondResponse = favoriteSpotService.removeFavoriteSpot(1L, 10L);

        assertThat(firstResponse.favorite()).isFalse();
        assertThat(secondResponse.favorite()).isFalse();
        verify(favoriteSpotRepository).delete(favoriteSpot);
    }

    @Test
    void getFavoriteSpotRouteUsesSavedRouteOrder() {
        User user = user(1L);
        TouristSpot jeongseon = spot(10L, "정선 5일장", "37.3801000", "128.6609000");
        TouristSpot gangneung = spot(20L, "강릉 감자빵 카페", "37.7519000", "128.8961000");
        TouristSpot chuncheon = spot(30L, "춘천 감자밭", "37.8813000", "127.7298000");
        when(favoriteSpotRepository.findByUserIdWithTouristSpot(1L))
            .thenReturn(List.of(
                new FavoriteSpot(user, jeongseon, Instant.parse("2026-06-21T03:00:00Z"), 1),
                new FavoriteSpot(user, chuncheon, Instant.parse("2026-06-21T02:00:00Z"), 2),
                new FavoriteSpot(user, gangneung, Instant.parse("2026-06-21T01:00:00Z"), 3)
            ));

        FavoriteSpotRouteResponse response = favoriteSpotService.getFavoriteSpotRoute(1L);

        assertThat(response.routeName()).isEqualTo("나만의 감자 동선");
        assertThat(response.waypoints()).extracting("spotId")
            .containsExactly(10L, 30L, 20L);
        assertThat(response.polyline()).hasSize(3);
        assertThat(response.totalDistanceKm()).isGreaterThan(0);
        assertThat(response.estimatedMinutes()).isGreaterThan(0);
        assertThat(response.waypoints().get(0).distanceFromPreviousKm()).isZero();
        assertThat(response.waypoints().get(1).distanceFromPreviousKm()).isGreaterThan(0);
    }

    @Test
    void getFavoriteSpotRouteReturnsEmptyRouteWhenFavoriteSpotIsEmpty() {
        when(favoriteSpotRepository.findByUserIdWithTouristSpot(1L))
            .thenReturn(List.of());

        FavoriteSpotRouteResponse response = favoriteSpotService.getFavoriteSpotRoute(1L);

        assertThat(response.totalDistanceKm()).isZero();
        assertThat(response.estimatedMinutes()).isZero();
        assertThat(response.waypoints()).isEmpty();
        assertThat(response.polyline()).isEmpty();
    }

    @Test
    void updateFavoriteSpotOrderPersistsUserSelectedOrder() {
        User user = user(1L);
        FavoriteSpot first = new FavoriteSpot(
            user,
            spot(10L, "정선 5일장", "37.3801000", "128.6609000"),
            Instant.parse("2026-06-21T03:00:00Z"),
            1
        );
        FavoriteSpot second = new FavoriteSpot(
            user,
            spot(20L, "강릉 감자빵 카페", "37.7519000", "128.8961000"),
            Instant.parse("2026-06-21T02:00:00Z"),
            2
        );
        FavoriteSpot third = new FavoriteSpot(
            user,
            spot(30L, "춘천 감자밭", "37.8813000", "127.7298000"),
            Instant.parse("2026-06-21T01:00:00Z"),
            3
        );
        when(favoriteSpotRepository.findByUserId(1L)).thenReturn(List.of(first, second, third));
        when(favoriteSpotRepository.findByUserIdWithTouristSpot(1L))
            .thenReturn(List.of(third, first, second));

        FavoriteSpotRouteResponse response = favoriteSpotService.updateFavoriteSpotOrder(1L, List.of(30L, 10L, 20L));

        assertThat(third.getRouteOrder()).isEqualTo(1);
        assertThat(first.getRouteOrder()).isEqualTo(2);
        assertThat(second.getRouteOrder()).isEqualTo(3);
        assertThat(response.waypoints()).extracting("spotId")
            .containsExactly(30L, 10L, 20L);
    }

    private User user(Long id) {
        User user = new User(
            AuthProvider.KAKAO,
            "123",
            "user@email.com",
            "감자러버",
            "https://example.com/profile.png",
            Instant.parse("2026-06-21T00:00:00Z")
        );
        ReflectionTestUtils.setField(user, "id", id);
        return user;
    }

    private TouristSpot spot(Long id) {
        return spot(id, "정선 감자옹심이", "37.3801000", "128.6609000");
    }

    private TouristSpot spot(Long id, String name, String latitude, String longitude) {
        TouristSpot spot = new TouristSpot(
            "content-10",
            39,
            name,
            SpotCategory.POTATO_RESTAURANT,
            new BigDecimal(latitude),
            new BigDecimal(longitude),
            "강원특별자치도 정선군",
            "정선군",
            "",
            "감자,옹심이",
            Instant.parse("2026-06-21T00:00:00Z")
        );
        ReflectionTestUtils.setField(spot, "id", id);
        return spot;
    }
}
