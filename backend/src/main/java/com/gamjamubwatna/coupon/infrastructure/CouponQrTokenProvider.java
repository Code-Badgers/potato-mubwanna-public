package com.gamjamubwatna.coupon.infrastructure;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Clock;
import java.time.Instant;
import java.util.Base64;
import java.util.Map;
import java.util.UUID;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class CouponQrTokenProvider {

    private static final String HMAC_ALGORITHM = "HmacSHA256";
    private static final TypeReference<Map<String, Object>> PAYLOAD_TYPE = new TypeReference<>() {
    };

    private final ObjectMapper objectMapper;
    private final Clock clock;
    private final String secret;
    private final long ttlSeconds;

    @Autowired
    public CouponQrTokenProvider(
        ObjectMapper objectMapper,
        @Value("${coupon.qr.secret}") String secret,
        @Value("${coupon.qr.ttl-seconds}") long ttlSeconds
    ) {
        this(objectMapper, Clock.systemUTC(), secret, ttlSeconds);
    }

    public CouponQrTokenProvider(
        ObjectMapper objectMapper,
        Clock clock,
        String secret,
        long ttlSeconds
    ) {
        if (secret == null || secret.isBlank()) {
            throw new IllegalArgumentException("쿠폰 QR 서명 키는 필수입니다.");
        }
        if (ttlSeconds <= 0) {
            throw new IllegalArgumentException("쿠폰 QR 만료 시간은 0보다 커야 합니다.");
        }
        this.objectMapper = objectMapper;
        this.clock = clock;
        this.secret = secret;
        this.ttlSeconds = ttlSeconds;
    }

    public CouponQrToken create(Long userCouponId, Long userId, Instant couponExpiresAt) {
        Instant issuedAt = clock.instant();
        Instant expiresAt = issuedAt.plusSeconds(ttlSeconds);
        if (couponExpiresAt.isBefore(expiresAt)) {
            expiresAt = couponExpiresAt;
        }

        Map<String, Object> claims = Map.of(
            "userCouponId", userCouponId,
            "userId", userId,
            "nonce", UUID.randomUUID().toString(),
            "iat", issuedAt.getEpochSecond(),
            "exp", expiresAt.getEpochSecond()
        );
        String encodedPayload = encode(claims);
        String signature = Base64.getUrlEncoder().withoutPadding().encodeToString(sign(encodedPayload));
        return new CouponQrToken(encodedPayload + "." + signature, expiresAt);
    }

    public CouponQrClaims parse(String token) {
        try {
            String[] parts = token.split("\\.");
            if (parts.length != 2) {
                throw invalidToken();
            }
            byte[] actualSignature = Base64.getUrlDecoder().decode(parts[1]);
            if (!MessageDigest.isEqual(sign(parts[0]), actualSignature)) {
                throw invalidToken();
            }

            Map<String, Object> claims = decode(parts[0]);
            Long userCouponId = ((Number) claims.get("userCouponId")).longValue();
            Long userId = ((Number) claims.get("userId")).longValue();
            Instant expiresAt = Instant.ofEpochSecond(((Number) claims.get("exp")).longValue());
            if (!clock.instant().isBefore(expiresAt)) {
                throw invalidToken();
            }
            return new CouponQrClaims(userCouponId, userId, expiresAt);
        } catch (IllegalArgumentException exception) {
            throw exception;
        } catch (Exception exception) {
            throw invalidToken();
        }
    }

    private String encode(Map<String, Object> claims) {
        try {
            return Base64.getUrlEncoder().withoutPadding()
                .encodeToString(objectMapper.writeValueAsBytes(claims));
        } catch (Exception exception) {
            throw new IllegalStateException("쿠폰 QR payload 직렬화에 실패했습니다.", exception);
        }
    }

    private Map<String, Object> decode(String encodedPayload) {
        try {
            byte[] decoded = Base64.getUrlDecoder().decode(encodedPayload);
            return objectMapper.readValue(decoded, PAYLOAD_TYPE);
        } catch (Exception exception) {
            throw invalidToken();
        }
    }

    private byte[] sign(String encodedPayload) {
        try {
            Mac mac = Mac.getInstance(HMAC_ALGORITHM);
            mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), HMAC_ALGORITHM));
            return mac.doFinal(encodedPayload.getBytes(StandardCharsets.UTF_8));
        } catch (Exception exception) {
            throw new IllegalStateException("쿠폰 QR 서명에 실패했습니다.", exception);
        }
    }

    private IllegalArgumentException invalidToken() {
        return new IllegalArgumentException("쿠폰 QR payload가 유효하지 않거나 만료되었습니다.");
    }

    public record CouponQrToken(String payload, Instant expiresAt) {
    }

    public record CouponQrClaims(Long userCouponId, Long userId, Instant expiresAt) {
    }
}
