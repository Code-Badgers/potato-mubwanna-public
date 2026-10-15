package com.gamjamubwatna.auth.application;

import com.gamjamubwatna.auth.api.AuthLoginResponse;
import com.gamjamubwatna.auth.api.AuthUserResponse;
import com.gamjamubwatna.auth.domain.AuthProvider;
import com.gamjamubwatna.auth.domain.RefreshToken;
import com.gamjamubwatna.auth.domain.RefreshTokenRepository;
import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.auth.infrastructure.JwtTokenProvider;
import com.gamjamubwatna.auth.infrastructure.KakaoAuthorizationCodeClient;
import com.gamjamubwatna.auth.infrastructure.KakaoUserClient;
import com.gamjamubwatna.auth.infrastructure.KakaoUserInfo;
import com.gamjamubwatna.potato.application.StarterPotatoGrantService;
import java.time.Clock;
import java.time.Instant;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {

    private final KakaoUserClient kakaoUserClient;
    private final KakaoAuthorizationCodeClient kakaoAuthorizationCodeClient;
    private final JwtTokenProvider jwtTokenProvider;
    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final StarterPotatoGrantService starterPotatoGrantService;
    private final Clock clock;

    @Autowired
    public AuthService(
        KakaoUserClient kakaoUserClient,
        KakaoAuthorizationCodeClient kakaoAuthorizationCodeClient,
        JwtTokenProvider jwtTokenProvider,
        UserRepository userRepository,
        RefreshTokenRepository refreshTokenRepository,
        StarterPotatoGrantService starterPotatoGrantService
    ) {
        this(
            kakaoUserClient,
            kakaoAuthorizationCodeClient,
            jwtTokenProvider,
            userRepository,
            refreshTokenRepository,
            starterPotatoGrantService,
            Clock.systemUTC()
        );
    }

    public AuthService(
        KakaoUserClient kakaoUserClient,
        KakaoAuthorizationCodeClient kakaoAuthorizationCodeClient,
        JwtTokenProvider jwtTokenProvider,
        UserRepository userRepository,
        RefreshTokenRepository refreshTokenRepository,
        StarterPotatoGrantService starterPotatoGrantService,
        Clock clock
    ) {
        this.kakaoUserClient = kakaoUserClient;
        this.kakaoAuthorizationCodeClient = kakaoAuthorizationCodeClient;
        this.jwtTokenProvider = jwtTokenProvider;
        this.userRepository = userRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.starterPotatoGrantService = starterPotatoGrantService;
        this.clock = clock;
    }

    @Transactional
    public AuthLoginResponse loginWithKakao(String kakaoAccessToken) {
        KakaoUserInfo kakaoUser = kakaoUserClient.fetchUser(kakaoAccessToken);
        User user = findOrCreateUser(kakaoUser);
        starterPotatoGrantService.grantIfNeeded(user, Instant.now(clock));

        return issueTokens(user);
    }

    @Transactional
    public AuthLoginResponse loginWithKakaoAuthorizationCode(
        String authorizationCode,
        String redirectUri
    ) {
        String kakaoAccessToken = kakaoAuthorizationCodeClient.exchange(
            authorizationCode,
            redirectUri
        );
        return loginWithKakao(kakaoAccessToken);
    }

    @Transactional
    public AuthLoginResponse refresh(String refreshTokenValue) {
        RefreshToken refreshToken = refreshTokenRepository.findByToken(refreshTokenValue)
            .orElseThrow(InvalidRefreshTokenException::new);

        Instant now = Instant.now(clock);
        if (!refreshToken.isUsable(now)) {
            throw new InvalidRefreshTokenException();
        }

        JwtTokenProvider.JwtClaims claims;
        try {
            claims = jwtTokenProvider.parse(refreshTokenValue);
        } catch (IllegalArgumentException exception) {
            // 토큰 검증 실패만 인증 거절로 분류하고 DB/보상 처리 장애는 그대로 전파한다.
            throw new InvalidRefreshTokenException();
        }
        if (!"refresh".equals(claims.tokenType())) {
            throw new InvalidRefreshTokenException();
        }

        starterPotatoGrantService.grantIfNeeded(refreshToken.getUser(), now);
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
