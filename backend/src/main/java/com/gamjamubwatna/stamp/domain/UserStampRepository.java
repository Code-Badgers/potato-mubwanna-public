package com.gamjamubwatna.stamp.domain;

import java.time.Instant;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UserStampRepository extends JpaRepository<UserStamp, Long> {

    @Query("""
        SELECT userStamp
        FROM UserStamp userStamp
        JOIN FETCH userStamp.stamp
        WHERE userStamp.user.id = :userId
        """)
    List<UserStamp> findByUserIdWithStamp(@Param("userId") Long userId);

    int countByUserId(Long userId);

    long countByUserIdAndAcquiredAtGreaterThanEqualAndAcquiredAtLessThan(
        Long userId,
        Instant startInclusive,
        Instant endExclusive
    );

    boolean existsByUserIdAndStampId(Long userId, Long stampId);
}
