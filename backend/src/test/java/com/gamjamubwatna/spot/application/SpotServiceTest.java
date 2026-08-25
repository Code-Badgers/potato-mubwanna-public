package com.gamjamubwatna.spot.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.Mockito.mock;
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
import org.junit.jupiter.api.Test;

class SpotServiceTest {

    private final TouristSpotRepository touristSpotRepository = mock(TouristSpotRepository.class);
    private final SpotMenuItemRepository spotMenuItemRepository = mock(SpotMenuItemRepository.class);
    private final SpotImageResolver spotImageResolver = mock(SpotImageResolver.class);
    private final SpotTourInfoResolver spotTourInfoResolver = mock(SpotTourInfoResolver.class);
    private final ExternalPlaceDetailsResolver externalPlaceDetailsResolver = mock(ExternalPlaceDetailsResolver.class);
    private final SpotService spotService = new SpotService(
        touristSpotRepository,
        spotMenuItemRepository,
        spotImageResolver,
        spotTourInfoResolver,
        externalPlaceDetailsResolver
    );

    @Test
    void returnsAtMostThreeMenuItemsForEachSpotAndAnEmptyListWithoutMenus() {
        TouristSpot cafe = spot(1L, "감자밭", SpotCategory.POTATO_CAFE);
        TouristSpot attraction = spot(2L, "남이섬", SpotCategory.POTATO_TOUR);
        when(spotImageResolver.resolveImageUrl(cafe))
            .thenReturn("https://example.com/cafe.jpg");
        when(spotImageResolver.resolveImageUrl(attraction))
            .thenReturn("https://example.com/attraction.jpg");
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
        assertThat(responses.get(1).menuItems()).isEmpty();
    }

    @Test
    void returnsTourApiSpotDetailInformation() {
        TouristSpot attraction = spot(2L, "평창무이예술관", SpotCategory.POTATO_TOUR);
        when(touristSpotRepository.findByIdAndActiveTrue(2L))
            .thenReturn(java.util.Optional.of(attraction));
        when(spotImageResolver.resolveImageUrl(attraction))
            .thenReturn("https://example.com/muei.jpg");
        when(spotImageResolver.resolveImageUrls(attraction, 3))
            .thenReturn(List.of(
                "https://example.com/muei.jpg",
                "https://tour.example.com/muei-2.jpg"
            ));
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
        when(spotImageResolver.resolveImageUrls(cafe, 3))
            .thenReturn(List.of("https://example.com/internal.jpg"));
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
                "https://google.example.com/photo.jpg"
            );
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
