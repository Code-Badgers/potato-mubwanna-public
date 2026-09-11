package com.gamjamubwatna.spot.infrastructure;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.JsonNode;
import com.gamjamubwatna.spot.application.SpotTourInfo;
import java.math.BigDecimal;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.atomic.AtomicBoolean;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.util.UriUtils;
import org.springframework.web.client.RestClient;

@Component
public class TourApiClient {

    private static final Logger log = LoggerFactory.getLogger(TourApiClient.class);

    private final RestClient restClient;
    private final String baseUrl;
    private final String searchKeywordPath;
    private final String detailImagePath;
    private final String detailCommonPath;
    private final String detailIntroPath;
    private final String serviceKey;
    private final String mobileOs;
    private final String mobileApp;
    private final String legalRegionCode;
    private final List<String> spotKeywords;
    private final AtomicBoolean missingServiceKeyLogged = new AtomicBoolean();

    public TourApiClient(
        RestClient.Builder restClientBuilder,
        @Value("${external.tour-api.base-url}") String baseUrl,
        @Value("${external.tour-api.search-keyword-path}") String searchKeywordPath,
        @Value("${external.tour-api.detail-image-path}") String detailImagePath,
        @Value("${external.tour-api.detail-common-path}") String detailCommonPath,
        @Value("${external.tour-api.detail-intro-path}") String detailIntroPath,
        @Value("${external.tour-api.service-key}") String serviceKey,
        @Value("${external.tour-api.mobile-os}") String mobileOs,
        @Value("${external.tour-api.mobile-app}") String mobileApp,
        @Value("${external.tour-api.legal-region-code}") String legalRegionCode,
        @Value("${external.tour-api.spot-keywords}") String spotKeywords
    ) {
        this.restClient = SpotEnrichmentHttp.build(restClientBuilder);
        this.baseUrl = baseUrl;
        this.searchKeywordPath = searchKeywordPath;
        this.detailImagePath = detailImagePath;
        this.detailCommonPath = detailCommonPath;
        this.detailIntroPath = detailIntroPath;
        this.serviceKey = serviceKey;
        this.mobileOs = mobileOs;
        this.mobileApp = mobileApp;
        this.legalRegionCode = legalRegionCode;
        this.spotKeywords = parseKeywords(spotKeywords);
    }

