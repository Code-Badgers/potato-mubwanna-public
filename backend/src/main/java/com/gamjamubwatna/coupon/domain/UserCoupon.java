package com.gamjamubwatna.coupon.domain;

import com.gamjamubwatna.auth.domain.User;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "user_coupons")
public class UserCoupon {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "user_coupon_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "coupon_id", nullable = false)
    private Coupon coupon;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    private UserCouponStatus status;

    @Column(name = "issued_at", nullable = false, updatable = false)
    private Instant issuedAt;

    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;

    @Column(name = "used_at")
    private Instant usedAt;

    protected UserCoupon() {
    }

    public UserCoupon(
        User user,
        Coupon coupon,
        UserCouponStatus status,
        Instant issuedAt,
        Instant expiresAt,
        Instant usedAt
    ) {
        if (user == null) {
            throw new IllegalArgumentException("쿠폰 소유 사용자는 필수입니다.");
        }
        if (coupon == null) {
            throw new IllegalArgumentException("쿠폰 정보는 필수입니다.");
        }
        if (status == null) {
            throw new IllegalArgumentException("쿠폰 상태는 필수입니다.");
        }
        if (issuedAt == null || expiresAt == null || !expiresAt.isAfter(issuedAt)) {
            throw new IllegalArgumentException("만료 시간은 발급 시간보다 이후여야 합니다.");
        }
        if (status == UserCouponStatus.AVAILABLE && usedAt != null) {
            throw new IllegalArgumentException("사용 가능한 쿠폰은 사용 일시를 가질 수 없습니다.");
        }
        if (status == UserCouponStatus.USED && usedAt == null) {
            throw new IllegalArgumentException("사용된 쿠폰은 사용 일시를 가져야 합니다.");
        }
        this.user = user;
        this.coupon = coupon;
        this.status = status;
        this.issuedAt = issuedAt;
        this.expiresAt = expiresAt;
        this.usedAt = usedAt;
    }

    public CouponDisplayStatus displayStatus(Instant now) {
        if (status == UserCouponStatus.USED) {
            return CouponDisplayStatus.USED;
        }
        if (!expiresAt.isAfter(now)) {
            return CouponDisplayStatus.EXPIRED;
        }
        return CouponDisplayStatus.AVAILABLE;
    }

    public Long getId() {
        return id;
    }

    public Coupon getCoupon() {
        return coupon;
    }

    public Instant getIssuedAt() {
        return issuedAt;
    }

    public Instant getExpiresAt() {
        return expiresAt;
    }

    public Instant getUsedAt() {
        return usedAt;
    }
}
