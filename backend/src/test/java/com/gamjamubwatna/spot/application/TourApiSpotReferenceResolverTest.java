package com.gamjamubwatna.spot.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.spot.domain.SpotCategory;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.infrastructure.TourApiClient;
import com.gamjamubwatna.spot.infrastructure.TourApiClient.TourApiSpotItem;
import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.Test;

class TourApiSpotReferenceResolverTest {

    private final TourApiClient tourApiClient = mock(TourApiClient.class);
    private final TourApiSpotReferenceResolver resolver = new TourApiSpotReferenceResolver(tourApiClient);

    @Test
    void resolvesCuratedSpotToTourApiContentByNameAndCity() {
        TouristSpot spot = spot("평창무이예술관", "평창군", "CURATED:NOTION:PYEONGCHANG_MUI_ART");
        TourApiSpotItem reference = item("12345", "평창무이예술관", "강원특별자치도 평창군 봉평면");
        when(tourApiClient.searchByKeyword("평창무이예술관 평창군", 10)).thenReturn(List.of(reference));

        Optional<TourApiSpotItem> result = resolver.resolve(spot);

        assertThat(result).contains(reference);
        verify(tourApiClient).searchByKeyword("평창무이예술관 평창군", 10);
    }

    @Test
    void doesNotUseAWeakTourApiMatch() {
        TouristSpot spot = spot("감자 카페", "정선군", "CURATED:NOTION:POTATO_CAFE");
        when(tourApiClient.searchByKeyword("감자 카페 정선군", 10)).thenReturn(List.of(
            item("99999", "서울 감자 축제", "서울특별시")
        ));
        when(tourApiClient.searchByKeyword("감자 카페", 10)).thenReturn(List.of());

        assertThat(resolver.resolve(spot)).isEmpty();
    }

    @Test
    void reusesNumericContentIdWithoutSearching() {
        TouristSpot spot = spot("남이섬", "춘천시", "12345");

        assertThat(resolver.resolve(spot))
            .hasValueSatisfying(item -> assertThat(item.contentId()).isEqualTo("12345"));
    }

    private TouristSpot spot(String name, String cityName, String contentId) {
        TouristSpot spot = mock(TouristSpot.class);
        when(spot.getId()).thenReturn(1L);
        when(spot.getName()).thenReturn(name);
        when(spot.getCityName()).thenReturn(cityName);
        when(spot.getAddress()).thenReturn("강원특별자치도 " + cityName);
        when(spot.getContentId()).thenReturn(contentId);
        when(spot.getContentTypeId()).thenReturn(12);
        when(spot.getCategory()).thenReturn(SpotCategory.POTATO_TOUR);
        when(spot.getLatitude()).thenReturn(new BigDecimal("37.6000000"));
        when(spot.getLongitude()).thenReturn(new BigDecimal("128.3000000"));
        return spot;
    }

    private TourApiSpotItem item(String contentId, String title, String address) {
        return new TourApiSpotItem(
            contentId,
            12,
            title,
            address,
            new BigDecimal("37.6001000"),
            new BigDecimal("128.3001000"),
            null
        );
    }
}
