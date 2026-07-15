package com.gamjamubwatna.coupon.domain;

import jakarta.persistence.LockModeType;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UserCouponRepository extends JpaRepository<UserCoupon, Long> {

    @EntityGraph(attributePaths = "coupon")
    List<UserCoupon> findByUserIdOrderByIssuedAtDesc(Long userId);

    @EntityGraph(attributePaths = "coupon")
    Optional<UserCoupon> findByIdAndUserId(Long id, Long userId);

    // 쿠폰 사용 요청이 동시에 들어와도 한 트랜잭션만 AVAILABLE 상태를 변경해야 한다.
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @EntityGraph(attributePaths = "coupon")
    @Query("select userCoupon from UserCoupon userCoupon "
        + "where userCoupon.id = :id and userCoupon.user.id = :userId")
    Optional<UserCoupon> findByIdAndUserIdForUpdate(
        @Param("id") Long id,
        @Param("userId") Long userId
    );
}
