package com.gamjamubwatna.spot.infrastructure;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.junit.jupiter.api.Assertions.assertTimeoutPreemptively;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.spot.application.ExternalPlaceDetails;
import com.gamjamubwatna.spot.application.ExternalPlaceDetailsResolver;
import com.gamjamubwatna.spot.application.SpotImageResolver;
import com.gamjamubwatna.spot.application.SpotService;
import com.gamjamubwatna.spot.application.SpotTourInfoResolver;
import com.gamjamubwatna.spot.application.TourApiSpotReferenceResolver;
import com.gamjamubwatna.spot.domain.SpotCategory;
import com.gamjamubwatna.spot.domain.SpotMenuItemRepository;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.domain.TouristSpotRepository;
import com.sun.net.httpserver.HttpServer;
import java.math.BigDecimal;
import java.net.InetSocketAddress;
import java.time.Duration;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;

class SpotEnrichmentTimeoutTest {
    private HttpServer server;
    private final CountDownLatch release = new CountDownLatch(1);

    @BeforeEach
    void startUnresponsiveProvider() throws Exception {
        server = HttpServer.create(new InetSocketAddress("localhost", 0), 0);
        server.createContext("/", exchange -> {
            try {
                release.await(10, TimeUnit.SECONDS);
            } catch (InterruptedException exception) {
                Thread.currentThread().interrupt();
            } finally {
                exchange.close();
            }
        });
        server.start();
    }

    @AfterEach
    void stopProvider() {
        release.countDown();
        server.stop(0);
    }

    @Test
    void returnsBasicSpotDetailWhenTourApiDoesNotRespond() {
        TourApiClient client = new TourApiClient(RestClient.builder(), baseUrl(),
            "/search", "/images", "/common", "/intro", "test-key", "ETC", "test", "51", "감자");
        TouristSpot spot = mock(TouristSpot.class);
        when(spot.getId()).thenReturn(17L);
        when(spot.getName()).thenReturn("영금정");
        when(spot.getContentId()).thenReturn("12345");
        when(spot.getContentTypeId()).thenReturn(12);
        when(spot.getCategory()).thenReturn(SpotCategory.POTATO_TOUR);
        when(spot.getLatitude()).thenReturn(new BigDecimal("38.2119012"));
        when(spot.getLongitude()).thenReturn(new BigDecimal("128.6014625"));
        TouristSpotRepository spots = mock(TouristSpotRepository.class);
        when(spots.findByIdAndActiveTrue(17L)).thenReturn(Optional.of(spot));
        SpotImageResolver images = mock(SpotImageResolver.class);
        when(images.resolveStoredImageUrls(spot, 3)).thenReturn(List.of("https://test/1"));
        ExternalPlaceDetailsResolver google = mock(ExternalPlaceDetailsResolver.class);
        when(google.resolve(spot)).thenReturn(new ExternalPlaceDetails(null, null, null, null, null,
            List.of("https://test/2", "https://test/3")));
        SpotService service = new SpotService(spots, mock(SpotMenuItemRepository.class), images,
            new SpotTourInfoResolver(client, new TourApiSpotReferenceResolver(client)), google);

        assertTimeoutPreemptively(Duration.ofSeconds(5), () -> {
            var response = service.getSpot(17L);
            assertThat(response.name()).isEqualTo("영금정");
            assertThat(response.latitude()).isEqualByComparingTo("38.2119012");
            assertThat(response.imageUrls()).hasSize(3);
        });
        verify(images, never()).resolveTourApiImageUrls(spot, 3);
    }

    @Test
    void timesOutGoogleDetailsInsteadOfWaitingIndefinitely() {
        GooglePlacesClient client = new GooglePlacesClient(RestClient.builder(), baseUrl(), "test-key", "ko", "KR", 3);
        assertTimeoutPreemptively(Duration.ofSeconds(5), () ->
            assertThatThrownBy(() -> client.findDetails("test-place"))
                .isInstanceOf(ResourceAccessException.class));
    }

    private String baseUrl() {
        return "http://localhost:" + server.getAddress().getPort();
    }
}
