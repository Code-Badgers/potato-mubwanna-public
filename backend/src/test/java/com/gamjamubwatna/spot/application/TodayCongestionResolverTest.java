package com.gamjamubwatna.spot.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;
import com.gamjamubwatna.spot.domain.*;
import java.time.*;
import java.util.*;
import org.junit.jupiter.api.Test;

class TodayCongestionResolverTest {
    private final SpotCongestionPredictionRepository repository = mock(SpotCongestionPredictionRepository.class);
    private final Clock clock = Clock.fixed(Instant.parse("2026-09-12T15:30:00Z"), ZoneOffset.UTC);
    private final TodayCongestionResolver resolver = new TodayCongestionResolver(repository, clock);
    private final LocalDate today = LocalDate.of(2026, 9, 13);

    @Test
    void usesKoreanDateAndOneBatchQueryWithNewestSourceFirst() {
        TouristSpot first = mock(TouristSpot.class);
        TouristSpot second = mock(TouristSpot.class);
        when(first.getId()).thenReturn(1L);
        when(second.getId()).thenReturn(2L);
        var newest = prediction(first, today, "TOURISM_CONGESTION_API");
        var older = prediction(first, today, "MANUAL");
        when(repository.findTodayPredictions(List.of(1L, 2L), today)).thenReturn(List.of(newest, older));
        var result = resolver.resolve(List.of(first, second));
        assertThat(result).containsOnlyKeys(1L);
        assertThat(result.get(1L)).isSameAs(newest);
        verify(repository).findTodayPredictions(List.of(1L, 2L), today);
        verifyNoMoreInteractions(repository);
    }

    @Test
    void neverSubstitutesPastOrFuturePredictionsForToday() {
        TouristSpot spot = mock(TouristSpot.class);
        when(spot.getId()).thenReturn(1L);
        when(repository.findTodayPredictions(List.of(1L), today)).thenReturn(List.of(
            prediction(spot, today.minusDays(1), "PAST"), prediction(spot, today.plusDays(1), "FUTURE")));
        assertThat(resolver.resolve(List.of(spot))).isEmpty();
    }

    @Test
    void emptyListDoesNotQueryDatabase() {
        assertThat(resolver.resolve(List.of())).isEmpty();
        verifyNoInteractions(repository);
    }

    private SpotCongestionPrediction prediction(TouristSpot spot, LocalDate date, String source) {
        return new SpotCongestionPrediction(spot, date, 10, 100, CongestionLevel.LOW, source, clock.instant());
    }
}
