package com.gamjamubwatna.coupon.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "coupons")
public class Coupon {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "coupon_id")
    private Long id;

    @Column(name = "code", unique = true, length = 80)
    private String code;

    @Column(name = "name", nullable = false, length = 255)
    private String name;

    @Column(name = "description", nullable = false, length = 500)
    private String description;

    @Column(name = "benefit_amount", nullable = false)
    private int benefitAmount;

    @Column(name = "usage_place", nullable = false, length = 255)
    private String usagePlace;

    @Column(name = "valid_days", nullable = false)
    private int validDays;

    protected Coupon() {
    }

    public Coupon(String name, String description, int benefitAmount, String usagePlace) {
        this(null, name, description, benefitAmount, usagePlace, 30);
    }

    public Coupon(
        String code,
        String name,
        String description,
        int benefitAmount,
        String usagePlace,
        int validDays
    ) {
        if (code != null && code.isBlank()) {
            throw new IllegalArgumentException("쿠폰 코드는 공백일 수 없습니다.");
        }
        if (name == null || name.isBlank()) {
            throw new IllegalArgumentException("쿠폰 이름은 필수입니다.");
        }
        if (description == null || description.isBlank()) {
            throw new IllegalArgumentException("쿠폰 설명은 필수입니다.");
        }
        if (benefitAmount < 0) {
            throw new IllegalArgumentException("혜택 금액은 0원 이상이어야 합니다.");
        }
        if (usagePlace == null || usagePlace.isBlank()) {
            throw new IllegalArgumentException("사용 장소는 필수입니다.");
        }
        if (validDays <= 0) {
            throw new IllegalArgumentException("쿠폰 유효일은 1일 이상이어야 합니다.");
        }
        this.code = code;
        this.name = name;
        this.description = description;
        this.benefitAmount = benefitAmount;
        this.usagePlace = usagePlace;
        this.validDays = validDays;
    }

    public Long getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public String getCode() {
        return code;
    }

    public String getDescription() {
        return description;
    }

    public int getBenefitAmount() {
        return benefitAmount;
    }

    public String getUsagePlace() {
        return usagePlace;
    }

    public int getValidDays() {
        return validDays;
    }
}
