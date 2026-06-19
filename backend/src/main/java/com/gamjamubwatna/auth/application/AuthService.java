package com.gamjamubwatna.auth.application;

import com.gamjamubwatna.auth.api.AuthLoginResponse;
import com.gamjamubwatna.auth.api.AuthUserResponse;
import com.gamjamubwatna.auth.domain.AuthProvider;
import com.gamjamubwatna.auth.domain.RefreshToken;
import com.gamjamubwatna.auth.domain.RefreshTokenRepository;
import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.auth.infrastructure.JwtTokenProvider;
import com.gamjamubwatna.auth.infrastructure.KakaoUserClient;
import com.gamjamubwatna.auth.infrastructure.KakaoUserInfo;
import java.time.Clock;
import java.time.Instant;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {

    private final KakaoUserClient kakaoUserClient;
    private final JwtTokenProvider jwtTokenProvider;
    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final Clock clock;

    public AuthService(
        KakaoUserClient kakaoUserClient,
        JwtTokenProvider jwtTokenProvider,
        UserRepository userRepository,
        RefreshTokenRepository refreshTokenRepository
    ) {
        this(kakaoUserClient, jwtTokenProvider, userRepository, refreshTokenRepository, Clock.systemUTC());
    }

    public AuthService(
        KakaoUserClient kakaoUserClient,
        JwtTokenProvider jwtTokenProvider,
        UserRepository userRepository,
        RefreshTokenRepository refreshTokenRepository,
        Clock clock
    ) {
        this.kakaoUserClient = kakaoUserClient;
        this.jwtTokenProvider = jwtTokenProvider;
        this.userRepository = userRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.clock = clock;
    }

    @Transactional
    public AuthLoginResponse loginWithKakao(String kakaoAccessToken) {
        KakaoUserInfo kakaoUser = kakaoUserClient.fetchUser(kakaoAccessToken);
        User user = findOrCreateUser(kakaoUser);

        return issueTokens(user);
    }

    @Transactional
    public AuthLoginResponse refresh(String refreshTokenValue) {
        RefreshToken refreshToken = refreshTokenRepository.findByToken(refreshTokenValue)
            .orElseThrow(() -> new IllegalArgumentException("유효하지 않은 refreshToken입니다."));

        Instant now = Instant.now(clock);
        if (!refreshToken.isUsable(now)) {
            throw new IllegalArgumentException("사용할 수 없는 refreshToken입니다.");
        }

        JwtTokenProvider.JwtClaims claims = jwtTokenProvider.parse(refreshTokenValue);
        if (!"refresh".equals(claims.tokenType())) {
            throw new IllegalArgumentException("refreshToken 형식이 아닙니다.");
        }

        refreshToken.revoke();
        return issueTokens(refreshToken.getUser());
    }

    @Transactional
    public void logout(String refreshTokenValue) {
        refreshTokenRepository.findByToken(refreshTokenValue)
            .ifPresent(RefreshToken::revoke);
    }

    private User findOrCreateUser(KakaoUserInfo kakaoUser) {
        Instant now = Instant.now(clock);
        return userRepository.findByProviderAndProviderUserId(
                AuthProvider.KAKAO,
                String.valueOf(kakaoUser.id())
            )
            .map(user -> {
                user.updateProfile(
                    kakaoUser.email(),
                    defaultNickname(kakaoUser.nickname()),
                    kakaoUser.profileImage(),
                    now
                );
                return user;
            })
            .orElseGet(() -> userRepository.save(new User(
                AuthProvider.KAKAO,
                String.valueOf(kakaoUser.id()),
                kakaoUser.email(),
                defaultNickname(kakaoUser.nickname()),
                kakaoUser.profileImage(),
                now
            )));
    }

    private AuthLoginResponse issueTokens(User user) {
        String subject = "user:%s".formatted(user.getId());
        String accessToken = jwtTokenProvider.createAccessToken(subject);
        String refreshTokenValue = jwtTokenProvider.createRefreshToken(subject);

        refreshTokenRepository.save(new RefreshToken(
            user,
            refreshTokenValue,
            jwtTokenProvider.getRefreshTokenExpiresAt()
        ));

        return new AuthLoginResponse(
            accessToken,
            refreshTokenValue,
            new AuthUserResponse(
                user.getId(),
                user.getEmail(),
                user.getNickname(),
                user.getProfileImage()
            )
        );
    }

    private String defaultNickname(String nickname) {
        if (nickname == null || nickname.isBlank()) {
            return "감자러버";
        }
        return nickname;
    }
}
