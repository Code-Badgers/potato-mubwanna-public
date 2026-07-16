package com.gamjamubwatna.audio.infrastructure.external;

import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
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
        this.restClient = restClientBuilder.build();
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
            OdiiSearchResponse response = restClient.get()
                .uri(searchUri(keyword))
                .retrieve()
                .body(OdiiSearchResponse.class);

            validateResponse(response);
            if (response.body() == null
                || response.body().items() == null
                || response.body().items().item() == null) {
                return List.of();
            }
            return response.body().items().item();
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
        return value.contains("%") ? value : encode(value);
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

    private record OdiiSearchResponse(OdiiHeader header, OdiiBody body) {
    }

    private record OdiiHeader(String resultCode, String resultMsg) {
    }

    private record OdiiBody(OdiiItems items) {
    }

    private record OdiiItems(List<OdiiStory> item) {
    }
}
