package com.gamjamubwatna.coupon.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;

class CouponTest {

    @Test
    void keepsCouponCodeAndValidityPeriod() {
        Coupon coupon = new Coupon("CP_TEST", "감자빵 교환권", "설명", 3000, "제휴점", 14);

        assertThat(coupon.getCode()).isEqualTo("CP_TEST");
        assertThat(coupon.getValidDays()).isEqualTo(14);
    }

    @Test
    void rejectsBlankCouponCodeWhenProvided() {
        assertThatThrownBy(() -> new Coupon(" ", "교환권", "설명", 0, "제휴점", 30))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessage("쿠폰 코드는 공백일 수 없습니다.");
    }

    @Test
    void rejectsNegativeBenefitAmount() {
        assertThatThrownBy(() -> new Coupon("감자빵 교환권", "설명", -1, "제휴점"))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessage("혜택 금액은 0원 이상이어야 합니다.");
    }

    @Test
    void rejectsBlankRequiredValues() {
        assertThatThrownBy(() -> new Coupon(" ", "설명", 0, "제휴점"))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessage("쿠폰 이름은 필수입니다.");
        assertThatThrownBy(() -> new Coupon("교환권", null, 0, "제휴점"))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessage("쿠폰 설명은 필수입니다.");
        assertThatThrownBy(() -> new Coupon("교환권", "설명", 0, ""))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessage("사용 장소는 필수입니다.");
    }

    @Test
    void rejectsNonPositiveValidityPeriod() {
        assertThatThrownBy(() -> new Coupon("CP_TEST", "교환권", "설명", 0, "제휴점", 0))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessage("쿠폰 유효일은 1일 이상이어야 합니다.");
    }
}
