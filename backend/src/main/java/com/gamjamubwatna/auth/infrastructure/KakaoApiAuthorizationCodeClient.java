package com.gamjamubwatna.auth.infrastructure;

import com.fasterxml.jackson.annotation.JsonProperty;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestClient;

@Component
public class KakaoApiAuthorizationCodeClient implements KakaoAuthorizationCodeClient {

    private final RestClient restClient;
    private final String restApiKey;

    public KakaoApiAuthorizationCodeClient(
        RestClient.Builder restClientBuilder,
        @Value("${auth.kakao.token-uri}") String tokenUri,
        @Value("${auth.kakao.rest-api-key}") String restApiKey
    ) {
        this.restClient = restClientBuilder.baseUrl(tokenUri).build();
        this.restApiKey = restApiKey;
    }

    @Override
    public String exchange(String authorizationCode, String redirectUri) {
        if (restApiKey.isBlank()) {
            throw new IllegalStateException("KAKAO_REST_API_KEY가 설정되지 않았습니다.");
        }

        MultiValueMap<String, String> form = new LinkedMultiValueMap<>();
        form.add("grant_type", "authorization_code");
        form.add("client_id", restApiKey);
        form.add("redirect_uri", redirectUri);
        form.add("code", authorizationCode);

        KakaoTokenResponse response = restClient.post()
            .contentType(MediaType.APPLICATION_FORM_URLENCODED)
            .body(form)
            .retrieve()
            .body(KakaoTokenResponse.class);

        if (response == null || response.accessToken() == null || response.accessToken().isBlank()) {
            throw new IllegalStateException("카카오 access token을 발급받지 못했습니다.");
        }
        return response.accessToken();
    }

    private record KakaoTokenResponse(
        @JsonProperty("access_token")
        String accessToken
    ) {
    }
}
