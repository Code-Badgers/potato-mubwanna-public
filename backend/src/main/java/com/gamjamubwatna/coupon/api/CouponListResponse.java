package com.gamjamubwatna.coupon.api;

import java.util.List;

public record CouponListResponse(
    List<CouponSummaryResponse> coupons
) {
}
