package com.gamjamubwatna.coupon.infrastructure;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import org.junit.jupiter.api.Test;

class CouponQrTokenProviderTest {

    private static final Instant NOW = Instant.parse("2026-07-15T00:00:00Z");
    private static final String SECRET = "test-coupon-qr-secret-must-be-long-enough";

    @Test
    void createsSignedShortLivedCouponPayload() {
        CouponQrTokenProvider provider = providerAt(NOW);

        CouponQrTokenProvider.CouponQrToken token = provider.create(
            3L,
            1L,
            NOW.plusSeconds(600)
        );
        CouponQrTokenProvider.CouponQrClaims claims = provider.parse(token.payload());

        assertThat(claims.userCouponId()).isEqualTo(3L);
        assertThat(claims.userId()).isEqualTo(1L);
        assertThat(token.expiresAt()).isEqualTo(NOW.plusSeconds(300));
    }

    @Test
    void capsQrExpirationAtCouponExpiration() {
        CouponQrTokenProvider provider = providerAt(NOW);

        CouponQrTokenProvider.CouponQrToken token = provider.create(
            3L,
            1L,
            NOW.plusSeconds(60)
        );

        assertThat(token.expiresAt()).isEqualTo(NOW.plusSeconds(60));
    }

    @Test
    void rejectsTamperedOrExpiredPayload() {
        CouponQrTokenProvider provider = providerAt(NOW);
        String payload = provider.create(3L, 1L, NOW.plusSeconds(600)).payload();
        String tampered = "A" + payload.substring(1);

        assertThatThrownBy(() -> provider.parse(tampered))
            .isInstanceOf(IllegalArgumentException.class);

        CouponQrTokenProvider expiredProvider = providerAt(NOW.plusSeconds(300));
        assertThatThrownBy(() -> expiredProvider.parse(payload))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessage("쿠폰 QR payload가 유효하지 않거나 만료되었습니다.");
    }

    @Test
    void rejectsSigningKeyShorterThan32Bytes() {
        assertThatThrownBy(() -> new CouponQrTokenProvider(
            new ObjectMapper(),
            Clock.fixed(NOW, ZoneOffset.UTC),
            "short-secret",
            300
        ))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessage("쿠폰 QR 서명 키는 최소 32바이트(256비트) 이상이어야 합니다.");
    }

    private CouponQrTokenProvider providerAt(Instant instant) {
        return new CouponQrTokenProvider(
            new ObjectMapper(),
            Clock.fixed(instant, ZoneOffset.UTC),
            SECRET,
            300
        );
    }
}
