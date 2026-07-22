package com.gamjamubwatna.visit.domain;

import org.springframework.data.jpa.repository.JpaRepository;

public interface UserVisitRepository extends JpaRepository<UserVisit, Long> {

    boolean existsByUserIdAndTouristSpotId(Long userId, Long touristSpotId);
}
