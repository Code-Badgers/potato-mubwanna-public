package com.gamjamubwatna.visit.domain;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UserVisitRepository extends JpaRepository<UserVisit, Long> {

    boolean existsByUserIdAndTouristSpotId(Long userId, Long touristSpotId);

    // 사진 기록의 보상 복구 요청이 동시에 들어와도 한 번만 처리한다.
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select visit from UserVisit visit where visit.user.id = :userId "
        + "and visit.touristSpot.id = :spotId")
    Optional<UserVisit> findByUserIdAndSpotIdForUpdate(
        @Param("userId") Long userId, @Param("spotId") Long spotId
    );

    boolean existsByUserIdAndTouristSpotNameAndTouristSpotCityName(
        Long userId,
        String spotName,
        String cityName
    );

    boolean existsByUserIdAndTouristSpotNameAndTouristSpotCityNameAndVisitedAtGreaterThanEqualAndVisitedAtLessThan(
        Long userId,
        String spotName,
        String cityName,
        Instant startInclusive,
        Instant endExclusive
    );

    @Query("""
        SELECT COUNT(DISTINCT visit.touristSpot.cityName)
        FROM UserVisit visit
        WHERE visit.user.id = :userId
          AND visit.visitedAt >= :startInclusive
          AND visit.visitedAt < :endExclusive
        """)
    long countDistinctVisitedCities(
        @Param("userId") Long userId,
        @Param("startInclusive") Instant startInclusive,
        @Param("endExclusive") Instant endExclusive
    );

    @EntityGraph(attributePaths = "touristSpot")
    List<UserVisit> findByUserIdOrderByVisitedAtDesc(Long userId);

    void deleteAllByUserId(Long userId);
}
