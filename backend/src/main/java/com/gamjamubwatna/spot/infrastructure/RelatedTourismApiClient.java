package com.gamjamubwatna.spot.infrastructure;

import com.fasterxml.jackson.annotation.JsonFormat;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.util.UriUtils;

@Component
public class RelatedTourismApiClient {

    private static final int MAX_RESULTS = 50;

    private final RestClient restClient;
    private final String baseUrl;
    private final String searchKeywordPath;
    private final String serviceKey;
    private final String mobileOs;
    private final String mobileApp;
    private final String baseYearMonth;
    private final String areaCode;

    public RelatedTourismApiClient(
        RestClient.Builder restClientBuilder,
        @Value("${external.related-tourism-api.base-url}") String baseUrl,
        @Value("${external.related-tourism-api.search-keyword-path}") String searchKeywordPath,
        @Value("${external.related-tourism-api.service-key}") String serviceKey,
        @Value("${external.related-tourism-api.mobile-os}") String mobileOs,
        @Value("${external.related-tourism-api.mobile-app}") String mobileApp,
        @Value("${external.related-tourism-api.base-year-month}") String baseYearMonth,
        @Value("${external.related-tourism-api.area-code}") String areaCode
    ) {
        this.restClient = restClientBuilder.build();
        this.baseUrl = baseUrl;
        this.searchKeywordPath = searchKeywordPath;
        this.serviceKey = serviceKey;
        this.mobileOs = mobileOs;
        this.mobileApp = mobileApp;
        this.baseYearMonth = baseYearMonth;
        this.areaCode = areaCode;
    }

    public List<RelatedTourismSpot> searchRelatedSpots(String keyword, String signguCode) {
        if (serviceKey == null || serviceKey.isBlank()) {
            throw new RelatedTourismApiException("RELATED_TOURISM_API_SERVICE_KEY가 설정되지 않았습니다.");
        }

        try {
            RelatedTourismResponse response = restClient.get()
                .uri(searchUri(keyword, signguCode))
                .retrieve()
                .body(RelatedTourismResponse.class);

            validateResponse(response);
            if (response.body() == null
                || response.body().items() == null
                || response.body().items().item() == null) {
                return List.of();
            }
            return response.body().items().item();
        } catch (RelatedTourismApiException exception) {
            throw exception;
        } catch (RuntimeException exception) {
            throw new RelatedTourismApiException("연관 관광지 API 호출에 실패했습니다.", exception);
        }
    }

    private void validateResponse(RelatedTourismResponse response) {
        if (response == null || response.header() == null) {
            throw new RelatedTourismApiException("연관 관광지 API 응답 형식을 확인할 수 없습니다.");
        }
        String resultCode = response.header().resultCode();
        if (!"00".equals(resultCode) && !"0000".equals(resultCode)) {
            throw new RelatedTourismApiException(
                "연관 관광지 API 오류: %s".formatted(response.header().resultMsg())
            );
        }
    }

    private URI searchUri(String keyword, String signguCode) {
        String query = String.join("&",
            "serviceKey=%s".formatted(encodeServiceKey(serviceKey)),
            "pageNo=1",
            "numOfRows=%d".formatted(MAX_RESULTS),
            "MobileOS=%s".formatted(encode(mobileOs)),
            "MobileApp=%s".formatted(encode(mobileApp)),
            "baseYm=%s".formatted(encode(baseYearMonth)),
            "areaCd=%s".formatted(encode(areaCode)),
            "signguCd=%s".formatted(encode(signguCode)),
            "keyword=%s".formatted(encode(keyword)),
            "_type=json"
        );
        return URI.create("%s%s?%s".formatted(normalizedBaseUrl(), normalizedPath(), query));
    }

    private String normalizedBaseUrl() {
        return baseUrl.endsWith("/") ? baseUrl.substring(0, baseUrl.length() - 1) : baseUrl;
    }

    private String normalizedPath() {
        return searchKeywordPath.startsWith("/")
            ? searchKeywordPath
            : "/%s".formatted(searchKeywordPath);
    }

    private String encode(String value) {
        return UriUtils.encodeQueryParam(value, StandardCharsets.UTF_8);
    }

    private String encodeServiceKey(String value) {
        // 포털이 제공한 Encoding 키의 '%'를 다시 인코딩하면 인증에 실패한다.
        return value.contains("%") ? value : encode(value);
    }

    public record RelatedTourismSpot(
        String baseYm,
        String tAtsCd,
        String tAtsNm,
        String areaCd,
        String areaNm,
        String signguCd,
        String signguNm,
        String rlteTatsCd,
        String rlteTatsNm,
        String rlteRegnCd,
        String rlteRegnNm,
        String rlteSignguCd,
        String rlteSignguNm,
        String rlteCtgryLclsNm,
        String rlteCtgryMclsNm,
        String rlteCtgrySclsNm,
        String rlteRank
    ) {
    }

    private record RelatedTourismResponse(RelatedTourismHeader header, RelatedTourismBody body) {
    }

    private record RelatedTourismHeader(String resultCode, String resultMsg) {
    }

    private record RelatedTourismBody(RelatedTourismItems items) {
    }

    private record RelatedTourismItems(
        @JsonFormat(with = JsonFormat.Feature.ACCEPT_SINGLE_VALUE_AS_ARRAY)
        List<RelatedTourismSpot> item
    ) {
    }
}
