package com.gamjamubwatna.spot.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

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
    private final SpotService spotService = new SpotService(
        touristSpotRepository,
        spotMenuItemRepository
    );

    @Test
    void returnsAtMostThreeMenuItemsForEachSpotAndAnEmptyListWithoutMenus() {
        TouristSpot cafe = spot(1L, "감자밭", SpotCategory.POTATO_CAFE);
        TouristSpot attraction = spot(2L, "남이섬", SpotCategory.POTATO_TOUR);
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
        assertThat(responses.get(1).menuItems()).isEmpty();
    }

    private TouristSpot spot(Long id, String name, SpotCategory category) {
        TouristSpot spot = mock(TouristSpot.class);
        when(spot.getId()).thenReturn(id);
        when(spot.getName()).thenReturn(name);
        when(spot.getCategory()).thenReturn(category);
        when(spot.getLatitude()).thenReturn(new BigDecimal("37.9000000"));
        when(spot.getLongitude()).thenReturn(new BigDecimal("127.7000000"));
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
