package com.gamjamubwatna.visit.domain;

import java.time.Instant;
import java.util.List;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UserVisitRepository extends JpaRepository<UserVisit, Long> {

    boolean existsByUserIdAndTouristSpotId(Long userId, Long touristSpotId);

    boolean existsByUserIdAndTouristSpotNameAndTouristSpotCityName(
        Long userId,
        String spotName,
        String cityName
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
