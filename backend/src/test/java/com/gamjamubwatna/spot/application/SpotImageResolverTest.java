package com.gamjamubwatna.spot.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.infrastructure.TourApiClient;
import java.util.Optional;
import org.junit.jupiter.api.Test;

class SpotImageResolverTest {

    private final TourApiClient tourApiClient = mock(TourApiClient.class);
    private final SpotImageResolver resolver = new SpotImageResolver(tourApiClient);

    @Test
    void returnsInternalImageBeforeCallingTourApi() {
        TouristSpot spot = spot("https://example.com/internal.jpg", "12345");

        String imageUrl = resolver.resolveImageUrl(spot);

        assertThat(imageUrl).isEqualTo("https://example.com/internal.jpg");
        verify(tourApiClient, never()).findRepresentativeImage("12345");
    }

    @Test
    void returnsTourApiDetailImageWhenInternalImageIsMissing() {
        TouristSpot spot = spot(null, "12345");
        when(tourApiClient.findRepresentativeImage("12345"))
            .thenReturn(Optional.of("https://tour.example.com/detail.jpg"));

        String imageUrl = resolver.resolveImageUrl(spot);

        assertThat(imageUrl).isEqualTo("https://tour.example.com/detail.jpg");
    }

    @Test
    void skipsTourApiWhenContentIdIsMissingOrNotTourApiContentId() {
        assertThat(resolver.resolveImageUrl(spot(null, null))).isNull();
        assertThat(resolver.resolveImageUrl(spot(null, "curated-1"))).isNull();

        verify(tourApiClient, never()).findRepresentativeImage(null);
        verify(tourApiClient, never()).findRepresentativeImage("curated-1");
    }

    @Test
    void treatsTourApiFailureAsNonCriticalAndCachesEmptyResult() {
        TouristSpot spot = spot(null, "12345");
        when(tourApiClient.findRepresentativeImage("12345"))
            .thenThrow(new IllegalStateException("timeout"));

        assertThat(resolver.resolveImageUrl(spot)).isNull();
        assertThat(resolver.resolveImageUrl(spot)).isNull();

        verify(tourApiClient).findRepresentativeImage("12345");
    }

    private TouristSpot spot(String imageUrl, String contentId) {
        TouristSpot spot = mock(TouristSpot.class);
        when(spot.getImageUrl()).thenReturn(imageUrl);
        when(spot.getContentId()).thenReturn(contentId);
        return spot;
    }
}
