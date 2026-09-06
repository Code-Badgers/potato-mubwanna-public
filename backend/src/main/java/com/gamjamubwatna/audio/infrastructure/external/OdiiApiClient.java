package com.gamjamubwatna.audio.infrastructure.external;

import com.fasterxml.jackson.databind.JsonNode;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestClient;
import org.springframework.web.util.UriUtils;

@Component
public class OdiiApiClient {

    private final RestClient restClient;
    private final String baseUrl;
    private final String storySearchPath;
    private final String serviceKey;
    private final String mobileOs;
    private final String mobileApp;
    private final String language;

    public OdiiApiClient(
        RestClient.Builder restClientBuilder,
        @Value("${external.odii-api.base-url}") String baseUrl,
        @Value("${external.odii-api.story-search-path}") String storySearchPath,
        @Value("${external.odii-api.service-key}") String serviceKey,
        @Value("${external.odii-api.mobile-os}") String mobileOs,
        @Value("${external.odii-api.mobile-app}") String mobileApp,
        @Value("${external.odii-api.language}") String language
    ) {
        // 오디 연결 실패가 오디오 영역을 무기한 로딩 상태로 남기지 않도록 제한한다.
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(Duration.ofSeconds(2));
        factory.setReadTimeout(Duration.ofSeconds(3));
        this.restClient = restClientBuilder.clone().requestFactory(factory).build();
        this.baseUrl = baseUrl;
        this.storySearchPath = storySearchPath;
        this.serviceKey = serviceKey;
        this.mobileOs = mobileOs;
        this.mobileApp = mobileApp;
        this.language = language;
    }

    public List<OdiiStory> searchStories(String keyword) {
        if (serviceKey == null || serviceKey.isBlank()) {
            throw new OdiiApiException("ODII_API_SERVICE_KEY가 설정되지 않았습니다.");
        }

        try {
            OdiiSearchEnvelope envelope = restClient.get()
                .uri(searchUri(keyword))
                .retrieve()
                .body(OdiiSearchEnvelope.class);

            OdiiSearchResponse response = envelope == null ? null : envelope.response();
            validateResponse(response);
            return stories(response.body());
        } catch (OdiiApiException exception) {
            throw exception;
        } catch (RuntimeException exception) {
            throw new OdiiApiException("오디 API 호출에 실패했습니다.", exception);
        }
    }

    private void validateResponse(OdiiSearchResponse response) {
        if (response == null || response.header() == null) {
            throw new OdiiApiException("오디 API 응답 형식을 확인할 수 없습니다.");
        }
        String resultCode = response.header().resultCode();
        if (!"00".equals(resultCode) && !"0000".equals(resultCode)) {
            throw new OdiiApiException("오디 API 오류: %s".formatted(response.header().resultMsg()));
        }
    }

    private URI searchUri(String keyword) {
        String query = String.join("&",
            "serviceKey=%s".formatted(encodeServiceKey(serviceKey)),
            "MobileOS=%s".formatted(encode(mobileOs)),
            "MobileApp=%s".formatted(encode(mobileApp)),
            "_type=json",
            "keyword=%s".formatted(encode(keyword)),
            "langCode=%s".formatted(encode(language)),
            "pageNo=1",
            "numOfRows=100"
        );
        return URI.create("%s%s?%s".formatted(normalizedBaseUrl(), normalizedPath(), query));
    }

    private String normalizedBaseUrl() {
        return baseUrl.endsWith("/") ? baseUrl.substring(0, baseUrl.length() - 1) : baseUrl;
    }

    private String normalizedPath() {
        return storySearchPath.startsWith("/") ? storySearchPath : "/%s".formatted(storySearchPath);
    }

    private String encode(String value) {
        return UriUtils.encodeQueryParam(value, StandardCharsets.UTF_8);
    }

    private String encodeServiceKey(String value) {
        return value.contains("%")
            ? value
            : UriUtils.encode(value, StandardCharsets.UTF_8);
    }

    private List<OdiiStory> stories(OdiiBody body) {
        if (body == null || body.items() == null || !body.items().isObject()) {
            return List.of();
        }

        JsonNode itemNode = body.items().get("item");
        if (itemNode == null || itemNode.isNull()) {
            return List.of();
        }

        List<OdiiStory> stories = new ArrayList<>();
        if (itemNode.isArray()) {
            itemNode.forEach(item -> stories.add(story(item)));
        } else if (itemNode.isObject()) {
            stories.add(story(itemNode));
        }
        return stories;
    }

    private OdiiStory story(JsonNode item) {
        return new OdiiStory(
            text(item, "tid"),
            text(item, "tlid"),
            text(item, "stid"),
            text(item, "stlid"),
            text(item, "title"),
            text(item, "audioTitle"),
            text(item, "script"),
            text(item, "audioUrl"),
            text(item, "langCode")
        );
    }

    private String text(JsonNode item, String fieldName) {
        JsonNode value = item.get(fieldName);
        return value == null || value.isNull() ? null : value.asText();
    }

    public record OdiiStory(
        String tid,
        String tlid,
        String stid,
        String stlid,
        String title,
        String audioTitle,
        String script,
        String audioUrl,
        String langCode
    ) {
    }

    private record OdiiSearchEnvelope(OdiiSearchResponse response) {
    }

    private record OdiiSearchResponse(OdiiHeader header, OdiiBody body) {
    }

    private record OdiiHeader(String resultCode, String resultMsg) {
    }

    private record OdiiBody(JsonNode items) {
    }
}
