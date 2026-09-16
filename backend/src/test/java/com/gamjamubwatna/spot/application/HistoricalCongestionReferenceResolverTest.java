package com.gamjamubwatna.spot.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.spot.domain.CongestionLevel;
import com.gamjamubwatna.spot.domain.SpotCongestionPrediction;
import com.gamjamubwatna.spot.domain.SpotCongestionPredictionRepository;
import com.gamjamubwatna.spot.domain.TouristSpot;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Set;
import org.junit.jupiter.api.Test;

class HistoricalCongestionReferenceResolverTest {
    private final SpotCongestionPredictionRepository repository = mock(SpotCongestionPredictionRepository.class);
    private final Clock clock = Clock.fixed(Instant.parse("2026-09-15T15:30:00Z"), ZoneOffset.UTC);
    private final HistoricalCongestionReferenceResolver resolver =
        new HistoricalCongestionReferenceResolver(repository, clock);
    private final LocalDate today = LocalDate.of(2026, 9, 16);

    @Test
    void prefersYesterdayOverLastWeekForTheSameSpot() {
        TouristSpot spot = spot(1L);
        var yesterday = prediction(spot, today.minusDays(1));
        var lastWeek = prediction(spot, today.minusDays(7));
        when(repository.findReferencePredictions(
            List.of(1L), List.of(today.minusDays(1), today.minusDays(7))
        )).thenReturn(List.of(lastWeek, yesterday));

        assertThat(resolver.resolve(List.of(spot), Set.of()).get(1L)).isSameAs(yesterday);
        verify(repository).findReferencePredictions(
            List.of(1L), List.of(today.minusDays(1), today.minusDays(7))
        );
    }

    @Test
    void usesLastWeeksSameWeekdayOnlyWhenYesterdayIsMissing() {
        TouristSpot spot = spot(1L);
        var lastWeek = prediction(spot, today.minusDays(7));
        when(repository.findReferencePredictions(
            List.of(1L), List.of(today.minusDays(1), today.minusDays(7))
        )).thenReturn(List.of(lastWeek));

        assertThat(resolver.resolve(List.of(spot), Set.of()).get(1L)).isSameAs(lastWeek);
    }

    @Test
    void neverReferencesSpotsWithTodayPredictionsOrOtherDates() {
        TouristSpot current = spot(1L);
        TouristSpot missing = spot(2L);
        when(repository.findReferencePredictions(
            List.of(2L), List.of(today.minusDays(1), today.minusDays(7))
        )).thenReturn(List.of(prediction(missing, today.minusDays(2))));

        assertThat(resolver.resolve(List.of(current, missing), Set.of(1L))).isEmpty();
        verify(repository).findReferencePredictions(
            List.of(2L), List.of(today.minusDays(1), today.minusDays(7))
        );
    }

    @Test
    void skipsQueryWhenNoSpotNeedsReference() {
        TouristSpot spot = spot(1L);
        assertThat(resolver.resolve(List.of(spot), Set.of(1L))).isEmpty();
        assertThat(resolver.resolve(List.of(), Set.of())).isEmpty();
        verifyNoInteractions(repository);
    }

    private TouristSpot spot(Long id) {
        TouristSpot spot = mock(TouristSpot.class);
        when(spot.getId()).thenReturn(id);
        return spot;
    }

    private SpotCongestionPrediction prediction(TouristSpot spot, LocalDate date) {
        return new SpotCongestionPrediction(
            spot, date, 20, 100, CongestionLevel.LOW, "TOURISM_CONGESTION_API", clock.instant()
        );
    }
}
