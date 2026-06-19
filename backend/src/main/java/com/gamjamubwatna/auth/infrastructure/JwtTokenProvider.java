package com.gamjamubwatna.auth.infrastructure;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.nio.charset.StandardCharsets;
import java.time.Clock;
import java.time.Instant;
import java.util.Base64;
import java.util.Map;
import java.util.UUID;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class JwtTokenProvider {

    private static final String HMAC_ALGORITHM = "HmacSHA256";
    private static final TypeReference<Map<String, Object>> PAYLOAD_TYPE = new TypeReference<>() {
    };

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

    public JwtClaims parse(String token) {
        String[] parts = token.split("\\.");
        if (parts.length != 3) {
            throw new IllegalArgumentException("JWT 형식이 올바르지 않습니다.");
        }

        String unsignedToken = "%s.%s".formatted(parts[0], parts[1]);
        if (!sign(unsignedToken).equals(parts[2])) {
            throw new IllegalArgumentException("JWT 서명이 올바르지 않습니다.");
        }

        Map<String, Object> payload = decodePayload(parts[1]);
        String subject = (String) payload.get("sub");
        String tokenType = (String) payload.get("type");
        long expiresAt = ((Number) payload.get("exp")).longValue();

        if (Instant.now(clock).isAfter(Instant.ofEpochSecond(expiresAt))) {
            throw new IllegalArgumentException("JWT가 만료되었습니다.");
        }

        return new JwtClaims(subject, tokenType, Instant.ofEpochSecond(expiresAt));
    }

    public Instant getRefreshTokenExpiresAt() {
        return Instant.now(clock).plusSeconds(refreshTokenTtlSeconds);
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
            "jti", UUID.randomUUID().toString(),
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

    private Map<String, Object> decodePayload(String payload) {
        try {
            byte[] decoded = Base64.getUrlDecoder().decode(payload);
            return objectMapper.readValue(decoded, PAYLOAD_TYPE);
        } catch (Exception exception) {
            throw new IllegalArgumentException("JWT payload를 읽을 수 없습니다.", exception);
        }
    }

    public record JwtClaims(
        String subject,
        String tokenType,
        Instant expiresAt
    ) {
    }
}
