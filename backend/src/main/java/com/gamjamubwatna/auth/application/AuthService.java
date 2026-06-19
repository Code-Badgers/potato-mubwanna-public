package com.gamjamubwatna.auth.application;

import com.gamjamubwatna.auth.api.AuthLoginResponse;
import com.gamjamubwatna.auth.api.AuthUserResponse;
import com.gamjamubwatna.auth.infrastructure.JwtTokenProvider;
import com.gamjamubwatna.auth.infrastructure.KakaoUserClient;
import com.gamjamubwatna.auth.infrastructure.KakaoUserInfo;
import org.springframework.stereotype.Service;

@Service
public class AuthService {

    private final KakaoUserClient kakaoUserClient;
    private final JwtTokenProvider jwtTokenProvider;

    public AuthService(
        KakaoUserClient kakaoUserClient,
        JwtTokenProvider jwtTokenProvider
    ) {
        this.kakaoUserClient = kakaoUserClient;
        this.jwtTokenProvider = jwtTokenProvider;
    }

    public AuthLoginResponse loginWithKakao(String kakaoAccessToken) {
        KakaoUserInfo kakaoUser = kakaoUserClient.fetchUser(kakaoAccessToken);
        String subject = "kakao:%s".formatted(kakaoUser.id());

        return new AuthLoginResponse(
            jwtTokenProvider.createAccessToken(subject),
            jwtTokenProvider.createRefreshToken(subject),
            new AuthUserResponse(
                kakaoUser.id(),
                kakaoUser.email(),
                kakaoUser.nickname(),
                kakaoUser.profileImage()
            )
        );
    }
}
