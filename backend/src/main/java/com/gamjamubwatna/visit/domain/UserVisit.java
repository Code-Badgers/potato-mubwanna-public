package com.gamjamubwatna.visit.domain;

import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.spot.domain.TouristSpot;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(
    name = "user_visits",
    uniqueConstraints = {
        @UniqueConstraint(
            name = "uk_user_visits_user_spot",
            columnNames = {"user_id", "tourist_spot_id"}
        )
    }
)
public class UserVisit {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "user_visit_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tourist_spot_id", nullable = false)
    private TouristSpot touristSpot;

    @Column(name = "distance_meters", nullable = false, precision = 10, scale = 2)
    private BigDecimal distanceMeters;

    @Column(name = "visited_at", nullable = false, updatable = false)
    private Instant visitedAt;

    @Column(name = "visit_rewards_processed", nullable = false)
    private boolean visitRewardsProcessed = true;

    protected UserVisit() {
    }

    public UserVisit(User user, TouristSpot touristSpot, BigDecimal distanceMeters, Instant visitedAt) {
        this.user = user;
        this.touristSpot = touristSpot;
        this.distanceMeters = distanceMeters;
        this.visitedAt = visitedAt;
    }

    public static UserVisit fromPhotoEvidence(
        User user, TouristSpot touristSpot, BigDecimal distanceMeters, Instant visitedAt
    ) {
        UserVisit visit = new UserVisit(user, touristSpot, distanceMeters, visitedAt);
        // 사진 미션은 여행 기록만 생성한다. 별도 방문 인증에서 보상을 처리해야 한다.
        visit.visitRewardsProcessed = false;
        return visit;
    }

    public boolean isVisitRewardsProcessed() {
        return visitRewardsProcessed;
    }

    public void markVisitRewardsProcessed() {
        visitRewardsProcessed = true;
    }

    public Long getId() {
        return id;
    }

    public User getUser() {
        return user;
    }

    public TouristSpot getTouristSpot() {
        return touristSpot;
    }

    public BigDecimal getDistanceMeters() {
        return distanceMeters;
    }

    public Instant getVisitedAt() {
        return visitedAt;
    }
}
