package com.gamjamubwatna.coupon.domain;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserCouponRepository extends JpaRepository<UserCoupon, Long> {

    @EntityGraph(attributePaths = "coupon")
    List<UserCoupon> findByUserIdOrderByIssuedAtDesc(Long userId);

    @EntityGraph(attributePaths = "coupon")
    Optional<UserCoupon> findByIdAndUserId(Long id, Long userId);
}
