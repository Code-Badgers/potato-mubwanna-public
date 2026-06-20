package com.gamjamubwatna.spot.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.domain.TouristSpotRepository;
import com.gamjamubwatna.spot.infrastructure.KakaoLocalClient;
import com.gamjamubwatna.spot.infrastructure.KakaoLocalClient.KakaoLocalSpotItem;
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
        KakaoLocalClient kakaoLocalClient = mock(KakaoLocalClient.class);
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
        when(kakaoLocalClient.searchPotatoSpots(1, 20)).thenReturn(List.of());
        when(repository.findByContentId("100")).thenReturn(Optional.empty());
        when(repository.save(any(TouristSpot.class))).thenAnswer(invocation -> invocation.getArgument(0));

        TourApiSpotImportService importService = new TourApiSpotImportService(
            tourApiClient,
            kakaoLocalClient,
            new PotatoSpotClassifier(),
            repository,
            Clock.fixed(Instant.parse("2026-06-20T00:00:00Z"), ZoneOffset.UTC)
        );

        int savedCount = importService.importPotatoSpots(1, 20);

        assertThat(savedCount).isEqualTo(1);
        verify(repository).save(any(TouristSpot.class));
    }

    @Test
    void importsConfiguredPageRange() {
        TourApiClient tourApiClient = mock(TourApiClient.class);
        KakaoLocalClient kakaoLocalClient = mock(KakaoLocalClient.class);
        TouristSpotRepository repository = mock(TouristSpotRepository.class);
        when(tourApiClient.searchPotatoSpots(1, 10)).thenReturn(List.of());
        when(tourApiClient.searchPotatoSpots(2, 10)).thenReturn(List.of());
        when(kakaoLocalClient.searchPotatoSpots(1, 10)).thenReturn(List.of());
        when(kakaoLocalClient.searchPotatoSpots(2, 10)).thenReturn(List.of());

        TourApiSpotImportService importService = new TourApiSpotImportService(
            tourApiClient,
            kakaoLocalClient,
            new PotatoSpotClassifier(),
            repository,
            Clock.fixed(Instant.parse("2026-06-20T00:00:00Z"), ZoneOffset.UTC)
        );

        int savedCount = importService.importPotatoSpotPages(2, 10);

        assertThat(savedCount).isZero();
        verify(tourApiClient).searchPotatoSpots(1, 10);
        verify(tourApiClient).searchPotatoSpots(2, 10);
        verify(kakaoLocalClient).searchPotatoSpots(1, 10);
        verify(kakaoLocalClient).searchPotatoSpots(2, 10);
    }

    @Test
    void importsPotatoSpotFromKakaoLocalSearchResult() {
        TourApiClient tourApiClient = mock(TourApiClient.class);
        KakaoLocalClient kakaoLocalClient = mock(KakaoLocalClient.class);
        TouristSpotRepository repository = mock(TouristSpotRepository.class);
        when(tourApiClient.searchPotatoSpots(1, 15)).thenReturn(List.of());
        when(kakaoLocalClient.searchPotatoSpots(1, 15))
            .thenReturn(List.of(new KakaoLocalSpotItem(
                "kakao-100",
                "강릉 감자빵 카페",
                "음식점 > 카페",
                "강원특별자치도 강릉시 감자길 1",
                "",
                "https://place.map.kakao.com/kakao-100",
                "128.8961000",
                "37.7519000"
            )));
        when(repository.findByContentId("KAKAO_LOCAL:kakao-100")).thenReturn(Optional.empty());
        when(repository.findByNameAndAddress("강릉 감자빵 카페", "강원특별자치도 강릉시 감자길 1"))
            .thenReturn(Optional.empty());
        when(repository.save(any(TouristSpot.class))).thenAnswer(invocation -> invocation.getArgument(0));

        TourApiSpotImportService importService = new TourApiSpotImportService(
            tourApiClient,
            kakaoLocalClient,
            new PotatoSpotClassifier(),
            repository,
            Clock.fixed(Instant.parse("2026-06-20T00:00:00Z"), ZoneOffset.UTC)
        );

        int savedCount = importService.importPotatoSpots(1, 15);

        assertThat(savedCount).isEqualTo(1);
        verify(repository).save(any(TouristSpot.class));
    }
}