    public List<TourApiSpotItem> searchPotatoSpots(int pageNo, int numOfRows) {
        if (serviceKey == null || serviceKey.isBlank()) {
            logMissingServiceKey();
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

    public List<TourApiSpotItem> searchByKeyword(String keyword, int numOfRows) {
        if (serviceKey == null || serviceKey.isBlank()) {
            logMissingServiceKey();
            throw new IllegalStateException("TOUR_API_SERVICE_KEY가 설정되지 않았습니다.");
        }
        if (keyword == null || keyword.isBlank() || numOfRows <= 0) {
            return List.of();
        }
        return searchPotatoSpots(keyword.trim(), 1, Math.min(numOfRows, 10));
    }

    public Optional<String> findRepresentativeImage(String contentId) {
        return findRepresentativeImages(contentId, 1).stream().findFirst();
    }

    public List<String> findRepresentativeImages(String contentId, int limit) {
        if (serviceKey == null || serviceKey.isBlank()) {
            logMissingServiceKey();
            throw new IllegalStateException("TOUR_API_SERVICE_KEY가 설정되지 않았습니다.");
        }
        if (contentId == null || contentId.isBlank() || limit <= 0) {
            return List.of();
        }

        List<String> candidates = new ArrayList<>();
        candidates.addAll(findRepresentativeImagesFromCommon(contentId));
        if (validImageCandidates(candidates).size() >= limit) {
            return validImageCandidates(candidates).stream()
                .limit(limit)
                .toList();
        }

        JsonNode response = restClient.get()
            .uri(detailImageUri(contentId))
            .retrieve()
            .body(JsonNode.class);
        candidates.addAll(imageCandidates(response));

        return candidates.stream()
            .map(String::trim)
            .filter(value -> !value.isBlank())
            .distinct()
            .limit(limit)
            .toList();
    }

    private List<String> validImageCandidates(List<String> candidates) {
        return candidates.stream()
            .map(String::trim)
            .filter(value -> !value.isBlank())
            .distinct()
            .toList();
    }

    private List<String> findRepresentativeImagesFromCommon(String contentId) {
        try {
            JsonNode commonResponse = restClient.get()
                .uri(detailCommonUri(contentId))
                .retrieve()
                .body(JsonNode.class);
            return imageCandidatesFromCommon(firstItem(commonResponse));
        } catch (RuntimeException ignored) {
            return List.of();
        }
    }

    public Optional<SpotTourInfo> findSpotTourInfo(String contentId, Integer contentTypeId) {
        if (serviceKey == null || serviceKey.isBlank()) {
            logMissingServiceKey();
            throw new IllegalStateException("TOUR_API_SERVICE_KEY가 설정되지 않았습니다.");
        }
        if (contentId == null || contentId.isBlank()) {
            return Optional.empty();
        }

        JsonNode commonItem = fetchDetailItem(
            "detailCommon2",
            contentId,
            detailCommonUri(contentId)
        );
        JsonNode introItem = contentTypeId == null
            ? null
            : fetchDetailItem(
                "detailIntro2",
                contentId,
                detailIntroUri(contentId, contentTypeId)
            );

        SpotTourInfo tourInfo = new SpotTourInfo(
            readFirstText(commonItem, "overview"),
            readFirstText(
                introItem,
                "opentimefood",
                "usetime",
                "usetimeculture",
                "usetimeleports",
                "usetimefestival",
                "opentime"
            ),
            readFirstText(introItem, "restdate", "restdateculture", "restdateleports", "restdatefood", "restdateshopping"),
            readFirstText(introItem, "usefee", "usefeeleports", "expagerangeleports"),
            readFirstText(introItem, "parking", "parkingculture", "parkingleports", "parkingfood", "parkingshopping"),
            readFirstText(introItem, "infocenter", "infocenterculture", "infocenterleports", "infocenterfood", "infocentershopping")
        );
        if (isEmpty(tourInfo)) {
            return Optional.empty();
        }
        return Optional.of(tourInfo);
    }

    private void logMissingServiceKey() {
        if (missingServiceKeyLogged.compareAndSet(false, true)) {
            log.warn("TourAPI enrichment unavailable: TOUR_API_SERVICE_KEY is not configured");
        }
    }

    private JsonNode fetchDetailItem(String endpoint, String contentId, URI uri) {
        try {
            return firstItem(restClient.get()
                .uri(uri)
                .retrieve()
                .body(JsonNode.class));
        } catch (RuntimeException exception) {
            // 공통/소개 API는 서로 독립된 데이터이므로 한쪽 장애가 다른 쪽의
            // 정상 필드까지 숨기지 않게 하고, 키가 포함될 수 있는 예외 메시지는 기록하지 않는다.
            log.warn(
                "TourAPI detail response skipped. endpoint={}, contentId={}, errorType={}",
                endpoint,
                contentId,
                exception.getClass().getSimpleName()
            );
            return null;
        }
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

    private URI detailImageUri(String contentId) {
        String query = String.join("&",
            "serviceKey=%s".formatted(encodeServiceKey(serviceKey)),
            "MobileOS=%s".formatted(encode(mobileOs)),
            "MobileApp=%s".formatted(encode(mobileApp)),
            "_type=json",
            "contentId=%s".formatted(encode(contentId)),
            "imageYN=Y",
            "pageNo=1",
            "numOfRows=10"
        );
        return URI.create("%s%s?%s".formatted(normalizedBaseUrl(), normalizedDetailImagePath(), query));
    }

    private URI detailCommonUri(String contentId) {
        // KorService2 rejects the legacy *YN flags with resultCode=10, even with HTTP 200.
        String query = String.join("&",
            "serviceKey=%s".formatted(encodeServiceKey(serviceKey)),
            "MobileOS=%s".formatted(encode(mobileOs)),
            "MobileApp=%s".formatted(encode(mobileApp)),
            "_type=json",
            "contentId=%s".formatted(encode(contentId))
        );
        return URI.create("%s%s?%s".formatted(normalizedBaseUrl(), normalizedDetailCommonPath(), query));
    }

    private URI detailIntroUri(String contentId, Integer contentTypeId) {
        String query = String.join("&",
            "serviceKey=%s".formatted(encodeServiceKey(serviceKey)),
            "MobileOS=%s".formatted(encode(mobileOs)),
            "MobileApp=%s".formatted(encode(mobileApp)),
            "_type=json",
            "contentId=%s".formatted(encode(contentId)),
            "contentTypeId=%d".formatted(contentTypeId)
        );
        return URI.create("%s%s?%s".formatted(normalizedBaseUrl(), normalizedDetailIntroPath(), query));
    }

    private JsonNode firstItem(JsonNode response) {
        JsonNode itemNode = response == null
            ? null
            : response.path("response").path("body").path("items").path("item");
        if (itemNode == null || itemNode.isMissingNode() || itemNode.isNull()) {
            return null;
        }
        if (itemNode.isArray()) {
            return itemNode.isEmpty() ? null : itemNode.get(0);
        }
        return itemNode.isObject() ? itemNode : null;
    }

    private String readFirstText(JsonNode item, String... fieldNames) {
        if (item == null) {
            return null;
        }
        for (String fieldName : fieldNames) {
            String cleaned = cleanText(item.path(fieldName).asText(""));
            if (cleaned != null) {
                return cleaned;
            }
        }
        return null;
    }

    private String cleanText(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        String cleaned = value
            .replaceAll("(?i)<br\\s*/?>", " ")
            .replaceAll("<[^>]+>", " ")
            .replace("&nbsp;", " ")
            .replace("&amp;", "&")
            .replace("&lt;", "<")
            .replace("&gt;", ">")
            .replaceAll("\\s+", " ")
            .trim();
        return cleaned.isBlank() ? null : cleaned;
    }

    private boolean isEmpty(SpotTourInfo tourInfo) {
        return tourInfo.description() == null
            && tourInfo.openingHours() == null
            && tourInfo.closedDays() == null
            && tourInfo.admissionFee() == null
            && tourInfo.parking() == null
            && tourInfo.contactPhone() == null;
    }

    private List<String> imageCandidates(JsonNode response) {
        JsonNode itemNode = response == null
            ? null
            : response.path("response").path("body").path("items").path("item");
        if (itemNode == null || itemNode.isMissingNode() || itemNode.isNull()) {
            return List.of();
        }

        List<String> candidates = new ArrayList<>();
        if (itemNode.isArray()) {
            itemNode.forEach(item -> candidates.addAll(imageCandidatesFromItem(item)));
            return candidates;
        }
        if (itemNode.isObject()) {
            return imageCandidatesFromItem(itemNode);
        }
        return List.of();
    }

    private List<String> imageCandidatesFromItem(JsonNode item) {
        List<String> candidates = new ArrayList<>();
        addIfText(candidates, item.path("originimgurl"));
        addIfText(candidates, item.path("imgurl"));
        addIfText(candidates, item.path("smallimageurl"));
        return candidates;
    }

    private List<String> imageCandidatesFromCommon(JsonNode item) {
        if (item == null) {
            return List.of();
        }
        List<String> candidates = new ArrayList<>();
        addIfText(candidates, item.path("firstimage"));
        addIfText(candidates, item.path("firstimage2"));
        return candidates;
    }

    private void addIfText(List<String> candidates, JsonNode node) {
        if (node.isTextual()) {
            candidates.add(node.asText());
        }
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

    private String normalizedDetailImagePath() {
        if (detailImagePath.startsWith("/")) {
            return detailImagePath;
        }
        return "/%s".formatted(detailImagePath);
    }

    private String normalizedDetailCommonPath() {
        if (detailCommonPath.startsWith("/")) {
            return detailCommonPath;
        }
        return "/%s".formatted(detailCommonPath);
    }

    private String normalizedDetailIntroPath() {
        if (detailIntroPath.startsWith("/")) {
            return detailIntroPath;
        }
        return "/%s".formatted(detailIntroPath);
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
