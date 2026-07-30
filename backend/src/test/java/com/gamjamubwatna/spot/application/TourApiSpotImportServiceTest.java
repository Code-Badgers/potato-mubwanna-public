package com.gamjamubwatna.spot.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.spot.domain.SpotCategory;
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
import org.mockito.ArgumentCaptor;

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
    void skipsTourApiSpotOutsideGangwonCoordinateBounds() {
        TourApiClient tourApiClient = mock(TourApiClient.class);
        KakaoLocalClient kakaoLocalClient = mock(KakaoLocalClient.class);
        TouristSpotRepository repository = mock(TouristSpotRepository.class);
        when(tourApiClient.searchPotatoSpots(1, 20))
            .thenReturn(List.of(
                new TourApiSpotItem(
                    "100",
                    39,
                    "서울 감자옹심이",
                    "서울특별시 중구",
                    new BigDecimal("37.5665000"),
                    new BigDecimal("126.9780000"),
                    ""
                ),
                new TourApiSpotItem(
                    "101",
                    39,
                    "좌표 없는 감자집",
                    "강원특별자치도 강릉시",
                    BigDecimal.ZERO,
                    BigDecimal.ZERO,
                    ""
                )
            ));
        when(kakaoLocalClient.searchPotatoSpots(1, 20)).thenReturn(List.of());

        TourApiSpotImportService importService = new TourApiSpotImportService(
            tourApiClient,
            kakaoLocalClient,
            new PotatoSpotClassifier(),
            repository,
            Clock.fixed(Instant.parse("2026-06-20T00:00:00Z"), ZoneOffset.UTC)
        );

        int savedCount = importService.importPotatoSpots(1, 20);

        assertThat(savedCount).isZero();
        verify(repository, never()).save(any(TouristSpot.class));
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

    @Test
    void skipsKakaoLocalSpotOutsideGangwonCoordinateBounds() {
        TourApiClient tourApiClient = mock(TourApiClient.class);
        KakaoLocalClient kakaoLocalClient = mock(KakaoLocalClient.class);
        TouristSpotRepository repository = mock(TouristSpotRepository.class);
        when(tourApiClient.searchPotatoSpots(1, 15)).thenReturn(List.of());
        when(kakaoLocalClient.searchPotatoSpots(1, 15))
            .thenReturn(List.of(new KakaoLocalSpotItem(
                "kakao-seoul-100",
                "서울 감자빵 카페",
                "음식점 > 카페",
                "서울특별시 중구 감자길 1",
                "",
                "https://place.map.kakao.com/kakao-seoul-100",
                "126.9780000",
                "37.5665000"
            )));

        TourApiSpotImportService importService = new TourApiSpotImportService(
            tourApiClient,
            kakaoLocalClient,
            new PotatoSpotClassifier(),
            repository,
            Clock.fixed(Instant.parse("2026-06-20T00:00:00Z"), ZoneOffset.UTC)
        );

        int savedCount = importService.importPotatoSpots(1, 15);

        assertThat(savedCount).isZero();
        verify(repository, never()).save(any(TouristSpot.class));
    }

    @Test
    void mapsKakaoLocalShoppingCategoryToShopContentType() {
        TourApiClient tourApiClient = mock(TourApiClient.class);
        KakaoLocalClient kakaoLocalClient = mock(KakaoLocalClient.class);
        TouristSpotRepository repository = mock(TouristSpotRepository.class);
        when(tourApiClient.searchPotatoSpots(1, 15)).thenReturn(List.of());
        when(kakaoLocalClient.searchPotatoSpots(1, 15))
            .thenReturn(List.of(new KakaoLocalSpotItem(
                "kakao-shop-1",
                "강원 감자 특산품 판매장",
                "가정,생활 > 식품판매 > 농수축산물",
                "강원특별자치도 평창군 감자길 2",
                "",
                "https://place.map.kakao.com/kakao-shop-1",
                "128.7071000",
                "37.3702000"
            )));
        when(repository.findByContentId("KAKAO_LOCAL:kakao-shop-1")).thenReturn(Optional.empty());
        when(repository.findByNameAndAddress("강원 감자 특산품 판매장", "강원특별자치도 평창군 감자길 2"))
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

        ArgumentCaptor<TouristSpot> captor = ArgumentCaptor.forClass(TouristSpot.class);
        assertThat(savedCount).isEqualTo(1);
        verify(repository).save(captor.capture());
        assertThat(captor.getValue().getContentTypeId()).isEqualTo(38);
        assertThat(captor.getValue().getCategory()).isEqualTo(SpotCategory.POTATO_SHOP);
        assertThat(captor.getValue().getPotatoTags()).isEqualTo("감자,기념품");
    }

    @Test
    void mapsKakaoLocalTourCategoryToTourContentType() {
        TourApiClient tourApiClient = mock(TourApiClient.class);
        KakaoLocalClient kakaoLocalClient = mock(KakaoLocalClient.class);
        TouristSpotRepository repository = mock(TouristSpotRepository.class);
        when(tourApiClient.searchPotatoSpots(1, 15)).thenReturn(List.of());
        when(kakaoLocalClient.searchPotatoSpots(1, 15))
            .thenReturn(List.of(new KakaoLocalSpotItem(
                "kakao-tour-1",
                "평창 고랭지 감자밭",
                "여행 > 관광,명소",
                "강원특별자치도 평창군 감자길 3",
                "",
                "https://place.map.kakao.com/kakao-tour-1",
                "128.7151000",
                "37.3812000"
            )));
        when(repository.findByContentId("KAKAO_LOCAL:kakao-tour-1")).thenReturn(Optional.empty());
        when(repository.findByNameAndAddress("평창 고랭지 감자밭", "강원특별자치도 평창군 감자길 3"))
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

        ArgumentCaptor<TouristSpot> captor = ArgumentCaptor.forClass(TouristSpot.class);
        assertThat(savedCount).isEqualTo(1);
        verify(repository).save(captor.capture());
        assertThat(captor.getValue().getContentTypeId()).isEqualTo(12);
        assertThat(captor.getValue().getCategory()).isEqualTo(SpotCategory.POTATO_TOUR);
        assertThat(captor.getValue().getPotatoTags()).isEqualTo("감자,관광");
    }
}
