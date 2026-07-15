package com.gamjamubwatna.coupon.api;

import jakarta.validation.constraints.NotBlank;

public record CouponUseRequest(
    @NotBlank(message = "QR payload는 필수입니다.") String payload
) {
}
