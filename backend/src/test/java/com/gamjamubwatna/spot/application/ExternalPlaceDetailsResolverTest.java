package com.gamjamubwatna.spot.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gamjamubwatna.spot.domain.GooglePlaceDetailsCache;
import com.gamjamubwatna.spot.domain.GooglePlaceDetailsCacheRepository;
import com.gamjamubwatna.spot.domain.SpotCategory;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.infrastructure.GooglePlacesClient;
import com.gamjamubwatna.spot.infrastructure.GooglePlacesClient.GooglePlaceSearchResult;
import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.junit.jupiter.api.Test;

class ExternalPlaceDetailsResolverTest {

    private final GooglePlacesClient googlePlacesClient = mock(GooglePlacesClient.class);
    private final GooglePlaceDetailsCacheRepository googlePlaceDetailsCacheRepository =
        mock(GooglePlaceDetailsCacheRepository.class);
    private final GooglePlaceDetailsCacheWriter googlePlaceDetailsCacheWriter =
        mock(GooglePlaceDetailsCacheWriter.class);
    private final ObjectMapper objectMapper = new ObjectMapper();
    private final ExternalPlaceDetailsResolver resolver = new ExternalPlaceDetailsResolver(
        googlePlacesClient,
        googlePlaceDetailsCacheRepository,
        googlePlaceDetailsCacheWriter,
        objectMapper,
        3600
    );

    @Test
    void resolvesGoogleDetailsForTrustedRestaurantMatchAndCachesResult() {
        TouristSpot spot = spot(1L, "토지옹심이 원주", SpotCategory.POTATO_RESTAURANT);
        when(googlePlaceDetailsCacheRepository.findById(1L)).thenReturn(Optional.empty());
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
        when(googlePlaceDetailsCacheRepository.findById(2L)).thenReturn(Optional.empty());
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
    void usesFreshPersistedCacheBeforeCallingGoogle() throws JsonProcessingException {
        TouristSpot spot = spot(4L, "감자 카페", SpotCategory.POTATO_CAFE);
        ExternalPlaceDetails cachedDetails = googleDetails("google-place-id", "https://google.example.com/cached.jpg");
        GooglePlaceDetailsCache persistedCache = persistedCache(
            4L,
            cachedDetails,
            Instant.now(),
            Duration.ofHours(1)
        );
        when(googlePlaceDetailsCacheRepository.findById(4L)).thenReturn(Optional.of(persistedCache));

        ExternalPlaceDetails details = resolver.resolve(spot);

        assertThat(details.googlePlaceId()).isEqualTo("google-place-id");
        assertThat(details.imageUrls()).containsExactly("https://google.example.com/cached.jpg");
        verify(googlePlacesClient, never()).searchText(anyString());
        verify(googlePlacesClient, never()).findDetails(anyString());
    }

    @Test
    void resolvesCachedDetailsInBatchWithoutCallingGoogle() throws JsonProcessingException {
        TouristSpot spot = spot(7L, "감자 카페", SpotCategory.POTATO_CAFE);
        ExternalPlaceDetails cachedDetails = googleDetails(
            "google-place-id",
            "https://google.example.com/list.jpg"
        );
        GooglePlaceDetailsCache persistedCache = persistedCache(
            7L,
            cachedDetails,
            Instant.now().minus(Duration.ofDays(1)),
            Duration.ofSeconds(1)
        );
        when(googlePlaceDetailsCacheRepository.findAllById(List.of(7L)))
            .thenReturn(List.of(persistedCache));

        Map<Long, ExternalPlaceDetails> detailsBySpotId =
            resolver.resolveCached(List.of(spot));

        assertThat(detailsBySpotId.get(7L).imageUrls())
            .containsExactly("https://google.example.com/list.jpg");
        verify(googlePlacesClient, never()).searchText(anyString());
        verify(googlePlacesClient, never()).findDetails(anyString());
    }

    @Test
    void reusesPersistedGooglePlaceIdWithoutTextSearch() {
        TouristSpot spot = spot(5L, "감자 카페", SpotCategory.POTATO_CAFE);
        GooglePlaceDetailsCache persistedCache = new GooglePlaceDetailsCache(5L, Instant.now());
        persistedCache.recordMatch("google-place-id", Instant.now());
        when(googlePlaceDetailsCacheRepository.findById(5L)).thenReturn(Optional.of(persistedCache));
        when(googlePlacesClient.findDetails("google-place-id"))
            .thenReturn(Optional.of(googleDetails("google-place-id", "https://google.example.com/fresh.jpg")));

        ExternalPlaceDetails details = resolver.resolve(spot);

        assertThat(details.imageUrls()).containsExactly("https://google.example.com/fresh.jpg");
        verify(googlePlacesClient, never()).searchText(anyString());
        verify(googlePlacesClient).findDetails("google-place-id");
    }

    @Test
    void fallsBackToLastSuccessfulCacheWhenGoogleFails() throws JsonProcessingException {
        TouristSpot spot = spot(6L, "감자 카페", SpotCategory.POTATO_CAFE);
        ExternalPlaceDetails staleDetails = googleDetails("google-place-id", "https://google.example.com/stale.jpg");
        GooglePlaceDetailsCache persistedCache = persistedCache(
            6L,
            staleDetails,
            Instant.now().minus(Duration.ofHours(2)),
            Duration.ofSeconds(1)
        );
        when(googlePlaceDetailsCacheRepository.findById(6L)).thenReturn(Optional.of(persistedCache));
        when(googlePlacesClient.findDetails("google-place-id"))
            .thenThrow(new RuntimeException("timeout"));

        ExternalPlaceDetails details = resolver.resolve(spot);

        assertThat(details.googlePlaceId()).isEqualTo("google-place-id");
        assertThat(details.imageUrls()).containsExactly("https://google.example.com/stale.jpg");
        verify(googlePlacesClient, never()).searchText(anyString());
    }

    @Test
    void resolvesGoogleDetailsForTourismSpotWhenMatched() {
        TouristSpot spot = spot(3L, "남이섬", SpotCategory.POTATO_TOUR);
        when(googlePlaceDetailsCacheRepository.findById(3L)).thenReturn(Optional.empty());
        when(googlePlacesClient.searchText("남이섬 원주시"))
            .thenReturn(List.of(new GooglePlaceSearchResult(
                "google-tour-id",
                "남이섬",
                "강원특별자치도 원주시 감자길 1",
                new BigDecimal("37.9000100"),
                new BigDecimal("127.7000100")
            )));
        when(googlePlacesClient.findDetails("google-tour-id"))
            .thenReturn(Optional.of(googleDetails("google-tour-id", "https://google.example.com/nami.jpg")));

        ExternalPlaceDetails details = resolver.resolve(spot);

        assertThat(details.imageUrls()).containsExactly("https://google.example.com/nami.jpg");
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

    private ExternalPlaceDetails googleDetails(String googlePlaceId, String imageUrl) {
        return new ExternalPlaceDetails(
            googlePlaceId,
            "033-000-0000",
            "https://example.com",
            4.4,
            new PlaceOpeningHours(true, "화요일: 오전 10:00~오후 8:00", List.of()),
            List.of(imageUrl)
        );
    }

    private GooglePlaceDetailsCache persistedCache(
        Long spotId,
        ExternalPlaceDetails details,
        Instant fetchedAt,
        Duration ttl
    ) throws JsonProcessingException {
        GooglePlaceDetailsCache cache = new GooglePlaceDetailsCache(spotId, fetchedAt);
        cache.cacheDetails(details.googlePlaceId(), objectMapper.writeValueAsString(details), fetchedAt, ttl);
        return cache;
    }
}
