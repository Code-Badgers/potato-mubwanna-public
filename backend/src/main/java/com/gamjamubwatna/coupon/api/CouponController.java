package com.gamjamubwatna.coupon.api;

import com.gamjamubwatna.auth.api.AuthApiResponse;
import com.gamjamubwatna.coupon.application.CouponAuthenticationException;
import com.gamjamubwatna.coupon.application.CouponCommandService;
import com.gamjamubwatna.coupon.application.CouponConflictException;
import com.gamjamubwatna.coupon.application.CouponNotFoundException;
import com.gamjamubwatna.coupon.application.CouponQueryService;
import jakarta.validation.Valid;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/coupons")
public class CouponController {

    private static final Pattern USER_PRINCIPAL_PATTERN = Pattern.compile("^user:([1-9]\\d*)$");

    private final CouponQueryService couponQueryService;
    private final CouponCommandService couponCommandService;

    public CouponController(
        CouponQueryService couponQueryService,
        CouponCommandService couponCommandService
    ) {
        this.couponQueryService = couponQueryService;
        this.couponCommandService = couponCommandService;
    }

    // 사용 가능한 본인 쿠폰을 짧게 만료되는 서명 QR payload로 발급한다.
    @GetMapping("/{userCouponId}/qr")
    public ResponseEntity<AuthApiResponse<CouponQrResponse>> getCouponQr(
        @PathVariable Long userCouponId,
        Authentication authentication
    ) {
        try {
            return ResponseEntity.ok(AuthApiResponse.success(
                couponCommandService.getQr(userId(authentication), userCouponId)
            ));
        } catch (CouponAuthenticationException exception) {
            return unauthorized();
        } catch (CouponNotFoundException exception) {
            return notFound();
        } catch (CouponConflictException exception) {
            return conflict(exception.getMessage());
        }
    }

    // QR에 서명된 사용자와 쿠폰을 검증한 뒤 해당 쿠폰을 한 번만 사용 처리한다.
    @PostMapping("/{userCouponId}/use")
    public ResponseEntity<AuthApiResponse<CouponDetailResponse>> useCoupon(
        @PathVariable Long userCouponId,
        @Valid @RequestBody CouponUseRequest request,
        Authentication authentication
    ) {
        try {
            return ResponseEntity.ok(AuthApiResponse.success(
                couponCommandService.useCoupon(
                    userId(authentication),
                    userCouponId,
                    request.payload()
                )
            ));
        } catch (CouponAuthenticationException exception) {
            return unauthorized();
        } catch (CouponNotFoundException exception) {
            return notFound();
        } catch (CouponConflictException exception) {
            return conflict(exception.getMessage());
        }
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

    private <T> ResponseEntity<AuthApiResponse<T>> notFound() {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(AuthApiResponse.failure("쿠폰을 찾을 수 없습니다."));
    }

    private <T> ResponseEntity<AuthApiResponse<T>> conflict(String message) {
        return ResponseEntity.status(HttpStatus.CONFLICT)
            .body(AuthApiResponse.failure(message));
    }
}
