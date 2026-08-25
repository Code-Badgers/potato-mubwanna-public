package com.gamjamubwatna.spot.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.spot.domain.SpotCategory;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.infrastructure.GooglePlacesClient;
import com.gamjamubwatna.spot.infrastructure.GooglePlacesClient.GooglePlaceSearchResult;
import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.Test;

class ExternalPlaceDetailsResolverTest {

    private final GooglePlacesClient googlePlacesClient = mock(GooglePlacesClient.class);
    private final ExternalPlaceDetailsResolver resolver = new ExternalPlaceDetailsResolver(
        googlePlacesClient,
        3600
    );

    @Test
    void resolvesGoogleDetailsForTrustedRestaurantMatchAndCachesResult() {
        TouristSpot spot = spot(1L, "토지옹심이 원주", SpotCategory.POTATO_RESTAURANT);
        when(googlePlacesClient.searchText("토지옹심이 원주 원주시"))
            .thenReturn(List.of(new GooglePlaceSearchResult(
                "google-place-id",
                "토지옹심이 원주",
                "강원특별자치도 원주시 감자길 1",
                new BigDecimal("37.9000100"),
                new BigDecimal("127.7000100")
            )));
        when(googlePlacesClient.findDetails("google-place-id"))
            .thenReturn(Optional.of(new ExternalPlaceDetails(
                "google-place-id",
                "033-000-0000",
                "https://example.com",
                4.4,
                new PlaceOpeningHours(true, "화요일: 오전 10:00~오후 8:00", List.of()),
                List.of("https://google.example.com/photo.jpg")
            )));

        ExternalPlaceDetails details = resolver.resolve(spot);
        ExternalPlaceDetails cached = resolver.resolve(spot);

        assertThat(details.googlePlaceId()).isEqualTo("google-place-id");
        assertThat(details.openingHours().openNow()).isTrue();
        assertThat(cached.imageUrls()).containsExactly("https://google.example.com/photo.jpg");
        verify(googlePlacesClient).searchText("토지옹심이 원주 원주시");
        verify(googlePlacesClient).findDetails("google-place-id");
    }

    @Test
    void skipsGoogleWhenMatchScoreIsLow() {
        TouristSpot spot = spot(2L, "카페수미", SpotCategory.POTATO_CAFE);
        when(googlePlacesClient.searchText("카페수미 평창군"))
            .thenReturn(List.of(new GooglePlaceSearchResult(
                "wrong-place-id",
                "다른 카페",
                "서울특별시",
                new BigDecimal("37.5000000"),
                new BigDecimal("126.9000000")
            )));

        ExternalPlaceDetails details = resolver.resolve(spot);

        assertThat(details).isEqualTo(ExternalPlaceDetails.empty());
    }

    @Test
    void skipsGoogleForTourismSpot() {
        TouristSpot spot = spot(3L, "남이섬", SpotCategory.POTATO_TOUR);

        ExternalPlaceDetails details = resolver.resolve(spot);

        assertThat(details).isEqualTo(ExternalPlaceDetails.empty());
    }

    private TouristSpot spot(Long id, String name, SpotCategory category) {
        TouristSpot spot = mock(TouristSpot.class);
        when(spot.getId()).thenReturn(id);
        when(spot.getName()).thenReturn(name);
        when(spot.getCategory()).thenReturn(category);
        when(spot.getLatitude()).thenReturn(new BigDecimal("37.9000000"));
        when(spot.getLongitude()).thenReturn(new BigDecimal("127.7000000"));
        when(spot.getAddress()).thenReturn("강원특별자치도 원주시 감자길 1");
        when(spot.getCityName()).thenReturn(category == SpotCategory.POTATO_CAFE ? "평창군" : "원주시");
        return spot;
    }
}
