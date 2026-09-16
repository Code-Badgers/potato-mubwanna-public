package com.gamjamubwatna.spot.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verifyNoMoreInteractions;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.spot.domain.CongestionLevel;
import com.gamjamubwatna.spot.domain.SpotCategory;
import com.gamjamubwatna.spot.domain.SpotCongestionPrediction;
import com.gamjamubwatna.spot.domain.SpotCongestionPredictionRepository;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.domain.TouristSpotRepository;
import com.gamjamubwatna.spot.infrastructure.TourismCongestionApiClient;
import com.gamjamubwatna.spot.infrastructure.TourismCongestionApiClient.TourismCongestionPrediction;
import com.gamjamubwatna.spot.infrastructure.TourismCongestionApiException;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

class TourismCongestionSyncServiceTest {

    private TouristSpotRepository touristSpotRepository;
    private SpotCongestionPredictionRepository predictionRepository;
    private TourismCongestionApiClient apiClient;
    private TourismCongestionSyncService syncService;

    @BeforeEach
    void setUp() {
        touristSpotRepository = mock(TouristSpotRepository.class);
        predictionRepository = mock(SpotCongestionPredictionRepository.class);
        apiClient = mock(TourismCongestionApiClient.class);
        syncService = new TourismCongestionSyncService(
            touristSpotRepository,
            predictionRepository,
            apiClient,
            new CongestionLevelPolicy(),
            Clock.fixed(Instant.parse("2026-07-26T00:00:00Z"), ZoneOffset.UTC)
        );
    }

    @Test
    void syncsPredictionsAndUpdatesNearestFutureCongestionLevel() {
        TouristSpot spot = spot(1L, "123456");
        when(touristSpotRepository.findAllByActiveTrueOrderByIdAsc()).thenReturn(List.of(spot));
        when(apiClient.fetchPredictions("51770", "정선 5일장")).thenReturn(List.of(
            new TourismCongestionPrediction("정선 5일장", LocalDate.parse("2026-07-25"), 140),
            new TourismCongestionPrediction("정선 5일장", LocalDate.parse("2026-07-27"), 50),
            new TourismCongestionPrediction("정선 5일장", LocalDate.parse("2026-07-28"), 130)
        ));
        when(predictionRepository.findByTouristSpotIdAndPredictionDateAndSource(
            any(),
            any(),
            any()
        )).thenReturn(Optional.empty());
        when(predictionRepository.save(any(SpotCongestionPrediction.class)))
            .thenAnswer(invocation -> invocation.getArgument(0));

        TourismCongestionSyncResult result = syncService.syncActiveSpots();

        assertThat(result.targetSpotCount()).isEqualTo(1);
        assertThat(result.syncedSpotCount()).isEqualTo(1);
        assertThat(result.savedPredictionCount()).isEqualTo(3);
        assertThat(result.failedSpotCount()).isZero();
        assertThat(spot.getCongestionLevel()).isEqualTo(CongestionLevel.LOW);
    }

    @Test
    void updatesExistingPredictionForSameSpotDateAndSource() {
        TouristSpot spot = spot(1L, "123456");
        SpotCongestionPrediction existing = new SpotCongestionPrediction(
            spot,
            LocalDate.parse("2026-07-27"),
            50,
            100,
            CongestionLevel.LOW,
            "TOURISM_CONGESTION_API",
            Instant.parse("2026-07-20T00:00:00Z")
        );
        when(touristSpotRepository.findAllByActiveTrueOrderByIdAsc()).thenReturn(List.of(spot));
        when(apiClient.fetchPredictions("51770", "정선 5일장")).thenReturn(List.of(
            new TourismCongestionPrediction("정선 5일장", LocalDate.parse("2026-07-27"), 130)
        ));
        when(predictionRepository.findByTouristSpotIdAndPredictionDateAndSource(
            1L,
            LocalDate.parse("2026-07-27"),
            "TOURISM_CONGESTION_API"
        )).thenReturn(Optional.of(existing));
        when(predictionRepository.save(existing)).thenReturn(existing);

        TourismCongestionSyncResult result = syncService.syncActiveSpots();

        assertThat(result.savedPredictionCount()).isEqualTo(1);
        assertThat(existing.getPredictedVisitors()).isEqualTo(130);
        assertThat(existing.getBaselineVisitors()).isEqualTo(100);
        assertThat(existing.getCongestionLevel()).isEqualTo(CongestionLevel.HIGH);
        assertThat(spot.getCongestionLevel()).isEqualTo(CongestionLevel.HIGH);
    }

