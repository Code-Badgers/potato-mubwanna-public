package com.gamjamubwatna.potato.domain;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserDailyActivityRepository extends JpaRepository<UserDailyActivity, Long> {

    Optional<UserDailyActivity> findByUserIdAndActivityDateAndSource(
        Long userId,
        LocalDate activityDate,
        ActivitySource source
    );

    List<UserDailyActivity> findByUserIdAndActivityDateBetween(
        Long userId,
        LocalDate startDate,
        LocalDate endDate
    );
}
