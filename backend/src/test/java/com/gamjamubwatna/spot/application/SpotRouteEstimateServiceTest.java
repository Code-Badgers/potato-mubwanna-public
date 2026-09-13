package com.gamjamubwatna.spot.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.spot.api.SpotRouteEstimateResponse;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.domain.TouristSpotRepository;
import com.gamjamubwatna.spot.infrastructure.KakaoMobilityDirectionsClient;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

class SpotRouteEstimateServiceTest {

    private final TouristSpotRepository touristSpotRepository = mock(TouristSpotRepository.class);
    private final KakaoMobilityDirectionsClient directionsClient = mock(KakaoMobilityDirectionsClient.class);
    private final SpotRouteEstimateService service = new SpotRouteEstimateService(
        touristSpotRepository,
        directionsClient,
        900
    );

    @Test
    void preservesRequestedSpotOrderForRoadRoute() {
        TouristSpot first = activeSpot(1L);
        TouristSpot second = activeSpot(2L);
        TouristSpot third = activeSpot(3L);
        when(touristSpotRepository.findAllById(List.of(3L, 1L, 2L)))
            .thenReturn(List.of(first, second, third));
        when(directionsClient.estimate(List.of(third, first, second)))
            .thenReturn(new KakaoMobilityDirectionsClient.RouteEstimate(18400, 2760, "KAKAO_MOBILITY"));

        SpotRouteEstimateResponse response = service.estimate(List.of(3L, 1L, 2L));

        assertThat(response.distanceMeters()).isEqualTo(18400);
        assertThat(response.durationSeconds()).isEqualTo(2760);
        assertThat(response.source()).isEqualTo("KAKAO_MOBILITY");
        ArgumentCaptor<List<TouristSpot>> spots = ArgumentCaptor.forClass(List.class);
        verify(directionsClient).estimate(spots.capture());
        assertThat(spots.getValue()).containsExactly(third, first, second);

        assertThat(service.estimate(List.of(3L, 1L, 2L))).isEqualTo(response);
        verify(directionsClient).estimate(spots.capture());
    }

    @Test
    void rejectsDuplicateSpotIdsBeforeRepositoryLookup() {
        assertThatThrownBy(() -> service.estimate(List.of(1L, 1L)))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("중복 없이");
        verifyNoInteractions(touristSpotRepository, directionsClient);
    }

    @Test
    void rejectsInactiveOrMissingSpot() {
        TouristSpot first = activeSpot(1L);
        when(touristSpotRepository.findAllById(List.of(1L, 2L)))
            .thenReturn(List.of(first));

        assertThatThrownBy(() -> service.estimate(List.of(1L, 2L)))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("활성 감자 스팟");
        verifyNoInteractions(directionsClient);
    }

    private TouristSpot activeSpot(Long id) {
        TouristSpot spot = mock(TouristSpot.class);
        when(spot.getId()).thenReturn(id);
        when(spot.isActive()).thenReturn(true);
        return spot;
    }
}
