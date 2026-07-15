package com.gamjamubwatna.coupon.application;

import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.coupon.api.CouponDetailResponse;
import com.gamjamubwatna.coupon.api.CouponListResponse;
import com.gamjamubwatna.coupon.api.CouponSummaryResponse;
import com.gamjamubwatna.coupon.domain.UserCoupon;
import com.gamjamubwatna.coupon.domain.UserCouponRepository;
import java.time.Clock;
import java.time.Instant;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class CouponQueryService {

    private final UserRepository userRepository;
    private final UserCouponRepository userCouponRepository;
    private final Clock clock;

    @Autowired
    public CouponQueryService(
        UserRepository userRepository,
        UserCouponRepository userCouponRepository
    ) {
        this(userRepository, userCouponRepository, Clock.systemUTC());
    }

    CouponQueryService(
        UserRepository userRepository,
        UserCouponRepository userCouponRepository,
        Clock clock
    ) {
        this.userRepository = userRepository;
        this.userCouponRepository = userCouponRepository;
        this.clock = clock;
    }

    public CouponListResponse getMyCoupons(Long userId) {
        validateUser(userId);
        Instant now = clock.instant();
        return new CouponListResponse(
            userCouponRepository.findByUserIdOrderByIssuedAtDesc(userId).stream()
                .map(userCoupon -> CouponSummaryResponse.from(userCoupon, now))
                .toList()
        );
    }

    public CouponDetailResponse getCoupon(Long userId, Long userCouponId) {
        validateUser(userId);
        UserCoupon userCoupon = userCouponRepository.findByIdAndUserId(userCouponId, userId)
            .orElseThrow(() -> new CouponNotFoundException("쿠폰을 찾을 수 없습니다."));
        return CouponDetailResponse.from(userCoupon, clock.instant());
    }

    private void validateUser(Long userId) {
        if (!userRepository.existsById(userId)) {
            throw new CouponAuthenticationException("사용자를 찾을 수 없습니다.");
        }
    }
}
