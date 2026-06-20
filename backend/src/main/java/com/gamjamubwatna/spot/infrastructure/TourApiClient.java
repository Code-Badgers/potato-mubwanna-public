package com.gamjamubwatna.spot.infrastructure;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.math.BigDecimal;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

@Component
public class TourApiClient {

    private final RestClient restClient;
    private final String serviceKey;
    private final String mobileOs;
    private final String mobileApp;

    public TourApiClient(
        RestClient.Builder restClientBuilder,
        @Value("${external.tour-api.base-url}") String baseUrl,
        @Value("${external.tour-api.service-key}") String serviceKey,
        @Value("${external.tour-api.mobile-os}") String mobileOs,
        @Value("${external.tour-api.mobile-app}") String mobileApp
    ) {
        this.restClient = restClientBuilder.baseUrl(baseUrl).build();
        this.serviceKey = serviceKey;
        this.mobileOs = mobileOs;
        this.mobileApp = mobileApp;
    }

    public List<TourApiSpotItem> searchPotatoSpots(int pageNo, int numOfRows) {
        if (serviceKey == null || serviceKey.isBlank()) {
            throw new IllegalStateException("TOUR_API_SERVICE_KEY가 설정되지 않았습니다.");
        }

        TourApiSearchResponse response = restClient.get()
            .uri(uriBuilder -> uriBuilder
                .path("/searchKeyword4")
                .queryParam("serviceKey", serviceKey)
                .queryParam("MobileOS", mobileOs)
                .queryParam("MobileApp", mobileApp)
                .queryParam("_type", "json")
                .queryParam("areaCode", "32")
                .queryParam("keyword", "감자")
                .queryParam("pageNo", pageNo)
                .queryParam("numOfRows", numOfRows)
                .build())
            .retrieve()
            .body(TourApiSearchResponse.class);

        if (response == null || response.response() == null
            || response.response().body() == null
            || response.response().body().items() == null
            || response.response().body().items().item() == null) {
            return List.of();
        }

        return response.response().body().items().item();
    }

    public record TourApiSpotItem(
        @JsonProperty("contentid")
        String contentId,
        @JsonProperty("contenttypeid")
        Integer contentTypeId,
        String title,
        @JsonProperty("addr1")
        String address,
        @JsonProperty("mapy")
        BigDecimal latitude,
        @JsonProperty("mapx")
        BigDecimal longitude,
        @JsonProperty("firstimage")
        String imageUrl
    ) {
    }

    private record TourApiSearchResponse(
        TourApiResponse response
    ) {
    }

    private record TourApiResponse(
        TourApiBody body
    ) {
    }

    private record TourApiBody(
        TourApiItems items
    ) {
    }

    private record TourApiItems(
        List<TourApiSpotItem> item
    ) {
    }
}
