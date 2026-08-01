package com.gamjamubwatna.potato.domain;

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
import jakarta.persistence.UniqueConstraint;
import java.time.Instant;
import java.time.LocalDate;

@Entity
@Table(
    name = "user_daily_activities",
    uniqueConstraints = {
        @UniqueConstraint(
            name = "uk_user_daily_activities_user_date_source",
            columnNames = {"user_id", "activity_date", "source"}
        )
    }
)
public class UserDailyActivity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "user_daily_activity_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "activity_date", nullable = false)
    private LocalDate activityDate;

    @Column(name = "steps", nullable = false)
    private int steps;

    @Column(name = "distance_meters", nullable = false)
    private double distanceMeters;

    @Enumerated(EnumType.STRING)
    @Column(name = "source", nullable = false, length = 30)
    private ActivitySource source;

    @Column(name = "synced_at", nullable = false)
    private Instant syncedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected UserDailyActivity() {
    }

    public UserDailyActivity(
        User user,
        LocalDate activityDate,
        int steps,
        double distanceMeters,
        ActivitySource source,
        Instant now
    ) {
        this.user = user;
        this.activityDate = activityDate;
        this.steps = steps;
        this.distanceMeters = distanceMeters;
        this.source = source;
        this.syncedAt = now;
        this.createdAt = now;
        this.updatedAt = now;
    }

    // 하향 보정 뒤 같은 누적 구간이 다시 들어와 성장량이 중복 지급되지 않도록 최대값만 보관한다.
    public double mergeSnapshot(int steps, double distanceMeters, Instant now) {
        double previousDistanceMeters = this.distanceMeters;
        this.steps = Math.max(this.steps, steps);
        this.distanceMeters = Math.max(this.distanceMeters, distanceMeters);
        this.syncedAt = now;
        this.updatedAt = now;
        return this.distanceMeters - previousDistanceMeters;
    }

    public LocalDate getActivityDate() {
        return activityDate;
    }

    public int getSteps() {
        return steps;
    }

    public double getDistanceMeters() {
        return distanceMeters;
    }

    public ActivitySource getSource() {
        return source;
    }

    public Instant getSyncedAt() {
        return syncedAt;
    }
}
