package com.gamjamubwatna.spot.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.domain.TouristSpotRepository;
import com.gamjamubwatna.spot.infrastructure.TourApiClient;
import com.gamjamubwatna.spot.infrastructure.TourApiClient.TourApiSpotItem;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.Test;

class TourApiSpotImportServiceTest {

    @Test
    void importsPotatoSpotFromTourApiSearchResult() {
        TourApiClient tourApiClient = mock(TourApiClient.class);
        TouristSpotRepository repository = mock(TouristSpotRepository.class);
        when(tourApiClient.searchPotatoSpots(1, 20))
            .thenReturn(List.of(new TourApiSpotItem(
                "100",
                39,
                "정선 감자옹심이",
                "강원특별자치도 정선군 정선읍",
                new BigDecimal("37.3801000"),
                new BigDecimal("128.6609000"),
                ""
            )));
        when(repository.findByContentId("100")).thenReturn(Optional.empty());
        when(repository.save(any(TouristSpot.class))).thenAnswer(invocation -> invocation.getArgument(0));

        TourApiSpotImportService importService = new TourApiSpotImportService(
            tourApiClient,
            new PotatoSpotClassifier(),
            repository,
            Clock.fixed(Instant.parse("2026-06-20T00:00:00Z"), ZoneOffset.UTC)
        );

        int savedCount = importService.importPotatoSpots(1, 20);

        assertThat(savedCount).isEqualTo(1);
        verify(repository).save(any(TouristSpot.class));
    }
}
