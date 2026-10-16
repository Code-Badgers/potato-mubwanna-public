package com.gamjamubwatna.spot.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.infrastructure.TourApiClient;
import org.junit.jupiter.api.Test;
import java.util.Optional;

class SpotTourInfoResolverTest {
    @Test
    void coldCachedLookupNeverSearchesForATourApiReference() {
        TourApiClient client = mock(TourApiClient.class);
        TouristSpot spot = mock(TouristSpot.class);
        when(spot.getContentId()).thenReturn("local-7");
        when(spot.getName()).thenReturn("test place");
        SpotTourInfoResolver resolver = new SpotTourInfoResolver(client, new TourApiSpotReferenceResolver(client));
        assertThat(resolver.resolveCached(spot)).isEqualTo(SpotTourInfo.empty());
        verifyNoInteractions(client);
    }

    @Test
    void reusesTourInformationFromAnEarlierFullLookup() {
        TourApiClient client = mock(TourApiClient.class);
        TouristSpot spot = mock(TouristSpot.class);
        when(spot.getContentId()).thenReturn("12345");
        when(spot.getContentTypeId()).thenReturn(12);
        SpotTourInfo info = new SpotTourInfo("saved description", null, null, null, null, null);
        when(client.findSpotTourInfo("12345", 12)).thenReturn(Optional.of(info));
        SpotTourInfoResolver resolver = new SpotTourInfoResolver(client, new TourApiSpotReferenceResolver(client));
        assertThat(resolver.resolve(spot)).isEqualTo(info);
        assertThat(resolver.resolveCached(spot)).isEqualTo(info);
        verify(client).findSpotTourInfo("12345", 12);
        verifyNoMoreInteractions(client);
    }
}
