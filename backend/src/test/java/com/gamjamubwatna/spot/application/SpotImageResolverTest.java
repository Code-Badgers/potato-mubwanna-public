package com.gamjamubwatna.spot.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.infrastructure.TourApiClient;
import com.gamjamubwatna.spot.infrastructure.TourApiClient.TourApiSpotItem;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.Test;

class SpotImageResolverTest {

    private final TourApiClient tourApiClient = mock(TourApiClient.class);
    private final TourApiSpotReferenceResolver tourApiSpotReferenceResolver = mock(TourApiSpotReferenceResolver.class);
    private final SpotImageCacheWriter spotImageCacheWriter = mock(SpotImageCacheWriter.class);
    private final SpotImageResolver resolver = new SpotImageResolver(
        tourApiClient,
        spotImageCacheWriter,
        tourApiSpotReferenceResolver
    );

    @Test
    void returnsInternalImageBeforeCallingTourApi() {
        TouristSpot spot = spot("https://example.com/internal.jpg", "12345");

        String imageUrl = resolver.resolveImageUrl(spot);

        assertThat(imageUrl).isEqualTo("https://example.com/internal.jpg");
        verify(tourApiClient, never()).findRepresentativeImages("12345", 3);
        verify(spotImageCacheWriter, never()).cacheResolvedImage(1L, "https://example.com/internal.jpg");
    }

    @Test
    void returnsTourApiDetailImageWhenInternalImageIsMissing() {
        TouristSpot spot = spot(null, "12345");
        when(tourApiClient.findRepresentativeImages("12345", 3))
            .thenReturn(List.of("https://tour.example.com/detail.jpg"));

        String imageUrl = resolver.resolveImageUrl(spot);

        assertThat(imageUrl).isEqualTo("https://tour.example.com/detail.jpg");
        verify(spotImageCacheWriter).cacheResolvedImage(1L, "https://tour.example.com/detail.jpg");
    }

    @Test
    void replacesKakaoPlacePageUrlWithRenderableTourApiImage() {
        TouristSpot spot = spot("http://place.map.kakao.com/11554270", "12345");
        when(tourApiClient.findRepresentativeImages("12345", 3))
            .thenReturn(List.of("https://tour.example.com/detail.jpg"));

        String imageUrl = resolver.resolveImageUrl(spot);

        assertThat(imageUrl).isEqualTo("https://tour.example.com/detail.jpg");
        verify(spotImageCacheWriter).cacheResolvedImage(1L, "https://tour.example.com/detail.jpg");
    }

    @Test
    void ignoresMalformedStoredImageUrl() {
        TouristSpot spot = spot("not-an-image-url", null);

        assertThat(resolver.resolveImageUrl(spot)).isNull();
    }

    @Test
    void skipsTourApiWhenContentIdIsMissingOrNotTourApiContentId() {
        assertThat(resolver.resolveImageUrl(spot(null, null))).isNull();
        assertThat(resolver.resolveImageUrl(spot(null, "curated-1"))).isNull();

        verify(tourApiClient, never()).findRepresentativeImages(null, 3);
        verify(tourApiClient, never()).findRepresentativeImages("curated-1", 3);
        verify(spotImageCacheWriter, never()).cacheResolvedImage(1L, "curated-1");
    }

    @Test
    void treatsTourApiFailureAsNonCriticalAndCachesEmptyResult() {
        TouristSpot spot = spot(null, "12345");
        when(tourApiClient.findRepresentativeImages("12345", 3))
            .thenThrow(new IllegalStateException("timeout"));

        assertThat(resolver.resolveImageUrl(spot)).isNull();
        assertThat(resolver.resolveImageUrl(spot)).isNull();

        verify(tourApiClient).findRepresentativeImages("12345", 3);
        verify(spotImageCacheWriter, never()).cacheResolvedImage(1L, "12345");
    }

    @Test
    void appendsTourApiImagesAfterInternalImageForDetailGallery() {
        TouristSpot spot = spot("https://example.com/internal.jpg", "12345");
        when(tourApiClient.findRepresentativeImages("12345", 3))
            .thenReturn(List.of(
                "https://example.com/internal.jpg",
                "https://tour.example.com/detail-2.jpg",
                "https://tour.example.com/detail-3.jpg"
            ));

        List<String> imageUrls = resolver.resolveImageUrls(spot, 3);

        assertThat(imageUrls)
            .containsExactly(
                "https://example.com/internal.jpg",
                "https://tour.example.com/detail-2.jpg",
                "https://tour.example.com/detail-3.jpg"
            );
        verify(spotImageCacheWriter, never()).cacheResolvedImage(1L, "https://example.com/internal.jpg");
    }

    private TouristSpot spot(String imageUrl, String contentId) {
        TouristSpot spot = mock(TouristSpot.class);
        when(spot.getId()).thenReturn(1L);
        when(spot.getImageUrl()).thenReturn(imageUrl);
        when(spot.getContentId()).thenReturn(contentId);
        if (contentId != null && contentId.chars().allMatch(Character::isDigit)) {
            when(tourApiSpotReferenceResolver.resolve(spot)).thenReturn(Optional.of(
                new TourApiSpotItem(
                    contentId,
                    12,
                    "테스트 장소",
                    "강원도 테스트 주소",
                    null,
                    null,
                    imageUrl
                )
            ));
        } else {
            when(tourApiSpotReferenceResolver.resolve(spot)).thenReturn(Optional.empty());
        }
        return spot;
    }
}
