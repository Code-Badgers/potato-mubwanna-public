package com.gamjamubwatna.visit.domain;

import java.util.List;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserVisitRepository extends JpaRepository<UserVisit, Long> {

    boolean existsByUserIdAndTouristSpotId(Long userId, Long touristSpotId);

    @EntityGraph(attributePaths = "touristSpot")
    List<UserVisit> findByUserIdOrderByVisitedAtDesc(Long userId);

    void deleteAllByUserId(Long userId);
}
