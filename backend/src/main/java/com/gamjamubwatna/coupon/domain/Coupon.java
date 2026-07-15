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

    @Column(name = "name", nullable = false, length = 255)
    private String name;

    @Column(name = "description", nullable = false, length = 500)
    private String description;

    @Column(name = "benefit_amount", nullable = false)
    private int benefitAmount;

    @Column(name = "usage_place", nullable = false, length = 255)
    private String usagePlace;

    protected Coupon() {
    }

    public Coupon(String name, String description, int benefitAmount, String usagePlace) {
        this.name = name;
        this.description = description;
        this.benefitAmount = benefitAmount;
        this.usagePlace = usagePlace;
    }

    public Long getId() {
        return id;
    }

    public String getName() {
        return name;
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
}
