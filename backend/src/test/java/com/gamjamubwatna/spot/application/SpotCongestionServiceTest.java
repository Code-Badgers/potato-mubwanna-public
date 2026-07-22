package com.gamjamubwatna.spot.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.spot.api.SpotCongestionSyncRequest;
import com.gamjamubwatna.spot.api.SpotCongestionSyncResponse;
import com.gamjamubwatna.spot.domain.CongestionLevel;
import com.gamjamubwatna.spot.domain.SpotCategory;
import com.gamjamubwatna.spot.domain.SpotCongestionPrediction;
import com.gamjamubwatna.spot.domain.SpotCongestionPredictionRepository;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.domain.TouristSpotRepository;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

class SpotCongestionServiceTest {

    private TouristSpotRepository touristSpotRepository;
    private SpotCongestionPredictionRepository spotCongestionPredictionRepository;
    private SpotCongestionService spotCongestionService;

    @BeforeEach
    void setUp() {
        touristSpotRepository = mock(TouristSpotRepository.class);
        spotCongestionPredictionRepository = mock(SpotCongestionPredictionRepository.class);
        spotCongestionService = new SpotCongestionService(
            touristSpotRepository,
            spotCongestionPredictionRepository,
            new CongestionLevelPolicy(),
            Clock.fixed(Instant.parse("2026-07-22T00:00:00Z"), ZoneOffset.UTC)
        );
    }

    @Test
    void createsPredictionAndUpdatesSpotCongestionLevel() {
        TouristSpot spot = spot();
        LocalDate predictionDate = LocalDate.parse("2026-07-23");
        when(touristSpotRepository.findByIdAndActiveTrue(1L)).thenReturn(Optional.of(spot));
        when(spotCongestionPredictionRepository.findByTouristSpotIdAndPredictionDateAndSource(
            1L,
            predictionDate,
            "TOURISM_CONGESTION_API"
        )).thenReturn(Optional.empty());
        when(spotCongestionPredictionRepository.save(org.mockito.ArgumentMatchers.any(SpotCongestionPrediction.class)))
            .thenAnswer(invocation -> invocation.getArgument(0));

        SpotCongestionSyncResponse result = spotCongestionService.syncPrediction(
            1L,
            new SpotCongestionSyncRequest(predictionDate, 500, 1000, null)
        );

        assertThat(result.touristSpotId()).isEqualTo(1L);
        assertThat(result.congestionLevel()).isEqualTo(CongestionLevel.LOW);
        assertThat(result.source()).isEqualTo("TOURISM_CONGESTION_API");
        assertThat(spot.getCongestionLevel()).isEqualTo(CongestionLevel.LOW);
    }

    @Test
    void updatesExistingPredictionForSameSpotDateAndSource() {
        TouristSpot spot = spot();
        LocalDate predictionDate = LocalDate.parse("2026-07-23");
        SpotCongestionPrediction existing = new SpotCongestionPrediction(
            spot,
            predictionDate,
            500,
            1000,
            CongestionLevel.LOW,
            "TOURISM_CONGESTION_API",
            Instant.parse("2026-07-21T00:00:00Z")
        );
        when(touristSpotRepository.findByIdAndActiveTrue(1L)).thenReturn(Optional.of(spot));
        when(spotCongestionPredictionRepository.findByTouristSpotIdAndPredictionDateAndSource(
            1L,
            predictionDate,
            "TOURISM_CONGESTION_API"
        )).thenReturn(Optional.of(existing));
        when(spotCongestionPredictionRepository.save(existing)).thenReturn(existing);

        SpotCongestionSyncResponse result = spotCongestionService.syncPrediction(
            1L,
            new SpotCongestionSyncRequest(predictionDate, 1500, 1000, "TOURISM_CONGESTION_API")
        );

        assertThat(result.congestionLevel()).isEqualTo(CongestionLevel.HIGH);
        assertThat(existing.getPredictedVisitors()).isEqualTo(1500);
        assertThat(existing.getCongestionLevel()).isEqualTo(CongestionLevel.HIGH);
        assertThat(spot.getCongestionLevel()).isEqualTo(CongestionLevel.HIGH);
    }

    @Test
    void rejectsInvalidPredictionValues() {
        assertThatThrownBy(() -> spotCongestionService.syncPrediction(
            1L,
            new SpotCongestionSyncRequest(LocalDate.parse("2026-07-23"), 100, 0, null)
        ))
            .isInstanceOf(SpotCongestionException.class)
            .hasMessage("기준 방문자 수가 허용 범위를 벗어났습니다.");
    }

    private TouristSpot spot() {
        TouristSpot spot = new TouristSpot(
            "spot-1",
            12,
            "정선 5일장",
            SpotCategory.POTATO_TOUR,
            new BigDecimal("37.3801000"),
            new BigDecimal("128.6609000"),
            "강원특별자치도 정선군",
            "정선군",
            null,
            "감자,시장",
            Instant.parse("2026-07-01T00:00:00Z")
        );
        ReflectionTestUtils.setField(spot, "id", 1L);
        return spot;
    }
}
