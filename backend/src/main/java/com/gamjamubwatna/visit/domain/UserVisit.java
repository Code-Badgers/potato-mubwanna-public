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

    protected UserVisit() {
    }

    public UserVisit(User user, TouristSpot touristSpot, BigDecimal distanceMeters, Instant visitedAt) {
        this.user = user;
        this.touristSpot = touristSpot;
        this.distanceMeters = distanceMeters;
        this.visitedAt = visitedAt;
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