    @Test
    void keepsSyncGoingWhenOneSpotFails() {
        TouristSpot failedSpot = spot(1L, "failed", "실패 관광지");
        TouristSpot syncedSpot = spot(2L, "synced", "성공 관광지");
        when(touristSpotRepository.findAllByActiveTrueOrderByIdAsc()).thenReturn(List.of(failedSpot, syncedSpot));
        when(apiClient.fetchPredictions("51770", "실패 관광지")).thenThrow(new TourismCongestionApiException("API 오류"));
        when(apiClient.fetchPredictions("51770", "성공 관광지")).thenReturn(List.of(
            new TourismCongestionPrediction("성공 관광지", LocalDate.parse("2026-07-27"), 100)
        ));
        when(predictionRepository.findByTouristSpotIdAndPredictionDateAndSource(
            any(),
            any(),
            any()
        )).thenReturn(Optional.empty());
        when(predictionRepository.save(any(SpotCongestionPrediction.class)))
            .thenAnswer(invocation -> invocation.getArgument(0));

        TourismCongestionSyncResult result = syncService.syncActiveSpots();

        assertThat(result.targetSpotCount()).isEqualTo(2);
        assertThat(result.syncedSpotCount()).isEqualTo(1);
        assertThat(result.savedPredictionCount()).isEqualTo(1);
        assertThat(result.failedSpotCount()).isEqualTo(1);
        verify(apiClient).fetchPredictions("51770", "실패 관광지");
        verify(apiClient).fetchPredictions("51770", "성공 관광지");
    }

    @Test
    void skipsPlacesOutsideGangwonAndKeepsUnknownPredictionsEmpty() {
        TouristSpot outside = spot(1L, "outside", "도외 관광지", "가평군");
        TouristSpot unavailable = spot(2L, "curated", "예측 없는 장소", "정선군");
        when(touristSpotRepository.findAllByActiveTrueOrderByIdAsc())
            .thenReturn(List.of(outside, unavailable));
        when(apiClient.fetchPredictions("51770", "예측 없는 장소")).thenReturn(List.of());

        TourismCongestionSyncResult result = syncService.syncActiveSpots();

        assertThat(result.targetSpotCount()).isEqualTo(2);
        assertThat(result.syncedSpotCount()).isZero();
        assertThat(result.savedPredictionCount()).isZero();
        verify(apiClient).validateConfiguration();
        verify(apiClient).fetchPredictions("51770", "예측 없는 장소");
        verifyNoMoreInteractions(apiClient);
        verify(predictionRepository, never()).save(any(SpotCongestionPrediction.class));
    }

    @Test
    void stopsBeforePerSpotRequestsWhenTheServiceKeyIsMissing() {
        when(touristSpotRepository.findAllByActiveTrueOrderByIdAsc())
            .thenReturn(List.of(spot(1L, "123456")));
        doThrow(new TourismCongestionApiException("키 없음"))
            .when(apiClient).validateConfiguration();

        assertThatThrownBy(() -> syncService.syncActiveSpots())
            .isInstanceOf(TourismCongestionApiException.class)
            .hasMessageContaining("키 없음");
        verify(apiClient, never()).fetchPredictions("51770", "정선 5일장");
    }

    private TouristSpot spot(Long id, String contentId) {
        return spot(id, contentId, "정선 5일장");
    }

    private TouristSpot spot(Long id, String contentId, String name) {
        return spot(id, contentId, name, "정선군");
    }

    private TouristSpot spot(Long id, String contentId, String name, String cityName) {
        TouristSpot spot = new TouristSpot(
            contentId,
            12,
            name,
            SpotCategory.POTATO_TOUR,
            new BigDecimal("37.3801000"),
            new BigDecimal("128.6609000"),
            "강원특별자치도 정선군",
            cityName,
            null,
            "감자,시장",
            Instant.parse("2026-07-01T00:00:00Z")
        );
        ReflectionTestUtils.setField(spot, "id", id);
        return spot;
    }
}
