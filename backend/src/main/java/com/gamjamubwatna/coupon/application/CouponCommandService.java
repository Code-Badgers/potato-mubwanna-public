package com.gamjamubwatna.coupon.application;

import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.coupon.api.CouponDetailResponse;
import com.gamjamubwatna.coupon.api.CouponQrResponse;
import com.gamjamubwatna.coupon.domain.CouponDisplayStatus;
import com.gamjamubwatna.coupon.domain.UserCoupon;
import com.gamjamubwatna.coupon.domain.UserCouponRepository;
import com.gamjamubwatna.coupon.infrastructure.CouponQrTokenProvider;
import com.gamjamubwatna.coupon.infrastructure.CouponQrTokenProvider.CouponQrClaims;
import com.gamjamubwatna.coupon.infrastructure.CouponQrTokenProvider.CouponQrToken;
import java.time.Clock;
import java.time.Instant;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class CouponCommandService {

    private final UserRepository userRepository;
    private final UserCouponRepository userCouponRepository;
    private final CouponQrTokenProvider couponQrTokenProvider;
    private final Clock clock;

    @Autowired
    public CouponCommandService(
        UserRepository userRepository,
        UserCouponRepository userCouponRepository,
        CouponQrTokenProvider couponQrTokenProvider
    ) {
        this(userRepository, userCouponRepository, couponQrTokenProvider, Clock.systemUTC());
    }

    CouponCommandService(
        UserRepository userRepository,
        UserCouponRepository userCouponRepository,
        CouponQrTokenProvider couponQrTokenProvider,
        Clock clock
    ) {
        this.userRepository = userRepository;
        this.userCouponRepository = userCouponRepository;
        this.couponQrTokenProvider = couponQrTokenProvider;
        this.clock = clock;
    }

    @Transactional(readOnly = true)
    public CouponQrResponse getQr(Long userId, Long userCouponId) {
        validateUser(userId);
        UserCoupon userCoupon = findOwnedCoupon(userId, userCouponId);
        Instant now = clock.instant();
        if (userCoupon.displayStatus(now) != CouponDisplayStatus.AVAILABLE) {
            throw new CouponConflictException("사용 가능한 쿠폰만 QR을 확인할 수 있습니다.");
        }

        CouponQrToken token = couponQrTokenProvider.create(
            userCouponId,
            userId,
            userCoupon.getExpiresAt()
        );
        return new CouponQrResponse(userCouponId, token.payload(), token.expiresAt());
    }

    public CouponDetailResponse useCoupon(Long userId, Long userCouponId, String payload) {
        validateUser(userId);
        UserCoupon userCoupon = userCouponRepository.findByIdAndUserIdForUpdate(userCouponId, userId)
            .orElseThrow(() -> new CouponNotFoundException("쿠폰을 찾을 수 없습니다."));

        CouponQrClaims claims = parsePayload(payload);
        if (!userCouponId.equals(claims.userCouponId()) || !userId.equals(claims.userId())) {
            throw new CouponConflictException("쿠폰 QR payload가 일치하지 않습니다.");
        }

        Instant now = clock.instant();
        try {
            userCoupon.use(now);
        } catch (IllegalStateException exception) {
            throw new CouponConflictException(exception.getMessage());
        }
        return CouponDetailResponse.from(userCoupon, now);
    }

    private UserCoupon findOwnedCoupon(Long userId, Long userCouponId) {
        return userCouponRepository.findByIdAndUserId(userCouponId, userId)
            .orElseThrow(() -> new CouponNotFoundException("쿠폰을 찾을 수 없습니다."));
    }

    private CouponQrClaims parsePayload(String payload) {
        try {
            return couponQrTokenProvider.parse(payload);
        } catch (IllegalArgumentException exception) {
            throw new CouponConflictException("쿠폰 QR payload가 유효하지 않거나 만료되었습니다.");
        }
    }

    private void validateUser(Long userId) {
        if (!userRepository.existsById(userId)) {
            throw new CouponAuthenticationException("사용자를 찾을 수 없습니다.");
        }
    }
}
