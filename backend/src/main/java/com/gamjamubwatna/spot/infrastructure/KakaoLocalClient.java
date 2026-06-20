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
import org.springframework.web.client.RestClient;
import org.springframework.web.util.UriUtils;

@Component
public class KakaoLocalClient {

    private static final int KAKAO_LOCAL_MAX_PAGE_SIZE = 15;

    private final RestClient restClient;
    private final String keywordSearchUrl;
    private final String restApiKey;
    private final List<String> spotKeywords;

    public KakaoLocalClient(
        RestClient.Builder restClientBuilder,
        @Value("${external.kakao-local.keyword-search-url}") String keywordSearchUrl,
        @Value("${external.kakao-local.rest-api-key}") String restApiKey,
        @Value("${external.kakao-local.spot-keywords}") String spotKeywords
    ) {
        this.restClient = restClientBuilder.build();
        this.keywordSearchUrl = keywordSearchUrl;
        this.restApiKey = restApiKey;
        this.spotKeywords = parseKeywords(spotKeywords);
    }

    public List<KakaoLocalSpotItem> searchPotatoSpots(int pageNo, int numOfRows) {
        if (restApiKey == null || restApiKey.isBlank()) {
            return List.of();
        }

        Map<String, KakaoLocalSpotItem> uniqueItems = new LinkedHashMap<>();
        for (String keyword : spotKeywords) {
            for (KakaoLocalSpotItem item : searchPotatoSpots(keyword, pageNo, numOfRows)) {
                if (item.id() == null || item.id().isBlank()) {
                    continue;
                }
                uniqueItems.putIfAbsent(item.id(), item);
            }
        }
        return List.copyOf(uniqueItems.values());
    }

    private List<KakaoLocalSpotItem> searchPotatoSpots(String keyword, int pageNo, int numOfRows) {
        KakaoLocalSearchResponse response = restClient.get()
            .uri(searchKeywordUri(keyword, pageNo, Math.min(numOfRows, KAKAO_LOCAL_MAX_PAGE_SIZE)))
            .header("Authorization", "KakaoAK %s".formatted(restApiKey))
            .retrieve()
            .body(KakaoLocalSearchResponse.class);

        if (response == null || response.documents() == null) {
            return List.of();
        }
        return response.documents();
    }

    private URI searchKeywordUri(String keyword, int pageNo, int numOfRows) {
        String query = String.join("&",
            "query=%s".formatted(encode(keyword)),
            "page=%d".formatted(pageNo),
            "size=%d".formatted(numOfRows)
        );
        return URI.create("%s?%s".formatted(keywordSearchUrl, query));
    }

    private List<String> parseKeywords(String value) {
        if (value == null || value.isBlank()) {
            return List.of();
        }
        return Arrays.stream(value.split(","))
            .map(String::trim)
            .filter(keyword -> !keyword.isBlank())
            .distinct()
            .toList();
    }

    private String encode(String value) {
        return UriUtils.encodeQueryParam(value, StandardCharsets.UTF_8);
    }

    public record KakaoLocalSpotItem(
        String id,
        @JsonProperty("place_name")
        String placeName,
        @JsonProperty("category_name")
        String categoryName,
        @JsonProperty("road_address_name")
        String roadAddressName,
        @JsonProperty("address_name")
        String addressName,
        @JsonProperty("place_url")
        String placeUrl,
        String x,
        String y
    ) {
        public BigDecimal latitude() {
            return toBigDecimal(y);
        }

        public BigDecimal longitude() {
            return toBigDecimal(x);
        }

        public String address() {
            if (roadAddressName != null && !roadAddressName.isBlank()) {
                return roadAddressName;
            }
            return addressName;
        }

        private BigDecimal toBigDecimal(String value) {
            if (value == null || value.isBlank()) {
                return null;
            }
            return new BigDecimal(value);
        }
    }

    private record KakaoLocalSearchResponse(
        List<KakaoLocalSpotItem> documents
    ) {
    }
}
