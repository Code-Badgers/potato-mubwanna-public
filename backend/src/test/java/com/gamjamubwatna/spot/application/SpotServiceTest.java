package com.gamjamubwatna.spot.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.anySet;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.spot.api.SpotDetailResponse;
import com.gamjamubwatna.spot.api.SpotListResponse;
import com.gamjamubwatna.spot.domain.CongestionLevel;
import com.gamjamubwatna.spot.domain.SpotCategory;
import com.gamjamubwatna.spot.domain.SpotMenuItem;
import com.gamjamubwatna.spot.domain.SpotMenuItemRepository;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.domain.TouristSpotRepository;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class SpotServiceTest {

    private final TouristSpotRepository touristSpotRepository = mock(TouristSpotRepository.class);
    private final SpotMenuItemRepository spotMenuItemRepository = mock(SpotMenuItemRepository.class);
    private final SpotImageResolver spotImageResolver = mock(SpotImageResolver.class);
    private final SpotTourInfoResolver spotTourInfoResolver = mock(SpotTourInfoResolver.class);
    private final ExternalPlaceDetailsResolver externalPlaceDetailsResolver = mock(ExternalPlaceDetailsResolver.class);
    private final TodayCongestionResolver todayCongestionResolver = mock(TodayCongestionResolver.class);
    private final HistoricalCongestionReferenceResolver historicalCongestionReferenceResolver =
        mock(HistoricalCongestionReferenceResolver.class);
    private final SpotService spotService = new SpotService(
        touristSpotRepository,
        spotMenuItemRepository,
        spotImageResolver,
        spotTourInfoResolver,
        externalPlaceDetailsResolver,
        todayCongestionResolver,
        historicalCongestionReferenceResolver
    );

    @BeforeEach
    void noHistoricalReferencesByDefault() {
        when(historicalCongestionReferenceResolver.resolve(anyList(), anySet())).thenReturn(Map.of());
    }

    @Test
    void returnsAtMostThreeMenuItemsForEachSpotAndAnEmptyListWithoutMenus() {
        TouristSpot cafe = spot(1L, "감자밭", SpotCategory.POTATO_CAFE);
        TouristSpot attraction = spot(2L, "남이섬", SpotCategory.POTATO_TOUR);
        when(spotImageResolver.resolveStoredImageUrls(cafe, 3))
            .thenReturn(List.of("https://example.com/cafe.jpg"));
        when(spotImageResolver.resolveStoredImageUrls(attraction, 3))
            .thenReturn(List.of("https://example.com/attraction.jpg"));
        when(externalPlaceDetailsResolver.resolveCached(anyList()))
            .thenReturn(java.util.Map.of());
        when(touristSpotRepository.findActiveSpots(null, null, null))
            .thenReturn(List.of(cafe, attraction));
        when(spotMenuItemRepository.findActiveByTouristSpotIds(anyCollection()))
            .thenReturn(List.of(
                menu(1L, "감자빵", 3300, 1),
                menu(1L, "감자빵 BOX(10ea)", 29700, 2),
                menu(1L, "아메리카노", 4800, 3),
                menu(1L, "카페라떼", 4800, 4)
            ));

        List<SpotListResponse> responses = spotService.getSpots(null, null, null);

        assertThat(responses.get(0).menuItems())
            .extracting(item -> item.name())
            .containsExactly("감자빵", "감자빵 BOX(10ea)", "아메리카노");
        assertThat(responses.get(0).imageUrl()).isEqualTo("https://example.com/cafe.jpg");
        assertThat(responses.get(0).imageUrls()).containsExactly("https://example.com/cafe.jpg");
        assertThat(responses.get(1).menuItems()).isEmpty();
        verify(externalPlaceDetailsResolver, never()).resolve(cafe);
        verify(spotImageResolver, never()).resolveTourApiImageUrls(cafe, 3);
    }

    @Test
    void appendsGooglePlaceDetailsForRestaurantAndCafeList() {
        TouristSpot cafe = spot(3L, "감자 카페", SpotCategory.POTATO_CAFE);
        when(touristSpotRepository.findActiveSpots(null, null, null))
            .thenReturn(List.of(cafe));
        when(spotImageResolver.resolveStoredImageUrls(cafe, 3))
            .thenReturn(List.of());
        when(spotMenuItemRepository.findActiveByTouristSpotIds(anyCollection()))
            .thenReturn(List.of(menu(3L, "감자라떼", 5500, 1)));
        ExternalPlaceDetails cachedDetails = new ExternalPlaceDetails(
                "google-place-id",
                "033-000-0000",
                "https://example.com",
                4.3,
                new PlaceOpeningHours(true, "화요일: 오전 11:00~오후 8:00", List.of("화요일: 오전 11:00~오후 8:00")),
                List.of("https://google.example.com/photo.jpg")
            );
        when(externalPlaceDetailsResolver.resolveCached(anyList()))
            .thenReturn(java.util.Map.of(3L, cachedDetails));

        List<SpotListResponse> responses = spotService.getSpots(null, null, null);

        assertThat(responses).hasSize(1);
        SpotListResponse response = responses.get(0);
        assertThat(response.imageUrl()).isEqualTo("https://google.example.com/photo.jpg");
        assertThat(response.imageUrls()).containsExactly("https://google.example.com/photo.jpg");
        assertThat(response.phone()).isEqualTo("033-000-0000");
        assertThat(response.website()).isEqualTo("https://example.com");
        assertThat(response.rating()).isEqualTo(4.3);
        assertThat(response.businessOpeningHours().todayText()).contains("오전 11:00");
        assertThat(response.menuItems())
            .extracting(item -> item.name())
            .containsExactly("감자라떼");
        verify(externalPlaceDetailsResolver, never()).resolve(cafe);
        verify(spotImageResolver, never()).resolveTourApiImageUrls(cafe, 3);
    }

    @Test
    void returnsTourApiSpotDetailInformation() {
        TouristSpot attraction = spot(2L, "평창무이예술관", SpotCategory.POTATO_TOUR);
        when(touristSpotRepository.findByIdAndActiveTrue(2L))
            .thenReturn(java.util.Optional.of(attraction));
        when(spotImageResolver.resolveStoredImageUrls(attraction, 3))
            .thenReturn(List.of("https://example.com/muei.jpg"));
        when(spotImageResolver.resolveTourApiImageUrls(attraction, 3))
            .thenReturn(List.of("https://tour.example.com/muei-2.jpg"));
        when(spotMenuItemRepository.findActiveByTouristSpotIds(anyCollection()))
            .thenReturn(List.of(
                menu(2L, "입장권", 5000, 1),
                menu(2L, "체험권", 12000, 2)
            ));
        when(spotTourInfoResolver.resolve(attraction))
            .thenReturn(new SpotTourInfo(
                "폐교를 예술 공간으로 꾸민 평창의 문화 관광지입니다.",
                "10:00 - 18:00",
                "월요일",
                "성인 5,000원",
                "가능",
                "033-000-0000"
            ));
        when(externalPlaceDetailsResolver.resolve(attraction))
            .thenReturn(ExternalPlaceDetails.empty());

        SpotDetailResponse response = spotService.getSpot(2L);

        assertThat(response.imageUrl()).isEqualTo("https://example.com/muei.jpg");
        assertThat(response.imageUrls())
            .containsExactly("https://example.com/muei.jpg", "https://tour.example.com/muei-2.jpg");
        assertThat(response.menuItems())
            .extracting(item -> item.name())
            .containsExactly("입장권", "체험권");
        assertThat(response.description()).contains("평창의 문화 관광지");
        assertThat(response.openingHours()).isEqualTo("10:00 - 18:00");
        assertThat(response.closedDays()).isEqualTo("월요일");
        assertThat(response.admissionFee()).isEqualTo("성인 5,000원");
        assertThat(response.parking()).isEqualTo("가능");
        assertThat(response.contactPhone()).isEqualTo("033-000-0000");
    }

    @Test
    void appendsGooglePlaceDetailsForRestaurantAndCafeDetail() {
        TouristSpot cafe = spot(3L, "감자 카페", SpotCategory.POTATO_CAFE);
        when(touristSpotRepository.findByIdAndActiveTrue(3L))
            .thenReturn(java.util.Optional.of(cafe));
        when(spotImageResolver.resolveStoredImageUrls(cafe, 3))
            .thenReturn(List.of("https://example.com/internal.jpg"));
        when(spotImageResolver.resolveTourApiImageUrls(cafe, 3))
            .thenReturn(List.of("https://tour.example.com/cafe.jpg"));
        when(spotMenuItemRepository.findActiveByTouristSpotIds(anyCollection()))
            .thenReturn(List.of(menu(3L, "감자라떼", 5500, 1)));
        when(spotTourInfoResolver.resolve(cafe))
            .thenReturn(SpotTourInfo.empty());
        when(externalPlaceDetailsResolver.resolve(cafe))
            .thenReturn(new ExternalPlaceDetails(
                "google-place-id",
                "033-000-0000",
                "https://example.com",
                4.3,
                new PlaceOpeningHours(true, "화요일: 오전 11:00~오후 8:00", List.of("화요일: 오전 11:00~오후 8:00")),
                List.of("https://google.example.com/photo.jpg")
            ));

        SpotDetailResponse response = spotService.getSpot(3L);

        assertThat(response.googlePlaceId()).isEqualTo("google-place-id");
        assertThat(response.phone()).isEqualTo("033-000-0000");
        assertThat(response.website()).isEqualTo("https://example.com");
        assertThat(response.rating()).isEqualTo(4.3);
        assertThat(response.businessOpeningHours().openNow()).isTrue();
        assertThat(response.businessOpeningHours().todayText()).contains("오전 11:00");
        assertThat(response.imageUrls())
            .containsExactly(
                "https://example.com/internal.jpg",
                "https://google.example.com/photo.jpg",
                "https://tour.example.com/cafe.jpg"
            );
    }

    @Test
    void filtersByTodayPredictionAndDoesNotExposeStoredNormalWithoutPrediction() {
        TouristSpot current = spot(1L, "오늘 예측 장소", SpotCategory.POTATO_TOUR);
        TouristSpot missing = spot(2L, "예측 없는 장소", SpotCategory.POTATO_TOUR);
        var prediction = new com.gamjamubwatna.spot.domain.SpotCongestionPrediction(
            current, LocalDate.of(2026, 9, 13), 10, 100, CongestionLevel.LOW,
            "TOURISM_CONGESTION_API", java.time.Instant.parse("2026-09-13T00:00:00Z"));
        when(touristSpotRepository.findActiveSpots(null, null, null)).thenReturn(List.of(current, missing));
        when(todayCongestionResolver.resolve(List.of(current, missing)))
            .thenReturn(java.util.Map.of(1L, prediction));

        var all = spotService.getSpots(null, null, null);
        assertThat(all.get(0).congestionLevel()).isEqualTo(CongestionLevel.LOW);
        assertThat(all.get(0).congestionPredictionDate()).isEqualTo(LocalDate.of(2026, 9, 13));
        assertThat(all.get(0).congestionSource()).isEqualTo("TOURISM_CONGESTION_API");
        assertThat(all.get(1).congestionLevel()).isNull();
        assertThat(all.get(1).congestionPredictionDate()).isNull();
        assertThat(all.get(1).congestionSource()).isNull();
        assertThat(all.get(1).congestionReferenceLevel()).isNull();
        assertThat(spotService.getSpots(null, null, CongestionLevel.LOW))
            .extracting(SpotListResponse::id).containsExactly(1L);
        assertThat(spotService.getSpots(null, null, CongestionLevel.NORMAL)).isEmpty();
        verify(touristSpotRepository, never()).findActiveSpots(null, null, CongestionLevel.LOW);
    }

    @Test
    void exposesPastPredictionOnlyAsSeparateReferenceWithoutChangingTodayFilter() {
        TouristSpot spot = spot(2L, "어제 예측 장소", SpotCategory.POTATO_TOUR);
        var reference = new com.gamjamubwatna.spot.domain.SpotCongestionPrediction(
            spot, LocalDate.of(2026, 9, 15), 20, 100, CongestionLevel.LOW,
            "TOURISM_CONGESTION_API", java.time.Instant.parse("2026-09-15T00:00:00Z"));
        when(touristSpotRepository.findActiveSpots(null, null, null)).thenReturn(List.of(spot));
        when(historicalCongestionReferenceResolver.resolve(List.of(spot), Set.of()))
            .thenReturn(Map.of(2L, reference));

        SpotListResponse response = spotService.getSpots(null, null, null).get(0);
        assertThat(response.congestionLevel()).isNull();
        assertThat(response.congestionReferenceLevel()).isEqualTo(CongestionLevel.LOW);
        assertThat(response.congestionReferenceDate()).isEqualTo(LocalDate.of(2026, 9, 15));
        assertThat(response.congestionReferenceSource()).isEqualTo("TOURISM_CONGESTION_API");
        assertThat(spotService.getSpots(null, null, CongestionLevel.LOW)).isEmpty();
    }

    private TouristSpot spot(Long id, String name, SpotCategory category) {
        TouristSpot spot = mock(TouristSpot.class);
        when(spot.getId()).thenReturn(id);
        when(spot.getName()).thenReturn(name);
        when(spot.getCategory()).thenReturn(category);
        when(spot.getLatitude()).thenReturn(new BigDecimal("37.9000000"));
        when(spot.getLongitude()).thenReturn(new BigDecimal("127.7000000"));
        when(spot.getContentId()).thenReturn("12345");
        when(spot.getContentTypeId()).thenReturn(12);
        when(spot.getAddress()).thenReturn("강원특별자치도");
        when(spot.getCityName()).thenReturn("춘천시");
        when(spot.getCongestionLevel()).thenReturn(CongestionLevel.NORMAL);
        when(spot.getStampEnabled()).thenReturn(true);
        return spot;
    }

    private SpotMenuItem menu(
        Long spotId,
        String name,
        Integer priceWon,
        Integer displayOrder
    ) {
        return new SpotMenuItem(
            spotId,
            name,
            priceWon,
            null,
            displayOrder,
            "https://place.map.kakao.com/example",
            LocalDate.of(2026, 8, 3)
        );
    }
}
