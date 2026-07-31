package com.gamjamubwatna.potato.domain;

import java.time.LocalDate;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

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

    @Query("""
        SELECT COALESCE(SUM(activity.steps), 0)
        FROM UserDailyActivity activity
        WHERE activity.user.id = :userId
        """)
    long sumStepsByUserId(@Param("userId") Long userId);

    @Query("""
        SELECT COALESCE(SUM(activity.steps), 0)
        FROM UserDailyActivity activity
        WHERE activity.user.id = :userId
          AND activity.activityDate = :activityDate
          AND activity.source IN :sources
        """)
    long sumStepsByUserIdAndActivityDateAndSources(
        @Param("userId") Long userId,
        @Param("activityDate") LocalDate activityDate,
        @Param("sources") Collection<ActivitySource> sources
    );

    @Query("""
        SELECT COALESCE(SUM(activity.steps), 0)
        FROM UserDailyActivity activity
        WHERE activity.user.id = :userId
          AND activity.activityDate >= :startDate
          AND activity.activityDate < :endDate
          AND activity.source IN :sources
        """)
    long sumStepsByUserIdAndActivityDateRangeAndSources(
        @Param("userId") Long userId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate,
        @Param("sources") Collection<ActivitySource> sources
    );
}
