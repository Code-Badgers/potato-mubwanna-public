package com.gamjamubwatna.auth.infrastructure;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.nio.charset.StandardCharsets;
import java.time.Clock;
import java.time.Instant;
import java.util.Base64;
import java.util.Map;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class JwtTokenProvider {

    private static final String HMAC_ALGORITHM = "HmacSHA256";

    private final ObjectMapper objectMapper;
    private final Clock clock;
    private final String secret;
    private final long accessTokenTtlSeconds;
    private final long refreshTokenTtlSeconds;

    public JwtTokenProvider(
        ObjectMapper objectMapper,
        @Value("${auth.jwt.secret}") String secret,
        @Value("${auth.jwt.access-token-ttl-seconds}") long accessTokenTtlSeconds,
        @Value("${auth.jwt.refresh-token-ttl-seconds}") long refreshTokenTtlSeconds
    ) {
        this(objectMapper, Clock.systemUTC(), secret, accessTokenTtlSeconds, refreshTokenTtlSeconds);
    }

    public JwtTokenProvider(
        ObjectMapper objectMapper,
        Clock clock,
        String secret,
        long accessTokenTtlSeconds,
        long refreshTokenTtlSeconds
    ) {
        this.objectMapper = objectMapper;
        this.clock = clock;
        this.secret = secret;
        this.accessTokenTtlSeconds = accessTokenTtlSeconds;
        this.refreshTokenTtlSeconds = refreshTokenTtlSeconds;
    }

    public String createAccessToken(String subject) {
        return createToken(subject, "access", accessTokenTtlSeconds);
    }

    public String createRefreshToken(String subject) {
        return createToken(subject, "refresh", refreshTokenTtlSeconds);
    }

    private String createToken(String subject, String tokenType, long ttlSeconds) {
        Instant now = Instant.now(clock);
        Map<String, Object> header = Map.of(
            "alg", "HS256",
            "typ", "JWT"
        );
        Map<String, Object> payload = Map.of(
            "sub", subject,
            "type", tokenType,
            "iat", now.getEpochSecond(),
            "exp", now.plusSeconds(ttlSeconds).getEpochSecond()
        );

        String unsignedToken = "%s.%s".formatted(encodeJson(header), encodeJson(payload));
        return "%s.%s".formatted(unsignedToken, sign(unsignedToken));
    }

    private String encodeJson(Map<String, Object> value) {
        try {
            return Base64.getUrlEncoder()
                .withoutPadding()
                .encodeToString(objectMapper.writeValueAsBytes(value));
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("JWT payload 직렬화에 실패했습니다.", exception);
        }
    }

    private String sign(String unsignedToken) {
        try {
            Mac mac = Mac.getInstance(HMAC_ALGORITHM);
            mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), HMAC_ALGORITHM));
            return Base64.getUrlEncoder()
                .withoutPadding()
                .encodeToString(mac.doFinal(unsignedToken.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception exception) {
            throw new IllegalStateException("JWT 서명에 실패했습니다.", exception);
        }
    }
}
