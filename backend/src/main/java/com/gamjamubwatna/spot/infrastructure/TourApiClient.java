package com.gamjamubwatna.spot.infrastructure;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.math.BigDecimal;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.util.UriUtils;
import org.springframework.web.client.RestClient;

@Component
public class TourApiClient {

    private final RestClient restClient;
    private final String baseUrl;
    private final String searchKeywordPath;
    private final String serviceKey;
    private final String mobileOs;
    private final String mobileApp;
    private final String legalRegionCode;
    private final List<String> spotKeywords;

    public TourApiClient(
        RestClient.Builder restClientBuilder,
        @Value("${external.tour-api.base-url}") String baseUrl,
        @Value("${external.tour-api.search-keyword-path}") String searchKeywordPath,
        @Value("${external.tour-api.service-key}") String serviceKey,
        @Value("${external.tour-api.mobile-os}") String mobileOs,
        @Value("${external.tour-api.mobile-app}") String mobileApp,
        @Value("${external.tour-api.legal-region-code}") String legalRegionCode,
        @Value("${external.tour-api.spot-keywords}") String spotKeywords
    ) {
        this.restClient = restClientBuilder.build();
        this.baseUrl = baseUrl;
        this.searchKeywordPath = searchKeywordPath;
        this.serviceKey = serviceKey;
        this.mobileOs = mobileOs;
        this.mobileApp = mobileApp;
        this.legalRegionCode = legalRegionCode;
        this.spotKeywords = parseKeywords(spotKeywords);
    }

    public List<TourApiSpotItem> searchPotatoSpots(int pageNo, int numOfRows) {
        if (serviceKey == null || serviceKey.isBlank()) {
            throw new IllegalStateException("TOUR_API_SERVICE_KEY가 설정되지 않았습니다.");
        }

        Map<String, TourApiSpotItem> uniqueItems = new LinkedHashMap<>();
        for (String keyword : spotKeywords) {
            for (TourApiSpotItem item : searchPotatoSpots(keyword, pageNo, numOfRows)) {
                if (item.contentId() == null || item.contentId().isBlank()) {
                    continue;
                }
                uniqueItems.putIfAbsent(item.contentId(), item);
            }
        }
        return List.copyOf(uniqueItems.values());
    }

    private List<TourApiSpotItem> searchPotatoSpots(String keyword, int pageNo, int numOfRows) {
        TourApiSearchResponse response = restClient.get()
            .uri(searchKeywordUri(keyword, pageNo, numOfRows))
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

    private URI searchKeywordUri(String keyword, int pageNo, int numOfRows) {
        String query = String.join("&",
            "serviceKey=%s".formatted(encodeServiceKey(serviceKey)),
            "MobileOS=%s".formatted(encode(mobileOs)),
            "MobileApp=%s".formatted(encode(mobileApp)),
            "_type=json",
            "arrange=C",
            "lDongRegnCd=%s".formatted(encode(legalRegionCode)),
            "keyword=%s".formatted(encode(keyword)),
            "pageNo=%d".formatted(pageNo),
            "numOfRows=%d".formatted(numOfRows)
        );
        return URI.create("%s%s?%s".formatted(normalizedBaseUrl(), normalizedPath(), query));
    }

    private List<String> parseKeywords(String value) {
        if (value == null || value.isBlank()) {
            return List.of("감자");
        }
        return Arrays.stream(value.split(","))
            .map(String::trim)
            .filter(keyword -> !keyword.isBlank())
            .distinct()
            .toList();
    }

    private String normalizedBaseUrl() {
        if (baseUrl.endsWith("/")) {
            return baseUrl.substring(0, baseUrl.length() - 1);
        }
        return baseUrl;
    }

    private String normalizedPath() {
        if (searchKeywordPath.startsWith("/")) {
            return searchKeywordPath;
        }
        return "/%s".formatted(searchKeywordPath);
    }

    private String encode(String value) {
        return UriUtils.encodeQueryParam(value, StandardCharsets.UTF_8);
    }

    private String encodeServiceKey(String value) {
        // 공공데이터포털은 Encoding/Decoding 키를 모두 보여준다. Encoding 키를 다시 인코딩하면
        // '%'가 '%25'로 바뀌어 401이 나므로 이미 인코딩된 키는 그대로 전달한다.
        if (value.contains("%")) {
            return value;
        }
        return encode(value);
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
