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
import com.gamjamubwatna.spot.domain.FavoriteSpot;
import com.gamjamubwatna.spot.domain.FavoriteSpotRepository;
import com.gamjamubwatna.spot.domain.SpotCategory;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.domain.TouristSpotRepository;
import java.math.BigDecimal;
import java.time.Instant;
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
        TouristSpot spot = new TouristSpot(
            "content-10",
            39,
            "정선 감자옹심이",
            SpotCategory.POTATO_RESTAURANT,
            new BigDecimal("37.3801000"),
            new BigDecimal("128.6609000"),
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
