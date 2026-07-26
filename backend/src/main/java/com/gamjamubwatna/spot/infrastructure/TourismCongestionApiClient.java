package com.gamjamubwatna.spot.infrastructure;

import com.fasterxml.jackson.databind.JsonNode;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
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
    private final String contentIdParam;

    public TourismCongestionApiClient(
        RestClient.Builder restClientBuilder,
        @Value("${external.congestion-api.base-url}") String baseUrl,
        @Value("${external.congestion-api.prediction-path}") String predictionPath,
        @Value("${external.congestion-api.service-key}") String serviceKey,
        @Value("${external.congestion-api.mobile-os}") String mobileOs,
        @Value("${external.congestion-api.mobile-app}") String mobileApp,
        @Value("${external.congestion-api.content-id-param}") String contentIdParam
    ) {
        this.restClient = restClientBuilder.build();
        this.baseUrl = baseUrl;
        this.predictionPath = predictionPath;
        this.serviceKey = serviceKey;
        this.mobileOs = mobileOs;
        this.mobileApp = mobileApp;
        this.contentIdParam = contentIdParam;
    }

    public List<TourismCongestionPrediction> fetchPredictions(String contentId) {
        if (serviceKey == null || serviceKey.isBlank()) {
            throw new TourismCongestionApiException("CONGESTION_API_SERVICE_KEY 또는 TOUR_API_SERVICE_KEY가 설정되지 않았습니다.");
        }
        if (contentId == null || contentId.isBlank()) {
            return List.of();
        }

        try {
            JsonNode root = restClient.get()
                .uri(predictionUri(contentId))
                .retrieve()
                .body(JsonNode.class);

            JsonNode response = validatedResponse(root);
            JsonNode itemNode = response.path("body").path("items").path("item");
            if (itemNode.isMissingNode() || itemNode.isNull()) {
                return List.of();
            }
            if (itemNode.isTextual() && itemNode.asText().isBlank()) {
                return List.of();
            }
            if (itemNode.isArray()) {
                return parseItems(itemNode, contentId);
            }
            if (itemNode.isObject()) {
                return parseItems(List.of(itemNode), contentId);
            }
            throw new TourismCongestionApiException("관광지 혼잡도 API items 응답 형식을 확인할 수 없습니다.");
        } catch (TourismCongestionApiException exception) {
            throw exception;
        } catch (RuntimeException exception) {
            throw new TourismCongestionApiException("관광지 혼잡도 API 호출에 실패했습니다.", exception);
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

    private List<TourismCongestionPrediction> parseItems(Iterable<JsonNode> items, String fallbackContentId) {
        List<TourismCongestionPrediction> predictions = new ArrayList<>();
        for (JsonNode item : items) {
            LocalDate predictionDate = parseDate(text(
                item,
                "predictionDate",
                "baseYmd",
                "prdtYmd",
                "predictYmd",
                "cnctrYmd",
                "tAtsYmd"
            ));
            Integer concentrationRate = integer(
                item,
                "concentrationRate",
                "cnctrRate",
                "tAtsCnctrRate",
                "forecastRate",
                "predictRate",
                "rate"
            );
            if (predictionDate == null || concentrationRate == null) {
                continue;
            }
            String contentId = text(item, "contentId", "contentid", "tAtsCd", "touristSpotId");
            predictions.add(new TourismCongestionPrediction(
                contentId.isBlank() ? fallbackContentId : contentId,
                predictionDate,
                concentrationRate
            ));
        }
        return List.copyOf(predictions);
    }

    private URI predictionUri(String contentId) {
        String query = String.join("&",
            "serviceKey=%s".formatted(encodeServiceKey(serviceKey)),
            "MobileOS=%s".formatted(encode(mobileOs)),
            "MobileApp=%s".formatted(encode(mobileApp)),
            "_type=json",
            "%s=%s".formatted(encode(contentIdParam), encode(contentId))
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
        String contentId,
        LocalDate predictionDate,
        Integer concentrationRate
    ) {
    }
}
