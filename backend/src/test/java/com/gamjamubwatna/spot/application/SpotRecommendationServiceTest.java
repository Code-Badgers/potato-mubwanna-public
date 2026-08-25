package com.gamjamubwatna.spot.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anySet;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.spot.domain.SpotCategory;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.domain.TouristSpotRepository;
import com.gamjamubwatna.spot.infrastructure.RelatedTourismApiClient;
import com.gamjamubwatna.spot.infrastructure.RelatedTourismApiClient.RelatedTourismSpot;
import com.gamjamubwatna.spot.infrastructure.RelatedTourismApiException;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class SpotRecommendationServiceTest {

    private static final Instant NOW = Instant.parse("2026-07-16T00:00:00Z");

    @Mock
    private TouristSpotRepository touristSpotRepository;

    @Mock
    private RelatedTourismApiClient relatedTourismApiClient;

    @Mock
    private SpotImageResolver spotImageResolver;

    @Mock
    private ExternalPlaceDetailsResolver externalPlaceDetailsResolver;

    private SpotRecommendationService service;

    @BeforeEach
    void setUp() {
        service = new SpotRecommendationService(
            touristSpotRepository,
            relatedTourismApiClient,
            new GangwonSignguCodeResolver(),
            spotImageResolver,
            externalPlaceDetailsResolver
        );
    }

    @Test
    void mapsLocalActiveSpotsInExternalRankOrderAndLimitsToThree() {
        TouristSpot current = spot(1L, "뮤지엄산", "원주시");
        TouristSpot first = spot(2L, "원주소금산출렁다리", "원주시");
        TouristSpot second = spot(3L, "간현관광지", "원주시");
        TouristSpot third = spot(4L, "원주전통시장", "원주시");
        TouristSpot fourth = spot(5L, "원주감자체험장", "원주시");
        when(touristSpotRepository.findByIdAndActiveTrue(1L)).thenReturn(Optional.of(current));
        when(relatedTourismApiClient.searchRelatedSpots("뮤지엄산", "51130")).thenReturn(List.of(
            item("뮤지엄산", "51130", "원주감자체험장", "4"),
            item("뮤지엄산", "51130", "간현관광지", "2"),
            item("다른 관광지", "51130", "제외 관광지", "1"),
            item("뮤지엄산", "51130", "원주소금산출렁다리", "1"),
            item("뮤지엄산", "51130", "원주전통시장", "3"),
            item("뮤지엄산", "51130", "원주소금산출렁다리", "5")
        ));
        when(touristSpotRepository.findActiveSpotsByNames(Set.of(
            "원주감자체험장",
            "간현관광지",
            "원주소금산출렁다리",
            "원주전통시장"
        ))).thenReturn(List.of(fourth, third, second, first));
        mockImages(first, "https://example.com/2.jpg");
        mockImages(second, "https://example.com/3.jpg");
        mockImages(third, "https://example.com/4.jpg");

        var result = service.getRecommendations(1L);

        assertThat(result).extracting(response -> response.spotId())
            .containsExactly(2L, 3L, 4L);
        assertThat(result).extracting(response -> response.externalRank())
            .containsExactly(1, 2, 3);
        assertThat(result).extracting(response -> response.imageUrl())
            .containsExactly(
                "https://example.com/2.jpg",
                "https://example.com/3.jpg",
                "https://example.com/4.jpg"
            );
    }

    @Test
    void enrichesRecommendationImagesWithGoogleAndTourApiFallbacks() {
        TouristSpot current = spot(1L, "뮤지엄산", "원주시");
        TouristSpot related = spot(2L, "원주소금산출렁다리", "원주시");
        when(touristSpotRepository.findByIdAndActiveTrue(1L)).thenReturn(Optional.of(current));
        when(relatedTourismApiClient.searchRelatedSpots("뮤지엄산", "51130")).thenReturn(List.of(
            item("뮤지엄산", "51130", "원주소금산출렁다리", "1")
        ));
        when(touristSpotRepository.findActiveSpotsByNames(Set.of("원주소금산출렁다리")))
            .thenReturn(List.of(related));
        when(spotImageResolver.resolveStoredImageUrls(related, 3)).thenReturn(List.of());
        when(externalPlaceDetailsResolver.resolve(related))
            .thenReturn(new ExternalPlaceDetails(
                "google-place-id",
                null,
                null,
                null,
                PlaceOpeningHours.empty(),
                List.of("https://google.example.com/photo.jpg")
            ));
        when(spotImageResolver.resolveTourApiImageUrls(related, 3))
            .thenReturn(List.of("https://tour.example.com/photo.jpg"));

        var result = service.getRecommendations(1L);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).imageUrl()).isEqualTo("https://google.example.com/photo.jpg");
        assertThat(result.get(0).imageUrls())
            .containsExactly("https://google.example.com/photo.jpg", "https://tour.example.com/photo.jpg");
    }

    @Test
    void returnsEmptyListWhenNoExactSourceSpotMatches() {
        TouristSpot current = spot(1L, "뮤지엄산", "원주시");
        when(touristSpotRepository.findByIdAndActiveTrue(1L)).thenReturn(Optional.of(current));
        when(relatedTourismApiClient.searchRelatedSpots("뮤지엄산", "51130"))
            .thenReturn(List.of(item("다른 관광지", "51130", "간현관광지", "1")));

        assertThat(service.getRecommendations(1L)).isEmpty();
        verify(touristSpotRepository, never()).findActiveSpotsByNames(anySet());
    }

    @Test
    void rejectsUnknownSpot() {
        when(touristSpotRepository.findByIdAndActiveTrue(99L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.getRecommendations(99L))
            .isInstanceOf(SpotRecommendationNotFoundException.class)
            .hasMessage("관광지를 찾을 수 없습니다.");
    }

    @Test
    void rejectsUnsupportedCity() {
        TouristSpot current = spot(1L, "서울 관광지", "서울특별시");
        when(touristSpotRepository.findByIdAndActiveTrue(1L)).thenReturn(Optional.of(current));

        assertThatThrownBy(() -> service.getRecommendations(1L))
            .isInstanceOf(SpotRecommendationNotFoundException.class)
            .hasMessageContaining("강원 시군구 코드");
        verifyNoInteractions(relatedTourismApiClient);
    }

    @Test
    void convertsExternalApiFailureToServiceUnavailableError() {
        TouristSpot current = spot(1L, "뮤지엄산", "원주시");
        when(touristSpotRepository.findByIdAndActiveTrue(1L)).thenReturn(Optional.of(current));
        when(relatedTourismApiClient.searchRelatedSpots("뮤지엄산", "51130"))
            .thenThrow(new RelatedTourismApiException("인증키 오류"));

        assertThatThrownBy(() -> service.getRecommendations(1L))
            .isInstanceOf(SpotRecommendationExternalException.class)
            .hasMessage("연관 관광지 제공 서비스에 연결할 수 없습니다.");
    }

    private TouristSpot spot(Long id, String name, String cityName) {
        TouristSpot spot = new TouristSpot(
            "content-%d".formatted(id),
            12,
            name,
            SpotCategory.POTATO_TOUR,
            new BigDecimal("37.3000000"),
            new BigDecimal("127.9000000"),
            "강원특별자치도 %s".formatted(cityName),
            cityName,
            "https://example.com/%d.jpg".formatted(id),
            "감자",
            NOW
        );
        ReflectionTestUtils.setField(spot, "id", id);
        return spot;
    }

    private void mockImages(TouristSpot spot, String imageUrl) {
        when(spotImageResolver.resolveStoredImageUrls(spot, 3)).thenReturn(List.of(imageUrl));
        when(externalPlaceDetailsResolver.resolve(spot)).thenReturn(ExternalPlaceDetails.empty());
        when(spotImageResolver.resolveTourApiImageUrls(spot, 3)).thenReturn(List.of());
    }

    private RelatedTourismSpot item(
        String sourceName,
        String sourceSignguCode,
        String relatedName,
        String rank
    ) {
        return new RelatedTourismSpot(
            "202504",
            "source-code",
            sourceName,
            "51",
            "강원특별자치도",
            sourceSignguCode,
            "원주시",
            "related-code",
            relatedName,
            "51",
            "강원특별자치도",
            "51130",
            "원주시",
            "관광지",
            "기타관광",
            "기타관광",
            rank
        );
    }
}
