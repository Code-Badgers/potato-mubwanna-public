package com.gamjamubwatna.spot.infrastructure;

import com.fasterxml.jackson.databind.JsonNode;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.util.UriUtils;

@Component
public class TourismCongestionApiClient {

    private static final DateTimeFormatter BASIC_DATE = DateTimeFormatter.BASIC_ISO_DATE;

    private final RestClient restClient;
    private final String baseUrl;
    private final String predictionPath;
    private final String serviceKey;
    private final String mobileOs;
    private final String mobileApp;

    public TourismCongestionApiClient(
        RestClient.Builder restClientBuilder,
        @Value("${external.congestion-api.base-url}") String baseUrl,
        @Value("${external.congestion-api.prediction-path}") String predictionPath,
        @Value("${external.congestion-api.service-key}") String serviceKey,
        @Value("${external.congestion-api.mobile-os}") String mobileOs,
        @Value("${external.congestion-api.mobile-app}") String mobileApp
    ) {
        SimpleClientHttpRequestFactory requestFactory = new SimpleClientHttpRequestFactory();
        requestFactory.setConnectTimeout(Duration.ofSeconds(2));
        requestFactory.setReadTimeout(Duration.ofSeconds(5));
        this.restClient = restClientBuilder.clone().requestFactory(requestFactory).build();
        this.baseUrl = baseUrl;
        this.predictionPath = predictionPath;
        this.serviceKey = serviceKey;
        this.mobileOs = mobileOs;
        this.mobileApp = mobileApp;
    }

    public List<TourismCongestionPrediction> fetchPredictions(String districtCode, String touristSpotName) {
        validateConfiguration();
        if (districtCode == null || districtCode.isBlank() || touristSpotName == null || touristSpotName.isBlank()) {
            return List.of();
        }

        try {
            JsonNode root = restClient.get()
                .uri(predictionUri(districtCode, touristSpotName))
                .retrieve()
                .body(JsonNode.class);

            JsonNode response = validatedResponse(root);
            JsonNode body = response.path("body");
            if (body.path("totalCount").asInt(0) > 100) {
                throw new TourismCongestionApiException("관광지 혼잡도 API 조회 결과가 한 페이지를 초과했습니다.");
            }
            JsonNode itemNode = body.path("items").path("item");
            if (itemNode.isMissingNode() || itemNode.isNull()) {
                return List.of();
            }
            if (itemNode.isTextual() && itemNode.asText().isBlank()) {
                return List.of();
            }
            if (itemNode.isArray()) {
                return parseItems(itemNode, districtCode, touristSpotName);
            }
            if (itemNode.isObject()) {
                return parseItems(List.of(itemNode), districtCode, touristSpotName);
            }
            throw new TourismCongestionApiException("관광지 혼잡도 API items 응답 형식을 확인할 수 없습니다.");
        } catch (TourismCongestionApiException exception) {
            throw exception;
        } catch (RuntimeException exception) {
            throw new TourismCongestionApiException("관광지 혼잡도 API 호출에 실패했습니다.", exception);
        }
    }

    public void validateConfiguration() {
        if (serviceKey == null || serviceKey.isBlank()) {
            throw new TourismCongestionApiException("CONGESTION_API_SERVICE_KEY 또는 TOUR_API_SERVICE_KEY가 설정되지 않았습니다.");
        }
    }

    private JsonNode validatedResponse(JsonNode root) {
        if (root == null || root.path("response").isMissingNode()) {
            throw new TourismCongestionApiException("관광지 혼잡도 API 응답 형식을 확인할 수 없습니다.");
        }

        JsonNode response = root.path("response");
        JsonNode header = response.path("header");
        String resultCode = text(header, "resultCode", "resultCd");
        if (!resultCode.isBlank() && !"00".equals(resultCode) && !"0000".equals(resultCode)) {
            String resultMessage = text(header, "resultMsg", "resultMessage", "resultMessage");
            throw new TourismCongestionApiException("관광지 혼잡도 API 오류: %s".formatted(resultMessage));
        }
        return response;
    }

    private List<TourismCongestionPrediction> parseItems(
        Iterable<JsonNode> items, String districtCode, String touristSpotName
    ) {
        List<TourismCongestionPrediction> predictions = new ArrayList<>();
        for (JsonNode item : items) {
            String returnedName = text(item, "tAtsNm");
            String returnedDistrict = text(item, "signguCd");
            // 외부 API는 contentId를 제공하지 않아 시군구와 관광지명을 함께 검증해야 한다.
            if (!districtCode.equals(returnedDistrict)
                || !normalizedName(touristSpotName).equals(normalizedName(returnedName))) {
                continue;
            }
            LocalDate predictionDate = parseDate(text(item, "baseYmd"));
            Integer concentrationRate = integer(item, "cnctrRate");
            if (predictionDate == null || concentrationRate == null) {
                continue;
            }
            predictions.add(new TourismCongestionPrediction(
                returnedName,
                predictionDate,
                concentrationRate
            ));
        }
        return List.copyOf(predictions);
    }

    private String normalizedName(String name) {
        return name.replaceAll("\\s+", "");
    }

    private URI predictionUri(String districtCode, String touristSpotName) {
        String query = String.join("&",
            "serviceKey=%s".formatted(encodeServiceKey(serviceKey)),
            "pageNo=1",
            "numOfRows=100",
            "MobileOS=%s".formatted(encode(mobileOs)),
            "MobileApp=%s".formatted(encode(mobileApp)),
            "areaCd=51",
            "signguCd=%s".formatted(encode(districtCode)),
            "tAtsNm=%s".formatted(encode(touristSpotName)),
            "_type=json"
        );
        return URI.create("%s%s?%s".formatted(normalizedBaseUrl(), normalizedPath(), query));
    }

    private String normalizedBaseUrl() {
        return baseUrl.endsWith("/") ? baseUrl.substring(0, baseUrl.length() - 1) : baseUrl;
    }

    private String normalizedPath() {
        return predictionPath.startsWith("/")
            ? predictionPath
            : "/%s".formatted(predictionPath);
    }

    private String text(JsonNode node, String... fieldNames) {
        for (String fieldName : fieldNames) {
            JsonNode value = node.path(fieldName);
            if (!value.isMissingNode() && !value.isNull()) {
                return value.asText("").trim();
            }
        }
        return "";
    }

    private Integer integer(JsonNode node, String... fieldNames) {
        String value = text(node, fieldNames);
        if (value.isBlank()) {
            return null;
        }
        try {
            return (int) Math.round(Double.parseDouble(value));
        } catch (NumberFormatException exception) {
            return null;
        }
    }

    private LocalDate parseDate(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return value.contains("-")
                ? LocalDate.parse(value)
                : LocalDate.parse(value, BASIC_DATE);
        } catch (DateTimeParseException exception) {
            return null;
        }
    }

    private String encode(String value) {
        return UriUtils.encode(value, StandardCharsets.UTF_8);
    }

    private String encodeServiceKey(String value) {
        // 포털의 Encoding 키를 다시 인코딩하면 '%'가 '%25'로 바뀌어 인증에 실패한다.
        return value.contains("%") ? value : encode(value);
    }

    public record TourismCongestionPrediction(
        String touristSpotName,
        LocalDate predictionDate,
        Integer concentrationRate
    ) {
    }
}
