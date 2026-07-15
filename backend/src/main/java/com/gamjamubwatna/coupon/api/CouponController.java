package com.gamjamubwatna.coupon.api;

import com.gamjamubwatna.auth.api.AuthApiResponse;
import com.gamjamubwatna.coupon.application.CouponAuthenticationException;
import com.gamjamubwatna.coupon.application.CouponNotFoundException;
import com.gamjamubwatna.coupon.application.CouponQueryService;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/coupons")
public class CouponController {

    private static final Pattern USER_PRINCIPAL_PATTERN = Pattern.compile("^user:([1-9]\\d*)$");

    private final CouponQueryService couponQueryService;

    public CouponController(CouponQueryService couponQueryService) {
        this.couponQueryService = couponQueryService;
    }

    @GetMapping("/me")
    public ResponseEntity<AuthApiResponse<CouponListResponse>> getMyCoupons(
        Authentication authentication
    ) {
        try {
            return ResponseEntity.ok(AuthApiResponse.success(
                couponQueryService.getMyCoupons(userId(authentication))
            ));
        } catch (CouponAuthenticationException exception) {
            return unauthorized();
        }
    }

    @GetMapping("/{userCouponId}")
    public ResponseEntity<AuthApiResponse<CouponDetailResponse>> getCoupon(
        @PathVariable Long userCouponId,
        Authentication authentication
    ) {
        try {
            return ResponseEntity.ok(AuthApiResponse.success(
                couponQueryService.getCoupon(userId(authentication), userCouponId)
            ));
        } catch (CouponAuthenticationException exception) {
            return unauthorized();
        } catch (CouponNotFoundException exception) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(AuthApiResponse.failure("쿠폰을 찾을 수 없습니다."));
        }
    }

    private Long userId(Authentication authentication) {
        if (authentication == null || authentication.getName() == null) {
            throw invalidPrincipal();
        }

        Matcher matcher = USER_PRINCIPAL_PATTERN.matcher(authentication.getName());
        if (!matcher.matches()) {
            throw invalidPrincipal();
        }

        try {
            return Long.parseLong(matcher.group(1));
        } catch (NumberFormatException exception) {
            throw invalidPrincipal();
        }
    }

    private CouponAuthenticationException invalidPrincipal() {
        return new CouponAuthenticationException("유효하지 않은 인증 사용자입니다.");
    }

    private <T> ResponseEntity<AuthApiResponse<T>> unauthorized() {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
            .body(AuthApiResponse.failure("인증 정보를 확인할 수 없습니다."));
    }
}
