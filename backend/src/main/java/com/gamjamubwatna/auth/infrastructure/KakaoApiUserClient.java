package com.gamjamubwatna.auth.infrastructure;

import com.fasterxml.jackson.annotation.JsonProperty;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

@Component
public class KakaoApiUserClient implements KakaoUserClient {

    private final RestClient restClient;

    public KakaoApiUserClient(
        RestClient.Builder restClientBuilder,
        @Value("${auth.kakao.user-info-uri}") String userInfoUri
    ) {
        this.restClient = restClientBuilder.baseUrl(userInfoUri).build();
    }

    @Override
    public KakaoUserInfo fetchUser(String accessToken) {
        KakaoUserResponse response = restClient.get()
            .header(HttpHeaders.AUTHORIZATION, "Bearer %s".formatted(accessToken))
            .retrieve()
            .body(KakaoUserResponse.class);

        if (response == null || response.id() == null) {
            throw new IllegalStateException("카카오 사용자 정보를 확인할 수 없습니다.");
        }

        KakaoAccount account = response.kakaoAccount();
        KakaoProfile profile = account == null ? null : account.profile();

        return new KakaoUserInfo(
            response.id(),
            account == null ? null : account.email(),
            profile == null ? null : profile.nickname(),
            profile == null ? null : profile.profileImageUrl()
        );
    }

    private record KakaoUserResponse(
        Long id,
        @JsonProperty("kakao_account")
        KakaoAccount kakaoAccount
    ) {
    }

    private record KakaoAccount(
        String email,
        KakaoProfile profile
    ) {
    }

    private record KakaoProfile(
        String nickname,
        @JsonProperty("profile_image_url")
        String profileImageUrl
    ) {
    }
}
